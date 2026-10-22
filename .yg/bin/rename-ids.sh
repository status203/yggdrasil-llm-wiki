#!/bin/sh
# Rename fact and decision ids, rewriting every citation of them in one run.
#
#   sh rename-ids.sh <map> [<path>...]
#
# A record's id carries its place in the tree, so moving a record renames it (facts.md
# § *The four fields*), and a citation left on the old id fails silently: it still reads
# fine, beside the wrong entry. So a run rewrites the program's own files, every one git
# does not ignore, and each further file or folder it is handed — open ledgers, unconsumed
# handoffs, review dispositions — without the program recording where those live.
#
# The map is one rename per line, `<old> <new>`, blank lines and `#` lines aside. A new id
# has two parts at least, since a group's heading is not citable. An id is matched whole,
# never as the start of a longer or a nested one, and every match is looked up against the
# map as written, so a shift or a swap never renames an id twice. `<old> -` marks an entry
# split into siblings: there is no parent to send its citations to, so each is pointed at
# one half by hand first, and while any is left the run lists them and writes nothing.
#
# A file holding a NUL byte is not text, and is left alone. A rewritten file keeps its mode.
#
# Exit 0 renamed, printing each file it changed; 1 refused, listing the citations of a
# split id; 2 a bad map, a missing path, or a program root that is not a repository.
#
# Cost: not timed — run by hand on a rename, never waited on mid-turn.

set -eu

[ $# -ge 1 ] || { echo 'usage: rename-ids.sh <map> [<path>...]' >&2; exit 2; }
map=$1; shift
[ -f "$map" ] || { echo "rename-ids: no such map: $map" >&2; exit 2; }
case $map in /*) ;; *) map=$PWD/$map ;; esac

bad=$(awk '
	/^[ \t]*(#|$)/ { next }
	NF != 2 || $1 !~ /^[FD][0-9]+(\.[0-9]+)*[a-z]?$/ || ($2 != "-" && ($2 !~ /^[FD][0-9]+(\.[0-9]+)+$/ || substr($1, 1, 1) != substr($2, 1, 1))) {
		print FNR ": not `<old> <new>`: " $0; next
	}
	$1 in old { print FNR ": renamed twice: " $1 }
	$2 != "-" && $2 in new { print FNR ": two ids renamed to " $2 }
	{ old[$1] = 1; if ($2 != "-") new[$2] = 1 }' "$map")
[ -z "$bad" ] || { printf 'rename-ids: %s\n' "$bad" | sed "s|^rename-ids: |rename-ids: $map:|" >&2; exit 2; }

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Every path absolute before the move to the root, where the program's own are listed.
: >"$tmp/paths"
for p in "$@"; do
	[ -e "$p" ] || { echo "rename-ids: no such path: $p" >&2; exit 2; }
	case $p in /*) ;; *) p=$PWD/$p ;; esac
	find "$p" -name .git -prune -o -type f -print >>"$tmp/paths"
done
cd "$root"
git -c core.quotePath=false ls-files -co --exclude-standard >"$tmp/own" ||
	{ echo "rename-ids: $root is not a git checkout" >&2; exit 2; }

# The rewrite, into a copy of each file; a split id's citations go to $REFUSED instead.
# Exit 0 when the copy differs, 3 when it does not.
prog='
BEGIN {
	while ((getline l < ENVIRON["MAP"]) > 0) {
		if (l ~ /^[ \t]*(#|$)/) continue
		split(l, a, " "); to[a[1]] = a[2]
	}
}
{
	s = $0; out = ""; prev = ""
	while (match(s, /[FD][0-9]+(\.[0-9]+)*[a-z]?/)) {
		v = substr(s, RSTART, RLENGTH)
		pre = RSTART > 1 ? substr(s, RSTART - 1, 1) : prev
		post = substr(s, RSTART + RLENGTH, 1)
		out = out substr(s, 1, RSTART - 1)
		prev = substr(v, length(v), 1)
		s = substr(s, RSTART + RLENGTH)
		if (pre !~ /[A-Za-z0-9_-]/ && post !~ /[A-Za-z0-9_]/ && (v in to)) {
			if (to[v] == "-") print ENVIRON["SHOWN"] ":" FNR ": " v >>ENVIRON["REFUSED"]
			else { v = to[v]; changed = 1 }
		}
		out = out v
	}
	print out s
}
END { exit changed ? 0 : 3 }'

: >"$tmp/refused"; : >"$tmp/changed"; n=0
cat "$tmp/own" "$tmp/paths" >"$tmp/all"
# A loop fed by a redirect, not a pipe, so an exit inside it ends the run.
while IFS= read -r f; do
	[ -f "$f" ] && grep -q '[FD][0-9]' "$f" || continue
	tr -d '\000' <"$f" | cmp -s - "$f" || continue
	n=$((n + 1))
	set +e
	SHOWN=$f MAP=$map REFUSED=$tmp/refused awk "$prog" "$f" >"$tmp/$n"
	rc=$?
	set -e
	case $rc in
	0) printf '%s\t%s\n' "$n" "$f" >>"$tmp/changed" ;;
	3) ;;
	*) echo "rename-ids: the rewrite failed on $f" >&2; exit 2 ;;
	esac
done <"$tmp/all"

if [ -s "$tmp/refused" ]; then
	echo 'rename-ids: split into siblings, so each citation is pointed at one half by hand first:' >&2
	cat "$tmp/refused" >&2
	exit 1
fi
while IFS="$(printf '\t')" read -r n f; do
	cat "$tmp/$n" >"$f"
	printf '%s\n' "$f"
done <"$tmp/changed"
