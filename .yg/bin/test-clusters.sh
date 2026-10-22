#!/bin/sh
# Self-check for clusters.sh. Feeds it pairs and asserts the groups it prints.

set -eu
script=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/clusters.sh
fails=0

check() { # check <name> <expected> <actual>
	if [ "$2" = "$3" ]; then echo "ok: $1"; else
		printf 'FAIL: %s\n--- expected\n%s\n--- got\n%s\n' "$1" "$2" "$3"
		fails=$((fails + 1))
	fi
}

# A chain read as three separate pairs is one group of four — the case chaining by eye drops.
got=$(printf '%s\n' 'Chess/Lucena.md | Chess/Philidor.md' 'Chess/Philidor.md | Chess/Rook endings.md' \
	'Chess/Rook endings.md | Misc/Endgame drills.md' | sh "$script")
check chain "4	Chess/Lucena.md | Chess/Philidor.md | Chess/Rook endings.md | Misc/Endgame drills.md" "$got"

# Groups come largest first, then by their members; spaces and apostrophes in names survive;
# surrounding whitespace is trimmed; a repeated or reversed pair adds nothing.
got=$(printf '%s\n' "Cooking/Baker's percentages.md | Cooking/Hydration.md" \
	'  Speaking/Openers.md|Speaking/Hooks.md  ' 'Speaking/Hooks.md | Speaking/Openers.md' \
	'Speaking/Hooks.md | Speaking/Closers.md' '' | sh "$script")
check order "3	Speaking/Closers.md | Speaking/Hooks.md | Speaking/Openers.md
2	Cooking/Baker's percentages.md | Cooking/Hydration.md" "$got"

# No pairs, no groups, and a clean exit.
got=$(printf '' | sh "$script") && rc=0 || rc=$?
check empty "0:" "$rc:$got"

# A line that is not one pair is never dropped silently: exit 2, named on stderr, nothing on stdout.
out=$(printf '%s\n' 'A/One.md | A/Two.md' 'A/Three.md' 'A/One.md | A/Two.md | A/Four.md' |
	sh "$script" 2>"${TMPDIR:-/tmp}/clusters-err.$$") && rc=0 || rc=$?
err=$(cat "${TMPDIR:-/tmp}/clusters-err.$$"); rm -f "${TMPDIR:-/tmp}/clusters-err.$$"
check malformed-exit "2:" "$rc:$out"
check malformed-named "clusters: not a pair: A/Three.md
clusters: not a pair: A/One.md | A/Two.md | A/Four.md" "$err"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
