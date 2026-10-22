#!/bin/sh
# Transcription adapter: whisper.cpp. Contract 1 -- `contract.md` beside this file.
#
# Everything whisper.cpp-specific lives here and nowhere else: resolving the model from a tag, the
# VAD model and its preflight, the thread count, and the ways whisper-cli fails at rc=0. The flow
# above keeps only what holds for any engine.
#
# VAD is on and there is no flag to turn it off (F20.3). Without it a recording carrying no speech
# still produces a plausible transcript -- on the settled model, digital silence and a sine
# tone both yield a short polite sentence -- so a non-speech recording would land a fabricated
# transcript in the vault, and no size test can catch it because the file is not empty. With
# VAD those cases write nothing at all, which is what lets this adapter declare silence_safe. It
# also measurably improves real speech rather than merely filtering junk. A flag would be a knob
# for a case the flow's density floor already measures.
#
# whisper-cli returns rc=0 having written no .srt in four ways (F20.2): an audio file it cannot
# decode, an -of path whose directory does not exist, an argument it does not recognise, and a
# language code it does not know. The directory is made and the language is checked against
# WHISPER_LANGS, so no .srt at rc=0 means the input, or a flag this build does not know, which
# it names as an unknown argument and which is a dependency too old for this adapter (21). A
# zero-byte .srt at rc=0 is different, and is not a failure: it is VAD filtering the whole input,
# a recording with no speech, and it becomes an empty segments.tsv. A VAD model that
# cannot be loaded fails loudly -- rc=10 absent, malformed or header-damaged, rc=134 for a file of
# the wrong type (F20.4) -- so the preflight below buys a message that says what is wrong rather
# than correctness: rc=10 arrives behind "VAD is enabled, processing speech segments only", which
# reads as progress. What the preflight cannot see is a model truncated only in its tail, which
# loads, still filters silence to zero bytes, and quietly transcribes less (F20.4.1); only a checksum
# would catch that.
#
# Usage:
#   whisper.sh check <program> <wiki> [--consent <tokens>]
#   whisper.sh run <program> <wiki> [--consent <tokens>] <in.wav> <out-dir>
#
# The model tag is transcribe.whisper.model, read from <wiki>/.yg/resolved/config.conf with no
# fallback, since one would put a model in force that no config layer shows: a missing key is a
# missing dependency (21). The SRT converter is
# <program>/.yg/bin/srt-to-segments.awk. The one consent token it asks for is `download`, for
# an absent speech or VAD model.
#
# The language hint is always answered with -l, since whisper-cli's own default is en, explicitly
# not auto-detect: left off, every recording is decoded as English. A hint is the source's code as
# its metadata gave it, region and all (en-US), and whisper-cli refuses a code it does not know at
# rc=0 (F20.2), so it is cut to its primary subtag and passed only if WHISPER_LANGS holds it.
# Anything else, and no hint, is auto: an absent hint means the language is unknown, explicitly
# not English. An English-only model ignores -l with a warning, so auto costs it nothing.
#
# Cost: not timed — one recording per run, nothing that grows, and whisper-cli is the wait.
set -eu

VAD_TAG=silero-v6.2.0
# whisper.cpp's g_lang keys, in its order; a code added upstream after this list falls to auto.
WHISPER_LANGS="en zh de es ru ko fr ja pt tr pl ca nl ar sv it id hi fi vi he uk el ms cs ro da hu ta no th ur hr bg lt la mi ml cy sk te fa lv bn sr az sl kn et mk br eu is hy ne mn bs kk sq sw gl mr pa si km sn yo so af oc ka be tg sd gu am yi lo uz fo ht ps tk nn mt sa lb my bo tl mg as tt haw ln ha ba jw su yue"
SPEECH_URL=https://huggingface.co/ggerganov/whisper.cpp/resolve/main
# The VAD model is published in a different repository from the speech models.
VAD_URL=https://huggingface.co/ggml-org/whisper-vad/resolve/main

usage() { echo "usage: whisper.sh check <program> <wiki> [--consent <tokens>] | run <program> <wiki> [--consent <tokens>] <in.wav> <out-dir>" >&2; exit 10; }

cmd=${1-}
[ $# -ge 3 ] || usage
prog=$2; wiki=$3
shift 3
[ -d "$prog" ] || { echo "whisper.sh: no program at $prog" >&2; exit 10; }
[ -d "$wiki" ] || { echo "whisper.sh: no wiki at $wiki" >&2; exit 10; }
consent=""
if [ "${1-}" = "--consent" ]; then [ $# -ge 2 ] || usage; consent=$2; shift 2; fi
case $cmd in
    check) [ $# -eq 0 ] || usage ;;
    run)   [ $# -eq 2 ] || usage
           input=$1; outdir=$2
           [ -f "$input" ] || { echo "whisper.sh: no such file: $input" >&2; exit 10; } ;;
    *)     usage ;;
esac
case ,$consent, in *,download,*) allow_download=yes ;; *) allow_download=no ;; esac

# Flat "key: value", split on the first colon, value taken literally. The resolved file only,
# never the shipped defaults (D13.1). Read by index rather than by pattern so a key's dots stay
# literal.
conf_get() {
    awk -v k="$1" 'index($0, k ": ") == 1 { v = substr($0, length(k) + 3) } END { printf "%s", v }' \
        "$wiki/.yg/resolved/config.conf" 2>/dev/null || true
}

# POSIX symlink resolution: readlink -f is not POSIX.
resolve_link() {
    p=$1
    n=0
    while [ -L "$p" ] && [ "$n" -lt 40 ]; do
        t=$(readlink "$p")
        case $t in /*) p=$t ;; *) p=$(dirname "$p")/$t ;; esac
        n=$((n + 1))
    done
    printf '%s' "$p"
}

cache_dir() { printf '%s/whisper.cpp' "${XDG_CACHE_HOME:-$HOME/.cache}"; }

# Sibling of the binary first, then the cache. A source build keeps its models two levels above
# build/bin; a package install may keep them beside the binary or one level up. Nothing here
# reads an absolute path out of the environment: a variable of our own naming a model has no
# upstream anchor -- whisper.cpp reads exactly one environment variable and it is not that one.
find_model() {
    name=$1
    bin=$(command -v whisper-cli 2>/dev/null) || return 1
    d=$(dirname "$(resolve_link "$bin")")
    for c in "$d/../../models/$name" "$d/../models/$name" "$d/models/$name" "$(cache_dir)/$name"; do
        [ -f "$c" ] && { printf '%s' "$c"; return 0; }
    done
    return 1
}

fetch() {
    url=$1; dest=$2
    mkdir -p "$(dirname "$dest")"
    tmp="$dest.part.$$"
    # -sS and -nv: quiet but never silent about an error. A progress meter is for a terminal,
    # and a harness surfaces stderr only when the call returns, so the whole meter arrives at
    # once after the download it was tracking.
    if command -v curl >/dev/null 2>&1; then curl -fsSL --retry 2 -o "$tmp" "$url"
    elif command -v wget >/dev/null 2>&1; then wget -nv -O "$tmp" "$url"
    else echo "whisper.sh: neither curl nor wget is available to fetch $url" >&2; return 1
    fi || { rm -f "$tmp"; return 1; }
    mv "$tmp" "$dest"
}

# The size the consent line quotes, asked of the server rather than kept in a table that goes
# stale when a tag is added. A HEAD request, so nothing is fetched; unknown when it cannot answer.
size_of() {
    b=$(curl -fsSIL --max-time 5 "$1" 2>/dev/null | awk 'tolower($1) == "content-length:" { v = $2 } END { print v + 0 }') || b=0
    awk -v b="${b:-0}" 'BEGIN {
        if (b >= 1e9) printf "about %.1f GB", b / 1e9
        else if (b >= 1e6) printf "about %d MB", b / 1e6
        else if (b > 0) printf "about %d KB", b / 1e3
        else printf "size unknown"
    }'
}

command -v whisper-cli >/dev/null 2>&1 || {
    echo "whisper.sh: whisper-cli is not on PATH" >&2; exit 21; }

tag=$(conf_get transcribe.whisper.model)
[ -n "$tag" ] || {
    echo "whisper.sh: transcribe.whisper.model is missing from $wiki/.yg/resolved/config.conf -- resolve the wiki's config (sh <program>/.yg/hooks/resolve-config.sh <wiki>)" >&2
    exit 21; }
speech_name="ggml-$tag.bin"
vad_name="ggml-$VAD_TAG.bin"

# Both models are resolved before anything is asked, so one consent covers both downloads rather
# than the second being met on a re-run.
model=$(find_model "$speech_name") || model=""
vad=$(find_model "$vad_name") || vad=""
if [ -z "$model" ] || [ -z "$vad" ]; then
    if [ "$allow_download" = no ]; then
        need=""
        [ -n "$model" ] || need="speech model $speech_name ($(size_of "$SPEECH_URL/$speech_name"))"
        [ -n "$vad" ] || need="${need:+$need and }VAD model $vad_name ($(size_of "$VAD_URL/$vad_name"))"
        echo "whisper.sh: not found beside whisper-cli or in $(cache_dir): $need" >&2
        printf 'consent: download fetch the %s into %s\n' "$need" "$(cache_dir)"
        exit 20
    fi
    if [ -z "$model" ]; then
        model="$(cache_dir)/$speech_name"
        fetch "$SPEECH_URL/$speech_name" "$model" || exit 31
    fi
    if [ -z "$vad" ]; then
        vad="$(cache_dir)/$vad_name"
        fetch "$VAD_URL/$vad_name" "$vad" || exit 31
    fi
fi

if [ "$cmd" = check ]; then
    printf 'contract: 1\ntimestamps: yes\nspeakers: no\nsilence_safe: yes\n'
    exit 0
fi

# whisper-cli appends .srt to -of. A directory that does not exist is one of the four rc=0
# failures (F20.2), so it is made rather than assumed.
mkdir -p "$outdir"
stem="$outdir/whisper"

lang=$(awk 'index($0, "language: ") == 1 { v = substr($0, 11) } END { printf "%s", v }' \
    "$outdir/hints.conf" 2>/dev/null | tr 'A-Z' 'a-z') || lang=""
lang=${lang%%[-_]*}
case " $WHISPER_LANGS " in *" $lang "*) [ -n "$lang" ] || lang=auto ;; *) lang=auto ;; esac
rm -f "$stem.srt"

# Logical CPUs is the worst point on the curve: previously observed, the settled model ran about
# 40% slower with a thread per logical CPU than with half as many, and base.en three to five
# times slower. It is a ramp rather than one bad value, so roughly right is the whole
# requirement. The floor of 4 reproduces whisper.cpp's own default.
cpus=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 8)
threads=$((cpus / 2))
[ "$threads" -lt 4 ] && threads=4

# The input goes through -f rather than as a positional: whisper-cli has no end-of-options
# marker (F20.7), so a leading "-" in a filename would be read as a flag -- and an argument it does not
# recognise makes it print its help and exit 0, which is another way it fails at rc=0. The
# existence check below is what catches that one.
#
# Stdout is discarded, and this is the never-read rule rather than tidiness: whisper-cli prints
# the transcript there as it decodes, a run killed partway included, and its diagnostics to
# stderr (F20.6), so letting stdout reach the terminal would put the transcript into the
# session's context against a source nobody re-reads. The .srt is the output; the log is stderr
# alone, which a failure passes on whole. -np drops the model-loading banner, which leaves a
# failure log that is diagnostic instead of a wall.
log=$(mktemp)
trap 'rm -f "$log"' EXIT INT TERM
rc=0
whisper-cli -np -m "$model" --vad -vm "$vad" -t "$threads" -l "$lang" -osrt -of "$stem" -f "$input" \
    >/dev/null 2>"$log" || rc=$?
if [ "$rc" -ne 0 ]; then
    echo "whisper.sh: whisper-cli exited $rc" >&2
    sed 's/^/  /' "$log" >&2
    exit 40
fi

[ -e "$stem.srt" ] || {
    # Only the matched line reaches stderr; the rest of the log is the usage, a wall.
    if grep -q 'unknown argument' "$log"; then
        echo "whisper.sh: whisper-cli does not recognise an argument this adapter passes, so it may be too old:" >&2
        grep 'unknown argument' "$log" | sed 's/^/  /' >&2
        exit 21
    fi
    echo "whisper.sh: the engine exited 0 and wrote no transcript for $input" >&2
    exit 14
}

awk -f "$prog/.yg/bin/srt-to-segments.awk" "$stem.srt" > "$outdir/segments.tsv"
rm -f "$stem.srt"
printf 'model_requested: %s\n' "$tag" > "$outdir/meta.conf"
