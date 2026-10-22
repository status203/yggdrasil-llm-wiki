#!/bin/sh
# Black-box test for the pre-commit hook's integration-review notice (D19.3). POSIX sh, no
# framework. Builds a throwaway repository carrying the hook and the leak check it runs
# first, stages each case, runs the hook as git would, and asserts on exit code and
# stderr. The hook's leak-check cases are in .yg/bin/test-check-leaks.sh.
#
# The refused value is assembled with printf from pieces, so this file carries none and
# passes the check itself.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PASS=0
FAIL=0

ok()    { PASS=$((PASS + 1)); echo "ok   $1"; }
bad()   { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
code()  { if [ "$rc" = "$1" ]; then ok "$2"; else bad "$2 (exit $rc)"; fi; }
says()  { case "$out" in *"$1"*) ok "$2" ;; *) bad "$2" ;; esac; }
quiet() { case "$out" in *"$1"*) bad "$2" ;; *) ok "$2" ;; esac; }

T=$(mktemp -d "${TMPDIR:-/tmp}/yg-pc.XXXXXX")
trap 'rm -rf "$T"' EXIT
g() { git -C "$T" -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@example.com "$@"; }
hook() { out=$(cd "$T" && sh .yg/githooks/pre-commit 2>&1 >/dev/null); rc=$?; }
clean() { g merge --abort >/dev/null 2>&1; g reset -q --hard; g clean -qfd; }

# A notice-drawing case: printed, naming the paths, never refusing.
notice() { # description, path the notice must name
  hook
  says '/yggdrasil:integration-review' "$1: notice"
  says "$2" "$1: names $2"
  code 0 "$1: never refuses"
  clean
}
none() { # description
  hook
  quiet 'Notice' "$1: no notice"
  code 0 "$1: never refuses"
  clean
}

g init -q
mkdir -p "$T/.yg/bin" "$T/.yg/githooks" "$T/.claude" "$T/Test bed"
cp "$HERE/../bin/check-leaks.sh" "$HERE/../bin/check-leaks.awk" "$T/.yg/bin/"
cp "$HERE/../technical-well.txt" "$T/.yg/"
cp "$HERE/pre-commit" "$T/.yg/githooks/"
echo catalog >"$T/.yg/forge-catalog.md"
echo edit >"$T/.yg/bin/edit.sh"
echo gone >"$T/.yg/bin/gone.sh"
echo old >"$T/.yg/bin/old.sh"
echo forge >"$T/.claude/CLAUDE.md"
echo page >"$T/Test bed/Opening.md"
g add -A
g commit -q -m base

echo more >>"$T/.yg/bin/edit.sh"; g add .yg/bin/edit.sh
none 'an edit to a mechanism file'

echo new >"$T/.yg/bin/new.sh"; g add .yg/bin/new.sh
notice 'an added file' .yg/bin/new.sh

mkdir -p "$T/.claude-plugin"; echo '{}' >"$T/.claude-plugin/plugin.json"; g add .claude-plugin
notice 'an added file in a new program folder' .claude-plugin/plugin.json

g rm -q .yg/bin/gone.sh
notice 'a deleted file' .yg/bin/gone.sh

g mv .yg/bin/old.sh .yg/bin/renamed.sh
notice 'a renamed file' .yg/bin/renamed.sh

echo more >>"$T/.yg/forge-catalog.md"; g add .yg/forge-catalog.md
notice 'an edit to the catalog' .yg/forge-catalog.md

echo page >"$T/Test bed/Endgame.md"; g add "Test bed/Endgame.md"
none 'a forge-wiki page add'

printf 'see %s\n' "$(printf '/%s/%s/x' home alice)" >"$T/.yg/bin/leak.sh"; g add .yg/bin/leak.sh
hook
code 1 'a leak-refused commit: refused'
quiet 'Notice' 'a leak-refused commit: no notice'
clean

g checkout -q -b side
echo side >"$T/.yg/bin/side.sh"; g add .yg/bin/side.sh; g commit -q -m side
g checkout -q -
echo main >"$T/.yg/bin/main.sh"; g add .yg/bin/main.sh; g commit -q -m main
g merge -q --no-ff --no-commit side >/dev/null 2>&1
none 'a merge bringing in an added file'

# Through git itself, so the exec bit and core.hooksPath are part of what is tested.
chmod +x "$T/.yg/githooks/pre-commit"
echo new >"$T/.yg/bin/viagit.sh"; g add .yg/bin/viagit.sh
base=$(g rev-parse --short HEAD)
out=$(git -C "$T" -c core.hooksPath=.yg/githooks -c user.name=t -c user.email=t@example.com commit -q -m x 2>&1); rc=$?
code 0 'through git: the commit goes through'
says 'Notice: .yg/bin/viagit.sh — if this changes how the program operates, run /yggdrasil:integration-review (base '"$base"').' 'through git: the notice in full, naming the parent as base'

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
