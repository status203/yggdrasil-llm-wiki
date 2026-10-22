#!/bin/sh
# One line saying how long it has been since each review last ran — a reminder the reviews
# exist, meant to be ignored most of the time (D18.2) — and, as `ledger`, where a review writes
# its ledger, and as `marks`, what a ledger's findings were dispositioned before (D18.3.1, D18.1, D18.1.1).
#
#   sh review-status.sh <wiki> [line|notice] [YYYY-MM-DD]
#   sh review-status.sh <wiki> ledger system|harness|content <scope>
#   sh review-status.sh <wiki> marks <ledger>
#
# <wiki> is the wiki root. `line`, the default, prints the line; `notice` prints it as a
# SessionStart systemMessage, which the user sees and the model does not (F10.2, F10.3). Today
# defaults to the UTC date, which is what the ledgers are named by.
#
# Each review's ledgers are in the folder its own key names, review.<review>.ledger_location
# in the wiki's resolved config: absolute, ~/ under $HOME, or relative to the wiki root. System
# and content are days since the latest ledger there, content with the scope that run covered.
# With none, or no key, no ledger can be found, so that part is dropped rather than read as
# never run. Harness is the program's .yg/facts.md checkpoint against the installed Claude
# Code, and rests on no key. The content part shows in every session; system and harness only
# when session.kind is forge, since those reviews run only there. A part that cannot be worked
# out is dropped. Staleness is not here: D15.1 keeps due pages out of session start.
#
# `ledger` prints the path a review's ledger goes to — today's date, the review, the scope for
# content, and the next free letter (-b, -c) where the name is taken — or `none` where the key
# says so. It creates the folder where the key is relative, and refuses, exit 2, where it is
# absolute or ~/ and missing, since creating a wrong one starts a second store. It refuses a
# relative folder git ignores in a linked worktree for the same reason: that store goes with the
# worktree. A missing key refuses too: here it means no resolved config, not `none`.
#
# `marks` reads a ledger's ids — the first backticked id on each bold line — and prints a row
# per id that needs one (D18.1, D18.1.1): `invalid` where its file, from the wiki root, does not hold
# its anchor; `before` with the place's last disposition; for a `not yet`, `held` or, raised
# twice since, `promote`, and `before … expired` after five covering runs without it. A place
# is the id less its pass. In the system review, a `before` whose place has been dispositioned
# fix three times or more since its last `redesign` is `redesign` instead (`D18.1.2`). The harness review's `not yet` is a deferral, listed as `deferred`
# for five runs.
#
# Cost: `notice` runs at every `startup` session start (D18.2). Measured 2026-10-04 in a forge session with 6,
# 60 and 600 ledgers in each of the system and content folders: 0.030s, 0.031s, 0.034s, near
# flat, since the ledger folders are globbed with no process per ledger. No wiki page is read.

set -eu

usage() {
	echo "usage: review-status.sh <wiki> [line|notice] [YYYY-MM-DD] | <wiki> ledger system|harness|content <scope> | <wiki> marks <ledger>" >&2
	exit 2
}
[ $# -ge 1 ] && [ -n "$1" ] || usage
WIKI=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || usage
PROG=$(CDPATH= cd -P -- "$(dirname -- "$0")/../.." && pwd)
CONF=$WIKI/.yg/resolved/config.conf
mode=${2:-line}

# Flat "key: value" from the resolved config, by index so a key's dots stay literal.
conf_get() {
	awk -v k="$1" 'index($0, k ": ") == 1 { v = substr($0, length(k) + 3) } END { printf "%s", v }' \
		"$CONF" 2>/dev/null || true
}

# A review's ledger folder: KEY its key, RAW the value, LEDGERS the folder; LEDGERS is empty
# for no key and `none` for none.
ledger_dir() {
	case $1 in
	system) KEY=review.system.ledger_location ;;
	harness) KEY=review.harness.ledger_location ;;
	content) KEY=review.content.ledger_location ;;
	esac
	RAW=$(conf_get "$KEY")
	case $RAW in
	'' | none) LEDGERS=$RAW ;;
	"~/"*) LEDGERS=$HOME/${RAW#"~/"} ;;
	/*) LEDGERS=$RAW ;;
	*) LEDGERS=$WIKI/$RAW ;;
	esac
}

if [ "$mode" = ledger ]; then
	die() { echo "review-status.sh: $1" >&2; exit 2; }
	review=${3:-}
	case $review in
	system | harness) name=$review-review ;;
	content)
		case ${4:-} in '' | */*) die "content takes a scope, a name without /" ;; esac
		name=content-review-$4
		;;
	*) die "usage: review-status.sh <wiki> ledger system|harness|content <scope>" ;;
	esac
	ledger_dir "$review"
	case $LEDGERS in
	'') die "no $KEY in $CONF — run sh <program>/.yg/hooks/resolve-config.sh $WIKI" ;;
	none) echo none; exit 0 ;;
	esac
	# A relative folder git ignores, in a linked worktree, goes with the worktree, which
	# git removes without a word about ignored files, and no other checkout reads it.
	gitdir() { d=$(git -C "$WIKI" rev-parse "$1" 2>/dev/null) && (cd "$WIKI" && cd -P -- "$d" && pwd); }
	case $RAW in
	"~/"* | /*) ;;
	*)
		g=$(gitdir --git-dir) && c=$(gitdir --git-common-dir) && [ "$g" != "$c" ] &&
			git -C "$WIKI" check-ignore -q -- "$RAW/ledger.md" 2>/dev/null &&
			die "$RAW is ignored in this worktree, so a ledger there goes when it is removed — point $KEY at an absolute or ~/ folder, or run from the main checkout"
		;;
	esac
	if [ ! -d "$LEDGERS" ]; then
		case $RAW in
		"~/"* | /*) die "no ledger folder at $LEDGERS — create it, or check $KEY" ;;
		esac
		mkdir -p "$LEDGERS"
	fi
	f=$LEDGERS/$(date -u +%Y-%m-%d)-$name-findings
	path=$f.md
	for l in b c d e f g h i j k l m n o p q r s t u v w x y z; do
		[ -e "$path" ] || break
		path=$f-$l.md
	done
	[ -e "$path" ] && die "every name for today is taken in $LEDGERS"
	printf '%s\n' "$path"
	exit 0
fi

if [ "$mode" = marks ]; then
	cur=${3:-}
	case $(basename -- "$cur") in
	[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-system-review-*findings*.md) review=system ;;
	[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-harness-review-*findings*.md) review=harness ;;
	[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-content-review-*findings*.md) review=content ;;
	*) review= ;;
	esac
	if [ -z "$review" ] || [ ! -f "$cur" ]; then
		echo "review-status.sh: marks takes a ledger path, <date>-<review>-review-…-findings.md" >&2
		exit 2
	fi
	dir=$(dirname -- "$cur")
	# Limit: same-day runs are not ordered against each other; a not yet counts only
	# ledgers dated after it, so a second run on the day of the disposition is not counted.
	awk -v review="$review" -v cur="$(basename -- "$cur")" -v root="$WIKI" \
		-v disp="$dir/$review-review-dispositions.md" '
	function key(id) { sub(/^[^\/]*\//, "", id); return id }
	function slug(s) {
		s = tolower(s); sub(/^#+[ \t]+/, "", s); sub(/^[0-9]+\.[ \t]*/, "", s)
		gsub(/[^a-z0-9 -]/, "", s); gsub(/ +/, "-", s); gsub(/-+/, "-", s)
		sub(/^-/, "", s); sub(/-$/, "", s); return s
	}
	# The file an id names exists, and its anchor is a heading of a markdown file or a fact
	# or decision id the file holds.
	function valid(k,   file, a, e, p, path, line, r, ok, fence) {
		file = k; a = ""
		if (p = index(k, "#")) { file = substr(k, 1, p - 1); a = substr(k, p + 1) }
		if (file ~ /\*/) return 0
		path = root "/" file; ok = 0; fence = 0
		while ((r = (getline line < path)) > 0) {
			if (a == "") ok = 1
			else if (a ~ /^[DF][0-9]+(\.[0-9]+)*[a-z]*$/) {
				# Whole: a group id is not inside one of its entries.
				e = a; gsub(/\./, "[.]", e)
				if (line ~ ("(^|[^A-Za-z0-9])" e "([^A-Za-z0-9.]|[.]([^0-9]|$)|$)")) ok = 1
			}
			else if (file ~ /\.md$/) {
				if (line ~ /^```/) fence = !fence
				else if (!fence && line ~ /^#+[ \t]/ && slug(line) == a) ok = 1
			}
		}
		close(path)
		if (r < 0) return 0
		return a == "" ? 1 : ok
	}
	# A content run covers a page when its scope is the page subject, the first segment of
	# the page path; every other run covers all.
	function covers(i, k,   s) {
		if (review != "content") return 1
		s = k; sub(/\/.*/, "", s); s = tolower(s); gsub(/ /, "-", s)
		return s == scope[i]
	}
	BEGIN {
		# The latest line for a place is its disposition; the file is append-only.
		# Split on the separator by index: mawk counts it in bytes, gawk in characters (`F19.2`).
		sep = " — "
		while ((getline line < disp) > 0) {
			if (line !~ /^- `/) continue
			id = substr(line, 4); id = substr(id, 1, index(id, "`") - 1)
			rest = substr(line, 4 + length(id) + 1)
			rest = substr(rest, index(rest, sep) + length(sep))
			d = substr(rest, 1, index(rest, sep) - 1); gsub(/[*_]/, "", d); rest = substr(rest, index(rest, sep) + length(sep))
			dt = substr(rest, 1, 10); rest = substr(rest, 11)
			if (index(rest, sep) == 1) rest = substr(rest, length(sep) + 1)
			k = key(id); if (!(k in dd)) order[++o] = k
			dd[k] = d; ddate[k] = dt; dwhy[k] = rest; did[k] = id
			if (d == "redesign") fixes[k] = 0; else if (d == "fix") fixes[k]++
		}
		curdate = substr(cur, 1, 10)
	}
	FNR == 1 {
		f = FILENAME; sub(/.*\//, "", f)
		n++; date[n] = substr(f, 1, 10)
		s = substr(f, 12); sub(/^content-review-/, "", s); sub(/-findings.*/, "", s); scope[n] = s
		iscur = (f == cur)
	}
	/^\*\*[^`]*`[a-z][a-z-]*\// {
		id = substr($0, index($0, "`") + 1); id = substr(id, 1, index(id, "`") - 1)
		seen[n, key(id)] = 1
		if (iscur && !(id in listed)) { listed[id] = 1; ids[++m] = id }
	}
	END {
		for (j = 1; j <= m; j++) if (!valid(key(ids[j]))) print "invalid " ids[j]
		for (j = 1; j <= m; j++) {
			id = ids[j]; k = key(id)
			if (!(k in dd)) continue
			b = "before " id " — "
			if (review == "system" && fixes[k] >= 3) b = "redesign " id " — fixed " fixes[k] " times — "
			if (dd[k] != "not yet") { print b dd[k] " " ddate[k] " — " dwhy[k]; continue }
			if (review == "harness") continue
			sights = 0; miss = 0; gone = 0
			for (i = 1; i <= n; i++) {
				if (date[i] <= ddate[k] || date[i] > curdate) continue
				if (seen[i, k]) { sights++; miss = 0; if (sights >= 2) break }
				else if (covers(i, k) && ++miss >= 5) { gone = 1; break }
			}
			if (gone) print b "not yet " ddate[k] ", expired — " dwhy[k]
			else if (sights >= 2) print "promote " id " — not yet " ddate[k] ", raised " sights " times since — " dwhy[k]
			else print "held " id " — not yet " ddate[k] ", raised " sights " time" (sights == 1 ? "" : "s") " since"
		}
		if (review != "harness") exit
		for (j = 1; j <= o; j++) {
			k = order[j]
			if (dd[k] != "not yet") continue
			runs = 0
			for (i = 1; i <= n; i++) if (date[i] > ddate[k] && date[i] <= curdate) runs++
			if (runs <= 5) print "deferred " did[k] " — not yet " ddate[k] ", " runs " of 5 runs since — " dwhy[k]
		}
	}' "$dir"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-"$review"-review-*findings*.md
	exit 0
fi

case $mode in line | notice) ;; *) usage ;; esac
today=${3:-$(date -u +%Y-%m-%d)}

# Days from the date leading a name to today, as words. Plain arithmetic, as in
# staleness.sh, because mktime is gawk-only and date -d / -v split GNU from macOS
# (`F17.1`, `F18.1`, `F18.2`).
ago() {
	awk -v a="$(printf '%s' "$1" | cut -c1-10)" -v b="$today" '
		function days(s,   y, m, d) {
			y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
			if (m <= 2) { y--; m += 12 }
			return 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + d
		}
		BEGIN { n = days(b) - days(a); print n <= 0 ? "today" : n == 1 ? "1 day ago" : n " days ago" }'
}

# A review's part, from the latest ledger's name, or nothing where its key gives no folder.
# Globs expand sorted, and the date leads the name.
side() {
	ledger_dir "$1"
	case $LEDGERS in '' | none) return 0 ;; esac
	last=
	for f in "$LEDGERS"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-"$1"-review-*findings*.md; do
		[ -e "$f" ] && last=$f
	done
	last=${last##*/}
	if [ -z "$last" ]; then printf '%s: never run' "$1"; return 0; fi
	printf '%s: %s' "$1" "$(ago "$last")"
	# The scope sits between the review's name and -findings, as `ledger` names it.
	[ "$1" = content ] && printf ' (%s)' "$(printf '%s' "$last" | sed 's/^.\{11\}content-review-//; s/-findings.*//')"
	return 0
}

harness() {
	cp=$(sed -n '2,/^---$/s/^checkpoint: //p' "$PROG/.yg/facts.md" 2>/dev/null) || cp=
	if [ -z "$cp" ]; then printf 'harness: never run'; return; fi
	was=$(printf '%s' "$cp" | sed 's/.*@ *//; s/ .*//')
	now=$(claude --version 2>/dev/null | cut -d' ' -f1) || now=
	if [ -z "$now" ]; then printf 'harness: %s' "$was"
	elif [ "$now" = "$was" ]; then printf 'harness: up to date'
	else printf 'harness: %s → %s' "$was" "$now"
	fi
}

parts=
add() { [ -n "$1" ] && parts="${parts:+$parts · }$1" || true; }

forge=
[ "$(conf_get session.kind)" = forge ] && forge=1
[ -n "$forge" ] && add "$(side system)"
add "$(side content)"
[ -n "$forge" ] && add "$(harness)"

[ -n "$parts" ] || exit 0
line="Since last review — $parts"

case $mode in
line) printf '%s\n' "$line" ;;
# A content scope is free text, so quotes and backslashes are escaped for JSON.
notice) printf '{"systemMessage": "%s"}\n' "$(printf '%s' "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')" ;;
esac
