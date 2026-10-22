#!/bin/sh
# Self-check for staleness.sh. Builds a throwaway wiki with one page per state the listing
# turns on, runs the script in place against it with a fixed today, and asserts each row.

set -eu
script=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/staleness.sh
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

mkdir -p "$W/A" "$W/import" "$W/.yg/resolved"
printf -- '---\nrole: instruction\npitch: A subject.\n---\n' >"$W/A/.subject.md"
conf() { # conf <high> <medium> <low> — the resolved config, as resolve-config.sh writes it
	printf 'wiki.visibility: private\nstaleness-review.threshold.high: %s\nstaleness-review.threshold.medium: %s\nstaleness-review.threshold.low: %s\nsession.kind: wiki\n' \
		"$1" "$2" "$3" >"$W/.yg/resolved/config.conf"
}
conf 90 180 365

page() { { echo '---'; printf '%s\n' "$2"; echo '---'; echo 'Body.'; } >"$W/A/$1.md"; }

page Due 'type: progression/tutorial
volatility: high
checkpoint: Stockfish @ 17 (2026-05-26)'
page Fresh 'type: concept
volatility: high
checkpoint: 2026-09-01'
page Boundary 'type: concept
volatility: low
checkpoint: 2025-09-23'
page Leap 'type: concept
volatility: low
checkpoint: 2025-09-24'
page Unstamped 'type: progression/tutorial
volatility: low'
page Future 'type: concept
volatility: medium
checkpoint: 2027-01-01'
page Garbled 'type: concept
volatility: medium
checkpoint: sometime in May'
page BadMonth 'type: concept
volatility: medium
checkpoint: 2026-13-01'
page Unspaced 'type: concept
volatility: medium
checkpoint: Stockfish @ 17(2026-05-26)'
page Wobbly 'type: concept
volatility: extreme
checkpoint: 2026-01-01'
page Running 'type: progression/tutorial
volatility: high
progress: step 2/9
checkpoint: 2020-01-01'
page OptedOut 'type: progression/tutorial
checkpoint: 2026-05-26'
page Concept 'type: concept
pitch: No volatility, not a tutorial, so not listed.'
page BodyOnly 'type: concept'
printf 'volatility: high\n' >>"$W/A/BodyOnly.md"
# Only a subject folder holds pages: neither a folder with no .subject.md nor a root-level
# file is read.
printf -- '---\ntype: concept\nvolatility: high\ncheckpoint: 2020-01-01\n---\n' >"$W/import/Stray.md"
printf -- '---\ntype: concept\nvolatility: high\ncheckpoint: 2020-01-01\n---\n' >"$W/Loose.md"
printf '# Notes for the session\n\nvolatility: high\n' >"$W/CLAUDE.md"

fail=0
run() { out=$(sh "$script" "$W" "$@" 2>&1) || { echo "FAIL  — exited nonzero: $out"; fail=1; }; }
want() { if printf '%s\n' "$out" | grep -qF -- "$1"; then echo "ok    — $2"; else echo "FAIL  — $2"; fail=1; fi; }
# A row assertion matches from the start of the line, so "due" cannot match a "not due" row.
row() { if printf '%s\n' "$out" | awk -v s="$1" 'index($0, s) == 1 { f = 1 } END { exit !f }'; then echo "ok    — $2"; else echo "FAIL  — $2"; fail=1; fi; }
deny() { if printf '%s\n' "$out" | grep -qF -- "$1"; then echo "FAIL  — $2"; fail=1; else echo "ok    — $2"; fi; }
T='	'

run 2026-09-23
row "due${T}A/Due.md${T}high${T}Stockfish @ 17 (2026-05-26)${T}90" 'a versioned checkpoint past its threshold is due, with the threshold shown'
row "not due${T}A/Fresh.md" 'a recent checkpoint is not due'
row "due${T}A/Boundary.md${T}low${T}2025-09-23${T}365" 'exactly the threshold is due'
row "not due${T}A/Leap.md" 'a day short of the threshold is not due'
row "no checkpoint${T}A/Unstamped.md${T}low${T}-${T}365" 'a page with no checkpoint is listed as such'
row "unreadable${T}A/Future.md${T}medium${T}2027-01-01" 'a future checkpoint is unreadable, with its raw value'
row "unreadable${T}A/Garbled.md${T}medium${T}sometime in May" 'a checkpoint with no date is unreadable'
row "unreadable${T}A/BadMonth.md" 'an impossible date is unreadable'
row "unreadable${T}A/Unspaced.md${T}medium${T}Stockfish @ 17(2026-05-26)" 'a versioned checkpoint needs the space before its date, as check-vault does'
row "unreadable${T}A/Wobbly.md${T}extreme" 'an unknown volatility is unreadable'
deny 'Running.md' 'a running progression is out of scope'
row "opted out${T}A/OptedOut.md${T}-${T}2026-05-26" 'a tutorial without volatility is listed as opted out'
deny 'Concept.md' 'a page without volatility that is not a tutorial is not listed'
deny 'BodyOnly.md' 'volatility in the body is not frontmatter'
deny 'import' 'a folder with no .subject.md is not read'
deny 'Loose.md' 'a page-shaped file at the root is not read'
deny 'CLAUDE.md' 'nor is any other root-level file'

# Order: the pages to act on first, oldest first within them.
first=$(printf '%s\n' "$out" | sed -n 2p)
case $first in "unreadable$T"*|"no checkpoint$T"*) echo "ok    — undated and unreadable rows lead" ;; *) echo "FAIL  — undated and unreadable rows lead: $first"; fail=1 ;; esac
order=$(printf '%s\n' "$out" | grep "^due$T" | cut -f2 | tr '\n' ' ')
[ "$order" = "A/Boundary.md A/Due.md " ] && echo "ok    — due rows run oldest first" || { echo "FAIL  — due rows run oldest first: $order"; fail=1; }

# Thresholds come from the resolved config.
conf 400 180 365
run 2026-09-23
row "not due${T}A/Due.md${T}high${T}Stockfish @ 17 (2026-05-26)${T}400" 'a configured threshold is the one applied'
conf 90 180 365

# There is no fallback: a resolved config without a threshold stops the listing.
printf 'wiki.visibility: private\nstaleness-review.threshold.high: 90\nstaleness-review.threshold.low: 365\n' >"$W/.yg/resolved/config.conf"
rc=0; out=$(sh "$script" "$W" 2026-09-23 2>&1) || rc=$?
[ "$rc" -eq 2 ] && echo "ok    — a missing threshold exits 2" || { echo "FAIL  — a missing threshold exits 2 (exit $rc)"; fail=1; }
want 'staleness-review.threshold.medium is missing' 'and names the key'
deny "due$T" 'and lists nothing'
conf 90 '' 365
rc=0; out=$(sh "$script" "$W" 2026-09-23 2>&1) || rc=$?
[ "$rc" -eq 2 ] && echo "ok    — an empty threshold exits 2" || { echo "FAIL  — an empty threshold exits 2 (exit $rc)"; fail=1; }
conf 90 'six months' 365
rc=0; out=$(sh "$script" "$W" 2026-09-23 2>&1) || rc=$?
[ "$rc" -eq 2 ] && echo "ok    — a threshold that is not a number of days exits 2" || { echo "FAIL  — a threshold that is not a number of days exits 2 (exit $rc)"; fail=1; }
rm "$W/.yg/resolved/config.conf"
rc=0; out=$(sh "$script" "$W" 2026-09-23 2>&1) || rc=$?
[ "$rc" -eq 2 ] && echo "ok    — no resolved config exits 2" || { echo "FAIL  — no resolved config exits 2 (exit $rc)"; fail=1; }
want 'resolve' 'and says to resolve it'
conf 90 180 365

# Across a year end, and across February in a leap year.
page YearEnd 'type: concept
volatility: low
checkpoint: 2025-12-31'
run 2026-12-30
row "not due${T}A/YearEnd.md" 'a day short, across a year end, is not due'
run 2026-12-31
row "due${T}A/YearEnd.md" 'a year to the day, across a year end, is due'
rm "$W/A/YearEnd.md"
page Feb 'type: concept
volatility: high
checkpoint: 2028-02-01'
run 2028-05-01
row "due${T}A/Feb.md" 'ninety days across a leap February'
run 2028-04-30
row "not due${T}A/Feb.md" 'eighty-nine days across a leap February is not due'
rm "$W/A/Feb.md"

# A bad today is refused rather than compared against.
rc=0; sh "$script" "$W" yesterday >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && echo "ok    — a malformed today is refused" || { echo "FAIL  — a malformed today is refused (exit $rc)"; fail=1; }

# The listing runs in a copy with no repository.
run
want "${T}A/Due.md${T}" 'the listing runs without a date argument and without git'

# A wiki with no subject yet lists only the header, and does not wander into the working
# directory looking for pages.
E=$W/import/empty
mkdir -p "$E/.yg/resolved"
cp "$W/.yg/resolved/config.conf" "$E/.yg/resolved/"
rc=0; out=$(cd "$W/A" && sh "$script" "$E" 2026-09-23) || rc=$?
[ "$rc" -eq 0 ] && [ "$out" = "state${T}path${T}volatility${T}checkpoint${T}threshold" ] && echo "ok    — a wiki with no subject lists only the header" || { echo "FAIL  — a wiki with no subject lists only the header (exit $rc)"; fail=1; }

# The wiki root is the first argument, never found from the working directory.
rc=0; (cd "$W" && sh "$script") >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && echo "ok    — no wiki root is a usage error" || { echo "FAIL  — no wiki root is a usage error (exit $rc)"; fail=1; }
rc=0; (cd "$W" && sh "$script" 2026-09-23) >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] && echo "ok    — a date where the wiki root goes is refused" || { echo "FAIL  — a date where the wiki root goes is refused (exit $rc)"; fail=1; }

# The shared awkward wiki (fixture-awkward-wiki.sh): every page it writes is listed, and
# none as unreadable.
A=$(mktemp -d)
pages=$(sh "${script%/*}/fixture-awkward-wiki.sh" "$A")
mkdir -p "$A/.yg/resolved" && cp "$W/.yg/resolved/config.conf" "$A/.yg/resolved/"
out=$(sh "$script" "$A" 2026-06-01)
missed=$(printf '%s\n' "$pages" | while IFS= read -r p; do
	printf '%s\n' "$out" | grep -qxF "not due	$p	low	2026-01-01	365" || printf '%s; ' "$p"
done)
[ -z "$missed" ] && echo "ok    — every awkward page is listed as not due" || { echo "FAIL  — awkward pages not listed as not due: $missed"; fail=1; }
rm -rf "$A"

exit $fail
