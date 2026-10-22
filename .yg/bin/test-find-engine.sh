#!/bin/sh
# Self-check for find-engine.sh. Builds a throwaway program tree and user layer, and asserts the
# lookup order, the shadowing note, the safe-name refusal and the not-found status.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

mkdir -p "$W/prog/.yg/bin" "$W/prog/.yg/engines/transcribe" "$W/xdg/yggdrasil/engines/transcribe"
cp "$here/find-engine.sh" "$W/prog/.yg/bin/"
sut="$W/prog/.yg/bin/find-engine.sh"
prog=$(CDPATH= cd -P -- "$W/prog" && pwd)
: >"$prog/.yg/engines/transcribe/shipped.sh"
: >"$prog/.yg/engines/transcribe/both.sh"
: >"$W/xdg/yggdrasil/engines/transcribe/mine.sh"
: >"$W/xdg/yggdrasil/engines/transcribe/both.sh"

fail=0
run() { rc=0; out=$(XDG_CONFIG_HOME="$W/xdg" sh "$sut" "$@" 2>"$W/err") || rc=$?; err=$(cat "$W/err"); }
is() { if [ "$2" = "$3" ]; then echo "ok    — $1"; else echo "FAIL  — $1: expected [$3] got [$2]"; fail=1; fi; }
has() { case $2 in *"$3"*) echo "ok    — $1" ;; *) echo "FAIL  — $1: [$2]"; fail=1 ;; esac; }

run transcribe shipped
is 'a shipped adapter is found' "$out" "$prog/.yg/engines/transcribe/shipped.sh"
is 'and nothing is said about it' "$err" ""

run transcribe mine
is 'a personal adapter is found in the user layer' "$out" "$W/xdg/yggdrasil/engines/transcribe/mine.sh"

run transcribe both
is 'a personal adapter is found before a shipped one of the same name' "$out" "$W/xdg/yggdrasil/engines/transcribe/both.sh"
has 'and the shadowing is said on stderr' "$err" 'replaces the shipped one'

run transcribe absent
is 'no adapter by that name exits 21' "$rc" 21
is 'and prints no path' "$out" ""
has 'and names where it looked' "$err" "$prog/.yg/engines/transcribe/"

run transcribe ../shipped
is 'a name that is not a plain name exits 21' "$rc" 21
run transcribe Shipped
is 'an uppercase name is refused' "$rc" 21
run '../engines/transcribe' shipped
is 'a kind that is not a plain name exits 21' "$rc" 21
run transcribe ''
is 'an empty name is refused' "$rc" 21

# Without XDG_CONFIG_HOME the user layer is ~/.config, as resolve-config.sh reads it.
mkdir -p "$W/home/.config/yggdrasil/engines/transcribe"
: >"$W/home/.config/yggdrasil/engines/transcribe/mine.sh"
rc=0; out=$(env -u XDG_CONFIG_HOME HOME="$W/home" sh "$sut" transcribe mine 2>/dev/null) || rc=$?
is 'the user layer defaults to ~/.config' "$out" "$W/home/.config/yggdrasil/engines/transcribe/mine.sh"

run transcribe
is 'one argument is a usage error' "$rc" 2

exit $fail
