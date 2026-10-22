#!/bin/sh
# Self-check for transcribe.sh. The cases the logic turns on: which caption track is chosen and
# on what evidence, that a listed track failing to arrive is never read as "no captions", that a
# third party's title cannot escape the destination directory or the frontmatter, that a
# destination is bound once so a collision cannot land a body on an unrelated transcript, and
# that an empty render is refused rather than written.
#
# yt-dlp is stubbed for anything that would touch the network, but every --load-info-json call
# is handed to the real yt-dlp, which works entirely offline -- so the output templates under
# test are the real ones rather than a guess about them. ffmpeg and ffprobe are real throughout:
# the probes are local and take milliseconds. The engine adapter is stubbed, having its own test:
# here it is whatever the contract lets an adapter be, so the cases are the flow's handling of
# each thing an adapter may do -- and of the things it may not.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

pass=0; fail=0
ok() { pass=$((pass + 1)); }
no() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1" >&2; }
is() { if [ "$2" = "$3" ]; then ok; else no "$1: expected [$3] got [$2]"; fi }

command -v yt-dlp >/dev/null 2>&1 || { echo "skipped: yt-dlp is not installed"; exit 0; }
command -v ffmpeg >/dev/null 2>&1 || { echo "skipped: ffmpeg is not installed"; exit 0; }

# A scratch program, so the stub adapter can sit in its shipped directory; a scratch wiki apart
# from it, as a real one is; and a scratch user layer, so a personal adapter of the machine's own
# is never found.
prog="$work/prog"
wiki="$work/wiki"
xdg="$work/xdg"
mkdir -p "$prog/.yg/bin" "$prog/.yg/engines/transcribe" "$wiki/.yg/resolved" "$wiki/import" \
    "$xdg" "$work/bin" "$work/fx"
cp "$here/transcribe.sh" "$here/find-engine.sh" "$here/segments-to-markdown.sh" \
    "$here/segments-to-markdown.awk" "$here/srt-to-segments.awk" "$prog/.yg/bin/"
conf() { printf 'transcribe.engine: whisper\n' > "$wiki/.yg/resolved/config.conf"; }
conf
sut="$prog/.yg/bin/transcribe.sh"
real_ytdlp=$(command -v yt-dlp)

# --- stubs -----------------------------------------------------------------------------------

# A --print call is a pure offline read of a saved info-JSON, so it goes to the real yt-dlp and
# the output templates under test are the real ones. Everything else -- including a caption
# fetch, which also carries --load-info-json but does reach the network for the track's URL --
# is answered from fixtures.
cat > "$work/bin/yt-dlp" <<STUB
#!/bin/sh
for a in "\$@"; do [ "\$a" = "--print" ] && exec $real_ytdlp "\$@"; done
out=""; prev=""; wants_cap=no; wants_media=no
for a in "\$@"; do
    [ "\$prev" = "-o" ] && out=\$a
    case \$a in --write-subs|--write-auto-subs) wants_cap=yes ;; -f) wants_media=yes ;; esac
    prev=\$a
done
[ "\${STUB_FETCHABLE:-yes}" = yes ] || { echo "ERROR: not a valid URL" >&2; exit 1; }
if [ "\$wants_cap" = yes ]; then
    [ "\${STUB_CAP:-yes}" = yes ] && cp "\$STUB_CAP_FILE" "\$out.en.srt"
    exit 0
fi
if [ "\$wants_media" = yes ]; then
    [ -n "\${STUB_DLMARK:-}" ] && : > "\$STUB_DLMARK"
    cp "\$STUB_MEDIA" "\$out.wav" 2>/dev/null || cp "\$STUB_MEDIA" "\${out%.*}.wav"
    exit 0
fi
cp "\$STUB_INFO" "\$out.info.json"
exit 0
STUB
chmod +x "$work/bin/yt-dlp"

# The stub adapter, in the shipped directory under the configured name. STUB_ENGINE picks what it
# does: ok; consent, which asks for the download token and behaves as ok once given it; v2, a
# contract this flow does not keep; unsafe, which declares neither timings nor silence-safety; a
# bare number, which check exits with; empty, a recording with no speech; nosegs, success with no
# segments.tsv; and runN, which run exits with. STUB_ROOTS_OUT records the roots it was given.
cat > "$prog/.yg/engines/transcribe/whisper.sh" <<'STUB'
#!/bin/sh
cmd=$1; prog=$2; wiki=$3; shift 3
[ -n "${STUB_ROOTS_OUT:-}" ] && printf '%s\n%s\n' "$prog" "$wiki" > "$STUB_ROOTS_OUT"
consent=""
[ "${1-}" = --consent ] && { consent=$2; shift 2; }
mode=${STUB_ENGINE:-ok}
[ "$mode" = consent ] && [ "$consent" = download ] && mode=ok
case $cmd in
check)
    case $mode in
        consent) echo "consent: download fetch the test model (about 1 MB)"; exit 20 ;;
        v2)      printf 'contract: 2\n'; exit 0 ;;
        unsafe)  printf 'contract: 1\ntimestamps: no\nspeakers: no\nsilence_safe: no\n'; exit 0 ;;
        [0-9]*)  exit "$mode" ;;
    esac
    printf 'contract: 1\ntimestamps: yes\nspeakers: no\nsilence_safe: yes\n'
    exit 0 ;;
run)
    out=$2
    [ -n "${STUB_HINTS_OUT:-}" ] && cp "$out/hints.conf" "$STUB_HINTS_OUT" 2>/dev/null
    case $mode in
        empty)  : > "$out/segments.tsv" ;;
        nosegs) : ;;
        runconsent) echo "consent: send-audio upload the recording to example.com"; exit 20 ;;
        sleep)  sleep 3; cp "$STUB_SEGS" "$out/segments.tsv" ;;
        run*)   exit "${mode#run}" ;;
        *)      cp "$STUB_SEGS" "$out/segments.tsv" ;;
    esac
    # A key the flow does not read comes first, so every run shows it ignored (contract.md).
    printf 'detected_language: en\nmodel_requested: %s\n' "${STUB_ASKED:-testtag}" > "$out/meta.conf"
    [ -n "${STUB_RAN:-}" ] && printf 'model_reported: %s\n' "$STUB_RAN" >> "$out/meta.conf"
    exit 0 ;;
esac
exit 10
STUB

srt() { printf '1\n00:00:00,000 --> 00:00:04,000\n%s\n\n' "$1" > "$2"; }
seg() { printf '0.000\t4.000\t%s\t%s\n' "$1" "$2" > "$3"; }
seg "" "One two three four five six seven eight nine ten." "$work/fx/plain.tsv"
srt "manual track text here." "$work/fx/manual.srt"

# A thin transcript: few words against a long duration, which is what the density floor reports.
seg "" "Hello." "$work/fx/thin.tsv"

info() {
    cat > "$1" <<J
{"id":"vid1","title":$2,"ext":"mp4","duration":${3:-600},"language":"${FXLANG-en}",
 "webpage_url":"https://example.com/watch?v=vid1","extractor":"${7:-generic}",
 "vcodec":${6:-null},
 "subtitles":$4,"automatic_captions":$5,
 "formats":[{"format_id":"1","url":"https://example.com/a.m4a","ext":"m4a","acodec":"aac","vcodec":${6:-null}}]}
J
}

NONE='{}'
run() { ( PATH="$work/bin:$PATH" \
    STUB_INFO="${I:-$work/fx/info.json}" STUB_SEGS="${S:-$work/fx/plain.tsv}" \
    STUB_HINTS_OUT="${HINTS:-}" STUB_RAN="${RAN:-}" STUB_ASKED="${ASKED:-}" \
    STUB_CAP_FILE="${C:-$work/fx/manual.srt}" STUB_MEDIA="${M:-$work/fx/audio.wav}" \
    STUB_CAP="${CAP:-yes}" STUB_ENGINE="${ENGINE:-ok}" STUB_FETCHABLE="${FETCH:-yes}" \
    STUB_DLMARK="${DLMARK:-}" STUB_ROOTS_OUT="${ROOTS:-}" XDG_CONFIG_HOME="$xdg" \
    sh "$sut" "$wiki" "$@" ) }
clean() { rm -f "$wiki"/import/*.md; }
written() { ls "$wiki"/import/*.md 2>/dev/null | head -1; }
fm() { sed -n "/^$1: /s/^$1: //p" "$(written)"; }

ffmpeg -loglevel error -y -f lavfi -i "sine=f=300:r=16000:d=3" -ac 1 "$work/fx/audio.wav" 2>/dev/null

# --- which track is chosen, and on what evidence ------------------------------------------------

# A manual track is human-authored; an automatic one is ASR. Provenance decides, never the
# language code -- en can be an ASR key while en-GB is human-authored.
info "$work/fx/info.json" '"Talk One"' 600 \
    '{"en":[{"ext":"srt"}]}' '{"en":[{"ext":"srt"}],"en-orig":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
is "a manual track wins" "$(fm transcription_source)" "captions"
if grep -q 'manual caption track (en)' "$work/err"; then ok; else no "and says it was the manual one"; fi

# Among automatic tracks the original-language key is the one that was not machine-translated.
info "$work/fx/info.json" '"Talk Two"' 600 "$NONE" '{"en":[{"ext":"srt"}],"en-orig":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'auto caption track (en-orig)' "$work/err"; then ok
else no "en-orig beats plain en among automatic tracks"; fi

info "$work/fx/info.json" '"Talk Three"' 600 "$NONE" '{"en":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'auto caption track (en)' "$work/err"; then ok; else no "plain en is taken when there is no orig"; fi

# A track in another language is not a fallback: it would be a translation.
info "$work/fx/info.json" '"Talk Four"' 600 '{"fr":[{"ext":"srt"}]}' '{"de":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
is "no track in the original language means transcribe" "$(fm transcription_source)" "whisper:testtag"
if grep -q 'No usable caption track' "$work/err"; then ok; else no "and the slow path is announced first"; fi

info "$work/fx/info.json" '"Talk Five"' 600 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
is "an empty inventory falls through" "$(fm transcription_source)" "whisper:testtag"

# Metadata can carry a region-tagged language while a site keys its tracks by the bare one:
# language en-US, automatic tracks en and en-orig. The bare language is tried after the exact one,
# within each provenance, so a region tag cannot hide a usable track.
FXLANG=en-US info "$work/fx/info.json" '"Talk Six"' 600 "$NONE" '{"en":[{"ext":"srt"}],"en-orig":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'auto caption track (en-orig)' "$work/err"; then ok
else no "a region-tagged language finds the bare en-orig track"; fi

FXLANG=en-US info "$work/fx/info.json" '"Talk Seven"' 600 '{"en":[{"ext":"srt"}]}' '{"en-orig":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'manual caption track (en)' "$work/err"; then ok
else no "a region-tagged language finds a bare manual track before any automatic one"; fi

# An unknown language is read from the -orig key, so a translated en is never the default.
FXLANG= info "$work/fx/info.json" '"Talk Eight"' 600 "$NONE" '{"en":[{"ext":"srt"}],"fr-orig":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'auto caption track (fr-orig)' "$work/err"; then ok
else no "an unknown language takes the original-language track"; fi

FXLANG= info "$work/fx/info.json" '"Talk Nine"' 600 "$NONE" '{"en":[{"ext":"srt"}]}'
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
is "with no -orig key, an unknown language means transcribe" "$(fm transcription_source)" "whisper:testtag"
if grep -q 'language is unknown' "$work/err"; then ok; else no "and says why"; fi

# The test that closes a whole class of past incident: the inventory is the evidence, so a
# listed track that does not arrive is a failed fetch, never "this video has no captions".
info "$work/fx/info.json" '"Talk Six"' 600 '{"en":[{"ext":"srt"}]}' "$NONE"
clean; CAP=no run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'did not come back' "$work/err"; then ok
else no "a listed track that fails to arrive says so"; fi
if grep -q 'No usable caption track' "$work/err"; then no "and is not reported as having none"; else ok; fi
is "and it still produces a transcript" "$(fm transcription_source)" "whisper:testtag"

# A track that arrives under .srt in another format converts to nothing: transcribed, never exit 13.
printf '<tt><body><p begin="0s" end="2s">Hello</p></body></tt>\n' > "$work/fx/ttml.srt"
clean; rc=0; C="$work/fx/ttml.srt" run "https://example.com/v" >/dev/null 2>"$work/err" || rc=$?
is "a listed track that is not SRT is transcribed" "$(fm transcription_source)" "whisper:testtag"
is "and does not exit as having no speech" "$rc" 0

# --- what the caption path records about the source ----------------------------------------------

# The caption fast path downloads no media, so ffprobe never runs and cannot say whether there is
# a video stream. The info-JSON already knows, and vcodec names it. Without this every captioned
# video is recorded as an audio-transcript.
info "$work/fx/info.json" '"A Talk"' 600 '{"en":[{"ext":"srt"}]}' "$NONE" '"av01.0.08M.08"' youtube
clean; run "https://example.com/v" >/dev/null 2>&1
is "a captioned video is a video-transcript" "$(fm source_type)" "video-transcript"

info "$work/fx/info.json" '"A Podcast"' 600 '{"en":[{"ext":"srt"}]}' "$NONE" '"none"' youtube
clean; run "https://example.com/v" >/dev/null 2>&1
is "a captioned audio-only source stays audio" "$(fm source_type)" "audio-transcript"

# original_url is provenance and a citation has to survive. The generic extractor reports the
# post-redirect URL as webpage_url, which on a CDN is a rotating node hostname. A real
# extractor's webpage_url is canonical and is kept, which is what turns a tracking-laden paste
# into a stable reference.
info "$work/fx/info.json" '"Direct"' 600 "$NONE" "$NONE" null generic
clean; run "https://example.com/download/thing.ogg" >/dev/null 2>&1
is "the generic extractor keeps the requested URL" "$(fm original_url)" "https://example.com/download/thing.ogg"

info "$work/fx/info.json" '"Canonical"' 600 "$NONE" "$NONE" null youtube
clean; run "https://example.com/v?si=tracking" >/dev/null 2>&1
is "a real extractor's canonical URL is kept" "$(fm original_url)" "https://example.com/watch?v=vid1"

# --- the engine is asked before the payload is fetched --------------------------------------

# A consent refusal is the same wherever it is met, but met after the download it costs the
# transfer twice: once here, and once on the re-run that carries the consent. The first run on
# any machine meets it, the VAD model never being present by default.
info "$work/fx/info.json" '"Uncaptioned"' 600 "$NONE" "$NONE"
clean; rm -f "$work/dl.mark"; rc=0
DLMARK="$work/dl.mark" ENGINE=consent run "https://example.com/v" >/dev/null 2>"$work/err" || rc=$?
is "an engine needing consent is exit 20" "$rc" "20"
if [ -e "$work/dl.mark" ]; then no "and the media is not fetched first"; else ok; fi
if grep -q '^consent: download ' "$work/err"; then ok; else no "and its consent line reaches stderr"; fi

# A local input has no transfer to spend, but is asked before the engine runs all the same.
clean; rc=0
ENGINE=consent run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "consent is asked on a local input too" "$rc" "20"

# The token from the consent line, given back, reaches the adapter.
clean; rc=0
ENGINE=consent run --consent download "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "a re-run carrying the consent token succeeds" "$rc" "0"

# --- the adapter is found by name ----------------------------------------------------------------

# The adapter is handed the program and wiki roots, since a personal one can find neither itself.
clean; rm -f "$work/roots.out"; ROOTS="$work/roots.out" run "$work/fx/audio.wav" >/dev/null 2>&1
is "the adapter is given the program and wiki roots" "$(cat "$work/roots.out" 2>/dev/null)" \
    "$(CDPATH= cd -P -- "$prog" && pwd)
$(CDPATH= cd -P -- "$wiki" && pwd)"

# Personal first, from the user layer, so an adapter of one's own needs no file the program ships.
mkdir -p "$xdg/yggdrasil/engines/transcribe"
sed 's/STUB_ASKED:-testtag/STUB_ASKED:-personal/' "$prog/.yg/engines/transcribe/whisper.sh" \
    > "$xdg/yggdrasil/engines/transcribe/whisper.sh"
clean; run "$work/fx/audio.wav" >/dev/null 2>"$work/err"
is "a personal adapter is found before a shipped one" "$(fm transcription_source)" "whisper:personal"
if grep -q 'replaces the shipped one' "$work/err"; then ok; else no "and the shadowing is said"; fi
rm -rf "$xdg/yggdrasil"

printf 'transcribe.engine: absent\n' > "$wiki/.yg/resolved/config.conf"
clean; rc=0; run "$work/fx/audio.wav" >/dev/null 2>"$work/err" || rc=$?
is "an engine with no adapter is a missing dependency" "$rc" "21"
if grep -q 'no transcribe adapter named absent' "$work/err"; then ok; else no "and says which"; fi

# Looked up only when an engine is needed: the caption path finishes without one.
info "$work/fx/info.json" '"Captioned"' 600 '{"en":[{"ext":"srt"}]}' "$NONE"
clean; rc=0; run "https://example.com/v" >/dev/null 2>&1 || rc=$?
is "a missing adapter does not stop the caption path" "$rc" "0"

printf 'transcribe.engine: ../whisper\n' > "$wiki/.yg/resolved/config.conf"
clean; rc=0; run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "an engine name that is not a plain name is refused" "$rc" "21"

# There is no fallback engine: a resolved config without transcribe.engine stops a run that needs
# one, naming the key, and does not stop one the caption path finishes.
: > "$wiki/.yg/resolved/config.conf"
clean; rc=0; run "$work/fx/audio.wav" >/dev/null 2>"$work/err" || rc=$?
is "a missing transcribe.engine is a missing dependency" "$rc" "21"
if grep -q 'transcribe.engine is missing' "$work/err"; then ok; else no "and names the key"; fi
is "and nothing is written" "$(written)" ""
clean; rc=0; run "https://example.com/v" >/dev/null 2>&1 || rc=$?
is "a missing transcribe.engine does not stop the caption path" "$rc" "0"
rm -f "$wiki/.yg/resolved/config.conf"
clean; rc=0; run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "no resolved config at all is the same missing dependency" "$rc" "21"
conf

# --- the contract ------------------------------------------------------------------------------

clean; rc=0; ENGINE=v2 run "$work/fx/audio.wav" >/dev/null 2>"$work/err" || rc=$?
is "an adapter keeping another contract version is refused" "$rc" "42"
if grep -q 'keeps contract 2' "$work/err"; then ok; else no "and names the version"; fi

for st in 21 31 40; do
    clean; rc=0; ENGINE=$st run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
    is "check's declared status $st passes through" "$rc" "$st"
done
for st in 14 40; do
    clean; rc=0; ENGINE=run$st run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
    is "run's declared status $st passes through" "$rc" "$st"
done

# Anything else is the adapter breaking its contract -- never passed through, where an engine's
# own number could land on one of ours: whisper-cli's 3 would have read as a missing dependency.
clean; rc=0; ENGINE=3 run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "an undeclared status from check is a contract breach" "$rc" "41"
clean; rc=0; ENGINE=run134 run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "an undeclared status from run is a contract breach" "$rc" "41"
clean; rc=0; ENGINE=nosegs run "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "success with no segments.tsv is a contract breach" "$rc" "41"
is "and nothing is written" "$(written)" ""

# 10 is usage, which only a wrong call from the flow causes: the flow's own defect, not the adapter's.
clean; rc=0; ENGINE=10 run "$work/fx/audio.wav" >/dev/null 2>"$work/err" || rc=$?
is "an adapter's usage status is reported as the flow's defect" "$rc" "50"
if grep -q 'wrongly' "$work/err"; then ok; else no "and says the flow called it wrongly"; fi

# run may ask for consent too, and its consent line goes to stderr with every other message:
# stdout is the three-line report.
clean; rc=0; out=$(ENGINE=runconsent run "$work/fx/audio.wav" 2>"$work/err") || rc=$?
is "run asking for consent is exit 20" "$rc" "20"
is "and its consent line stays off stdout" "$out" ""
if grep -q '^consent: send-audio ' "$work/err"; then ok; else no "and reaches stderr"; fi

clean; ENGINE=unsafe run "$work/fx/audio.wav" >/dev/null 2>"$work/err"
if grep -q 'does not promise that a recording with no speech' "$work/err"; then ok
else no "an adapter that is not silence-safe is named"; fi
if grep -q 'no seek handles' "$work/err"; then ok; else no "and one with no timings"; fi

# Provenance is what the adapter reports: the model that ran where the service says, with the
# one asked for beside it when they differ.
clean; RAN=bigger run "$work/fx/audio.wav" >/dev/null 2>&1
is "a reported model differing from the request records both" \
    "$(fm transcription_source)" "whisper:bigger (asked for testtag)"
clean; RAN=testtag run "$work/fx/audio.wav" >/dev/null 2>&1
is "a reported model matching the request records one" "$(fm transcription_source)" "whisper:testtag"

# The metadata's language, where there was one, reaches the adapter as a hint.
info "$work/fx/info.json" '"Hinted"' 600 "$NONE" "$NONE"
clean; rm -f "$work/hints.out"; HINTS="$work/hints.out" run "https://example.com/v" >/dev/null 2>&1
is "the source's language is passed as a hint" "$(cat "$work/hints.out" 2>/dev/null)" "language: en"

# Speakers render as labels, and a label is not counted as a word of the transcript.
printf '0.0\t2.0\tA\tHello there friend.\n2.0\t4.0\tB\tHi.\n' > "$work/fx/spk.tsv"
clean; S="$work/fx/spk.tsv" run "$work/fx/audio.wav" >/dev/null 2>&1
if grep -q '^\[00:00:02\] \*\*B:\*\* Hi\.$' "$(written)"; then ok; else no "a speaker change is labelled in the transcript"; fi

# --- the exit trap ---------------------------------------------------------------------------------

# An unguarded command aborting under set -e carries its own status out, which could be any number.
# import/ as a file makes the mkdir that precedes the write fail with mkdir's own status.
clean; rmdir "$wiki/import"; : > "$wiki/import"; rc=0
run "$work/fx/audio.wav" >/dev/null 2>"$work/err" || rc=$?
is "an undeclared abort is reported as 50" "$rc" "50"
if grep -q 'which this script does not declare' "$work/err"; then ok; else no "and the raw status is named"; fi
rm -f "$wiki/import"; mkdir "$wiki/import"

# Interrupted part-way is its own status: nothing is wrong, and a re-run in the background answers
# it. Called without run()'s subshell, so the signal reaches the script itself.
clean; rc=0
PATH="$work/bin:$PATH" XDG_CONFIG_HOME="$xdg" STUB_ENGINE=sleep STUB_SEGS="$work/fx/plain.tsv" \
    sh "$sut" "$wiki" "$work/fx/audio.wav" >/dev/null 2>&1 &
pid=$!
sleep 1
kill -TERM "$pid"
wait "$pid" || rc=$?
is "a run interrupted by TERM is 51" "$rc" "51"
is "and nothing is written" "$(written)" ""

# A signal landing during the write itself, after part of the transcript is out: a stand-in cat
# writes a line of the body and signals the script, so the write is cut short where it lands.
mkdir -p "$work/catbin"
printf '#!/bin/sh\ncase $1 in */body.md) echo partial; kill -TERM "$PPID"; sleep 1 ;; *) exec %s "$@" ;; esac\n' \
    "$(command -v cat)" > "$work/catbin/cat"
chmod +x "$work/catbin/cat"
clean; rc=0
PATH="$work/catbin:$work/bin:$PATH" XDG_CONFIG_HOME="$xdg" STUB_SEGS="$work/fx/plain.tsv" \
    sh "$sut" "$wiki" "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "a run interrupted during its write is 51" "$rc" "51"
is "and leaves nothing in import/, part-written or whole" "$(ls -A "$wiki/import")" ""

# --- an input that is not a URL and not a file ---------------------------------------------------

clean; rc=0; FETCH=no run "not a url at all" >/dev/null 2>&1 || rc=$?
is "an unfetchable input is refused" "$rc" "11"

# There is no URL pattern matching: anything that is not a local file is handed to yt-dlp.
info "$work/fx/info.json" '"Schemeless"' 600 "$NONE" "$NONE"
clean; run "example.com/live/abc" >/dev/null 2>&1
if [ -n "$(written)" ]; then ok; else no "a schemeless input still reaches yt-dlp"; fi

# --- a title is a third party's text --------------------------------------------------------------

info "$work/fx/info.json" '"../../outside: A \"Talk\"\nsecond line"' 600 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>&1
f=$(written)
case $(basename "$f") in
    *..*|*/*) no "a traversing title cannot escape the directory" ;;
    *) ok ;;
esac
is "the written file is directly in import/" "$(dirname "$f")" "$(CDPATH= cd -P -- "$wiki" && pwd)/import"
if [ "$(awk 'NR>1 && /^---$/ { print NR; exit }' "$f")" -ge 6 ]; then ok
else no "frontmatter still closes after a title carrying a colon, a quote and a newline"; fi
if sed -n '2,/^---$/p' "$f" | grep -q '^pitch: '; then ok; else no "the pitch key survives"; fi
# Every frontmatter line is still key: value -- a newline in the title would otherwise start one.
bad=$(awk 'NR>1 && /^---$/ { exit } NR>1 && !/^[a-z_]+: / { print }' "$f" | wc -l | tr -d ' ')
is "no frontmatter line was broken open" "$bad" "0"

# Shape alone is too weak: pitch: Transcript of "a: b" is a well-shaped line and invalid YAML,
# because an unquoted scalar carrying ": " ends the value and starts something else -- which
# voids the whole property block rather than one field. So the value has to be quoted, and any
# quote inside it doubled, which is YAML's own escape.
info "$work/fx/info.json" '"It'"'"'s a \"Talk\": part 2"' 600 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>&1
pl=$(sed -n '2,/^---$/p' "$(written)" | sed -n 's/^pitch: //p')
case $pl in
    "'"*"'") ok ;;
    *) no "a pitch carrying a colon is quoted (got $pl)" ;;
esac
case $pl in
    *"''"*) ok ;;
    *) no "a single quote inside the pitch is doubled (got $pl)" ;;
esac

# A filename may legally carry a newline, and that path takes its title from basename rather
# than from yt-dlp, so nothing upstream has already flattened it. An unescaped newline in a
# frontmatter value is a line break in the middle of the block.
nl=$(printf 'two\nlines')
cp "$work/fx/audio.wav" "$work/fx/$nl.wav" 2>/dev/null || true
if [ -f "$work/fx/$nl.wav" ]; then
    clean; run "$work/fx/$nl.wav" >/dev/null 2>&1
    g=$(written)
    if [ -n "$g" ]; then
        head=$(awk 'NR>1 && /^---$/ { print NR; exit }' "$g")
        keys=$(sed -n "2,$((head - 1))p" "$g" | grep -c '^[a-z_]*: ' || true)
        is "a newline in a filename does not break the block open" \
            "$keys" "$((head - 2))"
    else
        no "a file whose name carries a newline is still transcribed"
    fi
else
    ok
fi

info "$work/fx/info.json" "\"$(printf 'A%.0s' 1 2 3 4 5 6 7 8 9 0)-very-long-title-that-runs-on-and-on-and-should-be-cut-at-a-word-boundary-well-before-here\"" 600 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>&1
stem=$(basename "$(written)" .md)
if [ "${#stem}" -le 72 ]; then ok; else no "a long title is capped (got ${#stem})"; fi

# The pitch's cut falls inside a two-byte character here: it has to drop the half, not keep it.
a99=$(printf 'a%.0s' $(seq 99))
info "$work/fx/info.json" "\"${a99}été and on and on\"" 600 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>&1
pl=$(sed -n '2,/^---$/p' "$(written)" | sed -n 's/^pitch: //p')
case $pl in
    *"${a99}\" ("*) ok ;;
    *) no "a cut through a character drops the half (got $pl)" ;;
esac

# --- the destination is bound once ------------------------------------------------------------------

# Re-deriving this name later is how a body once landed on an unrelated transcript, which the
# error path then deleted.
info "$work/fx/info.json" '"Same Name"' 600 "$NONE" "$NONE"
clean
run "https://example.com/v" >/dev/null 2>&1
first=$(written)
sz=$(wc -c < "$first")
run "https://example.com/v" >/dev/null 2>&1
n=$(ls "$wiki"/import/*.md | wc -l | tr -d ' ')
is "a second run does not overwrite the first" "$n" "2"
is "and the first is untouched" "$(wc -c < "$first")" "$sz"
if ls "$wiki"/import/*-2.md >/dev/null 2>&1; then ok; else no "the collision is bumped"; fi

# --- the render gate ---------------------------------------------------------------------------------

# No segments is a recording with no speech: the honest outcome, and its own status.
clean; rc=0; ENGINE=empty run "https://example.com/v" >/dev/null 2>&1 || rc=$?
is "an empty transcript is no speech" "$rc" "13"
is "and nothing is written" "$(written)" ""

# --- local files -------------------------------------------------------------------------------------

clean; run "$work/fx/audio.wav" >/dev/null 2>&1
is "a local file records its path" "$(fm original_path)" "$work/fx/audio.wav"
is "and carries no url" "$(fm original_url)" ""

# A relative local input is the caller's own argument: it resolves against the caller's working
# directory, never the wiki's.
cp "$work/fx/audio.wav" "$wiki/import/decoy.wav"
mkdir -p "$work/elsewhere"; cp "$work/fx/audio.wav" "$work/elsewhere/decoy.wav"
clean; rc=0; ( cd "$work/elsewhere" && run decoy.wav ) >/dev/null 2>&1 || rc=$?
is "a relative input resolves against the caller's directory" "$(fm original_path)" "$work/elsewhere/decoy.wav"
rm -f "$wiki/import/decoy.wav"
is "and is audio" "$(fm source_type)" "audio-transcript"
is "captured is today, fetched not assumed" "$(fm captured)" "$(date -u +%Y-%m-%d)"

# A bare image has a video stream and no audio: a test for any stream passes it, and it dies three
# steps later inside ffmpeg, on a remote input only after the download is spent.
ffmpeg -loglevel error -y -f lavfi -i "color=c=blue:s=64x64:d=2" "$work/fx/silent.mp4" 2>/dev/null
clean; rc=0; run "$work/fx/silent.mp4" >/dev/null 2>&1 || rc=$?
is "an input with no audio is refused" "$rc" "12"

ffmpeg -loglevel error -y -f lavfi -i "sine=f=300:r=16000:d=3" -f lavfi -i "color=c=red:s=64x64:d=3" \
    -shortest -ac 1 "$work/fx/av.mp4" 2>/dev/null
clean; run "$work/fx/av.mp4" >/dev/null 2>&1
is "a file with a real video stream is video" "$(fm source_type)" "video-transcript"

clean; run "$work/fx/audio.wav" >/dev/null 2>&1
is "a plain audio file stays audio" "$(fm source_type)" "audio-transcript"

# Cover art is an attached picture, not video, and the capital-V specifier is the whole
# difference: lowercase v counts the attached picture and calls a podcast episode a video. The
# fixture therefore has to actually carry cover art -- one without it passes under either
# specifier and tests nothing.
ffmpeg -loglevel error -y -f lavfi -i "color=c=green:s=32x32:d=1" -frames:v 1 "$work/fx/cover.png" 2>/dev/null
ffmpeg -loglevel error -y -i "$work/fx/audio.wav" -i "$work/fx/cover.png" \
    -map 0:a -map 1:v -c:v copy -disposition:v attached_pic "$work/fx/cover.mp3" 2>/dev/null
if [ -s "$work/fx/cover.mp3" ] \
    && [ -n "$(ffprobe -v error -select_streams v -show_entries stream=index -of csv=p=0 -- "$work/fx/cover.mp3" 2>/dev/null)" ]
then
    clean; run "$work/fx/cover.mp3" >/dev/null 2>&1
    is "an audio file with cover art stays audio" "$(fm source_type)" "audio-transcript"
else
    no "the cover-art fixture actually carries an attached picture"
fi

# A whole container family reports N/A for the stream's duration, so it is read from the format.
ffmpeg -loglevel error -y -f lavfi -i "sine=f=300:r=16000:d=3" -ac 1 -c:a libopus "$work/fx/o.webm" 2>/dev/null
if [ -s "$work/fx/o.webm" ]; then
    clean; run "$work/fx/o.webm" >/dev/null 2>&1
    is "duration comes from the format, not the stream" "$(fm duration)" "00:00:03"
else
    ok
fi

# --- the density floor reports and does not abort -------------------------------------------------------

info "$work/fx/info.json" '"Sparse"' 3600 "$NONE" "$NONE"
clean; rc=0; S="$work/fx/thin.tsv" run "https://example.com/v" >/dev/null 2>"$work/err" || rc=$?
is "a thin transcript still exits 0" "$rc" "0"
if [ -n "$(written)" ]; then ok; else no "and is still written"; fi
if grep -q 'words per second' "$work/err"; then ok; else no "and it is reported"; fi

info "$work/fx/info.json" '"Dense"' 20 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'words per second' "$work/err"; then no "an ordinary transcript is not flagged"; else ok; fi

# --- gaps and repetition report and do not abort -------------------------------------------------

# Engines fail as success: truncation, a dropped stretch, a phrase looping while the times
# advance. The flow reports each by its times and never quotes the text, since stderr reaches
# the session.
printf '0.000\t4.000\t\tOne two three.\n200.000\t204.000\t\tFour five six.\n' > "$work/fx/gap.tsv"
info "$work/fx/info.json" '"Gappy"' 206 "$NONE" "$NONE"
clean; rc=0; S="$work/fx/gap.tsv" run "https://example.com/v" >/dev/null 2>"$work/err" || rc=$?
is "a transcript with a gap still exits 0" "$rc" "0"
if [ -n "$(written)" ]; then ok; else no "and is still written"; fi
if grep -q 'nothing was transcribed from 00:00:04 to 00:03:20' "$work/err"; then ok; else no "and the gap is reported with its times"; fi
if grep -q 'transcript ends at' "$work/err"; then no "a covered end is not reported as truncation"; else ok; fi

info "$work/fx/info.json" '"Cut short"' 600 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'transcript ends at 00:00:04 and the recording at 00:10:00' "$work/err"; then ok; else no "an uncovered end is reported as truncation"; fi

info "$work/fx/info.json" '"Covered"' 20 "$NONE" "$NONE"
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'nothing was transcribed\|transcript ends at' "$work/err"; then no "an ordinary transcript has no gap reported"; else ok; fi

# The contract lets an adapter leave end times empty; a segment's start then stands for its end,
# or every segment would read as a gap from the start of the recording.
printf '0\t\t\tOne.\n100\t\t\tTwo.\n200\t\t\tThree.\n' > "$work/fx/noend.tsv"
info "$work/fx/info.json" '"No ends"' 210 "$NONE" "$NONE"
clean; S="$work/fx/noend.tsv" run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'nothing was transcribed\|transcript ends at' "$work/err"; then no "empty end times are not read as gaps"; else ok; fi

# Without timings there are no gaps to measure, so nothing is said about them.
info "$work/fx/info.json" '"Untimed"' 600 "$NONE" "$NONE"
clean; ENGINE=unsafe run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'nothing was transcribed\|transcript ends at' "$work/err"; then no "gaps are not measured without timings"; else ok; fi

# A caption track's gaps are the recording's -- music, silence -- not an engine failing.
info "$work/fx/info.json" '"Captioned"' 600 '{"en":[{"ext":"srt"}]}' "$NONE"
clean; run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'nothing was transcribed\|transcript ends at' "$work/err"; then no "a caption track is not checked for gaps"; else ok; fi

# A loop: the same text, punctuation and case aside, four times running while the times advance.
printf '0.000\t4.000\t\tIntro here.\n' > "$work/fx/loop.tsv"
for i in 1 2 3 4; do printf '%d.000\t%d.000\t\t%s\n' $((i * 4)) $((i * 4 + 4)) "$( [ $i -eq 2 ] && echo 'thank you for watching' || echo 'Thank you for watching.')"; done >> "$work/fx/loop.tsv"
info "$work/fx/info.json" '"Loop"' 20 "$NONE" "$NONE"
clean; rc=0; S="$work/fx/loop.tsv" run "https://example.com/v" >/dev/null 2>"$work/err" || rc=$?
is "a looping transcript still exits 0" "$rc" "0"
if grep -q 'repeats 4 times in a row from 00:00:04 to 00:00:20' "$work/err"; then ok; else no "and the loop is reported with its times"; fi
if grep -qi 'thank you' "$work/err"; then no "the report does not quote the looping text"; else ok; fi

head -4 "$work/fx/loop.tsv" > "$work/fx/three.tsv"
info "$work/fx/info.json" '"Three"' 16 "$NONE" "$NONE"
clean; S="$work/fx/three.tsv" run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'repeats' "$work/err"; then no "three in a row is not a loop"; else ok; fi

# Text in a script awk's punctuation class does not cover must not all fold to the same key.
printf '0\t4\t\t塩を入れる。\n4\t8\t\t砂糖を入れる。\n8\t12\t\t醤油を入れる。\n12\t16\t\t味噌を入れる。\n' > "$work/fx/ja.tsv"
info "$work/fx/info.json" '"Japanese"' 16 "$NONE" "$NONE"
clean; S="$work/fx/ja.tsv" run "https://example.com/v" >/dev/null 2>"$work/err"
if grep -q 'repeats' "$work/err"; then no "distinct non-Latin segments are not a loop"; else ok; fi

# --- what is reported ---------------------------------------------------------------------------------

info "$work/fx/info.json" '"Reported"' 125 "$NONE" "$NONE"
clean; out=$(run "https://example.com/v" 2>/dev/null)
is "the report names the written path" "$(printf '%s\n' "$out" | head -1)" "import/$(date -u +%Y-%m-%d)-reported.md"
if printf '%s\n' "$out" | grep -q '^transcription_source: '; then ok; else no "and the source"; fi
if printf '%s\n' "$out" | grep -q '^pitch: '; then ok; else no "and the pitch"; fi
is "duration is formatted" "$(fm duration)" "00:02:05"

# Nothing of the transcript body reaches the report: it is written, never read back.
if printf '%s\n' "$out" | grep -q 'One two three four'; then
    no "the report does not quote the transcript"
else ok; fi

# --- the frontmatter against a real parser ------------------------------------------------------

# The strongest form of the quoting assertions above, where a parser happens to be available.
# Checking the shape of a line cannot tell a quoted value from one that ends early, and a value
# that ends early voids the whole block rather than its own field.
if python3 -c 'import yaml' >/dev/null 2>&1; then
    for t in '"Plain Talk"' '"A Talk: Notes"' '"../../outside: A \"Talk\""' \
             '"It'"'"'s #1: part 2"' '"trailing space "' '"- leading dash"'; do
        info "$work/fx/info.json" "$t" 600 "$NONE" "$NONE"
        clean; run "https://example.com/v" >/dev/null 2>&1
        g=$(written)
        if [ -z "$g" ]; then no "a title like $t is still written"; continue; fi
        if python3 - "$g" <<'PY'
import sys, yaml
text = open(sys.argv[1], encoding="utf-8").read()
_, fm, _ = text.split("---", 2)
d = yaml.safe_load(fm)
keys = {"captured", "source_type", "pitch", "duration", "transcription_source"}
sys.exit(0 if isinstance(d, dict) and keys <= set(d) else 1)
PY
        then ok; else no "frontmatter parses as YAML with every key, for title $t"; fi
    done
else
    printf 'skipped: the YAML round-trip needs python3 with pyyaml\n'
fi

# --- keeping a transcript --------------------------------------------------------------------

# --keep moves a transcript from import/ under the wiki's .sources/recordings/, creating the
# directory, and a same-named source already there is never overwritten -- it may be cited.
keep() { sh "$sut" "$wiki" --keep "$@"; }
rec="$wiki/.sources/recordings"
printf 'first\n' > "$wiki/import/2026-01-01-talk.md"
out=$(keep import/2026-01-01-talk.md 2>/dev/null) && rc=0 || rc=$?
is "keep succeeds" "$rc" "0"
is "keep prints the path to cite, from the wiki root" "$out" ".sources/recordings/2026-01-01-talk.md"
is "keep moves the file" "$(cat "$rec/2026-01-01-talk.md" 2>/dev/null)" "first"
is "keep leaves nothing in import" "$(ls "$wiki/import" | grep -c talk || true)" "0"

printf 'second\n' > "$wiki/import/2026-01-01-talk.md"
out=$(keep import/2026-01-01-talk.md 2>/dev/null) && rc=0 || rc=$?
is "a colliding keep succeeds" "$rc" "0"
is "a colliding keep is bumped" "$out" ".sources/recordings/2026-01-01-talk-2.md"
is "a colliding keep never overwrites" "$(cat "$rec/2026-01-01-talk.md")" "first"
is "the bumped file carries the new body" "$(cat "$rec/2026-01-01-talk-2.md" 2>/dev/null)" "second"

# The path is the wiki's, whatever the caller's working directory.
printf 'third\n' > "$wiki/import/2026-01-02-talk.md"
out=$( cd "$work" && keep import/2026-01-02-talk.md 2>/dev/null) && rc=0 || rc=$?
is "keep reads import/ from the wiki, not the working directory" "$out" ".sources/recordings/2026-01-02-talk.md"

mkdir -p "$wiki/Cooking"
printf 'page\n' > "$wiki/Cooking/page.md"
keep Cooking/page.md >/dev/null 2>&1 && rc=0 || rc=$?
is "keep refuses anything outside import" "$rc" "10"
is "and leaves it where it was" "$(cat "$wiki/Cooking/page.md")" "page"
keep import/absent.md >/dev/null 2>&1 && rc=0 || rc=$?
is "keep refuses a missing file" "$rc" "10"

# --- the wiki root ------------------------------------------------------------------------------

# The wiki root is the first argument on every form, never found from the working directory.
rc=0; ( cd "$wiki" && sh "$sut" "$work/fx/audio.wav" ) >/dev/null 2>&1 || rc=$?
is "an input with no wiki root is a usage error" "$rc" "10"
rc=0; ( cd "$wiki" && sh "$sut" --keep import/x.md ) >/dev/null 2>&1 || rc=$?
is "a keep with no wiki root is a usage error" "$rc" "10"
rc=0; sh "$sut" "$work/nowiki" "$work/fx/audio.wav" >/dev/null 2>&1 || rc=$?
is "a wiki root that is not a directory is a usage error" "$rc" "10"

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
