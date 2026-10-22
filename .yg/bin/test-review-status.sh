#!/bin/sh
# Self-check for review-status.sh. Builds a throwaway program, holding a harness checkpoint,
# and a throwaway wiki beside it; stubs `claude` and `date`; and asserts the line, the ledger
# paths and the marks against a fixed today. A forge session is the program as its own wiki.

set -eu
bin=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

P=$tmp/prog
W=$tmp/wiki
mkdir -p "$P/.yg/bin" "$P/.yg/resolved" "$W/.yg/resolved" "$tmp/stub" "$tmp/home"
# The script finds the program from where it sits, so it runs from inside the throwaway program.
cp "$bin/review-status.sh" "$P/.yg/bin/"
printf -- '---\nrole: instruction\ncheckpoint: Claude Code @ 2.1.226 (2026-08-10)\n---\n' >"$P/.yg/facts.md"
stub() { printf '#!/bin/sh\necho "%s (Claude Code)"\n' "$1" >"$tmp/stub/claude"; chmod +x "$tmp/stub/claude"; }
stub 2.1.283

conf() { # wiki kind [line...] — the resolved config, as resolve-config.sh writes it
	f=$1/.yg/resolved/config.conf k=$2
	shift 2
	{
		for l; do printf '%s\n' "$l"; done
		echo "session.kind: $k"
	} >"$f"
}
defaults() { # wiki kind — the shipped default keys
	conf "$1" "$2" 'review.content.ledger_location: .yg/ledgers/content' \
		'review.system.ledger_location: .yg/ledgers/system' 'review.harness.ledger_location: .yg/ledgers/harness'
}
L=$P/.yg/ledgers
mkdir -p "$L/system" "$L/content" "$L/harness" "$W/.yg/ledgers/content"
defaults "$P" forge
touch "$L/system/2026-02-20-system-review-findings.md" # older: the latest is the one counted
touch "$L/system/2026-02-27-system-review-findings.md" # across a month end
touch "$L/content/2026-02-26-content-review-chess-findings-b.md"
touch "$L/system/system-review-dispositions.md" # no date: never the latest

fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; echo "  want: $2"; echo "  got:  $3"; fail=1; }
check() { # name expected wiki [mode]
	name=$1 want=$2 wiki=$3
	got=$(HOME="$tmp/home" PATH="$tmp/stub:$PATH" sh "$P/.yg/bin/review-status.sh" "$wiki" "${4:-line}" 2026-03-01 2>/dev/null) || got="exit $?"
	if [ "$got" = "$want" ]; then ok "$name"; else bad "$name" "$want" "$got"; fi
}

check forge-days 'Since last review — system: 2 days ago · content: 3 days ago (chess) · harness: 2.1.226 → 2.1.283' "$P"

touch "$L/system/2026-03-01-system-review-findings.md" "$L/content/2026-02-28-content-review-opening-traps-findings.md"
check today-and-one 'Since last review — system: today · content: 1 day ago (opening-traps) · harness: 2.1.226 → 2.1.283' "$P"

touch "$L/content/"'2026-03-01-content-review-say "hi"\-findings.md'
check notice-escapes '{"systemMessage": "Since last review — system: today · content: today (say \"hi\"\\) · harness: 2.1.226 → 2.1.283"}' "$P" notice

stub 2.1.226
rm "$L/content/"*content-review*
check never-run 'Since last review — system: today · content: never run · harness: up to date' "$P"

printf '#!/bin/sh\nexit 1\n' >"$tmp/stub/claude"
check no-claude 'Since last review — system: today · content: never run · harness: 2.1.226' "$P"
stub 2.1.226

# A wiki session shows the content part alone, from the wiki's own folder, even where the
# user layer points the program's reviews at folders that hold ledgers.
touch "$W/.yg/ledgers/content/2026-02-28-content-review-public-speaking-findings.md"
conf "$W" wiki 'review.content.ledger_location: .yg/ledgers/content' \
	"review.system.ledger_location: $L/system" "review.harness.ledger_location: $L/harness"
check wiki-content-only 'Since last review — content: 1 day ago (public-speaking)' "$W"
printf 'review.content.ledger_location: .yg/ledgers/content\n' >"$W/.yg/resolved/config.conf"
check wiki-no-kind 'Since last review — content: 1 day ago (public-speaking)' "$W"
conf "$W" wiki 'review.content.ledger_location: none'
check wiki-content-none '' "$W"
check wiki-content-none-notice '' "$W" notice
rm "$W/.yg/resolved/config.conf"
check wiki-no-config '' "$W"

# The harness checkpoint is the program's, whichever wiki the session is in.
conf "$W" forge
check harness-from-program 'Since last review — harness: up to date' "$W"

# An absolute folder outside the wiki, and one under ~/, read from each review's own key;
# none drops that review's part alone, and the harness part never rests on its key.
mkdir -p "$tmp/elsewhere" "$tmp/home/PH/ledgers"
touch "$tmp/elsewhere/2026-02-27-system-review-findings.md" "$tmp/home/PH/ledgers/2026-02-28-content-review-cooking-findings.md"
conf "$P" forge "review.system.ledger_location: $tmp/elsewhere" 'review.content.ledger_location: ~/PH/ledgers' \
	'review.harness.ledger_location: none'
check absolute-and-tilde 'Since last review — system: 2 days ago · content: 1 day ago (cooking) · harness: up to date' "$P"
conf "$P" forge 'review.system.ledger_location: none' 'review.content.ledger_location: ~/PH/ledgers'
check system-none 'Since last review — content: 1 day ago (cooking) · harness: up to date' "$P"
conf "$P" forge
check no-keys 'Since last review — harness: up to date' "$P"

# Arguments.
check unknown-mode 'exit 2' "$P" sideways
check no-such-wiki 'exit 2' "$tmp/nowhere"
got=$(sh "$P/.yg/bin/review-status.sh" 2>/dev/null) && rc=0 || rc=$?
if [ "$rc" = 2 ]; then ok no-wiki; else bad no-wiki 2 "$rc"; fi

# ledger: the path a review writes its ledger to, or none, or a refusal. The name carries
# today's UTC date, read here rather than stubbed: busybox sh runs its own `date` ahead of PATH.
D=$(date -u +%Y-%m-%d)
lcheck() { # name want-exit want-stdout wiki args...
	name=$1 wantrc=$2 want=$3
	shift 3
	rc=0
	got=$(HOME="$tmp/home" PATH="$tmp/stub:$PATH" sh "$P/.yg/bin/review-status.sh" "$1" ledger "$2" ${3+"$3"} 2>/dev/null) || rc=$?
	if [ "$rc" = "$wantrc" ] && [ "$got" = "$want" ]; then ok "$name"; else bad "$name" "$wantrc $want" "$rc $got"; fi
}

conf "$P" forge 'review.system.ledger_location: .yg/new-system' 'review.content.ledger_location: .yg/new-content' \
	'review.harness.ledger_location: .yg/new-harness'
lcheck ledger-relative-created 0 "$P/.yg/new-system/$D-system-review-findings.md" "$P" system
if [ -d "$P/.yg/new-system" ]; then ok ledger-dir-made; else bad ledger-dir-made dir none; fi
touch "$P/.yg/new-system/$D-system-review-findings.md" "$P/.yg/new-system/$D-system-review-findings-b.md"
lcheck ledger-next-letter 0 "$P/.yg/new-system/$D-system-review-findings-c.md" "$P" system
lcheck ledger-content-scope 0 "$P/.yg/new-content/$D-content-review-chess-findings.md" "$P" content chess
lcheck ledger-harness 0 "$P/.yg/new-harness/$D-harness-review-findings.md" "$P" harness
lcheck ledger-content-no-scope 2 '' "$P" content
lcheck ledger-scope-slash 2 '' "$P" content a/b
lcheck ledger-unknown-review 2 '' "$P" staleness

conf "$W" wiki 'review.content.ledger_location: .yg/ledgers/content'
lcheck ledger-relative-to-wiki 0 "$W/.yg/ledgers/content/$D-content-review-cooking-findings.md" "$W" content cooking

conf "$P" forge "review.system.ledger_location: $tmp/elsewhere" 'review.content.ledger_location: none'
lcheck ledger-absolute 0 "$tmp/elsewhere/$D-system-review-findings.md" "$P" system
lcheck ledger-none 0 none "$P" content chess
lcheck ledger-no-key 2 '' "$P" harness
conf "$P" forge "review.system.ledger_location: $tmp/missing"
lcheck ledger-absolute-missing 2 '' "$P" system
if [ ! -e "$tmp/missing" ]; then ok ledger-absolute-not-made; else bad ledger-absolute-not-made absent made; fi
conf "$P" forge 'review.system.ledger_location: ~/PH/nowhere'
lcheck ledger-tilde-missing 2 '' "$P" system
conf "$P" forge 'review.system.ledger_location: ~/PH/ledgers'
lcheck ledger-tilde 0 "$tmp/home/PH/ledgers/$D-system-review-findings.md" "$P" system
rm "$P/.yg/resolved/config.conf"
lcheck ledger-no-config 2 '' "$P" system

# A linked worktree: a relative folder git ignores goes with it, so it is refused there and
# not in the main checkout; a tracked one is committed with the worktree's branch.
R=$tmp/repo T=$tmp/repo-wt
git init -q "$R"
printf '/.yg/ledgers/system/\n' >"$R/.gitignore"
git -C "$R" add .gitignore
git -C "$R" -c user.name=t -c user.email=t@example.com commit -q -m x
git -C "$R" worktree add -q "$T" 2>/dev/null
for d in "$R" "$T"; do
	mkdir -p "$d/.yg/resolved"
	conf "$d" forge 'review.system.ledger_location: .yg/ledgers/system' 'review.content.ledger_location: .yg/ledgers/content'
done
lcheck ledger-worktree-ignored 2 '' "$T" system
if [ ! -e "$T/.yg/ledgers/system" ]; then ok ledger-worktree-not-made; else bad ledger-worktree-not-made absent made; fi
lcheck ledger-worktree-tracked 0 "$T/.yg/ledgers/content/$D-content-review-chess-findings.md" "$T" content chess
lcheck ledger-main-ignored 0 "$R/.yg/ledgers/system/$D-system-review-findings.md" "$R" system

# marks: a ledger's ids checked against the files, and against the review's dispositions and
# its other ledgers. Files for the ids to name, under the program for the program's reviews
# and under the wiki for the content review, and one ledger folder per review.
mkdir -p "$W/Public speaking" "$tmp/m"
printf -- '---\nrole: x\n---\n\n# Title\n\n## 4. Place it\n\n## Scan it\n\n```\n## Not a heading\n```\n\n## Scripts\n' >"$P/.yg/x.md"
printf '#!/bin/sh\n# Header comment, not a heading. Cites D13.1.\n' >"$P/.yg/bin/a.sh"
printf '# Pausing\n\n## Body\n' >"$W/Public speaking/Pausing.md"
m=$tmp/m
finding() { # ledger id... — each id as a finding's bold opening line
	f=$m/$1
	shift
	echo "# Ledger" >"$f"
	for i; do printf '**1. `%s`** — a finding\n- where: `Chess/prose.md`, not an id\n' "$i" >>"$f"; done
}
mcheck() { # name want wiki ledger
	got=$(sh "$P/.yg/bin/review-status.sh" "$3" marks "$m/$4" 2>&1) || true
	if [ "$got" = "$2" ]; then ok "$1"; else bad "$1" "$2" "$got"; fi
}

finding 2026-03-01-system-review-findings.md 'consistency/.yg/x.md#place-it' 'consistency/.yg/x.md#not-a-heading' \
	'decisions/.yg/bin/a.sh#D13.1' 'decisions/.yg/bin/a.sh#D13' 'residue/.yg/bin/a.sh#header' 'x/.yg/missing.md' 'files-facts/*#no-fact' 'x/.yg/x.md'
mcheck marks-invalid 'invalid consistency/.yg/x.md#not-a-heading
invalid decisions/.yg/bin/a.sh#D13
invalid residue/.yg/bin/a.sh#header
invalid x/.yg/missing.md
invalid files-facts/*#no-fact' "$P" 2026-03-01-system-review-findings.md
# Ids are checked against the wiki given, so the program's files are not found from a wiki.
mcheck marks-against-wiki 'invalid consistency/.yg/x.md#place-it
invalid consistency/.yg/x.md#not-a-heading
invalid decisions/.yg/bin/a.sh#D13.1
invalid decisions/.yg/bin/a.sh#D13
invalid residue/.yg/bin/a.sh#header
invalid x/.yg/missing.md
invalid files-facts/*#no-fact
invalid x/.yg/x.md' "$W" 2026-03-01-system-review-findings.md

cat >"$m/system-review-dispositions.md" <<'EOF'
# System review — dispositions

- `consistency/.yg/x.md#place-it` — not yet — 2026-03-01 — wait and see.
- `consistency/.yg/x.md#scripts` — not yet — 2026-03-01 — wait — and see.
- `decisions/.yg/bin/a.sh#D13.1` — fix — 2026-02-01 — fixed once.
- `decisions/.yg/bin/a.sh#D13.1` — ignore — 2026-03-01 — not worth it.
EOF
# The pass is not part of the match: a different pass raising the same place is a recurrence.
finding 2026-03-02-system-review-findings.md 'rule-homes/.yg/x.md#place-it' 'decisions/.yg/bin/a.sh#D13.1'
mcheck marks-held-and-before 'held rule-homes/.yg/x.md#place-it — not yet 2026-03-01, raised 1 time since
before decisions/.yg/bin/a.sh#D13.1 — ignore 2026-03-01 — not worth it.' "$P" 2026-03-02-system-review-findings.md
finding 2026-03-03-system-review-findings.md 'consistency/.yg/x.md#place-it'
mcheck marks-promote 'promote consistency/.yg/x.md#place-it — not yet 2026-03-01, raised 2 times since — wait and see.' \
	"$P" 2026-03-03-system-review-findings.md
# #scripts is missed by 03-02 to 03-06, five runs, so it has expired when 03-07 raises it.
finding 2026-03-04-system-review-findings.md
finding 2026-03-05-system-review-findings.md
finding 2026-03-06-system-review-findings.md
finding 2026-03-07-system-review-findings.md 'consistency/.yg/x.md#scripts'
mcheck marks-expired 'before consistency/.yg/x.md#scripts — not yet 2026-03-01, expired — wait — and see.' \
	"$P" 2026-03-07-system-review-findings.md
rm "$m/2026-03-06-system-review-findings.md"
mcheck marks-four-misses 'held consistency/.yg/x.md#scripts — not yet 2026-03-01, raised 1 time since' \
	"$P" 2026-03-07-system-review-findings.md

# A place fixed three times since its last redesign is marked for one in place of *before*,
# whatever that last disposition was; a *not yet* still shows as held or promote. A redesign
# starts the count again (`D18.1.2`).
finding 2026-03-08-system-review-findings.md 'decisions/.yg/x.md#scan-it'
printf -- '- `consistency/.yg/x.md#scan-it` — fix — 2026-03-02 — first.\n- `residue/.yg/x.md#scan-it` — fix — 2026-03-03 — second.\n' \
	>>"$m/system-review-dispositions.md"
mcheck marks-two-fixes 'before decisions/.yg/x.md#scan-it — fix 2026-03-03 — second.' "$P" 2026-03-08-system-review-findings.md
printf -- '- `consistency/.yg/x.md#scan-it` — fix — 2026-03-04 — third.\n- `consistency/.yg/x.md#scan-it` — ignore — 2026-03-05 — no.\n' \
	>>"$m/system-review-dispositions.md"
mcheck marks-redesign 'redesign decisions/.yg/x.md#scan-it — fixed 3 times — ignore 2026-03-05 — no.' \
	"$P" 2026-03-08-system-review-findings.md
printf -- '- `consistency/.yg/x.md#scan-it` — redesign — 2026-03-06 — cases listed.\n- `consistency/.yg/x.md#scan-it` — fix — 2026-03-07 — after.\n' \
	>>"$m/system-review-dispositions.md"
mcheck marks-redesign-resets 'before decisions/.yg/x.md#scan-it — fix 2026-03-07 — after.' "$P" 2026-03-08-system-review-findings.md

# Content: only a run scoped to the page's subject, its first path segment, counts as a miss.
printf -- '- `placement/Public speaking/Pausing.md` — not yet — 2026-03-01 — maybe.\n' >"$m/content-review-dispositions.md"
for d in 02 03 04 05 06; do finding "2026-03-$d-content-review-chess-findings.md"; done
finding 2026-03-07-content-review-public-speaking-findings.md 'overlap/Public speaking/Pausing.md' \
	'overlap/Public speaking/Pausing.md#body'
mcheck marks-content-scope 'held overlap/Public speaking/Pausing.md — not yet 2026-03-01, raised 1 time since' \
	"$W" 2026-03-07-content-review-public-speaking-findings.md
for d in 08 09 10 11 12; do finding "2026-03-$d-content-review-public-speaking-findings.md"; done
finding 2026-03-13-content-review-public-speaking-findings.md 'overlap/Public speaking/Pausing.md'
mcheck marks-content-expired 'before overlap/Public speaking/Pausing.md — not yet 2026-03-01, expired — maybe.' \
	"$W" 2026-03-13-content-review-public-speaking-findings.md

# Harness: nothing recurs, so a not yet is a deferral, listed at each later run for five runs.
printf -- '- `harness/.yg/x.md#scripts` — not yet — 2026-03-01 — later.\n- `harness/.yg/bin/a.sh#D13.1` — ignore — 2026-03-01 — no.\n' \
	>"$m/harness-review-dispositions.md"
finding 2026-03-02-harness-review-findings.md 'harness/.yg/bin/a.sh#D13.1'
mcheck marks-deferred 'before harness/.yg/bin/a.sh#D13.1 — ignore 2026-03-01 — no.
deferred harness/.yg/x.md#scripts — not yet 2026-03-01, 1 of 5 runs since — later.' "$P" 2026-03-02-harness-review-findings.md
for d in 03 04 05 06; do finding "2026-03-$d-harness-review-findings.md"; done
mcheck marks-deferred-last 'deferred harness/.yg/x.md#scripts — not yet 2026-03-01, 5 of 5 runs since — later.' \
	"$P" 2026-03-06-harness-review-findings.md
finding 2026-03-07-harness-review-findings.md
mcheck marks-deferred-gone '' "$P" 2026-03-07-harness-review-findings.md

# A disposition copied in bold from the skill's wording is still read.
printf -- '- `harness/.yg/x.md#place-it` — **not yet** — 2026-03-06 — bold.\n' >>"$m/harness-review-dispositions.md"
mcheck marks-bold-disposition 'deferred harness/.yg/x.md#place-it — not yet 2026-03-06, 1 of 5 runs since — bold.' \
	"$P" 2026-03-07-harness-review-findings.md

# The harness review marks no redesign: its findings do not recur.
printf -- '- `harness/.yg/bin/a.sh#D13.1` — fix — 2026-03-02 — a.\n- `harness/.yg/bin/a.sh#D13.1` — fix — 2026-03-03 — b.\n- `harness/.yg/bin/a.sh#D13.1` — fix — 2026-03-04 — c.\n' \
	>"$m/harness-review-dispositions.md"
finding 2026-03-08-harness-review-findings.md 'harness/.yg/bin/a.sh#D13.1'
mcheck marks-harness-no-redesign 'before harness/.yg/bin/a.sh#D13.1 — fix 2026-03-04 — c.' "$P" 2026-03-08-harness-review-findings.md
rm "$m/2026-03-08-harness-review-findings.md"

mcheck marks-not-a-ledger 'review-status.sh: marks takes a ledger path, <date>-<review>-review-…-findings.md' \
	"$P" content-review-dispositions.md

exit $fail
