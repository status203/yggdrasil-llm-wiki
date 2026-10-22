#!/bin/sh
# Self-check for rename-ids.sh. The cases the logic turns on are matching a whole id, so a
# rename never reaches a longer or a nested one; a shift and a swap, which a rename done one
# id at a time overwrites; a split into siblings, which refuses and writes nothing; and the
# files a run reaches: the program's own, ignored ones aside, and the paths it is handed.

set -eu
bin=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

ok() { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }
same() { if [ "$(cat "$1")" = "$2" ]; then ok; else bad "$1: expected [$2], got [$(cat "$1")]"; fi; }
has() { if printf '%s\n' "$out" | grep -qF -- "$1"; then ok; else bad "expected: $1, got: $out"; fi; }
run() { set +e; out=$(sh "$P/.yg/bin/rename-ids.sh" "$@" 2>&1); rc=$?; set -e; }

# A throwaway program: the script finds its root from where it sits.
P=$tmp/program
mkdir -p "$P/.yg/bin" "$P/Docs" "$P/ignored"
cp "$bin/rename-ids.sh" "$P/.yg/bin/"
git -C "$P" init -q
printf 'ignored/\n' >"$P/.gitignore"

M=$tmp/map
cat >"$M" <<'MAP'
# A comment, and a blank line.

D95 D90.1
F197a F94.4
F197 F94.1
D91.1 D91.2
D91.2 D91.3
D92.1 D92.2
D92.2 D92.1
MAP

# Whole ids only: D95 is not inside D950, D95a, D95.1, AD95 or D-95; it is beside punctuation.
printf '%s\n' 'D95, (D95), `D95`, D95. D950 D95a D95.1 AD95 D-95 D95_x' >"$P/.yg/whole.md"
# A suffixed id and its parent are two ids.
printf '%s\n' 'F197 and F197a, F197b.' >"$P/.yg/suffix.md"
# A shift: D91.1 to D91.2 must not go on to D91.3. A swap: D92.1 and D92.2 trade places.
printf '%s\n' 'D91.1 then D91.2; D92.1 and D92.2.' >"$P/.yg/shift.md"
# Untracked but not ignored is the program's; ignored is not.
printf 'D95\n' >"$P/Docs/Page.md"
printf 'D95\n' >"$P/ignored/x.md"
# An exec bit survives the rewrite.
printf '#!/bin/sh\n# D95\n' >"$P/.yg/bin/tool.sh"
chmod +x "$P/.yg/bin/tool.sh"
# A binary file is not text, whatever bytes it holds.
printf 'D95\000D95\n' >"$P/.yg/blob.bin"
git -C "$P" add .yg .gitignore
# Further paths: a folder, its own .git skipped, and a lone file.
X=$tmp/elsewhere
mkdir -p "$X/sub" "$X/.git"
printf 'D95 in a ledger\n' >"$X/sub/ledger.md"
printf 'D95\n' >"$X/.git/config"
printf 'F197a in a handoff\n' >"$tmp/handoff.md"

run "$M" "$X" "$tmp/handoff.md"
[ "$rc" = 0 ] && ok || bad "a clean rename exits 0, got $rc: $out"
same "$P/.yg/whole.md" 'D90.1, (D90.1), `D90.1`, D90.1. D950 D95a D95.1 AD95 D-95 D95_x'
same "$P/.yg/suffix.md" 'F94.1 and F94.4, F197b.'
same "$P/.yg/shift.md" 'D91.2 then D91.3; D92.2 and D92.1.'
same "$P/Docs/Page.md" 'D90.1'
same "$P/ignored/x.md" 'D95'
[ -x "$P/.yg/bin/tool.sh" ] && ok || bad "exec bit lost"
same "$P/.yg/bin/tool.sh" "$(printf '#!/bin/sh\n# D90.1')"
[ "$(od -An -c "$P/.yg/blob.bin" | tr -d ' \n')" = 'D95\0D95\n' ] && ok || bad "binary file rewritten"
same "$X/sub/ledger.md" 'D90.1 in a ledger'
same "$X/.git/config" 'D95'
same "$tmp/handoff.md" 'F94.4 in a handoff'
has ".yg/whole.md"
has "$X/sub/ledger.md"

# A run that finds nothing to rename changes nothing and reports nothing.
printf 'D99 D99.1\n' >"$tmp/none.map"
run "$tmp/none.map" "$X" "$tmp/handoff.md"
[ "$rc" = 0 ] && ok || bad "a run with nothing to rename exits 0, got $rc"
[ -z "$out" ] && ok || bad "a run with nothing to rename reports nothing: $out"

# A split into siblings: every citation listed, and nothing written, the clean renames included.
printf 'D97 here\nand D95 there\n' >"$P/.yg/split.md"
printf 'D97\n' >"$X/sub/other.md"
printf 'D97 -\nD90.1 D93.1\n' >"$tmp/split.map"
run "$tmp/split.map" "$X"
[ "$rc" = 1 ] && ok || bad "a split with citations left exits 1, got $rc"
has ".yg/split.md:1: D97"
has "$X/sub/other.md:1: D97"
same "$P/.yg/whole.md" 'D90.1, (D90.1), `D90.1`, D90.1. D950 D95a D95.1 AD95 D-95 D95_x'
# Once each is assigned by hand, the run goes through.
printf 'D96.1 here\nand D95 there\n' >"$P/.yg/split.md"
printf 'D96.2\n' >"$X/sub/other.md"
run "$tmp/split.map" "$X"
[ "$rc" = 0 ] && ok || bad "a split with every citation assigned exits 0, got $rc: $out"
same "$P/.yg/whole.md" 'D93.1, (D93.1), `D93.1`, D93.1. D950 D95a D95.1 AD95 D-95 D95_x'

# A bad map writes nothing and exits 2.
for m in 'D95' 'D95 D86.1 x' 'D95 F86.1' 'D95 D86' 'D95 D86.1.' 'd95 D86.1' 'D95 D86.1
D95 D97.1' 'D95 D86.1
D97 D86.1'; do
	printf '%s\n' "$m" >"$tmp/bad.map"
	run "$tmp/bad.map"
	[ "$rc" = 2 ] && ok || bad "bad map [$m] exits 2, got $rc"
done
run "$tmp/nosuch.map"
[ "$rc" = 2 ] && ok || bad "a missing map exits 2, got $rc"
run "$M" "$tmp/nosuch"
[ "$rc" = 2 ] && ok || bad "a missing path exits 2, got $rc"
run
[ "$rc" = 2 ] && ok || bad "no arguments exits 2, got $rc"

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
