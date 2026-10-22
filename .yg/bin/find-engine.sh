#!/bin/sh
# Find the adapter for an engine seam by kind and name, and print its path.
#
# Personal first: ${XDG_CONFIG_HOME:-~/.config}/yggdrasil/engines/<kind>/<name>.sh, the user
# layer, outside every repository. Then shipped: <program>/.yg/engines/<kind>/<name>.sh, the
# program this script belongs to. Personal first so an adapter of one's own needs no file the
# program ships, and later program commits keep applying. A personal adapter under a shipped
# name replaces it, and says so on stderr, since it then stops following the program's changes
# to that one.
#
# A name, never a path: config names the adapter, and a path carried to another machine points
# at nothing. Kind and name are held to one safe class, lowercase letters, digits, - and _,
# because they become a path.
#
# Usage: find-engine.sh <kind> <name>
# Output: the adapter's path on stdout; a shadowing note or the reason for a refusal on stderr.
# Exit: 0 found; 21 no adapter by that name, or a kind or name outside the safe class; 2 usage.
#
# Cost: not timed — two file tests, nothing that grows.
set -eu

[ $# -eq 2 ] || { echo "usage: find-engine.sh <kind> <name>" >&2; exit 2; }
kind=$1
name=$2

for v in "$kind" "$name"; do
    case $v in
        '' | *[!a-z0-9_-]*)
            echo "find-engine.sh: '$v' is not an engine kind or name — lowercase letters, digits, - and _ only" >&2
            exit 21 ;;
    esac
done

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prog=$(CDPATH= cd -P -- "$here/../.." && pwd)
personal="${XDG_CONFIG_HOME:-$HOME/.config}/yggdrasil/engines/$kind/$name.sh"
shipped="$prog/.yg/engines/$kind/$name.sh"

if [ -f "$personal" ]; then
    [ -f "$shipped" ] && echo "find-engine.sh: the personal $kind adapter $personal replaces the shipped one of the same name" >&2
    printf '%s\n' "$personal"
    exit 0
fi
if [ -f "$shipped" ]; then
    printf '%s\n' "$shipped"
    exit 0
fi
echo "find-engine.sh: no $kind adapter named $name in ${XDG_CONFIG_HOME:-~/.config}/yggdrasil/engines/$kind/ or $prog/.yg/engines/$kind/" >&2
exit 21
