#!/bin/sh
# Chain page pairs into groups. Reads one pair per line on stdin, `<page> | <page>`, and prints
# one row per group: `<size><TAB><page> | <page> | …`, largest first, then by members.
#
# The content review's whole-wiki scan judges which pairs share a central topic; grouping them
# is transitive closure, which a model doing it by eye gets wrong one way — a chain A–B, B–C,
# C–D read as three pairs, and a group of four never reaches the user. `|` separates because
# no page name holds one: a wikilink cannot reach such a name (`F16.2`), and check-vault.sh
# reports it.
#
# A line that is not one pair is named on stderr and the script exits 2 with nothing on stdout:
# a pair dropped silently would shrink a group the user reads as complete.
#
# Cost: one pass over the pairs, then one sort; a scan yields hundreds at most. 20,000 pairs
# took 0.1s on 2026-10-07.

set -eu
roots=$(mktemp)
trap 'rm -f "$roots"' EXIT

# POSIX sh has no pipefail, so the stage that can refuse writes to a file and is checked.
LC_ALL=C awk -F'|' '
	function find(x) { while (p[x] != x) { p[x] = p[p[x]]; x = p[x] } return x }
	function trim(s) { sub(/^[ \t\r]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
	trim($0) == "" { next }
	NF != 2 || trim($1) == "" || trim($2) == "" {
		print "clusters: not a pair: " trim($0) > "/dev/stderr"; bad = 1; next
	}
	{
		a = trim($1); b = trim($2)
		if (!(a in p)) p[a] = a
		if (!(b in p)) p[b] = b
		a = find(a); b = find(b)
		if (a != b) p[a] = b
	}
	END {
		if (bad) exit 2
		for (k in p) print find(k) "\t" k
	}
' >"$roots" || exit 2
LC_ALL=C sort -t'	' -k1,1 -k2,2 "$roots" | LC_ALL=C awk -F'\t' '
	{ if (!($1 in size)) order[++n] = $1; size[$1]++; who[$1] = who[$1] (size[$1] > 1 ? " | " : "") $2 }
	END { for (i = 1; i <= n; i++) printf "%d\t%s\n", size[order[i]], who[order[i]] }
' | LC_ALL=C sort -t'	' -k1,1nr -k2,2
