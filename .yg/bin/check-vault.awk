# Checks on wiki pages, frontmatter and body, one file at a time. Driven by check-vault.sh, which
# passes root, the wiki root with a trailing slash, today, YYYY-MM-DD, and names, a file
# listing each page name no other file shares, lowercased.
#
# Lives in its own file rather than inline in the shell: `find -exec ... {} +` treats
# the awk program's own {} blocks as its path placeholder and refuses the command.
#
# Portability (`F18.2`): no character classes; `[ \t\r]` stands in for [[:space:]].

function say(msg) { printf "%s: %s\n", file, msg }

# Required fields are checked at the closing --- , where the whole block is known.
# POSIX awk has no ENDFILE hook (`F18.1.1`), and the close is the same point in the file.
# Both delimiters are exactly ---, CR aside, as Obsidian reads them (`F15.2`); a block that
# never closes is reported at the next file or at END.
function finish() {
	if (is_machine || is_index) return
	if (!has_type)  say("missing type")
	if (!has_pitch) say("missing pitch")
	# The staleness review dates a page by its checkpoint and cannot research one it cannot
	# read, so a page carrying volatility: gets one it can, from the write that adds it.
	# Whether it is due is the review's (`D15.1`); this is only whether it can be dated.
	if (has_vol && vol !~ /^(high|medium|low)$/) say("volatility — not high, medium or low: " vol)
	if (has_vol && cp == "") say("volatility without a checkpoint")
	else if (has_vol) {
		d = cp; if (d ~ / \([^()]*\)$/) { sub(/.* \(/, "", d); sub(/\)$/, "", d) }
		if (!valid(d)) say("checkpoint — not a date or tool @ version (date): " cp)
		else if (today != "" && d > today) say("checkpoint — after today: " cp)
	}
}

# staleness.sh's own test of a date, so a checkpoint passing here is one it can read.
function valid(s,   y, m, dd, lim) {
	if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
	y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; dd = substr(s, 9, 2) + 0
	if (m < 1 || m > 12 || dd < 1) return 0
	lim = substr("312831303130313130313031", 2 * m - 1, 2) + 0
	if (m == 2 && (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0))) lim = 29
	return dd <= lim
}

FNR == 1 {
	if (infm) say("frontmatter never closed")
	# By index rather than sub(): the root is a path, and a regex would read its dots,
	# pluses and brackets as operators.
	file = FILENAME; if (index(file, root) == 1) file = substr(file, length(root) + 1)
	fence = 0; table = 0; prev = ""
	n = split(file, part, "/")
	is_index = (part[n] == "Index.md")
	infm = 0; has_type = 0; has_pitch = 0; is_machine = 0; has_vol = 0; vol = cp = ""
	if ($0 ~ /^---\r?$/) infm = 1
	else say("no frontmatter")
	next
}

infm && /^---\r?$/ { infm = 0; finish(); next }

infm {
	i = index($0, ":")
	if (i == 0) next
	key = substr($0, 1, i - 1)
	val = substr($0, i + 1)
	sub(/^[ \t\r]+/, "", val); sub(/[ \t\r]+$/, "", val)

	keys[key]++
	if (key == "type")  has_type = 1
	if (key == "pitch") has_pitch = 1
	if (key == "volatility") { has_vol = 1; vol = val }
	if (key == "checkpoint") cp = val
	if (key == "role" && (val == "instruction" || val == "derived")) is_machine = 1

	if (val == "") next

	# `F15.1`, `F15.1.1`. Obsidian parses frontmatter as strict YAML and rejects the *entire* property
	# block on one bad value, so a single stray colon-space silently costs the page
	# every field it has — including the pitch its index row and recall depend on. Some
	# values parse and lose content instead, and some parse as written but are banned (D21.1):
	# each row says which, so a parse failure is never conflated with house style. A closed
	# quoted value reads whole, `: ` and ` #` included.
	void = "which voids the whole property block"
	lead = substr(val, 1, 1)
	closed = index("\047\"", lead) > 0 && length(val) >= 2 && substr(val, length(val)) == lead
	if (!closed && val ~ /: /) say(key " — value contains \": \", " void)
	if (!closed && val ~ /:$/) say(key " — value ends with \":\", " void)
	if (!closed && val ~ / #/) say(key " — value contains \" #\", which cuts the value off at the comment")

	if (index(",[]{}*!%@`", lead) > 0 || (index("-?:", lead) > 0 && substr(val, 2, 1) == " "))
		say(key " — value leads with YAML indicator `" lead "`, " void)
	else if (lead == "#")
		say(key " — value leads with YAML indicator `#`, which leaves the value empty")
	else if (lead == "&")
		say(key " — value leads with YAML indicator `&`, which takes its first word as an anchor name")
	else if (index("|>", lead) > 0 && val !~ /^[|>][-+]?$/)
		say(key " — value leads with `" lead "` and has text after it, " void)
	else if (index("\047\"", lead) > 0 && !closed)
		say(key " — value opens a `" lead "` quote it never closes, " void)
	else if (index("-?:\047\"|>", lead) > 0)
		say(key " — value leads with `" lead "`: parses cleanly, but banned by house style (D21.1)")
}

# Body. A wikilink is written bare (`D7.4`), and Obsidian writes a qualified one by itself
# (`F14.3`): subject-first where the wiki is the vault, folder-first where it sits inside one,
# so the path's first segment says nothing. What does is the name: a link to a page whose
# name no other file in the wiki shares, in any letter case, would resolve bare, so it is reported. A shared name, a
# subject's Index and anything not a page keep their path. Indexes and machine files are not
# read: they are not pages, and a generated view's link form is the regenerator's (`F14.1`).
# Unique means among the wiki's files outside a dotfolder, not the vault's, and nothing is in a wiki inside a larger vault (`D7.4`). Fenced blocks and inline code
# are skipped, as in check-vault.sh: a page about links quotes examples, not references.
BEGIN { while ((getline n < names) > 0) unique[n] }

!infm && (/^[ \t\r]*```/ || /^[ \t\r]*~~~/) { fence = !fence; next }

# A table cell reads an unescaped | as a column break and drops the rest of the cell, an
# alias included (`F16.2`). Only in a table: outside one the two forms render the same, and
# Obsidian writes the pipe unescaped itself. A table is recognised by its delimiter row,
# which also puts the header row above it in, and runs to the next blank line.
function pipes(line,   s, i, j, t, p) {
	s = line
	gsub(/`[^`]*`/, "", s)
	while ((i = index(s, "[[")) > 0) {
		s = substr(s, i)
		j = index(s, "]]")
		if (j == 0) break
		t = substr(s, 3, j - 3)
		p = index(t, "|")
		if (p && substr(t, p - 1, 1) != "\\")
			say("unescaped alias pipe in a table, which drops the rest of the cell (F16.2): " substr(s, 1, j + 1))
		s = substr(s, j + 2)
	}
}

!infm && !fence && !is_machine && !is_index {
	if ($0 ~ /^[ \t\r]*$/) table = 0
	else if (!table && index($0, "|") && $0 ~ /^[ \t]*\|?[ \t]*:?-+:?[ \t]*(\|[ \t]*:?-+:?[ \t]*)*\|?[ \t\r]*$/) {
		table = 1
		pipes(prev)
	} else if (table) pipes($0)
	prev = $0
	# Obsidian's sanitizer strips a <style> element from a note (`F16.4`), so styling in one
	# never renders.
	s = $0; gsub(/`[^`]*`/, "", s)
	if (s ~ /<style([ \t\r>\/]|$)/) say("<style> element, which Obsidian strips (F16.4): style with attributes instead")
}

!infm && !fence && !is_machine && !is_index && index($0, "[[") {
	s = $0
	gsub(/`[^`]*`/, "", s)
	while ((i = index(s, "[[")) > 0) {
		s = substr(s, i)
		j = index(s, "]]")
		if (j == 0) break
		t = substr(s, 3, j - 3)
		sub(/[|#].*/, "", t); sub(/\\$/, "", t)
		if (index(t, "/")) {
			sub(/.*\//, "", t); sub(/\.md$/, "", t)
			if (tolower(t) in unique) say("qualified wikilink, write it bare (D7.4): " substr(s, 1, j + 1))
		}
		s = substr(s, j + 2)
	}
}

# Keys are counted across every page this invocation saw, and summed by the shell, since
# find may split the pages over several invocations. The = prefix cannot open a finding,
# every one of which starts with a path.
END {
	if (infm) say("frontmatter never closed")
	for (k in keys) printf "=key\t%s\t%d\n", k, keys[k]
}
