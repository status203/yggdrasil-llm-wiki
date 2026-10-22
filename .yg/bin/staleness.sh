#!/bin/sh
# List the pages the staleness review covers, and which are due. Reports; changes nothing.
#
# A page is a .md file in a subject folder — a top-level folder holding a .subject.md —
# outside any dotfolder. It is in scope by carrying `volatility:` and not `progress:` — a
# running progression is out until it finishes. Its `checkpoint:` is a date, or
# `tool @ version (date)`. Due is the checkpoint's date plus its volatility's threshold, at
# or before today.
#
# The thresholds are the keys staleness-review.threshold.{high,medium,low}, in days, read
# from <wiki>/.yg/resolved/config.conf. The resolved file is trusted as an invariant, with
# no fallback value here, since one would put a value in force that no config layer shows:
# a missing key stops the listing.
#
# One tab-separated row per page, under a header: state, path, volatility, checkpoint,
# threshold in days, `-` for an empty field. The threshold is shown so a flag can be checked
# rather than taken. States:
#   unreadable     a volatility or checkpoint that does not parse, or a future date — listed
#                  with its raw value, never skipped: suppressing a page silently is the
#                  failure a listing exists to prevent
#   no checkpoint  counts as due; the review asks for a date before researching
#   due, not due
#   opted out      a tutorial without `volatility:` — removing the field is the opt-out, and
#                  listing it shows a field dropped by accident
# Rows run unreadable and no checkpoint first, then oldest checkpoint first.
#
# A line's trailing CR is dropped first, so a page saved with CRLF line endings reads, as
# check-vault.sh reads it.
#
# Neither git nor mtime is read: history starts at a baseline commit and mtime moves on any
# copy, so the frontmatter is the only age signal a page has.
#
# Usage: staleness.sh WIKI_ROOT [YYYY-MM-DD]     today defaults to the UTC date
# Output: the listing on stdout, paths wiki-relative.
# Exit: 0 listed; 2 nothing listed — usage, a malformed today, no directory at WIKI_ROOT,
# or a threshold missing or not a whole number of days in the resolved config.
#
# Cost: run mid-turn when a tutorial finishes (page-contract.md § Progressions), and by the
# staleness review. Measured 2026-10-02 on synthetic wikis of 20 subjects at 500, 1,000,
# 2,000 and 4,000 pages: 0.02s, 0.03s, 0.04s, 0.08s, linear in pages.

set -eu

if [ $# -lt 1 ] || [ $# -gt 2 ] || [ -z "$1" ]; then
	echo "usage: staleness.sh WIKI_ROOT [YYYY-MM-DD]" >&2
	exit 2
fi
WIKI=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || {
	echo "staleness.sh: no wiki at $1 — not a directory" >&2
	exit 2
}
today=${2:-$(date -u +%Y-%m-%d)}
case $today in
	[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
	*) echo "staleness.sh: today must be YYYY-MM-DD: $today" >&2; exit 2 ;;
esac

# Flat "key: value" from the resolved config, by index so a key's dots stay literal.
CONF=$WIKI/.yg/resolved/config.conf
conf_get() {
	v=$(awk -v k="$1" 'index($0, k ": ") == 1 { v = substr($0, length(k) + 3) } END { printf "%s", v }' \
		"$CONF" 2>/dev/null) || v=
	case $v in
	"" | *[!0-9]*)
		echo "staleness.sh: $1 is missing from $CONF or is not a whole number of days — resolve the wiki's config (sh <program>/.yg/hooks/resolve-config.sh <wiki>) before listing." >&2
		exit 2
		;;
	esac
	printf '%s' "$v"
}
high=$(conf_get staleness-review.threshold.high)
medium=$(conf_get staleness-review.threshold.medium)
low=$(conf_get staleness-review.threshold.low)

# The subject folders, in place of the arguments, which are spent. With none, find is not
# run, since it would search the working directory instead.
set --
for d in "$WIKI"/*/; do
	[ -f "$d.subject.md" ] || continue
	set -- "$@" "${d%/}"
done

printf 'state\tpath\tvolatility\tcheckpoint\tthreshold\n'
[ $# -gt 0 ] || exit 0
find "$@" -name '.*' -prune -o \
	-name '*.md' -type f -exec awk -v root="$WIKI/" -v today="$today" \
	-v th="$high" -v tm="$medium" -v tl="$low" '
	# Days since a fixed epoch, from the civil date; only differences are used. Plain
	# arithmetic because mktime is gawk-only and date -d / -v split GNU from macOS
	# (`F17.1`, `F18.1`, `F18.2`).
	function days(s,   y, m, d) {
		y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
		if (m <= 2) { y--; m += 12 }
		return 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d
	}
	function valid(s,   y, m, d, lim) {
		if (s !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
		y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
		if (m < 1 || m > 12 || d < 1) return 0
		lim = substr("312831303130313130313031", 2 * m - 1, 2) + 0
		if (m == 2 && (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0))) lim = 29
		return d <= lim
	}
	function val(line) { sub(/^[^:]*:[ \t]*/, "", line); sub(/[ \t]+$/, "", line); return line }
	function emit(   path, t, date, state, key) {
		if (file == "" || prog != "") return
		path = substr(file, length(root) + 1)
		if (vol == "") {
			if (type ~ /(^|\/)tutorial$/) print "~" "\t" "opted out\t" path "\t-\t" (cp == "" ? "-" : cp) "\t-"
			return
		}
		t = vol == "high" ? th : vol == "medium" ? tm : vol == "low" ? tl : ""
		date = cp
		if (date ~ / \([^()]*\)$/) { sub(/.* \(/, "", date); sub(/\)$/, "", date) }
		if (t == "") { state = "unreadable"; key = "0" }
		else if (cp == "") { state = "no checkpoint"; key = "1" }
		else if (!valid(date) || days(date) > days(today)) { state = "unreadable"; key = "0" }
		else { state = days(date) + t <= days(today) ? "due" : "not due"; key = "2" date }
		print key "\t" state "\t" path "\t" vol "\t" (cp == "" ? "-" : cp) "\t" (t == "" ? "-" : t)
	}
	{ sub(/\r$/, "") }
	FNR == 1 { emit(); file = FILENAME; infm = ($0 == "---"); vol = cp = prog = type = ""; next }
	infm && $0 == "---" { infm = 0; next }
	infm && /^volatility:/ { vol = val($0) }
	infm && /^checkpoint:/ { cp = val($0) }
	infm && /^progress:/ { prog = val($0) }
	infm && /^type:/ { type = val($0) }
	END { emit() }
' {} + | LC_ALL=C sort -t '	' -k1,1 -k3,3 | cut -f2-
