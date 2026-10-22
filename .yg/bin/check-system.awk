# The single pass behind check-system.sh. Reads every scanned file once, collecting
# definitions and citations, and resolves them in END — a citation can precede its
# definition in argument order. Prints findings, `notice: ` lines, `P loc<TAB>path` for
# the paths the shell has to stat, and a `C` record per fact and checkpointed tool for the
# shell's drift check: line, id, tool, versions joined by `|`, self-judging probe, citers —
# separated by \037, since a tab is whitespace to the shell's read and collapses an empty
# field, which would slide the citers into the probe's place and run them. Filenames are
# relative to the root, as passed.
#
# POSIX awk only: macOS's is the floor (`F18.2`), so no \b, no
# match() with a capture array, no length() of an array.

BEGIN {
	FACTS = ".yg/facts.md"; CATALOG = ".yg/forge-catalog.md"; CONFIG = ".yg/default/config.conf"
	n = split(tests, t, " ")
	for (i = 1; i <= n; i++) script[base(t[i])] = 1
	WORD = "[A-Za-z0-9_]"; US = "\037"
	# An id is a group's number and one part or more below it (facts.md § *The four fields*):
	# an entry is a heading carrying one, and a group's heading, with no part below it, is
	# not an entry. A citation is matched in any shape, so a group or an id left over from
	# before a rename is reported as an id that does not exist.
	NUM = "[0-9]+(\\.[0-9]+)*[a-z]?"; ID = "[FD]" NUM
	ENTRY = "^#+ [FD][0-9]+(\\.[0-9]+)+ "
}

FNR == 1 {
	fclose_(); dclose()
	f = FILENAME; files[++nf] = f
	script[base(f)] = 1
}

{ text[f] = text[f] "\n" $0; lines[f, FNR] = $0; nl[f] = FNR }

# Record form: a fact carries its four fields, a probe is one of the four states, and a
# checkpoint is `tool @ version` with its date bracketed after it (facts.md § *The four
# fields*). A decision names what it ruled out.
f == FACTS && /^#+ / { fclose_(); if ($0 ~ ENTRY) { fid = idof($0); fline = FNR } }
f == FACTS && fid != "" && match($0, /^\*\*(Statement|Probe|Checkpoints|Trigger)\.\*\* */) {
	field = substr($0, 3, index($0, ".") - 3); seen[field] = 1
	rest = substr($0, RLENGTH + 1)
	if (field == "Probe" && rest !~ /^(`|Manual|Not probeable here|Unprobed)/)
		print f ":" FNR ": probe is none of the four states: " fid
	if (field == "Checkpoints" && rest !~ /^None/) checkpoints(rest)
	# A probe the script can judge is one command and nothing else: its exit status is
	# the verdict. A command wrapped in prose needs a reader to say whether it held.
	if (field == "Probe" && rest ~ /^`[^`]+`\.?$/) { c = rest; sub(/\.$/, "", c); auto[fid] = substr(c, 2, length(c) - 2) }
}
f == CATALOG && /^#/ { dclose(); if ($0 ~ ENTRY) { did = idof($0); dline = FNR; dnot = 0 } }
f == CATALOG && did != "" && tolower($0) ~ /explicitly not/ { dnot = 1 }

# An unpinned sort orders by locale under GNU and by byte under uutils, so on a uutils
# machine no test can see it (F19.1). Code only, comments aside; a version probe is exempt.
f ~ /^\.yg\/(bin|hooks|githooks)\// && unpinned_sort($0) { print f ":" FNR ": unpinned sort: pin it with LC_ALL=C" }

# Every date is UTC (D11.2). Prose as well as code, since a flow's prose fetches dates too; facts.md
# aside, whose probes run a tool's wrong form on purpose.
f != FACTS && (ld = local_date($0)) { print f ":" FNR ": " (ld == 2 ? "date -r: uutils ignores -u beside it (F17.1.1.1), so take the date from stat under TZ=UTC0" : "local date: pass -u") }

# Per-agent memory grants Read, Write and Edit over the whole project, whatever `tools:`
# declares (F6.1.1), so an agent's frontmatter never sets it. An agent whose tools: holds a
# web tool reads fetched text with a way off the machine, so it sets omitClaudeMd: true
# (agent-contract.md); checked at the closing ---, where the whole block is known.
f ~ /^\.yg\/agents\// {
	if (FNR == 1) { agentfm = ($0 == "---"); web = omit = 0 }
	else if (agentfm && $0 == "---") {
		agentfm = 0
		if (web && !omit) print f ":" web ": agent holds a web tool without omitClaudeMd: true"
	}
	else if (agentfm && /^memory:/) print f ":" FNR ": agent sets memory:, which grants Read, Write and Edit"
	else if (agentfm && /^tools:/ && /Web(Fetch|Search)/) web = FNR
	else if (agentfm && /^omitClaudeMd:[ \t]*true[ \t\r]*$/) omit = 1
}

# A script records what waiting on it costs, or why that is not timed (D23.1): a comment
# line opening with `Cost:`, anywhere in the file.
/^#[ \t]*Cost:/ { costed[f] = 1 }

# Definitions.
f == FACTS && $0 ~ ENTRY && /^#+ F/ { def("F", idof($0), FNR) }
f == CATALOG && $0 ~ ENTRY && /^#+ D/ { def("D", idof($0), FNR) }
f == CONFIG && match($0, /^(# )?[a-z][a-z-]*\.[a-z_][a-z0-9_.-]*:/) {
	k = substr($0, RSTART, RLENGTH - 1); sub(/^# /, "", k)
	known[k] = 1; ns[substr(k, 1, index(k, ".") - 1)] = 1
	if ($0 !~ /^#/) keyline[k] = FNR
	next
}
f ~ /\.md$/ && /^#+ / {
	h = $0; sub(/^#+ /, "", h); gsub(/[*`]/, "", h)
	heads[f] = heads[f] "\n" h
	# A record's heading is cited by its title too, the id before it dropped.
	if (sub("^" ID " — ", "", h)) heads[f] = heads[f] "\n" h
}

# Citations.
{
	loc = f ":" FNR
	scan($0, "\\.(yg|claude)/[A-Za-z0-9_./-]*", "path")
	scan($0, "/yggdrasil:[a-z][a-z-]*", "skill")
	scan($0, "[A-Za-z0-9_-]+\\.(sh|awk)", "script")
	scan($0, "F" NUM, "F")
	scan($0, "D" NUM, "D")
	scan($0, "[a-z][a-z-]*\\.[a-z_][a-z0-9_.-]*", "key")
	sections($0)
}

END {
	fclose_(); dclose()

	# A worklist replaces the report: id, line, and for a fact the files citing it.
	if (worklist != "") {
		k = worklist == "facts" ? "F" : "D"
		for (i = 1; i <= nk[k]; i++) {
			v = order[k, i]
			print v "\t" defline[k, v] (k == "F" ? "\t" citers[v] : "")
		}
		exit
	}

	for (i = 1; i <= ncp; i++)
		print "C" US cpline[i] US cpid[i] US cptool[i] US cpv[cpid[i], cptool[i]] US auto[cpid[i]] US citers[cpid[i]]

	for (i = 1; i <= ncite; i++) {
		k = ckind[i]; v = cval[i]; l = cloc[i]
		if (k == "F" && !(("F", v) in defline)) print l ": fact does not exist: " v
		if (k == "D" && !(("D", v) in defline)) print l ": decision does not exist: " v
		# A skill is invoked as /yggdrasil:<name> and lives in .yg/skills/<name>/ (F8.5).
		if (k == "skill" && !((".yg/skills/" substr(v, 12) "/SKILL.md") in text))
			print l ": skill does not exist: " v
		if (k == "script" && !(v in script)) print l ": script does not exist: " v
		if (k == "key" && (substr(v, 1, index(v, ".") - 1) in ns) && !(v in known))
			print l ": config key does not exist: " v
	}

	# Orphans. A citation from the defining file does not count: a fact's own entry, or
	# the catalog citing itself, keeps nothing alive that the mechanism has stopped using.
	for (k in defline) {
		split(k, p, SUBSEP)
		if (p[1] == "F" && !(k in citedout))
			print FACTS ":" defline[k] ": fact is cited by nothing: " p[2]
		if (p[1] == "D" && !(k in citedout))
			print "notice: " CATALOG ":" defline[k] ": decision is cited by nothing: " p[2]
	}
	for (i = 1; i <= nf; i++) {
		s = files[i]
		if (s ~ /^\.yg\/(bin|hooks|githooks)\//) {
			if (!named(base(s), s, "")) print s ": script is named by nothing"
			# An .awk runs under the script that calls it, which records the cost of both,
			# and a .json among the hooks is their configuration, not a script.
			if (s !~ /\.(awk|json)$/ && !(s in costed)) print s ": script records no cost: add a Cost: line"
		} else if (s ~ /^\.yg\/templates\/.*\.md$/ && base(s) != "README.md") {
			# Templates are chosen by type (`<type>.md`), so it is the type word that keeps
			# one live, whole-word so `practice` is not kept alive by `practices`.
			stem = base(s); sub(/\.md$/, "", stem)
			if (!named("(^|[^A-Za-z0-9_-])" stem "([^A-Za-z0-9_-]|$)", s, "^\\.yg/templates/", 1))
				print s ": template is referenced by nothing"
		}
	}
	# A section can be cited before its heading is read, in this file or a later one. A
	# file named without its folder is the one file of that name; a name two files share
	# names neither, and is skipped.
	for (s in text) { b = base(s); bases[b] = b in bases ? "" : s }
	for (i = 1; i <= nsec; i++) {
		target = sectarget[i]
		if (target !~ /\// && bases[target] != "") target = bases[target]
		if (!(target in text)) continue
		if (!index(heads[target] "\n", "\n" sectitle[i]))
			print secloc[i] ": section does not exist: " target " § *" sectitle[i] "*"
	}

	# A namespace is read whole where it is named as one, `ns.*` in backticks: bare, the
	# same characters open a bold span after a word ending in a full stop.
	for (k in keyline) {
		if (!named(k, CONFIG, "") && !named("`" substr(k, 1, index(k, ".")) "*`", CONFIG, ""))
			print CONFIG ":" keyline[k] ": config key is read by nothing: " k
	}
}

function fclose_(   k, i) {
	if (fid == "") return
	split("Statement Probe Checkpoints Trigger", k, " ")
	for (i = 1; i <= 4; i++) if (!(k[i] in seen)) print FACTS ":" fline ": fact lacks a field: " k[i] ": " fid
	fid = ""; split("", seen)
}

function dclose() {
	if (did != "" && !dnot) print CATALOG ":" dline ": decision names no rejected alternative: " did
	did = ""
}

# A group of checkpoints can share one date, and a span without `@` is an annotation
# (`sh -c`, a model tag), so what is required is one `tool @ version` and a date after it.
# A claim resting on no versioned tool — the model's — is checkpointed by its date alone,
# which the drift check has nothing to compare; a span there is a mistyped checkpoint.
function checkpoints(s,   last, span, tool, v) {
	if (s !~ /`/ && s ~ /\([^)]*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) return
	last = 0
	while (match(s, /`[^@`]+ @ [^`]+`/)) {
		last = 1; span = substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH)
		tool = substr(span, 1, index(span, " @ ") - 1); v = substr(span, index(span, " @ ") + 3)
		if (!((fid, tool) in cpv)) { cpid[++ncp] = fid; cptool[ncp] = tool; cpline[ncp] = fline; cpv[fid, tool] = v }
		else cpv[fid, tool] = cpv[fid, tool] "|" v
	}
	if (!last) print f ":" FNR ": checkpoint is not `tool @ version`: " fid
	else if (s !~ /\([^)]*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)
		print f ":" FNR ": checkpoint has no bracketed date: " fid
}

function base(p) { sub(/.*\//, "", p); return p }

function idof(s) { match(s, ID); return substr(s, RSTART, RLENGTH) }

function def(kind, id, line) {
	if ((kind, id) in defline) { print f ":" line ": id defined twice, first at line " defline[kind, id] ": " id; return }
	defline[kind, id] = line; order[kind, ++nk[kind]] = id
}

function cite(kind, v) {
	ckind[++ncite] = kind; cval[ncite] = v; cloc[ncite] = loc
	# A rule facts.md states outside every entry, as its preamble does, cites as any file does.
	if ((kind == "F" && (f != FACTS || fid == "")) || (kind == "D" && f != CATALOG)) citedout[kind, v] = 1
	if (kind == "F" && f != FACTS && !index(", " citers[v] ", ", ", " f ", "))
		citers[v] = citers[v] (citers[v] == "" ? "" : ", ") f
}

# Whether `name` appears in any scanned file other than `self` and those matching `skip`;
# as a regular expression when `re` is set, else literally.
function named(name, self, skip, re,   i) {
	for (i = 1; i <= nf; i++) {
		if (files[i] == self || (skip != "" && files[i] ~ skip)) continue
		if (re ? text[files[i]] ~ name : index(text[files[i]], name)) return 1
	}
	return 0
}

# Every match of `re` in `s`, filtered per kind by the characters either side of it.
function scan(s, re, kind,   line, at, st, pre, pre2, post, v) {
	line = s; at = 0
	while (match(s, re)) {
		v = substr(s, RSTART, RLENGTH)
		at += RSTART; st = at
		pre = at > 1 ? substr(line, at - 1, 1) : ""
		pre2 = at > 2 ? substr(line, at - 2, 2) : ""
		post = substr(s, RSTART + RLENGTH, 1)
		s = substr(s, RSTART + RLENGTH); at += RLENGTH - 1
		if (kind == "path") {
			# A pattern (`<name>`, `*`) or a shell variable is not a citation of one file,
			# nor is regex text (`\.yg/`), nor a path under the home folder (`~/.claude/`).
			if (pre ~ WORD || post ~ /[<*{$\\]/ || pre == "\\" || pre2 == "~/") continue
			sub(/\.+$/, "", v)
			print "P " loc "\t" v
		} else if (kind == "skill") {
			if (pre ~ /[A-Za-z0-9_.-]/) continue
			sub(/-+$/, "", v); cite(kind, v)
		} else if (kind == "script") {
			if (pre ~ /[A-Za-z0-9_.\/$<-]/ || post ~ WORD) continue
			cite(kind, v)
		} else if (kind == "F" || kind == "D") {
			if (pre ~ /[A-Za-z0-9_-]/ || post ~ WORD) continue
			# A record heading's own id defines it, and a group's is cited by no one.
			if ((f == FACTS || f == CATALOG) && substr(line, 1, st - 1) ~ /^#+ $/) continue
			cite(kind, v)
		} else if (kind == "key") {
			# A brace (`ns.key.{a,b}`) makes it a pattern, not one key.
			if (pre ~ /[A-Za-z0-9_.\/$-]/ || post ~ /[A-Za-z0-9_<*{]/) continue
			sub(/[.-]+$/, "", v)
			if (v ~ /\.(md|sh|awk|conf|json)$/) continue
			cite(kind, v)
		}
	}
}

# `§ *Title*` resolves against the headings of the file cited just before it, or of this
# file when none is, where this file is markdown. A file named through the program root
# (`${CLAUDE_PLUGIN_ROOT}/.yg/…`, `<program>/.yg/…`) is the same file. Resolved in END.
function sections(s,   head, target, title, m) {
	head = ""
	while (match(s, /§ \*[^*]+\*/)) {
		m = substr(s, RSTART, RLENGTH)
		head = head substr(s, 1, RSTART - 1)
		s = substr(s, RSTART + RLENGTH)
		title = m; sub(/^§ \*/, "", title); sub(/\*$/, "", title)
		target = head; sub(/[` ]+$/, "", target)
		if (match(target, /[A-Za-z0-9_.\/-]+\.md$/)) { target = substr(target, RSTART, RLENGTH); sub(/^\/+/, "", target) }
		else if (f ~ /\.md$/) target = f
		else continue
		secloc[++nsec] = loc; sectarget[nsec] = target; sectitle[nsec] = title
	}
}

# Whether a line formats a date without -u, 1, or from a file's mtime with -r, 2, whatever else
# it passes: date as a word, its options, then the + format.
function local_date(s,   seg) {
	s = " " s
	while (match(s, /[^A-Za-z0-9_.-]date([ \t]+-[-A-Za-z]+([ \t]+[^ \t+-][^ \t]*)?)*[ \t]+['"]?\+/)) {
		seg = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
		if (seg ~ /[ \t]-r[ \t]/) return 2
		if (seg !~ /[ \t](-u|--utc|--universal)[ \t]/) return 1
	}
	return 0
}

# Whether a line of shell calls sort without LC_ALL=C in front of it. A call is sort as a
# word after a separator or a quote, which takes in an awk pipe to "sort" as well.
function unpinned_sort(s,   pre) {
	if (s ~ /^[ \t]*#/) return 0
	sub(/[ \t]#.*/, "", s); s = " " s
	while (match(s, /[ \t|;&(`"']sort([ \t;|)`"']|$)/)) {
		pre = substr(s, 1, RSTART); s = substr(s, RSTART + 5)
		if (pre !~ /LC_ALL=C[ \t]+$/ && s !~ /^[ \t]+--version/) return 1
	}
	return 0
}
