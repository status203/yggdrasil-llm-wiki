#!/bin/sh
# Self-check for the whisper adapter. The cases the logic turns on: the ways whisper-cli fails at
# rc=0 are told apart -- no .srt is an input it could not decode, unless its log names an unknown
# argument, which is a dependency too old; a zero-byte .srt is a recording with no speech and is
# not a failure -- the models are resolved in the stated order and asked
# for rather than downloaded unasked, one consent covers both, VAD cannot be turned off, the
# input reaches the engine through a flag rather than as a positional, and every status is one
# the contract declares.
#
# Most of it runs against a stub whisper-cli on PATH, which is what makes the failure modes
# reproducible: a real engine cannot be asked to exit 0 having written nothing. curl is stubbed
# too, so a download and the size a consent line quotes need no network. One live run against
# the real engine follows, found as the adapter finds it, and skipped where it or a model is
# not installed -- nothing is downloaded for it.
#
# The adapter runs in place: the program and wiki roots are its arguments, so the config it
# reads is this test's scratch wiki, not the repository's. The conformance test,
# test-engine-contract.sh, checks the contract's shape against any adapter; this checks whisper.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prog=$(CDPATH= cd -- "$here/../../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

pass=0; fail=0
ok() { pass=$((pass + 1)); }
no() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1" >&2; }
is() { if [ "$2" = "$3" ]; then ok; else no "$1: expected [$3] got [$2]"; fi }

wiki="$work/wiki"
mkdir -p "$wiki/.yg/resolved" "$wiki/.yg/default" "$work/bin" "$work/cache" "$work/out"
sut="$here/whisper.sh"
printf 'transcribe.whisper.model: testmodel\n' > "$wiki/.yg/resolved/config.conf"

# A stub engine, so the rc=0 failures can actually be produced. It records its argv, then
# behaves as STUB_MODE says.
cat > "$work/bin/whisper-cli" <<'STUB'
#!/bin/sh
: > "$ARGV_LOG"
for a in "$@"; do printf '%s\n' "$a" >> "$ARGV_LOG"; done
of=""
prev=""
for a in "$@"; do
    [ "$prev" = "-of" ] && of=$a
    prev=$a
done
case ${STUB_MODE:-ok} in
    ok)     printf '1\n00:00:00,000 --> 00:00:02,000\nOne two three.\n\n' > "$of.srt" ;;
    silent) : ;;                 # exits 0, writes nothing: an undecodable input
    usage)  { echo "error: unknown argument: --vad"; echo "usage: ..."; } >&2 ;; # exits 0, writes nothing (F20.2)
    empty)  : > "$of.srt" ;;     # exits 0, writes a zero-byte SRT: VAD filtering a whole input
    fail)   echo "[00:00:00.000 --> 00:00:02.000]   One two three."   # decoded before it died (F20.6)
            echo "error: failed to initialize whisper context" >&2; exit 3 ;;
esac
STUB
chmod +x "$work/bin/whisper-cli"

# A stub curl: a HEAD request answers a size, a fetch writes the file or fails as STUB_FETCH says.
cat > "$work/bin/curl" <<'STUB'
#!/bin/sh
out=""; head=no; prev=""
for a in "$@"; do
    [ "$prev" = "-o" ] && out=$a
    case $a in -*I*) head=yes ;; esac
    prev=$a
done
if [ "$head" = yes ]; then printf 'HTTP/2 200\r\ncontent-length: 1624555275\r\n\r\n'; exit 0; fi
[ "${STUB_FETCH:-ok}" = ok ] || exit 22
printf 'model\n' > "$out"
STUB
chmod +x "$work/bin/curl"

: > "$work/audio.wav"
ARGV="$work/argv.log"

# run <subcommand> [args] -- the roots go after the subcommand, as the flow passes them.
run() { ( cmd=$1; shift
          PATH="$work/bin:$PATH" XDG_CACHE_HOME="$work/cache" ARGV_LOG="$ARGV" \
          STUB_MODE="${MODE:-ok}" STUB_FETCH="${FETCH:-ok}" sh "$sut" "$cmd" "$prog" "$wiki" "$@" ) }

models="$work/bin/models"
mkdir -p "$models"

# --- usage ------------------------------------------------------------------------------------

rc=0; ( PATH="$work/bin:$PATH" sh "$sut" ) 2>/dev/null || rc=$?
is "no subcommand is a usage error" "$rc" "10"
rc=0; ( PATH="$work/bin:$PATH" sh "$sut" check ) 2>/dev/null || rc=$?
is "a subcommand without the roots is a usage error" "$rc" "10"
rc=0; ( PATH="$work/bin:$PATH" sh "$sut" check "$prog" "$work/nowiki" ) 2>/dev/null || rc=$?
is "a wiki root that is not a directory is a usage error" "$rc" "10"
rc=0; run check "$work/audio.wav" 2>/dev/null || rc=$?
is "check takes no further arguments" "$rc" "10"
rc=0; run run "$work/audio.wav" 2>/dev/null || rc=$?
is "run takes two arguments" "$rc" "10"
rc=0; run run "$work/nosuch.wav" "$work/out/x" 2>/dev/null || rc=$?
is "a missing input is a usage error" "$rc" "10"

# --- refusals, before the engine is reached ------------------------------------------------

# A PATH holding only the shell, linked from wherever this machine keeps it, so a real
# whisper-cli cannot be found; the adapter runs nothing else before it looks.
mkdir -p "$work/noengine"
ln -s "$(command -v sh)" "$work/noengine/sh"
rc=0; ( PATH="$work/noengine" XDG_CACHE_HOME="$work/cache" \
        sh "$sut" check "$prog" "$wiki" ) >/dev/null 2>&1 || rc=$?
is "whisper-cli absent is a missing dependency" "$rc" "21"

# Both models absent: one consent names both, so the second is not met on a re-run.
rc=0; out=$(run check 2>/dev/null) || rc=$?
is "absent models ask for consent" "$rc" "20"
case $out in
    "consent: download "*"ggml-testmodel.bin"*"ggml-silero-v6.2.0.bin"*) ok ;;
    *) no "one consent line names both models (got $out)" ;;
esac
case $out in *"about 1.6 GB"*) ok ;; *) no "and quotes the size the server gives (got $out)" ;; esac

rc=0; run run "$work/audio.wav" "$work/out/x" >/dev/null 2>&1 || rc=$?
is "run asks on the same status as check" "$rc" "20"

: > "$models/ggml-testmodel.bin"
rc=0; out=$(run check 2>/dev/null) || rc=$?
is "the VAD model alone absent still asks" "$rc" "20"
case $out in *ggml-testmodel.bin*) no "and does not name the speech model it found" ;; *) ok ;; esac

: > "$models/ggml-silero-v6.2.0.bin"

# check resolves and stops: the engine is never invoked, which is the whole point of asking
# before the payload is fetched. The stub truncates its argv log on entry, so an empty log is proof.
: > "$ARGV"
rc=0; out=$(run check 2>/dev/null) || rc=$?
is "check with both models present exits 0" "$rc" "0"
is "and declares contract 1" "$(printf '%s\n' "$out" | sed -n 's/^contract: //p')" "1"
is "and silence_safe" "$(printf '%s\n' "$out" | sed -n 's/^silence_safe: //p')" "yes"
if [ -s "$ARGV" ]; then no "check does not reach the engine"; else ok; fi

# --- consent to download ---------------------------------------------------------------------------

rm -f "$models/ggml-testmodel.bin" "$models/ggml-silero-v6.2.0.bin"
rc=0; FETCH=fail run check --consent download >/dev/null 2>&1 || rc=$?
is "a permitted download that fails is its own status" "$rc" "31"
if ls "$work/cache/whisper.cpp/"*.part.* >/dev/null 2>&1; then no "a failed fetch leaves no partial"; else ok; fi

rc=0; run check --consent download >/dev/null 2>&1 || rc=$?
is "with consent the models are fetched" "$rc" "0"
if [ -f "$work/cache/whisper.cpp/ggml-testmodel.bin" ] && [ -f "$work/cache/whisper.cpp/ggml-silero-v6.2.0.bin" ]
then ok; else no "both models land in the cache"; fi
rm -rf "$work/cache/whisper.cpp"
: > "$models/ggml-testmodel.bin"
: > "$models/ggml-silero-v6.2.0.bin"

# --- the engine's rc=0 outcomes ------------------------------------------------------------------

# An undecodable input and an unrecognised argument both leave the engine at rc=0 with no file
# written. Passing either on as success is what would put a transcript holding frontmatter and
# no body into the vault.
rc=0; MODE=silent run run "$work/audio.wav" "$work/out/s" 2>/dev/null || rc=$?
is "engine exits 0 writing no file is an undecodable input" "$rc" "14"
rc=0; MODE=usage run run "$work/audio.wav" "$work/out/u" 2>"$work/err" || rc=$?
is "an argument the engine does not recognise is a dependency too old" "$rc" "21"
if grep -q 'unknown argument: --vad' "$work/err"; then ok; else no "and names the argument on stderr"; fi

# VAD filtering an entire input leaves a zero-byte SRT rather than no file -- probed on the real
# engine, six seconds of digital silence with VAD on gives rc=0 and a file of 0 bytes, where the
# same input with VAD off gives a 38-byte fabricated transcript. That is a recording with no
# speech, not a fault: success, with no segments, which the flow reports as no speech.
rc=0; MODE=empty run run "$work/audio.wav" "$work/out/e" 2>/dev/null || rc=$?
is "a zero-byte SRT is success" "$rc" "0"
if [ -e "$work/out/e/segments.tsv" ] && [ ! -s "$work/out/e/segments.tsv" ]; then ok
else no "and leaves an empty segments.tsv"; fi

# A loud engine failure is the contract's engine status, never the engine's own number: 3 from
# whisper-cli is a speech model that will not load, and passed through it read as a missing
# dependency.
rc=0; MODE=fail run run "$work/audio.wav" "$work/out/f" 2>"$work/err" || rc=$?
is "a loud engine failure is the engine status" "$rc" "40"
if grep -q 'exited 3' "$work/err"; then ok; else no "and names the engine's own status on stderr"; fi
if grep -q 'failed to initialize' "$work/err"; then ok; else no "and passes the engine's diagnostics on"; fi
if grep -q 'One two three' "$work/err"; then no "but never the transcript it printed before failing"; else ok; fi

# --- the happy path ---------------------------------------------------------------------------

rc=0; out=$(run run "$work/audio.wav" "$work/out/good" 2>/dev/null) || rc=$?
is "a successful run exits 0" "$rc" "0"
is "and prints nothing on stdout" "$out" ""
is "segments.tsv carries the cue" "$(cat "$work/out/good/segments.tsv")" "$(printf '0.000\t2.000\t\tOne two three.')"
is "meta.conf records the model asked for" "$(cat "$work/out/good/meta.conf")" "model_requested: testmodel"
if [ -e "$work/out/good/whisper.srt" ]; then no "the intermediate SRT is not left behind"; else ok; fi

# A directory that does not exist is the second rc=0 failure, so it is created rather than
# assumed.
rc=0; run run "$work/audio.wav" "$work/out/deeper/still" 2>/dev/null || rc=$?
if [ -s "$work/out/deeper/still/segments.tsv" ]; then ok; else no "a missing output directory is created"; fi

# --- what reaches the engine -------------------------------------------------------------------

run run "$work/audio.wav" "$work/out/argv" >/dev/null 2>&1
argv=$(cat "$ARGV")
if printf '%s\n' "$argv" | grep -qx -- '--vad'; then ok; else no "VAD is always on"; fi
if printf '%s\n' "$argv" | grep -qx -- '-vm'; then ok; else no "the VAD model is always passed"; fi
if printf '%s\n' "$argv" | grep -qx -- '-f'; then ok; else no "the input goes through -f"; fi

# The input must not also appear as a trailing positional: whisper-cli has no end-of-options
# marker, so a filename beginning with - would be read as a flag.
is "the input is not a positional" "$(printf '%s\n' "$argv" | tail -1)" "$work/audio.wav"
is "and it follows -f" "$(printf '%s\n' "$argv" | tail -2 | head -1)" "-f"

# Logical CPUs is the worst point on the curve, so the thread count must sit at or below half.
cpus=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 8)
t=$(printf '%s\n' "$argv" | grep -A1 -x -- '-t' | tail -1)
if [ "$t" -ge 4 ] && { [ "$t" -le $((cpus / 2)) ] || [ "$t" -eq 4 ]; }; then ok
else no "threads sit at or below half the logical CPUs (cpus=$cpus t=$t)"; fi

# --- the language hint -------------------------------------------------------------------------

# whisper-cli's own default is en, so leaving -l off decodes every recording as English. A hint
# is the source's code as its metadata gave it, region and all, and whisper-cli refuses a code
# it does not know at rc=0 with no SRT (F20.2), so the hint is cut to its primary subtag and passed
# only when whisper knows it; anything else, and no hint at all, is auto.
lang_for() {
    rm -f "$work/out/lang/hints.conf"
    mkdir -p "$work/out/lang"
    [ $# -eq 0 ] || printf 'language: %s\n' "$1" > "$work/out/lang/hints.conf"
    run run "$work/audio.wav" "$work/out/lang" >/dev/null 2>&1
    grep -A1 -x -- '-l' "$ARGV" | tail -1
}
is "no hint is auto-detect, overriding whisper's en default" "$(lang_for)" "auto"
is "a hint whisper knows is passed" "$(lang_for de)" "de"
is "a region subtag is cut to the language" "$(lang_for en-US)" "en"
is "an underscore region and upper case too" "$(lang_for PT_BR)" "pt"
is "a three-letter code whisper knows is passed" "$(lang_for haw)" "haw"
is "a code whisper does not know is auto" "$(lang_for xx)" "auto"
is "a hint shaped like a flag is auto" "$(lang_for -tr)" "auto"
is "an empty hint is auto" "$(lang_for '')" "auto"
is "the input still follows -f last" "$(tail -2 "$ARGV" | head -1)" "-f"

# --- model resolution ------------------------------------------------------------------------

is "the tag comes from resolved config" \
    "$(printf '%s\n' "$argv" | grep -c 'ggml-testmodel.bin')" "1"

# Sibling of the binary beats the cache.
mkdir -p "$work/cache/whisper.cpp"
printf 'cache copy\n' > "$work/cache/whisper.cpp/ggml-testmodel.bin"
run run "$work/audio.wav" "$work/out/pref" >/dev/null 2>&1
if printf '%s\n' "$(cat "$ARGV")" | grep -q "$models/ggml-testmodel.bin"; then ok
else no "a model beside the binary is preferred over the cache"; fi

# With no sibling, the cache is used.
mv "$models/ggml-testmodel.bin" "$work/held.bin"
run run "$work/audio.wav" "$work/out/cache" >/dev/null 2>&1
if printf '%s\n' "$(cat "$ARGV")" | grep -q "$work/cache/whisper.cpp/ggml-testmodel.bin"; then ok
else no "the cache is used when nothing sits beside the binary"; fi
mv "$work/held.bin" "$models/ggml-testmodel.bin"

# With no tag in resolved config there is no fallback (D13.1): not the shipped default, which a
# reader of resolved config never consults, and not a built-in tag, which would put a model in
# force that no config layer shows -- and the flow records provenance from what the adapter
# reports, so the two must not diverge. A missing key is a missing dependency, named.
mv "$wiki/.yg/resolved/config.conf" "$work/held.conf"
printf 'transcribe.whisper.model: shippeddefault\n' > "$wiki/.yg/default/config.conf"
: > "$models/ggml-shippeddefault.bin"
: > "$models/ggml-large-v3-turbo.bin"
: > "$ARGV"
rc=0; run run "$work/audio.wav" "$work/out/def" >/dev/null 2>"$work/err" || rc=$?
is "a missing model key is a missing dependency" "$rc" "21"
if grep -q 'transcribe.whisper.model is missing' "$work/err"; then ok; else no "and names the key"; fi
if [ -s "$ARGV" ]; then no "and the engine is not run on any model"; else ok; fi
rm -f "$models/ggml-large-v3-turbo.bin" "$models/ggml-shippeddefault.bin"
mv "$work/held.conf" "$wiki/.yg/resolved/config.conf"

# The roots are arguments, so whichever wiki is passed decides which config is read, and whichever
# program is passed decides where the converter is found -- a personal adapter, outside the
# program, needs both.
mkdir -p "$work/alt/.yg/resolved" "$work/altprog/.yg/bin"
printf 'transcribe.whisper.model: alttag\n' > "$work/alt/.yg/resolved/config.conf"
: > "$models/ggml-alttag.bin"
( PATH="$work/bin:$PATH" XDG_CACHE_HOME="$work/cache" ARGV_LOG="$ARGV" \
  sh "$sut" run "$prog" "$work/alt" "$work/audio.wav" "$work/out/alt" ) >/dev/null 2>&1
if grep -q 'ggml-alttag.bin' "$ARGV"; then ok; else no "the wiki argument decides which config is read"; fi
printf '{ print "from-alt-program" }\n' > "$work/altprog/.yg/bin/srt-to-segments.awk"
( PATH="$work/bin:$PATH" XDG_CACHE_HOME="$work/cache" ARGV_LOG="$ARGV" \
  sh "$sut" run "$work/altprog" "$wiki" "$work/audio.wav" "$work/out/altprog" ) >/dev/null 2>&1
if grep -q 'from-alt-program' "$work/out/altprog/segments.tsv" 2>/dev/null; then ok
else no "the program argument decides where the converter is found"; fi

# --- one live run against the real engine ------------------------------------------------------

# Found as the adapter finds it: whisper-cli on PATH, base.en and the VAD model beside it or in
# the cache, which check confirms. curl is stubbed to fail so that check, asking about an absent
# model, quotes no size rather than asking the network; with no consent given, nothing is
# fetched. A source build ships sample speech beside its models, which is the clip.
live_bin=$(command -v whisper-cli 2>/dev/null || true)
sample=""
if [ -n "$live_bin" ]; then
    while [ -L "$live_bin" ]; do
        t=$(readlink "$live_bin")
        case $t in /*) live_bin=$t ;; *) live_bin=$(dirname "$live_bin")/$t ;; esac
    done
    d=$(dirname "$live_bin")
    sample=$(ls "$d/../../samples/"*.wav 2>/dev/null | head -1 || true)
fi
mkdir -p "$work/nonet" "$work/live/.yg/resolved"
printf '#!/bin/sh\nexit 7\n' > "$work/nonet/curl"
chmod +x "$work/nonet/curl"
printf 'transcribe.whisper.model: base.en\n' > "$work/live/.yg/resolved/config.conf"
live() { ( PATH="$work/nonet:$PATH" sh "$sut" "$1" "$prog" "$work/live" ${2:+"$2"} ${3:+"$3"} ); }

if [ -n "$live_bin" ] && [ -n "$sample" ] && live check >/dev/null 2>&1; then
    rc=0
    live run "$sample" "$work/out/live" >/dev/null 2>&1 || rc=$?
    is "a real run exits 0" "$rc" "0"
    if [ -s "$work/out/live/segments.tsv" ]; then ok; else no "a real run writes non-empty segments"; fi
    bad=$(awk -F '\t' 'NF != 4' "$work/out/live/segments.tsv" 2>/dev/null | wc -l | tr -d ' ')
    is "every real segment has four fields" "$bad" "0"
else
    printf 'skipped: the live run needs whisper-cli, its ggml-base.en.bin and VAD model installed, and a sample clip beside them\n'
fi

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
