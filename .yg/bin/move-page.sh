#!/bin/sh
# Move or rename a wiki page, carrying its sidecars and fixing the links both halves break;
# or, with --merge, repoint a merged-away page's inbound links at the page kept.
#
# A rename is the degenerate case: the folder stays and the name changes. Both halves fail
# silently, in different directions, which is what puts them in a script:
#
#   Renaming  breaks every inbound wikilink -- the filename *is* the link target -- and
#             nothing checks that a wikilink resolves, so a partial rewrite looks exactly
#             like a complete one. The set of forms a link can take is closed:
#
#               [[Name]]          [[Name#Heading]]     ![[Name]]          [[Name.md]]
#               [[Name|alias]]    [[Name\|alias]]      [[Subject/Name]]   and combinations,
#
#             the name in any letter case (`F14.2`).
#
#             The escaped pipe is the one that bites: the backslash sits in the target half
#             by position and belongs to the alias by meaning (`F16.2` is why it is written at
#             all). A rewrite that splits on `|` without accounting for it corrupts the
#             target.
#
#   Moving    breaks every relative link the page carries -- source citations above all --
#             because those resolve by path rather than through Obsidian's link graph
#             (`F13.1.1`), and the depth changed. The editor shows nothing, because the target
#             is off the graph. It also strands the page's `.html` sidecars, which stay where
#             they were while the page that links them walks off.
#
# Matching for wikilinks is on the link's last path segment, because a wikilink resolves
# against any trailing part of a page's vault path (`F14.1`) -- so [[Subject/Name]] and
# [[Name]] point at the same page and both have to move. A path prefix follows a move: a
# bare link resolves wherever the page goes and a path-qualified one does not, so its prefix
# becomes the page's new folder from the wiki root (`D9.2`). A rename leaves the prefix
# as it is.
#
# Scanning is index/substr rather than regex, so a page name containing regex metacharacters
# is matched literally and needs no escaping. Names match in any letter case, links and twins
# alike; outside ASCII only where awk and grep fold it (`F19.3`), so elsewhere a link or a twin
# differing from the name in an accented letter's case is missed.
#
# Sidecars are found by name -- `<page-slug>--<what>.html` beside the page, the convention
# `.yg/page-contract.md` states -- because a link is not enough to own one: two pages may
# link the same file, and moving one would break the other. A sidecar named otherwise is
# left where it is, and check-vault.sh reports the link.
#
# Not handled, deliberately: a relative link on some OTHER page pointing at this one. Those
# are rare (a page is reached by wikilink), and check-vault.sh reports each one afterwards,
# where a rewrite here would have to guess which of them meant this page.
#
# Only the wiki is read and written, and not its dotfolders, which Obsidian ignores entirely
# (`F13.1`): .sources/ holds records, which a move does not rewrite, and .yg/ and .git/ hold
# no pages.
#
# A page moves only into a subject, a top-level folder holding a `.subject.md`, since the
# views and checks read nothing else and a page anywhere else drops out of all of them
# without a word. It may come from anywhere, import/ included. The link rewrite and the twin
# check read the whole wiki, since a name resolves across the vault (`F14.1.1`): a link in
# import/ does mean the page, and a same-named file outside a dotfolder does make a link
# ambiguous.
#
# Portability (`F18.2`): POSIX sh and awk, and no character classes in awk. `[ \t\r]` stands
# in for [[:space:]].
#
# Prints the files it changed, wiki-relative, because the exit status of a rewrite is not
# evidence that anything was rewritten; then the views it regenerated.
#
# A merge breaks the same inbound links a rename does, once the session deletes the page
# merged away, so --merge runs the inbound rewrite alone: it moves nothing and repoints
# every wikilink to the page at the page the merge kept, which must already exist. Bare
# links take the kept page's name, so that name must mean one page too.
#
# A deletion breaks them too, with nothing to repoint them at, so --links changes nothing:
# it prints what deleting the page would leave behind, by the same matching, for the session
# to put to the user first — `twin: <path>` where a page shares the name and the links may
# mean it, `link: <path>` for each page carrying a wikilink to it, and `sidecar: <path>`.
# A source only this page cites is check-vault.sh's to report, once the page is gone.
#
# Usage: move-page.sh WIKI_ROOT <page path> <destination>
#        move-page.sh WIKI_ROOT --merge <page path> <kept page path>
#        move-page.sh WIKI_ROOT --links <page path>
#
#   Both paths are relative to the wiki root, explicitly not to the working directory.
#   <destination> is a bare name to rename in place, or a path from the wiki root --
#   `Subject/` to keep the name, `Subject/New name` to change it too.
# Exit: 0 moved, links repointed, or listed; 1 failed partway, the lines it printed being what
# changed; 2 refused, with nothing changed — usage, no directory at WIKI_ROOT, or a page or
# destination that does not qualify.
#
# Cost: run by the session when the user asks for a move, and by the content review after a
# merge, which runs only the link rewrite and the regeneration measured here. Measured
# 2026-10-02 on synthetic wikis of 20 subjects and 20 progressions. A name one page holds
# costs 0.40s at 500 and 1,000 pages, nearly all of it the views it regenerates, per
# regen-views.sh's Cost:. The link rewrite adds about 3ms for every page whose text holds
# the name, linking it or not — an awk per page — so a name every page links costs 1.96s,
# 3.54s, 6.72s and 12.76s at 500, 1,000, 2,000 and 4,000 pages. Linux, warm cache: the
# times are this machine's, the ratios are not.

set -eu

merge=
links=
listing=
if [ $# -eq 4 ] && [ "$2" = --merge ]; then
	merge=1
	set -- "$1" "$3" "$4"
elif [ $# -eq 3 ] && [ "$2" = --links ]; then
	links=1
	set -- "$1" "$3" -
fi
if [ $# -ne 3 ] || [ -z "$1" ]; then
	echo "usage: move-page.sh WIKI_ROOT [--merge] <page path> <destination> | --links <page path>" >&2
	exit 2
fi
WIKI=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || {
	echo "move-page.sh: no wiki at $1 — not a directory" >&2
	exit 2
}
src=$2
dest=$3

# wikifind <find primaries...> — the wiki, its dotfolders pruned. Run from the wiki root;
# prints ./-relative.
wikifind() { (cd "$WIKI" && find . -name '.*' ! -name . -type d -prune -o "$@"); }

# samename <name> <./path left out> — the first page holding <name> in any letter case, since
# a link reaches a page that way (`F14.2`); find's -name matches case exactly.
samename() {
	wikifind -name '*.md' -type f -print | awk -v n="$1" -v self="$2" '
		{ b = $0; sub(/.*\//, "", b); sub(/\.md$/, "", b) }
		tolower(b) == tolower(n) && $0 != self { print; exit }'
}

# Under C, as check-vault.sh's copy is, since a language locale may lower a non-ASCII capital to
# an ASCII letter, and its [a-z] takes in accented letters (F19.3, F19.4).
slug() {
	printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' \
		-e 's/^-//' -e 's/-$//'
}

# Inbound wikilinks. A rename breaks every one of them; a move breaks only the qualified
# ones, since a link resolves against a trailing part of the page's path (`F14.1`) and the
# path changed. A bare link survives a move, which is why the prefix is rewritten and the
# bare form is left exactly as written. $1 is 1 where a qualified link's prefix becomes the
# new folder.
inbound() {
	newprefix=${newdir#"$WIKI"}
	newprefix=${newprefix#/}
	[ -z "$newprefix" ] || newprefix=$newprefix/
	# Only a page holding the name as text, in some letter case, can carry a link to it: one
	# grep over the wiki picks those, and the rewrite runs on them alone.
	# The views -- every Index.md and the root Progressions.md -- are left to the
	# regeneration below: rewritten here they would read fresh, and none of them would be
	# regenerated.
	wikifind -name '*.md' ! -name Index.md -type f -exec grep -liF -e "$old" {} + |
	while IFS= read -r page; do
		[ "$page" != ./Progressions.md ] || continue
		[ -z "$listing" ] || [ "$page" != "./${abs#"$WIKI"/}" ] || continue
		page=$WIKI/${page#./}
		awk -v old="$old" -v new="$new" -v newprefix="$newprefix" -v moved="$1" -v list="$listing" '
			{
				out = ""
				rest = $0
				while ((i = index(rest, "[[")) > 0) {
					out = out substr(rest, 1, i + 1)
					rest = substr(rest, i + 2)
					j = index(rest, "]]")
					if (j == 0) break
					inner = substr(rest, 1, j - 1)
					rest = substr(rest, j)

					# The target runs to the first # or |, whichever comes first.
					cut = length(inner) + 1
					p = index(inner, "#"); if (p > 0 && p < cut) cut = p
					p = index(inner, "|"); if (p > 0 && p < cut) cut = p
					target = substr(inner, 1, cut - 1)
					tail = substr(inner, cut)

					# Hand an escaping backslash back to the alias half it belongs to.
					if (tail ~ /^\|/ && target ~ /\\$/) {
						target = substr(target, 1, length(target) - 1)
						tail = "\\" tail
					}

					last = 0
					for (m = length(target); m >= 1; m--)
						if (substr(target, m, 1) == "/") { last = m; break }
					prefix = last ? substr(target, 1, last) : ""
					name = last ? substr(target, last + 1) : target
					ext = ""
					if (substr(name, length(name) - 2) == ".md") {
						ext = ".md"
						name = substr(name, 1, length(name) - 3)
					}

					if (tolower(name) == tolower(old)) {
						hit = 1
						name = new
						if (moved && prefix != "") prefix = newprefix
					}
					out = out prefix name ext tail
				}
				print out rest
			}
			END { if (list && !hit) exit 3 }
		' "$page" > "$scratch" || { st=$?; [ -n "$listing" ] && [ "$st" -eq 3 ] && continue; exit "$st"; }
		if [ -n "$listing" ]; then
			printf 'link: %s\n' "${page#"$WIKI"/}"
		elif ! cmp -s "$page" "$scratch"; then
			cat "$scratch" > "$page"
			printf '%s\n' "${page#"$WIKI"/}"
		fi
	done
}

case $src in
/*)
	echo "the page path is relative to the wiki root: $src" >&2
	exit 2
	;;
*.md) ;;
*)
	echo "not a page: $src" >&2
	exit 2
	;;
esac
[ -f "$WIKI/$src" ] || { echo "no such page: $src" >&2; exit 2; }

# Resolve to a physical path, as WIKI is, so the containment test holds through ../ and links.
abs=$(cd "$WIKI/$(dirname "$src")" && pwd -P)/$(basename "$src")
case $abs in
"$WIKI"/*) ;;
*)
	echo "not under the wiki: $src" >&2
	exit 2
	;;
esac
case /${abs#"$WIKI"/} in
*/.*/*)
	echo "not a page, in a dotfolder: $src; a source is cited by relative link, so grep for it" >&2
	exit 2
	;;
esac

old=$(basename "$abs" .md)
olddir=$(dirname "$abs")

# --links: what deleting the page would leave behind, changing nothing. The twin comes
# first, since with one the links listed may mean it instead.
if [ -n "$links" ]; then
	twin=$(samename "$old" "./${abs#"$WIKI"/}")
	[ -z "$twin" ] || printf 'twin: %s\n' "${twin#./}"
	listing=1 newdir=$olddir new=$old scratch=/dev/null
	inbound 0
	oldslug=$(slug "$old")
	for side in "$olddir/$oldslug"--*.html; do
		[ -f "$side" ] && printf 'sidecar: %s\n' "${side#"$WIKI"/}"
	done
	exit 0
fi

# A destination with no slash renames in place; one with a slash is wiki-relative, and a
# trailing slash keeps the page's name.
case $dest in
"")
	echo "no destination given" >&2
	exit 2
	;;
/*)
	echo "the destination is relative to the wiki root: $dest" >&2
	exit 2
	;;
*/)
	newdir=$WIKI/${dest%/}
	new=$old
	;;
*/*)
	newdir=$WIKI/$(dirname "$dest")
	new=$(basename "${dest%.md}")
	;;
*)
	newdir=$olddir
	new=${dest%.md}
	;;
esac

[ -d "$newdir" ] || { echo "no such subject directory: ${newdir#"$WIKI"/}" >&2; exit 2; }
newdir=$(cd "$newdir" && pwd -P)
case $newdir in
"$WIKI" | "$WIKI"/*) ;;
*)
	echo "destination is not under the wiki: $dest" >&2
	exit 2
	;;
esac
top=${newdir#"$WIKI"}
top=${top#/}
top=${top%%/*}
[ -n "$top" ] && [ -f "$WIKI/$top/.subject.md" ] || {
	echo "destination is not in a subject (a folder holding a .subject.md): $dest" >&2
	exit 2
}

[ "$newdir/$new.md" != "$abs" ] || { echo "already there, under that name" >&2; exit 2; }
if [ -n "$merge" ]; then
	[ -f "$newdir/$new.md" ] || { echo "no such page to merge into: $dest" >&2; exit 2; }
	clash=$(samename "$new" "./${newdir#"$WIKI"/}/$new.md")
	[ -z "$clash" ] || {
		echo "another page shares the kept page's name, so links to it are ambiguous: ${clash#./}" >&2
		exit 2
	}
else
	[ ! -e "$newdir/$new.md" ] || { echo "target exists: ${newdir#"$WIKI"/}/$new.md" >&2; exit 2; }
fi

if [ -z "$merge" ] && [ "$new" != "$old" ]; then
	# A bare wikilink resolves on filename alone, so a duplicate name anywhere outside a dotfolder
	# makes every link to either page ambiguous. Keep there being none.
	clash=$(samename "$new" "./${abs#"$WIKI"/}")
	[ -z "$clash" ] || { echo "a page of that name already exists: ${clash#./}" >&2; exit 2; }
fi

# Where the name is shared with another page, a link's last segment no longer identifies
# which page it means: rewriting every match would retarget links belonging to the twin, and
# a move alone is enough to do it, since a same-folder candidate wins and the shortest path
# breaks the tie (`F14.1.1`). Which link means which page is a judgement and a human's; refuse
# rather than guess, on a move, a rename or a merge alike.
twin=$(samename "$old" "./${abs#"$WIKI"/}")
[ -z "$twin" ] || {
	echo "another page shares that name, so links to it are ambiguous: ${twin#./}" >&2
	if [ -n "$merge" ]; then
		echo "repoint its links by hand, or rename that page first" >&2
	else
		echo "move or rename by hand, or rename that page first" >&2
	fi
	exit 2
}

# The scratch files live outside the wiki deliberately. Written beside each page they would
# bump every subject directory's mtime, and regen-views.sh reads a directory newer than its
# Index.md as stale -- so a move touching two pages would rewrite every index and bury its
# own diff.
scratch=$(mktemp)
mapfile=$(mktemp)
started=
trap 'st=$?; rm -f "$scratch" "$mapfile"
if [ "$st" -ne 0 ] && [ -n "$started" ]; then
	echo "move-page.sh: failed partway; the lines above are what changed, and nothing after them was done" >&2
	exit 1
fi' EXIT

# A merge moves nothing: the kept page may sit anywhere, so a qualified link takes its folder.
if [ -n "$merge" ]; then
	started=1
	inbound 1
	sh "$(dirname "$0")/regen-views.sh" "$WIKI" stale
	exit 0
fi

oldslug=$(slug "$old")
newslug=$(slug "$new")

# Every refusal comes before the first move, the sidecars' included, so a refusal changes
# nothing.
for side in "$olddir/$oldslug"--*.html; do
	[ -f "$side" ] || continue
	newside=$newslug--${side#"$olddir/$oldslug"--}
	[ "$side" = "$newdir/$newside" ] || [ ! -e "$newdir/$newside" ] || {
		echo "sidecar target exists: ${newdir#"$WIKI"/}/$newside" >&2
		exit 2
	}
done

# A page written this session is not yet committed, and git mv refuses an untracked file;
# a plain mv moves it, and git sees it when it is added.
move() {
	if git -C "$WIKI" ls-files --error-unmatch -- "$1" >/dev/null 2>&1; then
		git -C "$WIKI" mv -- "$1" "$2"
	else
		mv -- "$1" "$2"
	fi
}

started=1
move "$abs" "$newdir/$new.md"
printf '%s\n' "${abs#"$WIKI"/} -> ${newdir#"$WIKI"/}/$new.md"

# The sidecars, by the contract's naming pattern. A glob rather than find, which has no
# POSIX way to stay out of a subject's cluster folders (`F17.2`).
# The rename map goes to the rewrite below, since the page's own links carry the old name.
for side in "$olddir/$oldslug"--*.html; do
	[ -f "$side" ] || continue
	sidename=${side##*/}
	newside=$newslug--${sidename#"$oldslug"--}
	if [ "$side" != "$newdir/$newside" ]; then
		move "$side" "$newdir/$newside"
		printf '%s\n' "${side#"$WIKI"/} -> ${newdir#"$WIKI"/}/$newside"
	fi
	printf '%s\t%s\n' "$sidename" "$newside" >> "$mapfile"
done

# The moved page's own relative links: rebase each against the new folder, and follow any
# sidecar that was renamed with it. Anchors, absolute paths and anything with a scheme are
# left alone. Fenced blocks are skipped: a page about markdown quotes links that are
# examples, not references. The folders are passed as physical paths, so a page at the wiki
# root rebases like any other, and so does a link reaching above it.
if [ "$newdir" != "$olddir" ] || [ -s "$mapfile" ]; then
	awk -v oldrel="$olddir" -v newrel="$newdir" -v mapfile="$mapfile" '
		function norm(p,   n, i, parts, out, k, s) {
			n = split(p, parts, "/")
			k = 0
			for (i = 1; i <= n; i++) {
				if (parts[i] == "" || parts[i] == ".") continue
				if (parts[i] == ".." && k > 0 && out[k] != "..") { k--; continue }
				out[++k] = parts[i]
			}
			s = ""
			for (i = 1; i <= k; i++) s = s (i > 1 ? "/" : "") out[i]
			return s
		}
		function relpath(target, from,   t, f, tn, fn, i, j, res) {
			tn = split(target, t, "/")
			fn = split(from, f, "/")
			i = 1
			while (i <= tn && i <= fn && t[i] == f[i]) i++
			res = ""
			for (j = i; j <= fn; j++) res = res "../"
			for (j = i; j <= tn; j++) res = res t[j] (j < tn ? "/" : "")
			return res
		}
		BEGIN {
			while ((getline line < mapfile) > 0) {
				k = index(line, "\t")
				if (k > 0) side[substr(line, 1, k - 1)] = substr(line, k + 1)
			}
		}
		/^[ \t\r]*```/ || /^[ \t\r]*~~~/ { fence = !fence; print; next }
		fence { print; next }
		{
			out = ""
			rest = $0
			while ((i = index(rest, "](")) > 0) {
				out = out substr(rest, 1, i + 1)
				rest = substr(rest, i + 2)
				j = index(rest, ")")
				if (j == 0) break
				target = substr(rest, 1, j - 1)
				rest = substr(rest, j)

				anchor = ""
				h = index(target, "#")
				if (h > 0) { anchor = substr(target, h); target = substr(target, 1, h - 1) }

				if (target != "" && target !~ /^[A-Za-z]+:/ && target !~ /^\//) {
					if (target in side) target = side[target]
					else if (oldrel != newrel)
						target = relpath(norm(oldrel "/" target), norm(newrel))
				}
				out = out target anchor
			}
			print out rest
		}
	' "$newdir/$new.md" > "$scratch"
	if ! cmp -s "$newdir/$new.md" "$scratch"; then
		cat "$scratch" > "$newdir/$new.md"
		printf '%s\n' "${newdir#"$WIKI"/}/$new.md"
	fi
fi

if [ "$new" != "$old" ] || [ "$newdir" != "$olddir" ]; then
	inbound "$([ "$newdir" != "$olddir" ] && echo 1 || echo 0)"
fi

sh "$(dirname "$0")/regen-views.sh" "$WIKI" stale
