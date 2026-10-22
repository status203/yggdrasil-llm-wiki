#!/bin/sh
# Check a wiki's pages against the contract. Reports; changes nothing.
#
# Everything checked here is mechanically decidable, which is what puts it in a script
# rather than in prose (`D1.1`, home 1). An LLM asked to remember YAML indicator characters
# while writing a page will sometimes not; this cannot forget. Most checks read one file;
# orphan sources, key spellings, shared filenames, sidecar names and qualified wikilinks
# read the whole set, which costs about the same and is why they are here rather than in a
# mode of their own.
#
# Deliberately not checked: cross-page contradiction and placement, which take judgment
# and belong to the content review (`D14.1`), and staleness, which is the staleness
# review's (`D15.1`).
#
# A page is a .md file in a subject folder — a top-level folder holding a .subject.md —
# outside any dotfolder. Root-level files and other folders hold no pages and are not checked,
# though every .md filename outside a dotfolder counts toward the unique-name list, since a
# link outside a subject still resolves (`D4.1.1`);
# the typed subfolders of .sources/ are read for the citations they carry and receive, and
# an .html file in a subject folder by its name alone, as a page's sidecar.
#
# Portability (`F18.2`): POSIX sh and awk, and no character classes in awk. `[ \t\r]` stands
# in for [[:space:]], so a page saved with CRLF line endings still reads.
#
# Usage: check-vault.sh WIKI_ROOT
# Output: one finding or notice per line, sorted, paths wiki-relative.
# Exit: 0 clean, or notices only; 1 findings; 2 usage, or no directory at WIKI_ROOT.
#
# Cost: runs after every page write (page-contract.md § After writing). Measured 2026-10-04
# on synthetic wikis of 20 subjects at 500, 1,000, 2,000 and 4,000 pages, each citing a
# source and linking one page bare: 0.07s, 0.11s, 0.20s, 0.38s, linear in pages at about
# 0.1ms each. The relative-link check adds a term of its own, one shell iteration per link
# target: at 500 pages, 0, 5,000 and 20,000 targets cost 0.03s, 0.35s and 1.3s, linear at
# about 0.06ms each. Watch citation density: at the one target per five pages seen on
# 2026-10-06 the term is a few milliseconds, and the loop is worth replacing (one sorted
# find listing compared in a single pass) only near a second's worth, some 15,000 targets. Transcription-heavy use is what would raise it.
# The unique-name count reads every .md file outside a dotfolder, one find over the wiki:
# against counting subject pages alone it adds 3ms, 2ms, 2ms and 6ms at those four sizes
# (2026-10-13), within the runs' noise.
# Linux, warm cache: the times are this machine's, the ratios are not.

set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
	echo "usage: check-vault.sh WIKI_ROOT" >&2
	exit 2
fi
WIKI=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || {
	echo "check-vault.sh: no wiki at $1 — not a directory" >&2
	exit 2
}
AWKPROG=$(dirname "$0")/check-vault.awk

# pages <find primaries...> — every page in every subject folder, one find for them all.
# -exec ... {} + rather than a pipe into xargs: page filenames contain spaces and
# apostrophes, which xargs splits on by default. -print0/-0 would solve that but is not
# in POSIX find or xargs, and tool availability is per-install rather than per-OS (`F17.1`).
# Subject folders go in front of the primaries; their order is immaterial, since every
# result below is sorted or summed. With none, find is not run, since it would search the
# working directory instead.
pages() { subjects -name '*.md' -type f "$@"; }
subjects() {
	set -- -name '.*' -prune -o "$@"
	for d in "$WIKI"/*/; do
		[ -f "$d.subject.md" ] || continue
		set -- "${d%/}" "$@"
	done
	case $1 in /*) find "$@" ;; esac
}

# The typed subfolders of .sources/. Files loose at its root are uncited by design (the page
# contract's citing rule), so nothing there is read or checked: each subfolder is a starting
# point, since POSIX find has no -mindepth (`F17.2`).
sources() {
	set -- -name '.*' -prune -o -type f "$@"
	for d in "$WIKI"/.sources/*/; do
		[ -d "$d" ] || continue
		set -- "${d%/}" "$@"
	done
	case $1 in /*) find "$@" ;; esac
}

# Page names no other file in the wiki shares, lowercased, for the qualified-wikilink check:
# a link matches a name in any letter case (`F14.2`), and a same-named file outside a subject
# makes the bare link ambiguous too (`F14.1.1`). Where this awk does not fold a letter outside
# ASCII (`F19.3`), a name holding one is left off, since a twin by case would go uncounted.
# In a wiki inside a larger vault the list stays empty: Obsidian qualifies a link there
# because a page outside the wiki shares its name (`F14.3`), which nothing here may read
# (`D3.2`, `D7.4`); elsewhere regen-views.sh counts the same, inverted. The vault is found as
# wiki-boundary.sh finds it, so a vault whose config folder was renamed and holds no
# .obsidian/ is not found, and the list is filled there (`F13.2`). A file rather than a
# -v value, which awk would read escapes in and which a large wiki would outgrow.
names=$(mktemp)
trap 'rm -f "$names"' EXIT
folds=0
[ "$(printf '\303\211\n' | awk '{ print tolower($0) }')" != "$(printf '\303\251')" ] || folds=1
vault=$WIKI
while [ ! -d "$vault/.obsidian" ] && [ "$vault" != / ]; do vault=$(dirname -- "$vault"); done
[ "$vault" != "$WIKI" ] && [ -d "$vault/.obsidian" ] ||
find "$WIKI/." \( -name '.*' ! -name . \) -prune -o -name '*.md' -type f -print |
	awk -v folds="$folds" '{ n = $0; sub(/.*\//, "", n); sub(/\.md$/, "", n); n = tolower(n); c[n]++ }
	END { for (n in c) if (c[n] == 1 && n != "index" && (folds || n !~ /[^ -~]/)) print n }' >"$names"

raw=$(pages -exec awk -v root="$WIKI/" -v today="$(date -u +%Y-%m-%d)" -v names="$names" -f "$AWKPROG" {} +)
findings=$(printf '%s\n' "$raw" | grep -v '^=key	' || true)

# Keys differing only in case are one property to Obsidian (`F15.3`) but two to this program's
# own readers, which match keys exactly, so a page carrying the other spelling is invisible
# to them. Summed here, because find may split
# the pages over several awk invocations.
cases=$(printf '%s\n' "$raw" | sed -n 's/^=key	//p' | LC_ALL=C sort | awk -F '	' '
	{ n[$1] += $2; if (!($1 in seen)) { seen[$1]; order[++m] = $1 } }
	END {
		for (i = 1; i <= m; i++) {
			k = order[i]; l = tolower(k); c[l]++
			list[l] = list[l] (c[l] > 1 ? ", " : "") k " (" n[k] ")"
		}
		for (l in c) if (c[l] > 1) print "frontmatter key in more than one case: " list[l]
	}')

# Relative markdown links resolve by path rather than through Obsidian's link graph --
# which is why a source citation has to be one (`F13.1.1`) -- so a page moved to a different
# depth silently breaks every link under its `## Sources`. Nothing in the editor shows
# it, because the target is off the graph. Decidable from the one file plus a stat, so
# it belongs here; whether anything cites a given source reads the whole set, and is
# checked below. Fenced blocks and inline code are skipped: a page about markdown quotes
# links that are examples, not references.
# Deliberately simple: a code span is taken as single backticks, so ``a [b](c) d`` is still read;
# match runs of equal length if a page ever quotes one.
#
# One awk for the whole wiki rather than one per page, since a process per page was the
# cost that dominated.
#
# Batching makes `fence` persist across files, hence the FNR reset: without it a page
# ending inside an unclosed fence silences the next page entirely. The `)` joining target
# to page is the one character a target provably cannot hold, being cut at the first `)`
# by the extraction below -- so the page field carries whatever a filename does and needs
# no escaping. A newline in a filename still breaks this, as it did the per-page form.
linkprog='
	FNR == 1 { fence = 0 }
	/^[ \t\r]*```/ || /^[ \t\r]*~~~/ { fence = !fence; next }
	fence { next }
	{
		s = $0
		gsub(/`[^`]*`/, "", s)
		while ((i = index(s, "](")) > 0) {
			s = substr(s, i + 2)
			j = index(s, ")")
			if (j == 0) break
			t = substr(s, 1, j - 1)
			s = substr(s, j + 1)
			if (t != "" && t !~ /^[A-Za-z]+:/ && t !~ /^#/) print t ")" FILENAME
		}
	}'

# Links in sources are read only for what they cite -- an image is cited by the note
# describing it. A dead link inside a source is part of the record, so is not reported.
links=$( { pages -exec awk "$linkprog" {} +; sources -name '*.md' -exec awk "$linkprog" {} +; } |
	while IFS= read -r line; do
	target=${line%%")"*}
	page=${line#*")"}
	target=${target%%#*}
	[ -n "$target" ] || continue
	if [ -e "${page%/*}/$target" ]; then
		printf 'cited:%s/%s\n' "${page%/*}" "$target"
	else
		case $page in
		"$WIKI/.sources/"*) ;;
		*) printf '%s: link does not resolve: %s\n' "${page#"$WIKI"/}" "$target" ;;
		esac
	fi
done)

# A typed source nothing links to backs nothing, and nothing else will surface it:
# .sources/ is off Obsidian's link graph (`F13.1.1`). Paths are normalised before comparing,
# since a citation reaches its source through ../ segments.
orphans=$( { printf '%s\n' "$links" | sed -n 's|^cited:||p' | awk '{
		n = split($0, seg, "/"); m = 0
		for (i = 1; i <= n; i++) {
			if (seg[i] == "" || seg[i] == ".") continue
			if (seg[i] == "..") { if (m) m--; continue }
			out[++m] = seg[i]
		}
		p = ""; for (i = 1; i <= m; i++) p = p "/" out[i]
		print "c " p
	}'; sources -print | sed 's/^/s /'; } | awk -v root="$WIKI/" '
	/^c / { c[substr($0, 3)]; next }
	!(substr($0, 3) in c) {
		p = substr($0, 3); if (index(p, root) == 1) p = substr(p, length(root) + 1)
		print p ": source nothing cites"
	}')

# Two pages sharing a filename resolve by folder (`F14.1.1`); two whose names differ only in
# letter case make a bare link unpredictable (`F14.2`). move-page.sh refuses on either.
# Two subjects may rightly want the same title, so it is a notice rather than a finding.
# Sorted first, so the row reads the same on every filesystem.
shared=$(pages -print | LC_ALL=C sort | awk -v root="$WIKI/" '
	{ p = $0; if (index(p, root) == 1) p = substr(p, length(root) + 1); n = split(p, s, "/"); b = s[n]; k = tolower(b) }
	k != "index.md" { if (!(k in c)) f[k] = b; c[k]++; l[k] = l[k] (c[k] > 1 ? ", " : "") p }
	END { for (k in c) if (c[k] > 1) print "notice: shared filename " f[k] ": " l[k] }')

# A sidecar moves with its page only when named for it, `<page-slug>--<what>.html`, the
# pattern move-page.sh carries (`D9.2`); one named otherwise is left behind. The slug is
# move-page.sh's, both under C: the filename's ASCII letters lowercased, each run of other
# characters one hyphen, a hyphen at either end dropped. A slug never holds `--`, so the name up
# to its first `--` is the slug or nothing is.
sidecars=$(subjects \( -name '*.md' -o -name '*.html' \) -type f -print | LC_ALL=C awk -v root="$WIKI/" '
	function slug(n) { n = tolower(n); gsub(/[^a-z0-9]+/, "-", n); sub(/^-/, "", n); sub(/-$/, "", n); return n }
	{ d = $0; sub(/\/[^\/]*$/, "", d); b = substr($0, length(d) + 2) }
	/\.md$/ { sub(/\.md$/, "", b); s[d "/" slug(b)]; next }
	{ h[++m] = $0; hd[m] = d; i = index(b, "--"); hs[m] = i ? substr(b, 1, i - 1) : "" }
	END {
		for (k = 1; k <= m; k++) if (hs[k] == "" || !((hd[k] "/" hs[k]) in s)) {
			p = h[k]; if (index(p, root) == 1) p = substr(p, length(root) + 1)
			print p ": sidecar not named <page-slug>--<what>.html for a page in its folder, so no move carries it (D9.2)"
		}
	}')

# A | in a page name ends the link target at the alias separator, escaped or not (`F16.2`), so no
# wikilink reaches the page; clusters.sh takes | as its separator for the same reason.
piped=$(pages -print | awk -v root="$WIKI/" '{ p = $0; if (index(p, root) == 1) p = substr(p, length(root) + 1)
	n = split(p, s, "/"); if (index(s[n], "|")) print p ": page name holds |, which no wikilink can reach" }')

all=$(printf '%s\n' "$findings" "$cases" "$links" "$orphans" "$shared" "$sidecars" "$piped" | grep -v -e '^$' -e '^cited:' || true)

[ -z "$all" ] && exit 0
printf '%s\n' "$all" | LC_ALL=C sort
# A notice alone leaves the check clean: a writer after writing reads exit 0 as clean.
printf '%s\n' "$all" | grep -qv '^notice: ' || exit 0
exit 1
