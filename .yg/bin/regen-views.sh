#!/bin/sh
# Regenerate a wiki's derived index views: the wiki index and Progressions.md at its root,
# and an Index.md in each subject folder.
#
# Indexes are views, not documents: anything derivable from the pages themselves is
# generated, never hand-maintained. Every view here is the same shape — glob a set of files,
# read frontmatter, emit a markdown table — which is why they share one script rather than
# one each. Separate regenerators were previously observed drifting against each other,
# spelling the same pipe-escape two different ways (`D6.1`). `F16.2` is why the escape is
# required at all.
#
# A subject is a top-level folder holding a .subject.md, in every mode. Any other folder —
# an import folder, say — gets no index, and nothing in it is listed.
#
# Portability (`F18.2`): POSIX sh and awk, and no character classes in awk. `[ \t\r]` stands
# in for [[:space:]], so a page saved with CRLF line endings still reads.
#
# Usage: regen-views.sh WIKI_ROOT [wiki|subjects|subject <name>|progressions|stale [--check]|all]
#   The mode defaults to all. Prints one "wrote <path>" per view written, wiki-relative.
#   --check then runs check-vault.sh over the wiki, so page-contract.md § After writing's
#   two steps are one call that cannot be run in the wrong order.
# Exit: 0 done; 2 usage, no directory at WIKI_ROOT, or `subject` naming a folder with no
# .subject.md. With --check, check-vault.sh's exit once the views are written.
#
# Cost: `stale` runs after every page write and at session start. Measured 2026-10-02 on
# synthetic wikis of 20 subjects with one page touched. With 20 progressions, at 500, 1,000,
# 2,000 and 4,000 pages: 0.18s, 0.19s, 0.21s, 0.24s, nearly flat in pages. At 2,000 pages
# with 10, 20, 40 and 80 progressions: 0.14s, 0.21s, 0.32s, 0.59s, linear in progressions
# at about 6ms each — `progressions` is rewritten on any staleness, and each row costs a
# few processes. `all` is 0.45s to 0.55s over the page sizes. Linux, warm cache: the times
# are this machine's, the ratios are not. publish()'s unchanged-rows check adds about 2ms a
# view written (2026-10-07). The shared-name count adds one find over the wiki to a run that
# writes a page view: 4ms, 7ms, 10ms and 12ms at 500 to 4,000 pages (2026-10-11), linear.
# view_subject()'s check for a page written during its scan adds up to three finds over the subject
# to each subject view written: 11ms at 2,000 pages in one subject (2026-10-18), linear.

set -eu

usage() {
	echo "usage: regen-views.sh WIKI_ROOT [wiki|subjects|subject <name>|progressions|stale [--check]|all]" >&2
	exit 2
}
[ $# -ge 1 ] && [ -n "$1" ] || usage
WIKI=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || {
	echo "regen-views.sh: no wiki at $1 — not a directory" >&2
	exit 2
}
shift
TODAY=$(date -u +%F)
TAB=$(printf '\t')

# fm <file> <key> — the value of one frontmatter key, empty when absent.
# Splits on the first colon and takes the value literally, as the config format does.
# Both delimiters are exactly ---, CR aside, as Obsidian reads them (`F15.2`).
fm() {
	awk -v want="$2" '
		NR == 1 && $0 !~ /^---\r?$/ { exit }
		NR == 1 { next }
		/^---\r?$/ { exit }
		{
			i = index($0, ":")
			if (i == 0) next
			if (substr($0, 1, i - 1) != want) next
			v = substr($0, i + 1)
			sub(/^[ \t\r]+/, "", v)
			sub(/[ \t\r]+$/, "", v)
			print v
			exit
		}
	' "$1"
}

# fm_all "<key>..." <dir>... — one line per page under each <dir>, dotfolders pruned: its
# path, then each key's value as fm() reads it, separated by US (a non-whitespace IFS, so an
# empty value keeps its place). One awk for every page, stopping at each page's frontmatter:
# a process per page was previously measured at most of what a page write waits on.
US=$(printf '\037')
fm_all() {
	keys=$1
	shift
	find "$@" -name '.*' -prune -o -name '*.md' -type f -exec awk -v keys="$keys" -v us="$US" '
		BEGIN {
			n = split(keys, k, " ")
			for (a = 1; a < ARGC; a++) {
				f = ARGV[a]
				split("", v)
				first = 1
				while ((getline line < f) > 0) {
					if (first) { first = 0; if (line ~ /^---\r?$/) continue; break }
					if (line ~ /^---\r?$/) break
					c = index(line, ":")
					if (c == 0) continue
					for (i = 1; i <= n; i++) {
						if (substr(line, 1, c - 1) != k[i] || (i in v)) continue
						val = substr(line, c + 1)
						sub(/^[ \t\r]+/, "", val)
						sub(/[ \t\r]+$/, "", val)
						v[i] = val
					}
				}
				close(f)
				out = f
				for (i = 1; i <= n; i++) out = out us v[i]
				print out
			}
			exit
		}
	' {} +
}

# esc <text> — escape pipes for a markdown table cell.
# `F16.2`: an unescaped | inside a cell is a column break and the overflow is silently
# dropped, which reaches a wikilink's alias separator. Required, not defensive.
esc() { printf '%s' "$1" | sed 's/|/\\|/g'; }

# mtime <file> — the file's modification date as YYYY-MM-DD, in UTC like every date (`D11.2`).
# stat(1) diverges between GNU and BSD userlands and the flags are incompatible (`F17.1`),
# so probe once rather than per call; date -u -r is no way round it, since uutils ignores
# -u beside -r (`F17.1.1.1`). Git is not the source here: a page's last-touched
# date is when the file changed, not when it was committed, and a repository's history can
# begin long after its pages were written — a copy given a fresh history, or a wiki moved in.
# A metadata-only edit reads as activity too. Accepted, since a running progression rarely
# gets one, and a scripted pass over them keeps mtimes with touch -r — explicitly not a
# frontmatter activity date, which every writer moving progress: would have to stamp.
if stat -c %y . >/dev/null 2>&1; then
	mtime() { TZ=UTC0 stat -c %y "$1" | cut -d' ' -f1; }
else
	mtime() { TZ=UTC0 stat -f %Sm -t %F "$1"; }
fi

# A linked worktree's files all carry the moment it was checked out (`F22.4`), so a page the
# worktree has not changed takes its date from the main checkout's copy. The wiki root is
# its repository's root; in a linked worktree its .git is a file rather than a directory,
# and the main checkout is the first worktree git lists.
MAIN=
if [ -f "$WIKI/.git" ]; then
	MAIN=$(git -C "$WIKI" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p') || MAIN=
fi
touched() {
	if [ -n "$MAIN" ] && cmp -s "$1" "$MAIN${1#"$WIKI"}"; then
		mtime "$MAIN${1#"$WIKI"}"
	else
		mtime "$1"
	fi
}

# publish <path> — replace a file with stdin, atomically, keeping the old one on failure.
publish() {
	tmp=$1.regen.$$
	cat >"$tmp"
	# A view whose rows haven't changed keeps its old file, date and all, so a regeneration
	# that changes nothing leaves no diff to commit. Only the frontmatter line starts this way:
	# every body line is a heading, prose or a table row.
	old=
	[ -f "$1" ] && old=$(fm "$1" regenerated)
	if [ -n "$old" ] && sed "s/^regenerated: $TODAY\$/regenerated: $old/" "$tmp" | cmp -s - "$1"; then
		rm "$tmp"
	else
		mv "$tmp" "$1"
	fi
	# The rename bumps the containing directory's mtime, landing it after the file
	# just written. A freshness check comparing the directory against this file would
	# then read stale immediately after every regen, so stamp the file last.
	touch "$1"
	printf 'wrote %s\n' "${1#"$WIKI"/}"
}

# Page names, lowercased and without .md, that a bare link may not reach alone: one that more
# than one file in the wiki carries in any letter case (`F14.1.1`, `F14.2`), and, where this awk
# does not fold a letter outside ASCII (`F19.3`), any name holding one, since a twin by case
# would go uncounted. A view links such a page by its path from the wiki root. The count is
# check-vault.sh's unique-name list inverted, so the two agree on which link may be bare, save
# in a wiki inside a larger vault (`D7.4`);
# test-regen-views.sh holds them to it over the shared awkward wiki. Built once a run, on
# the first view that needs it.
SHARED= counted=
shared() {
	[ -z "$counted" ] || return 0
	folds=0
	[ "$(printf '\303\211\n' | awk '{ print tolower($0) }')" != "$(printf '\303\251')" ] || folds=1
	SHARED=$(find "$WIKI/." \( -name '.*' ! -name . \) -prune -o -name '*.md' -type f -print |
		awk -v folds="$folds" '{ n = $0; sub(/.*\//, "", n); sub(/\.md$/, "", n); n = tolower(n); c[n]++ }
		END { for (n in c) if (n != "index" && (c[n] > 1 || (!folds && n ~ /[^ -~]/))) print n }')
	counted=1
}

# header <mode> <to-change> <pitch> — the frontmatter every derived view carries.
header() {
	cat <<-EOF
		---
		role: derived
		note: Regenerated by sh <program>/.yg/bin/regen-views.sh <wiki> $1 — edits here are overwritten. To change a row, edit $2.
		pitch: $3
		regenerated: $TODAY
		---
	EOF
}

view_wiki() {
	{
		header wiki "that subject's pitch in its .subject.md" \
			"Wiki index — one row per subject, linking through to that subject's page index."
		cat <<-'EOF'

			# Wiki index

			Top of the multi-level wiki index. Each row is a subject; the link goes to that subject's `Index.md`, which lists its content pages.

			| Subject | Description |
			| --- | --- |
		EOF
		for dir in "$WIKI"/*/; do
			subject=$(basename "$dir")
			[ -f "$dir.subject.md" ] || continue
			printf '| %s | %s |\n' \
				"$(esc "[[$subject/Index|$subject]]")" "$(esc "$(fm "$dir.subject.md" pitch)")"
		done
	} | publish "$WIKI/Index.md"
}

# pages <dir> — how many pages stale_subject() watches there.
pages() { find "$1" -name '*.md' ! -name 'Index.md' -print | wc -l; }

# view_subject <dir> — the dir is passed without a trailing slash, since BSD find doubles
# the slash between a start path ending in one and what it finds under it.
view_subject() {
	dir=$1
	subject=$(basename "$dir")
	# A page another writer adds, changes or deletes during the scan predates the stamp
	# publish() gives the view, so no later `stale` would see it. Where one did, the view
	# takes the scan's start as its stamp, and the next `stale` redoes the subject.
	mark=$(mktemp)
	n=$(pages "$dir")
	{
		header subjects "that page's pitch frontmatter" \
			"Index of pages in the $subject subject — one row per page with a brief description."
		cat <<-EOF

			# $subject index

			Subject index for $subject. One row per content page; descriptions come from each page's \`pitch\` frontmatter. Machine-side files (\`role: instruction\` or \`role: derived\`) are excluded.

			| Page | Description |
			| --- | --- |
		EOF
		# Recurse: a subject may nest folders, and the link is the subject-relative path
		# (`F14.1` — a wikilink resolves against any trailing suffix of the vault path), or the
		# path from the wiki root for a name shared() lists.
		# Dotfolders are pruned: they are off the Obsidian graph entirely (`F13.1.1`). A content
		# page is anything not an index and not marked machine-side.
		# The prefix is measured by the awk that cuts it, since an awk may count characters where
		# sh counts bytes, and a mismatch mangles every name under a non-ASCII folder (`F19.2`).
		shared
		fm_all "role pitch" "$dir" | LC_ALL=C sort | D="$dir/" J=$subject S=$SHARED awk -F "$US" '
			BEGIN { skip = length(ENVIRON["D"]); n = split(ENVIRON["S"], a, "\n"); for (i = 1; i <= n; i++) shared[a[i]] }
			# F16.2: an unescaped | inside a cell is a column break; the same escape as esc().
			function esc(s,   out, i) {
				out = ""
				while ((i = index(s, "|")) > 0) { out = out substr(s, 1, i - 1) "\\|"; s = substr(s, i + 1) }
				return out s
			}
			{
				name = substr($1, skip + 1)
				if (name ~ /(^|\/)Index\.md$/ || $2 == "instruction" || $2 == "derived") next
				sub(/\.md$/, "", name)
				base = name; sub(/.*\//, "", base)
				link = tolower(base) in shared ? "[[" ENVIRON["J"] "/" name "|" name "]]" : "[[" name "]]"
				printf "| %s | %s |\n", esc(link), esc($3)
			}
		'
	} | publish "$dir/Index.md"
	if [ "$(pages "$dir")" != "$n" ] ||
		[ -n "$(find "$dir" -name '*.md' ! -name 'Index.md' -newer "$mark" -print)" ]; then
		touch -r "$mark" "$dir/Index.md"
	fi
	rm -f "$mark"
}

view_progressions() {
	set --
	for d in "$WIKI"/*/; do
		[ -f "$d.subject.md" ] || continue
		set -- "$@" "${d%/}"
	done
	rows=
	shared
	[ $# -eq 0 ] || rows=$(
		fm_all "progress type" "$@" | awk -F "$US" '$2 != ""' | while IFS=$US read -r page progress kind; do
			kind=${kind##*/}
			name=$(basename "$page" .md)
			# The display name drops the trailing kind word: "Chess practice" reads as "Chess".
			display=${name%" $kind"}
			touched=$(touched "$page")
			target=$name
			printf '%s\n' "$name" | S=$SHARED awk 'BEGIN { n = split(ENVIRON["S"], a, "\n"); for (i = 1; i <= n; i++) s[a[i]] }
				{ exit !(tolower($0) in s) }' && { target=${page#"$WIKI"/}; target=${target%.md}; }
			printf '%s\t%s\t| %s | %s | %s | %s |\n' \
				"$touched" "$name" "$kind" "$(esc "[[$target|$display]]")" "$(esc "$progress")" "$touched"
		done | LC_ALL=C sort -t"$TAB" -k1,1r -k2,2 | cut -f3-
	)
	{
		header progressions "that page's progress frontmatter" \
			"In-progress progressions — tutorials, companions and practice pages with live tracking."
		cat <<-'EOF'

			# Progressions

			Derived view of in-progress progressions; rows come from each page's `progress:` field, newest activity first.

			| Kind | Progression | Position | Last touched |
			| --- | --- | --- | --- |
		EOF
		[ -n "$rows" ] && printf '%s\n' "$rows"
	} | publish "$WIKI/Progressions.md"
}

# --- freshness ----------------------------------------------------------------
# A view is stale when its sources outran it. Two mtime checks are needed and neither
# is sufficient alone: a file newer than the index catches a page modified or added,
# and a directory newer than it catches a page added or deleted -- a deletion leaves
# nothing newer behind. publish() stamps the index last, so its own write does not
# read as staleness. No -quit or -maxdepth: both are outside POSIX find, and skipping
# the early exit costs nothing measurable here (`F17.2`).

stale_subject() {
	[ -f "$1/Index.md" ] || return 0
	[ -n "$(find "$1" \( \( -name '*.md' ! -name 'Index.md' -newer "$1/Index.md" \) \
		-o \( -type d -newer "$1/Index.md" \) \) -print 2>/dev/null)" ]
}

# The wiki index lists subjects rather than pages, so page churn never touches it. It
# moves when a subject appears or goes -- subjects are entries in the wiki directory --
# or when a .subject.md pitch is edited. Progressions.md is published into the same
# directory, after the wiki index whenever both are written, so the directory is compared
# against it too: a directory newer than the wiki index but not than Progressions.md was
# last changed by that publish, and reading it as a subject's change would restale the wiki
# index on every run.
stale_wiki() {
	[ -f "$WIKI/Index.md" ] || return 0
	if [ -f "$WIKI/Progressions.md" ]; then
		[ -n "$(find "$WIKI" -prune -newer "$WIKI/Index.md" -newer "$WIKI/Progressions.md" \
			-print 2>/dev/null)" ] && return 0
	else
		[ -n "$(find "$WIKI" -prune -newer "$WIKI/Index.md" -print 2>/dev/null)" ] && return 0
	fi
	[ -n "$(find "$WIKI"/*/.subject.md -newer "$WIKI/Index.md" -print 2>/dev/null)" ]
}

case ${1:-all} in
wiki) view_wiki ;;
subjects)
	for d in "$WIKI"/*/; do
		[ -f "$d.subject.md" ] || continue
		view_subject "${d%/}"
	done
	;;
subject)
	[ $# -ge 2 ] && [ -n "$2" ] || usage
	[ -f "$WIKI/$2/.subject.md" ] || {
		echo "regen-views.sh: not a subject, no .subject.md: $2" >&2
		exit 2
	}
	view_subject "$WIKI/${2%/}"
	;;
stale)
	[ $# -lt 2 ] || [ "$2" = --check ] || usage
	stale=0
	for d in "$WIKI"/*/; do
		[ -f "$d.subject.md" ] || continue
		stale_subject "${d%/}" || continue
		view_subject "${d%/}"
		stale=1
	done
	if stale_wiki; then
		view_wiki
		stale=1
	fi
	# Progressions draw on pages across every subject, so any staleness reaches them.
	if [ "$stale" -eq 1 ]; then view_progressions; fi
	if [ "${2:-}" = --check ]; then exec sh "$(dirname "$0")/check-vault.sh" "$WIKI"; fi
	;;
progressions) view_progressions ;;
all)
	view_wiki
	for d in "$WIKI"/*/; do
		[ -f "$d.subject.md" ] || continue
		view_subject "${d%/}"
	done
	view_progressions
	;;
*) usage ;;
esac
