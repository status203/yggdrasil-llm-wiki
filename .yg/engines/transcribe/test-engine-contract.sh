#!/bin/sh
# Conformance test for a transcription adapter: the half of contract.md a script can check, run
# against the real adapter and its real engine. For whoever writes an adapter, before pointing
# transcribe.engine at it; test-whisper.sh is whisper's own test, and this is any adapter's.
#
# It checks that usage and every status are ones the contract declares, that check states the
# contract version and its capabilities in the declared form, that stdout carries only protocol
# lines, that a generated silent recording succeeds -- with no segments where the adapter
# declared silence_safe -- and, given a speech clip, that segments.tsv and meta.conf are well
# formed. It grants no consent it is not given, so an adapter that needs a download stops at the
# consent line, which is printed with the token to re-run with.
#
# The adapter is found by name as the flow finds it, through find-engine.sh, so the file tested
# is the one transcribe.engine would run; --adapter <path> in place of the name tests a draft
# before it is installed. The wiki is the one whose resolved config the adapter reads.
#
# Usage: test-engine-contract.sh [--consent <tokens>] <wiki> <name> [<speech clip>]
#        test-engine-contract.sh [--consent <tokens>] <wiki> --adapter <path> [<speech clip>]
#
# Cost: not timed — a manual check, run once per adapter change, and the engine is the wait.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prog=$(CDPATH= cd -P -- "$here/../../.." && pwd)

usage() {
    echo "usage: test-engine-contract.sh [--consent <tokens>] <wiki> <name> [<speech clip>]" >&2
    echo "       test-engine-contract.sh [--consent <tokens>] <wiki> --adapter <path> [<speech clip>]" >&2
    exit 2
}

consent=""
adapter=""
if [ "${1-}" = "--consent" ]; then [ $# -ge 2 ] || usage; consent=$2; shift 2; fi
[ $# -ge 1 ] || usage
wiki=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || { echo "test-engine-contract.sh: no wiki at $1 -- not a directory" >&2; exit 2; }
shift
if [ "${1-}" = "--adapter" ]; then
    [ $# -ge 2 ] || usage
    adapter=$2; shift 2
    [ -f "$adapter" ] || { echo "test-engine-contract.sh: no adapter at $adapter" >&2; exit 2; }
else
    [ $# -ge 1 ] || usage
    adapter=$(sh "$prog/.yg/bin/find-engine.sh" transcribe "$1") || exit 2
    shift
fi
[ $# -le 1 ] || usage
clip=${1-}
command -v ffmpeg >/dev/null 2>&1 || { echo "skipped: ffmpeg is needed to make the test audio"; exit 0; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

pass=0; fail=0
ok() { pass=$((pass + 1)); }
no() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1" >&2; }
is() { if [ "$2" = "$3" ]; then ok; else no "$1: expected [$3] got [$2]"; fi }
declared() { case $2 in 0|10|20|21|31|40) ;; 14) [ "$1" = run ] || return 1 ;; *) return 1 ;; esac; }
# call <subcommand> [args] -- the roots after the subcommand, as the flow passes them.
call() { c=$1; shift; sh "$adapter" "$c" "$prog" "$wiki" "$@"; }

printf 'Checking %s against %s\n' "$adapter" "$wiki"

# --- usage ----------------------------------------------------------------------------------------

rc=0; sh "$adapter" >/dev/null 2>&1 || rc=$?
is "no subcommand is a usage error" "$rc" "10"
rc=0; call run >/dev/null 2>&1 || rc=$?
is "run with no arguments is a usage error" "$rc" "10"

# --- check ----------------------------------------------------------------------------------------

rc=0
call check ${consent:+--consent "$consent"} >"$work/check.out" 2>"$work/check.err" || rc=$?
if declared check "$rc"; then ok; else no "check exits a declared status (got $rc)"; fi
if [ "$rc" -eq 20 ]; then
    line=$(grep '^consent: ' "$work/check.out" || true)
    if [ -n "$line" ]; then ok; else no "a consent status comes with a consent: line"; fi
    printf 'The adapter asks for consent: %s\n' "${line#consent: }"
    printf 'Re-run with --consent %s to let it, then the rest is checked.\n' "$(printf '%s' "$line" | awk '{ print $2 }')"
    printf '%s passed, %s failed\n' "$pass" "$fail"
    exit 1
fi
[ "$rc" -eq 0 ] || { sed 's/^/  /' "$work/check.err" >&2; printf '%s passed, %s failed\n' "$pass" "$((fail + 1))"; exit 1; }

cap() { sed -n "s/^$1: //p" "$work/check.out" | head -1; }
is "check declares contract 1" "$(cap contract)" "1"
for c in timestamps speakers silence_safe; do
    case $(cap "$c") in yes|no) ok ;; *) no "check declares $c as yes or no (got '$(cap "$c")')" ;; esac
done
stray=$(grep -v -e '^contract: ' -e '^timestamps: ' -e '^speakers: ' -e '^silence_safe: ' "$work/check.out" || true)
is "check prints nothing else on stdout" "$stray" ""

# segments.tsv's shape: four fields, text never empty, times numeric or empty.
shape() {
    awk -F '\t' '
        NF != 4 { print "line " NR " has " NF " fields"; next }
        $4 == "" { print "line " NR " has no text" }
        $1 != "" && $1 !~ /^[0-9]+(\.[0-9]+)?$/ { print "line " NR " start is not seconds: " $1 }
        $2 != "" && $2 !~ /^[0-9]+(\.[0-9]+)?$/ { print "line " NR " end is not seconds: " $2 }
    ' "$1"
}

# --- a recording with no speech -------------------------------------------------------------------

ffmpeg -nostdin -loglevel error -y -f lavfi -i "anullsrc=r=16000:cl=mono" -t 6 -c:a pcm_s16le \
    "$work/silence.wav" </dev/null
rc=0
call run ${consent:+--consent "$consent"} "$work/silence.wav" "$work/silence" >"$work/run.out" 2>"$work/run.err" || rc=$?
is "a silent recording succeeds" "$rc" "0"
is "and prints nothing on stdout" "$(cat "$work/run.out")" ""
if [ -f "$work/silence/segments.tsv" ]; then
    ok
    if [ "$(cap silence_safe)" = yes ]; then
        is "silence_safe: a silent recording gives no segments" "$(wc -l < "$work/silence/segments.tsv" | tr -d ' ')" "0"
    elif [ -s "$work/silence/segments.tsv" ]; then
        printf 'note: not silence-safe, and six seconds of silence produced %s segments\n' \
            "$(wc -l < "$work/silence/segments.tsv" | tr -d ' ')"
    fi
    is "silent segments are well formed" "$(shape "$work/silence/segments.tsv")" ""
else
    no "a silent recording still writes segments.tsv"
fi

# --- a recording with speech ----------------------------------------------------------------------

if [ -n "$clip" ]; then
    ffmpeg -nostdin -loglevel error -y -i "$clip" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$work/speech.wav" </dev/null
    rc=0
    call run ${consent:+--consent "$consent"} "$work/speech.wav" "$work/speech" >"$work/run.out" 2>"$work/run.err" || rc=$?
    if declared run "$rc"; then ok; else no "run exits a declared status (got $rc)"; fi
    is "a speech clip succeeds" "$rc" "0"
    is "and prints nothing on stdout" "$(cat "$work/run.out")" ""
    if [ -s "$work/speech/segments.tsv" ]; then ok; else no "a speech clip gives segments"; fi
    is "speech segments are well formed" "$(shape "$work/speech/segments.tsv" 2>/dev/null)" ""
    if grep -q '^model_requested: .' "$work/speech/meta.conf" 2>/dev/null; then ok
    else no "meta.conf names the model asked for"; fi
    if [ "$(cap timestamps)" = yes ]; then
        untimed=$(awk -F '\t' '$1 == ""' "$work/speech/segments.tsv" | wc -l | tr -d ' ')
        is "timestamps: every segment has a start" "$untimed" "0"
    fi
else
    printf 'note: no speech clip given, so segments from real speech are not checked\n'
fi

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
