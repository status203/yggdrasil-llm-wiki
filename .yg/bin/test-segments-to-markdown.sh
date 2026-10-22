#!/bin/sh
# Self-check for srt-to-segments.awk and segments-to-markdown.sh, driven together as the caption
# path drives them. The cases the logic turns on: the word stream survives exactly, paragraph
# shape does not depend on how the source cut its cues, a paragraph's marker is the segment its
# first word came from, text carrying no sentence-final punctuation still breaks, a change of
# speaker closes and labels a paragraph, a segment with no start time gets no invented marker,
# and input that is not an SRT renders nothing at rc=0 -- which is the case the flow's
# render-to-a-file-then-test step exists for.
#
# Every SRT fixture is built here, from one word stream chopped six ways, so a difference between
# two of them can only be the cue structure.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sut="$here/segments-to-markdown.sh"
conv="$here/srt-to-segments.awk"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

pass=0; fail=0
ok() { pass=$((pass + 1)); }
no() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1" >&2; }
is() { if [ "$2" = "$3" ]; then ok; else no "$1: expected [$3] got [$2]"; fi }

# SRT through the converter, then the renderer: the caption path exactly.
render() { awk -f "$conv" "$1" > "$1.tsv" && sh "$sut" "$1.tsv"; }

# --- the word stream, chopped six ways --------------------------------------------------

cat > "$work/prose.txt" <<'PROSE'
So the first thing to understand is that a risotto is not really a recipe.
It is a method, most of the time, and that is a different claim.
When you stir the pan and watch the rice turn from chalky to glassy at the edge of each grain,
you will see it change slowly, minute by minute, and that change is what we follow this afternoon.
Nobody gets a risotto right by the clock alone.
You get it close, then closer, and at some point you taste it and decide it is done.
The stock is doing two jobs at once and that is what makes this confusing at first.
It cooks the grain from the outside in, a ladle at a time.
Add it too fast and the rice boils instead of simmering, and too slowly and it sticks and scorches.
That is the rhythm of the dish and it is the part everyone learns first because you can hear it.
The other job is the starch.
All that stirring rubs starch from the surface of each grain into the liquid, and if you stop
for too long the sauce stays thin and the grains sit apart from each other.
You cannot see the starch building as easily as you can see the liquid going, which is why people
skip the stirring, and then wonder why the finished dish never feels quite creamy on the plate.
Heat is the thing underneath both.
A pan that is far too hot drives the stock off before the grain can take it in.
A pan that is a little too cool simply takes longer, and forgives you while it does.
So the order matters: toast the rice, add the wine, then the stock, then taste, then again.
Two or three rounds of that and you are nearly done.
Start by warming the stock in a second pan and keeping it at a bare simmer beside you.
Cold stock stops the cooking every time it goes in.
A grain that tastes floury is underdone and one that falls apart has gone too far for this dish.
Sweat the onion slowly before the rice goes anywhere near the pan, because otherwise
you will chase a harsh raw flavour that is really an onion problem wearing a disguise.
Always one ladle, and always wait until it is nearly gone, so you can track what you have done.
A splash too much feels like nothing in the pan and it is an enormous change to the texture.
When the rice is close, start tasting a few grains every minute or so.
If the centre is still chalky, give it another ladle and keep stirring, and keep tasting,
because rice that seemed nearly done can tip over into soft in the space of a few minutes.
Watch the wave, not the clock.
Your eye is far better at judging how the risotto moves when you shake the pan than at judging
the time, which is why a loose wave across the pan makes such a good reference.
Rest the pan before you call it finished.
Take it off the heat, beat in the cold butter and the grated cheese hard, all the way round,
and you will feel the sauce tighten and turn glossy under the spoon.
Then taste it again, because it will have changed.
It always changes.
PROSE

# chop <words-per-cue> <cue-ms> <step-ms> <out>
# step below cue overlaps the cues, which is what a native YouTube track does; step above cue
# leaves real gaps, which is what a VAD-produced Whisper track does.
chop() {
    awk -v WPC="$1" -v CUE="$2" -v STEP="$3" '
    { for (i = 1; i <= NF; i++) { nw++; w[nw] = $i } }
    END {
        for (i = 1; i <= nw; i += WPC + 0) {
            idx++
            printf "%d\n%s --> %s\n", idx, stamp((idx-1) * STEP), stamp((idx-1) * STEP + CUE)
            line = ""
            for (j = i; j < i + WPC + 0 && j <= nw; j++) line = (line == "" ? w[j] : line " " w[j])
            printf "%s\n\n", line
        }
    }
    function stamp(ms,   h, m, s, r) {
        h = int(ms / 3600000); r = ms % 3600000
        m = int(r / 60000);    r = r % 60000
        s = int(r / 1000)
        return sprintf("%02d:%02d:%02d,%03d", h, m, s, r % 1000)
    }' < "$work/prose.txt" > "$4"
}

chop 12 5000  5000  "$work/tiled.srt"      # Whisper without VAD: cues tile, gaps exactly 0
chop 12 4000  5200  "$work/gapped.srt"     # Whisper with VAD: real gaps between cues
chop  7 3000  1500  "$work/overlap.srt"    # YouTube native: cues overlap, every gap negative
chop  9 2500  2600  "$work/human.srt"      # a human-authored track: short, even cues
chop 30 15000 15000 "$work/longcue.srt"    # one long cue per paragraph's worth of text
chop  3 1200  1200  "$work/shortcue.srt"   # three words a cue

words() { sed '/^$/d' | sed 's/^\[[0-9:]*\] //' | tr -s '[:space:]' '\n' | sed '/^$/d'; }
bodies() { sed 's/^\[[0-9:]*\] //'; }

ref=$(tr -s '[:space:]' '\n' < "$work/prose.txt" | sed '/^$/d')

for f in tiled gapped overlap human longcue shortcue; do
    render "$work/$f.srt" > "$work/$f.md"
    is "word stream survives: $f" "$(words < "$work/$f.md")" "$ref"
done

# The paragraphs themselves must be identical whatever the cue structure -- the rule reads the
# word stream and the sentence ends, and nothing else. Only the markers may differ.
base=$(bodies < "$work/tiled.md")
for f in gapped overlap human longcue shortcue; do
    is "paragraphs independent of cue structure: $f" "$(bodies < "$work/$f.md")" "$base"
done

# --- markers ----------------------------------------------------------------------------

is "first marker is the first cue" "$(head -1 "$work/tiled.md" | cut -c1-10)" "[00:00:00]"

# The overlapping track reaches the same word much earlier in wall-clock time than the tiled
# one, so its second marker must be lower. Identical markers would mean the marker is being
# taken from the paragraph index rather than from the cue.
m_tiled=$(grep -o '^\[[0-9:]*\]' "$work/tiled.md" | sed -n 2p)
m_over=$(grep -o '^\[[0-9:]*\]' "$work/overlap.md" | sed -n 2p)
if [ "$m_over" != "$m_tiled" ]; then ok; else no "marker tracks the cue, not the paragraph index"; fi

is "every paragraph carries a marker" \
    "$(grep -c '^\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] ' "$work/tiled.md")" \
    "$(sed '/^$/d' "$work/tiled.md" | wc -l | tr -d ' ')"

# --- paragraph shape ----------------------------------------------------------------------

# Every paragraph but the last reaches the budget; the last is whatever is left over.
short=$(bodies < "$work/tiled.md" | sed '/^$/d' | sed '$d' | awk 'length($0) < 600' | wc -l | tr -d ' ')
is "no full paragraph falls under the budget" "$short" "0"

# It closes at a sentence end rather than mid-sentence.
notend=$(bodies < "$work/tiled.md" | sed '/^$/d' | sed '$d' | grep -cv '[.!?]["'"'"')]*$' || true)
is "full paragraphs close on a sentence end" "$notend" "0"

# Exactly one newline at the end: a trailing blank line shows up as two.
last2=$(tail -c 2 "$work/tiled.md" | od -An -c | tr -d ' ')
case $last2 in
    '\n\n') no "no trailing blank line" ;;
    *'\n')  ok ;;
    *)      no "output ends with a newline (last two bytes: $last2)" ;;
esac

# --- text with no sentence-final punctuation ------------------------------------------------

sed 's/[.!?]//g' "$work/prose.txt" > "$work/flat.txt"
cp "$work/prose.txt" "$work/keep.txt"; cp "$work/flat.txt" "$work/prose.txt"
chop 9 2500 2600 "$work/flat.srt"
cp "$work/keep.txt" "$work/prose.txt"
render "$work/flat.srt" > "$work/flat.md"

n=$(grep -c '^\[' "$work/flat.md" || true)
if [ "$n" -gt 1 ]; then ok; else no "unpunctuated text still breaks into paragraphs (got $n)"; fi
longest=$(bodies < "$work/flat.md" | sed '/^$/d' | awk '{ if (length($0) > m) m = length($0) } END { print m }')
if [ "$longest" -le 1400 ]; then ok; else no "unpunctuated fallback bounds the paragraph (got $longest)"; fi
flatref=$(tr -s '[:space:]' '\n' < "$work/flat.txt" | sed '/^$/d')
is "word stream survives with no punctuation" "$(words < "$work/flat.md")" "$flatref"

# --- input that is not an SRT ---------------------------------------------------------------

# rc=0 with nothing written is the whole reason the caller renders to a file and tests its
# size rather than reading the exit status.
printf 'this is not an srt\nno timing line anywhere\n' > "$work/garbage.srt"
render "$work/garbage.srt" > "$work/garbage.md"; rc=$?
is "non-SRT input exits 0" "$rc" "0"
is "non-SRT input converts to nothing" "$(wc -c < "$work/garbage.srt.tsv" | tr -d ' ')" "0"
is "and renders nothing" "$(wc -c < "$work/garbage.md" | tr -d ' ')" "0"

: > "$work/empty.srt"
render "$work/empty.srt" > "$work/empty.md"; rc=$?
is "empty input exits 0" "$rc" "0"
is "empty input writes nothing" "$(wc -c < "$work/empty.md" | tr -d ' ')" "0"

# A cue whose text is blank contributes no segment and no empty paragraph.
printf '1\n00:00:00,000 --> 00:00:02,000\n\n2\n00:00:02,000 --> 00:00:04,000\nOne two three.\n\n' \
    > "$work/blankcue.srt"
render "$work/blankcue.srt" > "$work/blankcue.md"
is "a blank cue contributes nothing" "$(cat "$work/blankcue.md")" "[00:00:02] One two three."

# --- the converter's own output ------------------------------------------------------------------

# Times keep their milliseconds, a cue's lines join with a space, a tab in the text cannot open a
# fifth field, and the speaker field is present and empty.
printf '1\n00:01:02,345 --> 00:01:04,500 align:start\nfirst line\nsecond\tline\n\n' > "$work/one.srt"
awk -f "$conv" "$work/one.srt" > "$work/one.tsv"
is "a cue becomes one tab-separated line" "$(cat "$work/one.tsv")" \
    "$(printf '62.345\t64.500\t\tfirst line second line')"
is "with exactly four fields" "$(awk -F '\t' '{ print NF }' "$work/one.tsv")" "4"

# --- speakers ------------------------------------------------------------------------------------

# A change of speaker closes the paragraph however short it is, and each paragraph is labelled.
printf '0.0\t2.0\tA\tHello there.\n2.0\t3.0\tB\tHi.\n3.0\t5.0\tB\tHow are you.\n9.5\t11.0\tA\tFine thanks.\n' \
    > "$work/spk.tsv"
sh "$sut" "$work/spk.tsv" > "$work/spk.md"
is "a speaker change closes and labels a paragraph" "$(cat "$work/spk.md")" \
    "$(printf '[00:00:00] **A:** Hello there.\n\n[00:00:02] **B:** Hi. How are you.\n\n[00:00:09] **A:** Fine thanks.')"

# A long turn still breaks on the length budget within the speaker, and every piece is labelled.
awk '{ for (i = 1; i <= NF; i++) printf "%s ", $i }' "$work/prose.txt" \
    | awk '{ printf "0\t60\tA\t%s\n", $0 }' > "$work/turn.tsv"
sh "$sut" "$work/turn.tsv" > "$work/turn.md"
n=$(grep -c '^\[00:00:00\] \*\*A:\*\* ' "$work/turn.md" || true)
paras=$(sed '/^$/d' "$work/turn.md" | wc -l | tr -d ' ')
if [ "$paras" -gt 1 ] && [ "$n" -eq "$paras" ]; then ok
else no "a long turn breaks on the budget and each piece is labelled ($n of $paras)"; fi

# --- no timestamps -------------------------------------------------------------------------------

# An engine that returns no times gives paragraphs without a marker, never an invented one.
printf '\t\t\tOne two three.\n\t\t\tFour five.\n' > "$work/notime.tsv"
sh "$sut" "$work/notime.tsv" > "$work/notime.md"
is "a segment with no start time gets no marker" "$(cat "$work/notime.md")" "One two three. Four five."

# --- usage ------------------------------------------------------------------------------

if sh "$sut" >/dev/null 2>&1; then no "no argument is refused"; else ok; fi
if sh "$sut" "$work/nope.srt" >/dev/null 2>&1; then no "a missing file is refused"; else ok; fi

# --- portability --------------------------------------------------------------------------

# Portability is per tool, not per OS. macOS's awk is the floor, and nawk is the same lineage.
# The program is driven directly here rather than through the wrapper, so the wrapper needs no
# override knob it would otherwise carry only for this test.
for impl in mawk nawk busybox "gawk --posix"; do
    set -- $impl
    command -v "$1" >/dev/null 2>&1 || continue
    case $1 in busybox) set -- busybox awk ;; esac
    if "$@" -f "$conv" "$work/human.srt" 2>/dev/null \
        | "$@" -v BUDGET=600 -f "$here/segments-to-markdown.awk" 2>/dev/null \
        | cmp -s - "$work/human.md"
    then ok; else no "renders identically under $impl"; fi
    if "$@" -v BUDGET=600 -f "$here/segments-to-markdown.awk" "$work/spk.tsv" 2>/dev/null \
        | cmp -s - "$work/spk.md"
    then ok; else no "labels speakers identically under $impl"; fi
done

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
