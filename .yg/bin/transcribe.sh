#!/bin/sh
# One input -- a local media file, or anything yt-dlp accepts -- into one markdown transcript in
# the wiki's import/ drop-zone. It writes the file and nothing more: import/ is gitignored, and
# nothing here stages or commits. Where the transcript goes after that is a decision about the
# conversation, and belongs to the session rather than here.
#
# There is no URL pattern matching. Anything that is not an existing local file goes to yt-dlp,
# which owns the list of sites and URL forms and updates it weekly; a hand-kept list rots, and
# the one this replaces already missed /live/ and /embed/ paths and an alternative embed host,
# and sent a schemeless paste down the local-file branch to abort as a nonexistent file.
#
# The caption fast path is not YouTube-specific either. One metadata call asks whether a usable
# caption track exists, which is a question yt-dlp answers for any site, and a human-authored
# track beats anything transcribed locally -- punctuated, correctly spelled, proper nouns
# intact, and back in two round trips rather than minutes of CPU.
#
# The existence test reads that metadata and never the presence of a downloaded file. A caption
# body is not fetched during extraction: the inventory comes from the player response and
# carries URLs (`F21.5`). So a failed fetch cannot empty the inventory, and a caption-rich video cannot
# read as having none -- which is a whole class of past incident closed by construction rather
# than by a warning. F21.5 was probed on YouTube; for another site's extractor it is assumed.
#
# Nothing here reads the transcript; only the user's explicit request does, in the flow. It
# is arbitrary text from a third party, it is long, and a model that reads it can silently
# paraphrase or truncate it against a source nobody re-reads. The
# body reaches no model context here: what is written comes from the metadata, and the checks
# on the body -- size, word count, and gaps and repetition in segments.tsv -- run in the shell
# and report times and counts, never text. A check in awk is not a read.
#
# The engine is a seam. transcribe.engine names an adapter, which find-engine.sh finds in the
# user layer and then in <program>/.yg/engines/transcribe/, and the contract it keeps is
# <program>/.yg/engines/transcribe/contract.md: audio in, segments.tsv out, a closed set of
# statuses. What holds for any engine stays here -- fetching, captions, normalising, the checks
# on what came back, rendering, provenance -- so replacing the engine is a config line and a
# file, and no edit to this script.
#
# The wiki root is the first argument on every form; the program is found from where this script
# sits. Config is <wiki>/.yg/resolved/config.conf. A relative local input is the caller's own
# argument, so it resolves against the caller's working directory.
#
# Usage:
#   transcribe.sh <wiki> <path-or-url>
#   transcribe.sh <wiki> --consent <tokens> <path-or-url>   grant what the engine asked consent
#                                                           for, comma-separated, from its
#                                                           consent: line
#   transcribe.sh <wiki> --keep import/<file>               move a kept transcript under
#                                                           .sources/recordings/ and print the
#                                                           path to cite
#
# Exit status. One closed set, shared with the adapters, grouped by what the reader does about
# it: 1x the input, and nothing is wrong; 2x the user is needed; 3x fetching; 4x the engine; 5x
# this script. A status outside the set is caught by the EXIT trap and reported as 50 with the
# raw status on stderr, so no number reaches the caller meaning something it was not declared to.
#
#   0   wrote a transcript, or kept one
#   10  usage, no directory at the wiki root, or a --keep path that is not a file directly in
#       import/
#   11  an input that is neither a local file nor anything yt-dlp accepts
#   12  the input carries no audio stream
#   13  no speech: nothing came back, or it rendered empty
#   14  the input could not be decoded, by ffmpeg normalising it or by the engine
#   20  the engine needs consent; the consent: line on stderr says for what and names the token
#   21  a dependency is missing or too old -- a tool, transcribe.engine in resolved config, or an adapter
#       for the engine it names
#   30  the media or its metadata could not be fetched
#   31  a download the engine was permitted failed
#   40  the engine failed; the adapter's stderr says how
#   41  the adapter broke its contract -- an undeclared status, or no segments on success
#   42  the adapter declares a different contract version from this script's
#   50  a defect in this script: it stopped on a status it does not declare, or called the
#       adapter wrongly
#   51  interrupted, by INT or TERM -- a run killed part-way, which a re-run in the background
#       answers; a hard kill cannot be caught and reaches the caller as the shell's own status
#
# Cost: not timed — one recording per run, nothing that grows, and the engine is the wait.
set -eu

usage() {
    echo "usage: transcribe.sh <wiki> [--consent <tokens>] <path-or-url> | transcribe.sh <wiki> --keep import/<file>" >&2
    exit 10
}

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prog=$(CDPATH= cd -P -- "$here/../.." && pwd)
[ $# -ge 2 ] && [ -n "$1" ] || usage
wiki=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || {
    echo "transcribe.sh: no wiki at $1 -- not a directory" >&2
    exit 10
}
shift

# --keep: the keep routes' move, here rather than in the skill's prose because a plain mv
# overwrites a same-named source that may already be cited. Bumped the way import/ names are.
if [ "$1" = "--keep" ]; then
    [ $# -eq 2 ] || usage
    case $2 in /*) src=$2 ;; *) src="$wiki/$2" ;; esac
    name=${src#"$wiki/import/"}
    case $name in "$src"|*/*|"") echo "transcribe.sh: --keep takes a file directly in import/: $2" >&2; exit 10 ;; esac
    [ -f "$src" ] || { echo "transcribe.sh: no such file: $2" >&2; exit 10; }
    mkdir -p "$wiki/.sources/recordings"
    base=${name%.md}
    dest="$wiki/.sources/recordings/$name"
    n=2
    while [ -e "$dest" ]; do
        dest="$wiki/.sources/recordings/$base-$n.md"
        n=$((n + 1))
    done
    mv "$src" "$dest"
    printf '%s\n' "${dest#"$wiki"/}"
    exit 0
fi

consent=""
if [ "$1" = "--consent" ]; then
    [ $# -ge 2 ] || usage
    consent=$2; shift 2
fi
[ $# -eq 1 ] || usage
input=$1

CONTRACT=1

work=$(mktemp -d)
# The whole declared set, so that an unguarded command aborting under set -e -- carrying its own
# status, which could land on any number -- can never be read as one of these.
on_exit() {
    st=$1
    rm -rf "$work"
    [ -z "${part:-}" ] || rm -f "$part"
    case $st in
        0|10|11|12|13|14|20|21|30|31|40|41|42|50|51) ;;
        *) printf 'transcribe.sh: stopped on status %s, which this script does not declare\n' "$st" >&2
           exit 50 ;;
    esac
}
trap 'on_exit $?' EXIT
trap 'exit 51' INT TERM

note() { printf '%s\n' "$*" >&2; }

# --- dependencies, before anything is fetched or spent --------------------------------------

# The engine's own dependencies are its adapter's to report, from check.
missing=
for t in yt-dlp ffmpeg ffprobe; do
    command -v "$t" >/dev/null 2>&1 || missing="$missing $t"
done
[ -z "$missing" ] || { note "transcribe.sh: not installed:$missing"; exit 21; }

# --- the engine ------------------------------------------------------------------------------

# Flat "key: value" from the resolved config, by index so a key's dots stay literal. The
# resolved file is trusted as an invariant, with no fallback value here.
conf_get() {
    awk -v k="$1" 'index($0, k ": ") == 1 { v = substr($0, length(k) + 3) } END { printf "%s", v }' \
        "$wiki/.yg/resolved/config.conf" 2>/dev/null || true
}

# A name, never a path, found by find-engine.sh: personal before shipped, and held to one safe
# class because it becomes a filename. There is no built-in engine, since one would put a value in
# force that no config layer shows: a missing transcribe.engine stops the run.
#
# Looked up only once an engine is needed, so a misconfigured one cannot stop a run the caption
# path would have finished without it.
engine=$(conf_get transcribe.engine)
adapter=""
find_adapter() {
    [ -n "$engine" ] || {
        note "transcribe.sh: transcribe.engine is missing from $wiki/.yg/resolved/config.conf -- resolve the wiki's config (sh $prog/.yg/hooks/resolve-config.sh $wiki) before transcribing"
        exit 21
    }
    frc=0
    adapter=$(sh "$prog/.yg/bin/find-engine.sh" transcribe "$engine") || frc=$?
    case $frc in
        0) ;;
        21) exit 21 ;;
        *) note "transcribe.sh: find-engine.sh exited $frc -- a defect in this script's call"; exit 50 ;;
    esac
}

# Run through sh, as every script here is, with the program and wiki roots as its leading
# arguments, since a personal adapter sits outside the program and cannot find either itself.
adapter_call() { c=$1; shift; sh "$adapter" "$c" "$prog" "$wiki" "$@"; }

# An adapter's status is one the contract lets it use, or the adapter is broken, since an engine's
# own number could land on one of ours and mean something else.
#
# 10 is the one declared status that is not the adapter's to own: it means this script called it
# wrongly, so it is reported as this script's defect.
adapter_status() {
    case $1 in
        20|21|31|40) exit "$1" ;;
        14) [ "$2" = run ] && exit 14 ;;
        10) note "transcribe.sh: called the $engine adapter's $2 wrongly -- a defect in this script"
            exit 50 ;;
    esac
    note "transcribe.sh: the $engine adapter's $2 exited $1, which the contract does not allow"
    exit 41
}

# Asked before anything is spent: on a remote input, before the media download, since a refusal
# met after it costs the transfer twice -- once now and once on the re-run that carries the
# consent. The caption path never gets here, needing no engine at all.
checked=no
engine_check() {
    [ "$checked" = no ] || return 0
    find_adapter
    crc=0
    adapter_call check ${consent:+--consent "$consent"} > "$work/check.out" || crc=$?
    if [ "$crc" -eq 20 ]; then
        grep '^consent: ' "$work/check.out" >&2 || note "transcribe.sh: the $engine adapter asked for consent without saying for what"
        exit 20
    fi
    [ "$crc" -eq 0 ] || adapter_status "$crc" check
    got=$(sed -n 's/^contract: //p' "$work/check.out" | head -1)
    [ "$got" = "$CONTRACT" ] || {
        note "transcribe.sh: the $engine adapter keeps contract ${got:-(none stated)}, and this script needs $CONTRACT"
        exit 42
    }
    [ "$(cap silence_safe)" = yes ] || \
        note "transcribe.sh: the $engine engine does not promise that a recording with no speech produces nothing -- the words-per-second figure is the check"
    [ "$(cap timestamps)" = yes ] || \
        note "transcribe.sh: the $engine engine gives no timings, so the transcript will carry no seek handles, and a dropped stretch or a transcript cut short will not be reported"
    checked=yes
}
cap() { sed -n "s/^$1: //p" "$work/check.out" | head -1; }

# --- the date, fetched rather than assumed ---------------------------------------------------

# Its own step, before anything is named after it. A date carried in from elsewhere drifts and
# is not UTC; this is the one clock the flow has.
today=$(date -u +%Y-%m-%d)

# --- helpers ----------------------------------------------------------------------------------

# Top-level keys of a single-line JSON object, one per line. yt-dlp's own field-path syntax
# cannot reach a key containing a hyphen -- automatic_captions.en-orig reads as NA even when
# the key is there (`F21.4`) -- and that is exactly the key the selection below wants most.
json_keys() {
    awk '{
        s = $0; n = length(s); depth = 0; i = 1
        while (i <= n) {
            c = substr(s, i, 1)
            if (c == "\"") {
                j = i + 1; str = ""
                while (j <= n) {
                    ch = substr(s, j, 1)
                    if (ch == "\\") { str = str substr(s, j + 1, 1); j += 2; continue }
                    if (ch == "\"") break
                    str = str ch; j++
                }
                k = j + 1
                while (k <= n && substr(s, k, 1) ~ /[ \t]/) k++
                if (depth == 1 && substr(s, k, 1) == ":") print str
                i = j + 1
                continue
            }
            if (c == "{" || c == "[") depth++
            else if (c == "}" || c == "]") depth--
            i++
        }
    }'
}

has_key() { printf '%s\n' "$2" | grep -qx -- "$1"; }

# A title is a third party's text and lands in a filename. Reducing it to one safe class closes
# path traversal by construction rather than by rejecting suspicious input: there is no way to
# spell / or .. in what comes out. The class is ASCII only with sed under C (F19.4).
#
# Control characters are folded to a space first, and that ordering is load-bearing: sed is
# line-oriented, so a newline in the title is a record separator rather than a character it can
# substitute, and every later rule would run on the two halves independently and let the newline
# through into the filename. A filename may legally carry one, and the local-file branch takes
# its title from basename, so nothing upstream has already flattened it.
slugify() {
    printf '%s' "$1" \
        | tr '\000-\037' ' ' \
        | tr '[:upper:]' '[:lower:]' \
        | LC_ALL=C sed 's/[^a-z0-9]\{1,\}/-/g; s/^-*//; s/-*$//' \
        | awk '{ s = $0
                 if (length(s) > 60) { s = substr(s, 1, 60); sub(/-[^-]*$/, "", s) }
                 sub(/-*$/, "", s); print s }'
}

# A title also lands in a YAML value, where a colon, a quote or a newline ends the value and
# starts something else. Single-quoted with any single quote doubled is YAML's own escape, and
# control characters go entirely.
# Quoted only where YAML needs it, so an ordinary value looks the way its sibling files'
# values look -- the contract's take-shape-from-the-siblings rule applied to a machine-written
# file. What forces quoting is what actually ends a plain scalar early: a leading indicator
# character, ": " or " #" inside it, a trailing colon, or leading and trailing space. An
# unquoted value carrying ": " does not merely lose its own field, it voids the whole property
# block (`F15.1`, `F15.1.1`), so the cost of getting this wrong is the page's entire frontmatter.
#
# Control characters fold to a space first, and that ordering is load-bearing for the same reason
# as in the slug: with a newline still present sed would treat the halves as separate records and
# leave a bare line sitting in the middle of the block.
#
# Round-tripped through a real YAML parser over twenty shapes, including a traversing title, an
# embedded newline, an interior quote and every leading indicator.
yaml_scalar() {
    v=$(printf '%s' "$1" | tr '\000-\037' ' ')
    q=no
    case $v in
        '') q=yes ;;
        *': '*) q=yes ;;
        *' #'*) q=yes ;;
        *:) q=yes ;;
        ' '*) q=yes ;;
        *' ') q=yes ;;
    esac
    case $v in
        [-?:,\[{\#\&\*\!\|\>\'\"%@\`]*) q=yes ;;
    esac
    if [ "$q" = yes ]; then printf "'%s'" "$(printf '%s' "$v" | sed "s/'/''/g")"
    else printf '%s' "$v"; fi
}

hhmmss() {
    awk -v s="$1" 'BEGIN {
        s = int(s + 0.5)
        printf "%02d:%02d:%02d\n", int(s / 3600), int((s % 3600) / 60), s % 60
    }'
}

# --- classify the input -------------------------------------------------------------------------

media=""
segs=""
hint_lang=""
source_url=""
source_path=""
transcription_source=""
title=""
duration=""

if [ -f "$input" ]; then
    media=$input
    source_path=$(CDPATH= cd -- "$(dirname -- "$input")" && pwd)/$(basename -- "$input")
    title=$(basename -- "$input")
    title=${title%.*}
else
    # Metadata once. --skip-download means no media and no caption body is fetched here.
    if ! yt-dlp --skip-download --write-info-json --no-warnings \
        -o "$work/meta" "$input" >/dev/null 2>"$work/ytdlp.err"
    then
        note "transcribe.sh: $input is neither a local file nor anything yt-dlp could fetch"
        sed 's/^/  /' "$work/ytdlp.err" >&2 || true
        exit 11
    fi
    info=$(ls "$work"/meta*.info.json 2>/dev/null | head -1)
    [ -n "$info" ] || { note "transcribe.sh: no metadata came back for $input"; exit 30; }

    get() { yt-dlp --load-info-json "$info" --skip-download --no-warnings --print "$1" 2>/dev/null | head -1; }
    title=$(get '%(title)s')
    duration=$(get '%(duration)s')
    source_url=$(get '%(webpage_url)s')
    extractor=$(get '%(extractor)s')
    vcodec=$(get '%(vcodec)s')
    lang=$(get '%(language)s')
    case $lang in NA|"") lang="" ;; *) hint_lang=$lang ;; esac
    case $source_url in NA|"") source_url=$input ;; esac
    # webpage_url is canonical for a real extractor, which is what turns a short form or a
    # tracking-laden paste into a stable reference. The generic extractor has nothing to
    # canonicalise and reports the post-redirect URL instead -- on a CDN that is a rotating node
    # hostname, so the citation rots (F21.3). There the requested URL is the one that survives.
    case $extractor in generic|NA|"") source_url=$input ;; esac
    case $duration in NA|"") duration="" ;; esac

    manual=$(get '%(subtitles)j' | json_keys)
    auto=$(get '%(automatic_captions)j' | json_keys)

    # An unknown language is read from the one -orig key, the site's mark of the original
    # language, explicitly not assumed to be English, which would take a translated en track as
    # the original. With none, or several, no track can be told from a translation.
    if [ -z "$lang" ]; then
        orig=$(printf '%s\n' "$auto" | grep -- '-orig$' || true)
        case $orig in *"
"*|"") ;; *) lang=${orig%-orig} ;; esac
    fi

    # Provenance decides, not the language code. A manual track is human-authored; an
    # automatic one is ASR, and among those the original-language key is the one that was
    # not machine-translated from something else. A translated track is never taken: it is
    # a round trip through two models, and it is the class that draws refusals.
    #
    # Within each provenance the exact language is tried, then its bare form: metadata can say
    # en-US where the site keys its tracks en and en-orig, and the region tag would otherwise
    # hide a usable track and send a captioned video down the slow path.
    track=""
    kind=""
    pick() {
        for l in "$lang" "${lang%%-*}"; do
            has_key "$l$2" "$3" && { track="$l$2"; kind=$1; return 0; }
        done
        return 1
    }
    [ -z "$lang" ] || pick manual "" "$manual" || pick auto -orig "$auto" || pick auto "" "$auto" || true

    if [ -n "$track" ]; then
        # Native SRT, never a conversion. Converting a caption track through an intermediate
        # format renders a rolling display buffer literally and roughly triples the words.
        # One track, named exactly: --sub-langs entries are regexes matched whole (F21.1), so a
        # key carrying a metacharacter would widen the selection rather than fail.
        yt-dlp --load-info-json "$info" --skip-download --no-warnings \
            --sub-format srt --sub-langs "$track" \
            $( [ "$kind" = manual ] && echo --write-subs || echo --write-auto-subs ) \
            -o "$work/cap" >/dev/null 2>&1 || true
        got=$(ls "$work"/cap*.srt 2>/dev/null | head -1)
        # A track counts only once it converts to segments: a body that is not SRT converts to
        # nothing, and taking it would report a captioned video as one with no speech.
        if [ -n "$got" ] && [ -s "$got" ] \
            && awk -f "$here/srt-to-segments.awk" "$got" > "$work/segments.tsv" \
            && [ -s "$work/segments.tsv" ]; then
            segs="$work/segments.tsv"
            transcription_source=captions
            note "transcribe.sh: using the $kind caption track ($track)"
        else
            note "transcribe.sh: the $track caption track was listed but did not come back as SRT; transcribing instead"
        fi
    fi

    if [ -z "$segs" ]; then
        # Only where the inventory really held nothing. Where a track was listed and did not arrive
        # as SRT, the line above has already said so, and claiming the video has no captions
        # would be the same conflation the inventory test exists to prevent -- one stated to
        # the user rather than acted on.
        if [ -n "$track" ]; then :
        elif [ -z "$lang" ]; then
            note "transcribe.sh: the video's language is unknown, so a caption track can't be told from a translation; transcribing instead"
        else note "No usable caption track for this input."; fi
        engine_check
        note "Transcribing with the $engine engine. Locally and without a GPU this can take a long time -- minutes to tens of minutes."
        if ! yt-dlp --no-warnings -f 'bestaudio/best' -o "$work/media.%(ext)s" \
            "$input" >/dev/null 2>"$work/dl.err"
        then
            note "transcribe.sh: could not fetch the media for $input"
            sed 's/^/  /' "$work/dl.err" >&2 || true
            exit 30
        fi
        media=$(ls "$work"/media.* 2>/dev/null | head -1)
        [ -n "$media" ] || { note "transcribe.sh: nothing was downloaded for $input"; exit 30; }
    fi
fi

# --- probe, normalise, transcribe ------------------------------------------------------------

# The caption path downloads no media and the slow path downloads bestaudio, so ffprobe either
# never runs or sees a stream with the video deliberately stripped. Either way it cannot tell a
# talk from a podcast, and every remote video was being recorded as an audio-transcript. The
# info-JSON knows: vcodec names the source's video stream, and NA or none means there is none.
# It is read from a call that passes no -f, because the field describes the selected format
# rather than the source (F21.2), so an audio-only selector there would answer none every time.
# ffprobe below can still upgrade a local file; it never downgrades, because source_type
# describes the source rather than the bytes that were fetched from it.
source_type=audio-transcript
case ${vcodec:-} in NA|none|"") : ;; *) source_type=video-transcript ;; esac

if [ -z "$segs" ]; then
    # An input with no audio stream is refused here rather than three steps later inside
    # ffmpeg -- and on a remote input, before a long download is spent on it. A bare image and
    # a silent screen recording both reach this point looking like ordinary media.
    if [ -z "$(ffprobe -v error -select_streams a -show_entries stream=index \
                -of csv=p=0 -- "$media" 2>/dev/null)" ]; then
        note "transcribe.sh: $input carries no audio stream, so there is nothing to transcribe"
        exit 12
    fi
    # The capital V excludes an attached picture, so a track with cover art stays audio. It
    # cannot tell a talk uploaded as a static image from real video, and it is not asked to:
    # a wrong answer here is one word of frontmatter, which is why the two once had separate
    # directories and no longer do.
    [ -n "$(ffprobe -v error -select_streams V -show_entries stream=index \
            -of csv=p=0 -- "$media" 2>/dev/null)" ] && source_type=video-transcript

    # format=duration, never the stream's: a whole container family reports N/A on the audio
    # stream, and a multi-stream file reports values that disagree with no rule for choosing.
    [ -n "$duration" ] || duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 -- "$media" 2>/dev/null || true)

    # Normalised unconditionally, and this is the contract's input: 16 kHz mono 16-bit WAV. An
    # engine that accepts or rejects by container and codec pair rather than by extension --
    # whisper-cli does (F20.1), taking vorbis in ogg and refusing it in matroska -- leaves no
    # extension or format branch sound, and the pass costs a fraction of a second. An adapter
    # whose engine wants something else re-encodes from here. ffmpeg's failure is guarded rather
    # than left to set -e, which would exit on ffmpeg's own status.
    ffmpeg -nostdin -loglevel error -y -i "$media" -vn -ac 1 -ar 16000 -c:a pcm_s16le \
        "$work/audio.wav" </dev/null || true
    [ -s "$work/audio.wav" ] || { note "transcribe.sh: could not decode the audio of $input"; exit 14; }

    engine_check
    mkdir -p "$work/engine"
    [ -n "$hint_lang" ] && printf 'language: %s\n' "$hint_lang" > "$work/engine/hints.conf"
    erc=0
    # Captured, as check's is: stdout is this script's report, and an adapter's consent line
    # belongs on stderr with every other message.
    adapter_call run ${consent:+--consent "$consent"} "$work/audio.wav" "$work/engine" > "$work/run.out" || erc=$?
    if [ "$erc" -eq 20 ]; then
        grep '^consent: ' "$work/run.out" >&2 || note "transcribe.sh: the $engine adapter asked for consent without saying for what"
        exit 20
    fi
    [ "$erc" -eq 0 ] || adapter_status "$erc" run
    [ -f "$work/engine/segments.tsv" ] || {
        note "transcribe.sh: the $engine adapter exited 0 and wrote no segments.tsv"
        exit 41
    }
    segs="$work/engine/segments.tsv"

    # Provenance is what the adapter reports, never composed here from config it may not read. A
    # service that routes between models can run one other than the one asked for, so where it
    # says which ran, that is recorded, with the request beside it when they differ.
    meta() { sed -n "s/^$1: //p" "$work/engine/meta.conf" 2>/dev/null | head -1; }
    asked=$(meta model_requested)
    ran=$(meta model_reported)
    transcription_source=$engine
    if [ -n "$ran" ] && [ -n "$asked" ] && [ "$ran" != "$asked" ]; then
        transcription_source="$engine:$ran (asked for $asked)"
    elif [ -n "$ran$asked" ]; then
        transcription_source="$engine:${ran:-$asked}"
    fi
else
    [ -n "$duration" ] || duration=0
fi

[ -n "$duration" ] || duration=0

# --- render, then check, then write -------------------------------------------------------------

# To a file first. The renderer exits 0 having written nothing when there are no segments, so
# the exit status cannot carry this check, and a bare append would leave a transcript holding
# frontmatter and no body -- with the work directory already cleaned up behind it. No segments
# is a recording with no speech: an engine that filters silence to nothing, which is the outcome
# a silence-safe engine exists to produce, and not a fault.
sh "$here/segments-to-markdown.sh" "$segs" > "$work/body.md" || true
[ -s "$work/body.md" ] || {
    note "transcribe.sh: $input produced no transcript: the recording carries no speech the engine found"
    exit 13
}

# Reported, never enforced. Real speech measures well above this and a transcript hallucinated
# out of silence well below it, but a genuinely sparse recording exists -- a lecture with long
# pauses, an interview with dead air -- and throwing away a multi-minute run on a heuristic is
# worse than a flagged file the reader is already looking at. It is also the instrument that
# makes VAD safe to leave with no override: word loss would show up here.
words=$(sed 's/^\[[0-9:]*\] //; s/^\*\*[^*]*:\*\* //' "$work/body.md" | wc -w | tr -d ' ')
if [ "${duration%.*}" -gt 0 ] 2>/dev/null; then
    rate=$(awk -v w="$words" -v d="$duration" 'BEGIN { printf "%.2f", w / d }')
    awk -v w="$words" -v d="$duration" 'BEGIN { exit !(w / d < 0.3) }' \
        && note "transcribe.sh: the transcript is $rate words per second of audio; check the recording carries speech"
fi

# Engines fail as success, and density cannot see it: a transcript cut short, a stretch dropped
# from the middle, a phrase looping while its times advance all read as ordinary speech. Reported,
# never enforced, for the density check's reason; by times and counts, never the text, since
# stderr reaches the session. Engine output only: a caption track's gaps are the recording's
# music and silence, not a failure. A gap needs timings, a loop only the text.
# Limit: a gap is 120s with no segment, missing a short drop in a short recording; a loop is
# four identical segments running, missing one that alternates phrases or repeats inside a
# segment. Tune here if either shows up in practice.
if [ "$transcription_source" != captions ]; then
    awk -F '\t' -v d="$duration" -v ts="$(cap timestamps)" '
        function hms(s) { s = int(s + 0.5); return sprintf("%02d:%02d:%02d", int(s / 3600), int((s % 3600) / 60), s % 60) }
        function key(t) { t = tolower(t); gsub(/[.,!?;:"()-]/, "", t); gsub(/[ ]+/, " ", t); sub(/^ /, "", t); sub(/ $/, "", t); return t }
        function loop() {
            if (n < 4) return
            if (ts == "yes") printf "transcribe.sh: the same text repeats %d times in a row from %s to %s; the engine may have looped there\n", n, hms(rs), hms(re)
            else printf "transcribe.sh: the same text repeats %d times in a row; the engine may have looped there\n", n
        }
        { e = ($2 != "" ? $2 : $1) }
        ts == "yes" {
            if ($1 - last > 120) printf "transcribe.sh: nothing was transcribed from %s to %s; the engine may have dropped that stretch\n", hms(last), hms($1)
            if (e > last) last = e
        }
        {
            k = key($4)
            if (k != "" && k == prev) { n++; re = e }
            else { loop(); prev = k; n = 1; rs = $1; re = e }
        }
        END {
            loop()
            if (ts == "yes" && d - last > 120) printf "transcribe.sh: the transcript ends at %s and the recording at %s; the engine may have stopped early\n", hms(last), hms(d)
        }' "$segs" >&2 || true
fi

slug=$(slugify "$title")
[ -n "$slug" ] || slug=$(date -u +%Y%m%dT%H%M%SZ)

# Bound once, bump included, and named only as $dest from here. Re-deriving this name later is
# how a body once landed on an unrelated transcript and the cleanup then deleted it.
mkdir -p "$wiki/import"
dest="$wiki/import/$today-$slug.md"
n=2
while [ -e "$dest" ]; do
    dest="$wiki/import/$today-$slug-$n.md"
    n=$((n + 1))
done

# Quoted for the same reason as the pitch. A path is not third-party text the way a title is,
# but it can legally carry a newline or a colon, and a URL comes back from the metadata, so
# neither is provably constrained. captured, source_type and duration are: a fetched date, one
# of two literals, and the formatter's own output.
if [ -n "$source_url" ]; then origin="original_url: $(yaml_scalar "$source_url")"
else origin="original_path: $(yaml_scalar "$source_path")"
fi

# A third-party title can run to any length, and the pitch is the one-line characterisation
# the flow passes on, so a long title is cut to 100 bytes. Bytes, since `cut -c` counts bytes
# in some implementations and characters in others (F17.1, F17.1.1); then a character the cut split
# is dropped, so no half of one reaches the frontmatter.
pitch="Transcript of \"$title\" ($(hhmmss "$duration"))."
if [ ${#pitch} -gt 140 ]; then
    c=$(printf '[\200-\277]'); l2=$(printf '[\300-\337]'); l3=$(printf '[\340-\357]'); l4=$(printf '[\360-\367]')
    short=$(printf '%s' "$title" | LC_ALL=C cut -b1-100 |
        LC_ALL=C sed -e "s/$l2\$//" -e "s/$l3$c\{0,1\}\$//" -e "s/$l4$c\{0,2\}\$//")
    pitch="Transcript of \"$short\" ($(hhmmss "$duration"))."
fi

# Written beside $dest and renamed onto it, so a run stopped mid-write leaves no part-transcript
# under a transcript's name; the exit trap removes the part, and one only a hard kill leaves is
# named as such.
part="$dest.part"
{
    printf -- '---\n'
    printf 'captured: %s\n' "$today"
    printf 'source_type: %s\n' "$source_type"
    printf 'pitch: %s\n' "$(yaml_scalar "$pitch")"
    printf '%s\n' "$origin"
    printf 'duration: %s\n' "$(hhmmss "$duration")"
    printf 'transcription_source: %s\n' "$(yaml_scalar "$transcription_source")"
    printf -- '---\n\n'
    cat "$work/body.md"
} > "$part"
mv "$part" "$dest"

printf '%s\n' "${dest#"$wiki"/}"
printf 'transcription_source: %s\n' "$transcription_source"
printf 'pitch: %s\n' "$pitch"
