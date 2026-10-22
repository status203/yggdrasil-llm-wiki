#!/bin/sh
# Black-box test for .yg/hooks/inject-rules.sh. POSIX sh — no framework.
# The rules file is replaced by one carrying every character the JSON string must escape.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PASS=0
FAIL=0
ok()   { PASS=$((PASS + 1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
says() { case "$1" in *"$2"*) ok "$3" ;; *) bad "$3: $1" ;; esac; }
is()   { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3: got '$1', want '$2'"; fi; }

T=$(mktemp -d "${TMPDIR:-/tmp}/yg-inject.XXXXXX")
trap 'rm -rf "$T"' EXIT
T=$(CDPATH= cd -P -- "$T" && pwd)
P="$T/program"; W="$T/wiki"
mkdir -p "$P/.yg/hooks" "$W/.yg"
cp "$HERE/inject-rules.sh" "$P/.yg/hooks/"
printf '# Wiki rules\n\nA "quoted" word, a back\\slash and\ta tab.\n' > "$P/.yg/wiki.md"
run() { sh "$P/.yg/hooks/inject-rules.sh" "$@"; }

out=$(run "$W" SessionStart); rc=$?
is "$rc" 0 '1 unwired: exits 0'
is "$out" '' '1 unwired: says nothing'
is "$(run "$T/nowhere" SubagentStart)" '' '1 no folder: says nothing'

printf 'wiki.visibility: private\nwiki.format: 1\n' > "$W/.yg/config.conf"
out=$(run "$W" SubagentStart)
is "$out" '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"Yggdrasil: the wiki rules follow.\n\n# Wiki rules\n\nA \"quoted\" word, a back\\slash and\ta tab."}}' '2 wired: the rules, escaped, under a Yggdrasil: line'
says "$(run "$W" SessionStart)" '"hookEventName":"SessionStart"' '2 wired: the event is named back'

# Where python3 is present, the output must parse back to the text exactly.
if command -v python3 >/dev/null 2>&1; then
  back=$(printf '%s' "$out" | python3 -c 'import json,sys; sys.stdout.write(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])')
  want=$(printf 'Yggdrasil: the wiki rules follow.\n\n'; cat "$P/.yg/wiki.md")
  is "$back" "$want" '3 the JSON parses back to the rules'
fi

run "$W" 2>/dev/null; is "$?" 2 '4 usage: no event'

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
