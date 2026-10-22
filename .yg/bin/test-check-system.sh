#!/bin/sh
# Self-check for check-system.sh. Builds a throwaway corpus holding one instance of each
# defect plus clean controls, and asserts what is and is not reported.

set -eu
bin=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

ok() { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }
has() { if printf '%s\n' "$out" | grep -qF -- "$1"; then ok; else bad "expected: $1"; fi; }
hasntre() { if printf "%s\n" "$out" | grep -qE -- "$1"; then bad "unexpected: $1"; else ok; fi; }
hasnt() { if printf '%s\n' "$out" | grep -qF -- "$1"; then bad "unexpected: $1"; else ok; fi; }
# Tools whose versions the drift check reads: one in its checkpoints, one moved past them.
# ghosttool is on no PATH, so its version cannot be read at all.
mkdir -p "$tmp/shim"
printf '#!/bin/sh\necho "fakeprobe 1.2.0"\n' >"$tmp/shim/fakeprobe"
printf '#!/bin/sh\necho "movedtool version 9.0 (build 7)"\n' >"$tmp/shim/movedtool"
# Obsidian has no version flag: snap fails here, so the next package manager answers.
printf '#!/bin/sh\nexit 1\n' >"$tmp/shim/snap"
printf '#!/bin/sh\nprintf "          ID: md.obsidian.Obsidian\\n     Version: 9.9.9\\n"\n' >"$tmp/shim/flatpak"
chmod +x "$tmp/shim/fakeprobe" "$tmp/shim/movedtool" "$tmp/shim/snap" "$tmp/shim/flatpak"
run() { set +e; out=$(PATH="$tmp/shim:$PATH" sh "$tmp/.yg/bin/check-system.sh" "$@" 2>&1); rc=$?; set -e; }
file() { mkdir -p "$(dirname "$tmp/$1")"; cat >"$tmp/$1"; }

mkdir -p "$tmp/.yg/bin" "$tmp/.yg/hooks" "$tmp/.yg/githooks" "$tmp/.yg/templates" "$tmp/.yg/default"
# The script finds the root from where it sits, so it runs from inside the throwaway corpus.
cp "$bin/check-system.sh" "$bin/check-system.awk" "$tmp/.yg/bin/"
git -C "$tmp" init -q

file .yg/facts.md <<'MD'
# Facts
### F1.1 — cited
**Statement.** Something, as `date -u -r f +%F` shows.
**Probe.** Unprobed.
**Checkpoints.** None.
**Trigger.** None recorded.
#### F1.1.1 — nested, and mentioned only inside this file, which does not count
**Statement.** See F1.1.1.
**Probe.** `true`
**Checkpoints.** `fakeprobe @ 1.2.0` (2026-09-01), `fakeprobe @ unrecorded` (observed 2026-08-01) — a note.
**Trigger.** None recorded.
### F1.2 — cited by nothing
**Statement.** x.
**Probe.** Manual — look.
**Checkpoints.** `movedtool @ 2.50.0`, dated nowhere.
**Trigger.** None recorded.
### F1.3 — malformed
**Statement.** x.
**Probe.** Run the thing.
**Checkpoints.** `git 2.51.0` (2026-09-01), and `sh -c`.
### F1.4 — well formed, and not probeable
**Statement.** x.
**Probe.** Not probeable here — no Mac.
**Checkpoints.** `movedtool @ 8.0`, `ghosttool @ 1.3.4 20250131` under `sh -c` (2026-08-23, again 2026-09-08).
**Trigger.** None recorded.
### F1.5 — re-probed, and holds
**Statement.** x.
**Probe.** `true`
**Checkpoints.** `movedtool @ 1.0` (2026-09-01).
**Trigger.** None recorded.
### F1.6 — re-probed, and no longer holds
**Statement.** x.
**Probe.** `false`.
**Checkpoints.** `movedtool @ 1.0` (2026-09-01).
**Trigger.** None recorded.
### F1.7 — about the model, which has no version to read
**Statement.** x.
**Probe.** Manual — run it twice.
**Checkpoints.** Two runs over identical text (2026-08-21), three more (2026-09-08, 2026-09-09).
**Trigger.** None recorded.
### F1.8 — Obsidian, read from whichever package manager has it
**Statement.** x.
**Probe.** Manual — look.
**Checkpoints.** `Obsidian @ 1.0` (2026-09-01).
**Trigger.** None recorded.
### F1.2 — defined a second time
**Statement.** x.
**Probe.** Unprobed.
**Checkpoints.** None.
**Trigger.** None recorded.
### F1.8 — cited only by this file's own rule, outside every entry
**Statement.** x.
**Probe.** Unprobed.
**Checkpoints.** None.
**Trigger.** None recorded.
## F2 — a group, which is no fact and needs no fields
A rule of this file's own, resting on F1.8.
MD
file .yg/forge-catalog.md <<'MD'
# Forge catalog
## D1 — Where it goes — the homes
### D1.1 — Cited, explicitly not uncited. Rests on `F1.1`.
### D1.2 — Cited by nothing but its own catalog. See D1.2 and D1.1.

Explicitly not otherwise, in a later paragraph of the same entry.
### D1.3 — A bare directive.
MD
file .yg/forge-mode.md <<'MD'
# Forge mode
Per `.yg/forge-catalog.md` § *Where it goes*, and `.yg/forge-catalog.md` § *Nowhere at all*.
Rests on F1.1, F1.3, F1.4, F1.5, F1.6, F1.7, D1.1 and D1.3. Ghost fact F1.9, ghost decision D1.9, group F2, and F9 and D9 left flat.
Keys: `wrap.used`, `tooling.*`, `tooling.owned.<slug>`, and `wrap.missing`; an adapter's `wrap.hy-phen.key` and `wrap.hy-phen.gone`. Not a key: `wrap.md`.
A same-file ref to § *Forge mode* and one to § *No such heading*.
A forward ref to § *Later heading*, which the file reaches below.
Through the root, `${CLAUDE_PLUGIN_ROOT}/.yg/forge-mode.md` § *Gone heading*, and `<program>/.yg/forge-mode.md` § *Forge mode*.
Home paths are not the checkout's: `~/.claude/plugins/known.json`. Nor is regex text: `grep -q '^@.*/\.yg/wiki\.md$'`.
The keys wrap.level.{high,low} are a pattern, and **the whole lone.** namespace is only bold.
Ignored: `.yg/ledgers/system/`, `.yg/resolved/x.conf`, `.yg/resolved`; settings: `.claude/settings.json`.
## Later heading
MD
file .claude/CLAUDE.md <<'MD'
# Instruction
Read `.yg/forge-mode.md`, and `.yg/gone.md`. The dir `.yg/templates/` exists.
Generated: `.yg/resolved/config.conf`.
Patterns: `.yg/bin/test-<name>.sh`, `.yg/*-contract.md`, `.yg/skills/<name>/SKILL.md`.
Run `/yggdrasil:real`, not `/yggdrasil:nope`. Scripts: used.sh and ghost.sh.
A file read after this one: `.yg/wiki.md` § *Pages*, and `.yg/wiki.md` § *Nowhere here*.
Bare names: `wiki.md` § *Pages*, `wiki.md` § *Bare gone*, and `SKILL.md` § *Two files share it*.
MD
file .yg/wiki.md <<'MD'
# Wiki rules
## Pages
MD
file .yg/skills/real/SKILL.md <<'MD'
# Real skill
Uses default.md, the used.sh script and check-system.sh. Writes a typed page.
Prose may show `ls | sort`; only code is checked for the pin.
MD
file .yg/agents/munin.md <<'MD'
---
name: munin
tools: Read, WebSearch
omitClaudeMd: true
---
# Munin
memory: in the body is prose, not a setting.
MD
# Per-agent memory grants file tools whatever tools: says, so the frontmatter never sets it.
file .yg/agents/remembers.md <<'MD'
---
name: remembers
memory: project
tools: Read, WebFetch
---
# Remembers
MD
file .claude/settings.json <<'JSON'
{}
JSON
file .yg/bin/used.sh <<'SH'
#!/bin/sh
# Reads wrap.used.
# Cost: not timed — reads one config key.
SH
file .yg/bin/lonely.sh <<'SH'
#!/bin/sh
SH
file .yg/bin/test-lonely.sh <<'SH'
#!/bin/sh
# Only a test names lonely.sh, which does not rescue it.
ls | sort
SH
file .yg/githooks/pre-commit <<'SH'
#!/bin/sh
git diff --cached --name-only | sort
# Cost: not timed — scales with the diff.
SH
# Every way a sort is called, pinned or not.
file .yg/bin/sorts.sh <<'SH'
#!/bin/sh
printf 'b\na\n' | sort
x=$(sort -u f)
printf 'b\n' | LC_ALL=C sort -u
# A comment may say sort -u freely.
sort --version | head -n 1
echo resorted; y=$(LC_ALL=C sort -t: -k1,1 f)
awk '{ print | "sort" }' f
ls |sort # and sort in the comment too
SH
# Every way a date is fetched, UTC or not.
file .yg/bin/dates.sh <<'SH'
#!/bin/sh
a=$(date +%F)
b=$(date -u +%Y-%m-%d)
c=`date '+%F'`
d=$(date --utc +%F)
e=$(date -r f +%F)
echo update +1; f=$(date)
g=$(date -u -r f +%F)
SH
file .yg/skills/dated/SKILL.md <<'MD'
# Dated skill
Fetch the date — run `date +%F`.
Or the right way, `date -u +%F`.
MD
# Mentioning a cost is not recording one: the line has to open with it.
file .yg/hooks/hook.sh <<'SH'
#!/bin/sh
# Its Cost: goes unrecorded.
SH
file .yg/hooks/hooks.json <<'JSON'
{"command": "sh \"${CLAUDE_PLUGIN_ROOT}/.yg/hooks/hook.sh\" and pre-commit"}
JSON
# munin is listed and present; remembers is present and unlisted; retired is listed with no file.
file .claude-plugin/plugin.json <<'JSON'
{"hooks": "./.yg/hooks/hooks.json", "agents": ["./.yg/agents/munin.md", "./.yg/agents/retired.md"]}
JSON
file .yg/default/config.conf <<'CONF'
# Header.
wrap.used: on
wrap.unread: off
tooling.privacy: none
# wrap.commented: main
# wrap.hy-phen.key: x
lone.key: 1
review.system.ledger_location: .yg/ledgers/system
review.content.ledger_location: .yg/ledgers/content
review.harness.ledger_location: ~/PH/ledgers
CONF
file .yg/templates/default.md <<'MD'
# default
MD
file .yg/templates/unused.md <<'MD'
# unused
MD
# Selected by type rather than by filename, so naming the type is what keeps it live.
file .yg/templates/typed.md <<'MD'
# typed
MD
# `use` occurs only inside `used`, which must not count.
file .yg/templates/use.md <<'MD'
# use
MD
file .yg/templates/README.md <<'MD'
Describes default.md and unused.md, which does not count as using them.
MD
# What git ignores is out of the corpus, asked of git rather than listed.
file .gitignore <<'TXT'
/.yg/resolved/
/.yg/ledgers/system/
/.yg/scratch/
/.claude/settings.local.json
/.claude/worktrees/
/.claude/agent-memory/
*.lock
.obsidian/
TXT
# Coverage: a file under .yg/, .claude/ or .claude-plugin/ that no set matches is outside
# every review. What sits outside on purpose stays silent.
file .yg/stray/notes.md <<'MD'
# stray
MD
file .claude/commands/odd.md <<'MD'
# odd
MD
for p in .yg/resolved/config.conf .yg/sub/.obsidian/app.json .claude/settings.local.json .claude/x.lock \
	.claude/worktrees/w/CLAUDE.md .claude/agent-memory/munin/m.md; do
	mkdir -p "$(dirname "$tmp/$p")"; : >"$tmp/$p"
done
file .yg/scratch/notes.md <<'MD'
# ignored, and named in no list
MD
# Tracked, then deleted from the working tree: git still lists it, and it is not a file.
file .yg/agents/gone.md <<'MD'
# gone
MD
git -C "$tmp" add .yg/agents/gone.md
rm "$tmp/.yg/agents/gone.md"
# A usage doc's citations are checked like the program's, a page name with a space kept whole.
file 'Docs/Getting started.md' <<'MD'
# Getting started
Run `.yg/bin/gone-installer.sh`, then read `.yg/forge-mode.md`.
MD
# A docs: entry stands while it matches a tracked file, and is reported once it matches none.
file .yg/technical-well.txt <<'MD'
docs: ^\.yg/agents/
docs: ^Retired/
MD

run
[ "$rc" = 1 ] && ok || bad "exit 1 on findings, got $rc"

# Cross-references.
has ".claude/CLAUDE.md:2: path does not resolve: .yg/gone.md"
has "Docs/Getting started.md:2: path does not resolve: .yg/bin/gone-installer.sh"
hasnt "resolve: .yg/forge-mode.md"
hasnt "path does not resolve: .yg/templates/"
hasnt ".yg/resolved/config.conf"
hasnt "test-"
has ".claude/CLAUDE.md:5: skill does not exist: /yggdrasil:nope"
hasnt "/yggdrasil:real"
has ".claude/CLAUDE.md:5: script does not exist: ghost.sh"
hasnt "script does not exist: used.sh"
# A ghost, a group and an id left over from before a rename are none of them an entry.
has ".yg/forge-mode.md:3: fact does not exist: F1.9"
has ".yg/forge-mode.md:3: decision does not exist: D1.9"
has ".yg/forge-mode.md:3: fact does not exist: F2"
has ".yg/forge-mode.md:3: fact does not exist: F9"
has ".yg/forge-mode.md:3: decision does not exist: D9"
hasntre 'fact does not exist: F1\.1$'
hasnt "decision does not exist: D1.1"
hasnt "lacks a field: Statement: F2"
# A group heading's own id is not a citation of it.
hasntre '(facts|forge-catalog)\.md:[0-9]+: (fact|decision) does not exist'

has ".yg/forge-mode.md:2: section does not exist: .yg/forge-catalog.md § *Nowhere at all*"
# A record heading is cited by its title, the id before it dropped.
hasnt "Where it goes"
has ".yg/forge-mode.md:5: section does not exist: .yg/forge-mode.md § *No such heading*"
hasnt "§ *Forge mode*"
# Sections resolve once every file is read, whatever the order, and through the root.
hasnt "§ *Later heading*"
has ".claude/CLAUDE.md:6: section does not exist: .yg/wiki.md § *Nowhere here*"
hasnt "§ *Pages*"
has ".yg/forge-mode.md:7: section does not exist: .yg/forge-mode.md § *Gone heading*"
# A bare basename resolves when one file has it; a shared one names no file and is skipped.
has ".claude/CLAUDE.md:7: section does not exist: .yg/wiki.md § *Bare gone*"
hasnt "Two files share it"
# A home path, regex text and a brace pattern are not citations.
hasnt "known.json"
hasntre 'path does not resolve: \.yg/wiki$'
hasnt "wrap.level"
# What git ignores is not the checkout's to hold.
hasntre "(resolve|exist).*\.yg/ledgers"
hasnt "settings.json"
hasntre 'resolve: \.yg/resolved'
has ".yg/forge-mode.md:4: config key does not exist: wrap.missing"
hasnt "config key does not exist: wrap.used"
has ".yg/forge-mode.md:4: config key does not exist: wrap.hy-phen.gone"
hasnt "config key does not exist: wrap.hy-phen.key"
hasnt "tooling.owned"
hasnt "wrap.md"

# Orphans.
has ".yg/facts.md:12: fact is cited by nothing: F1.2"
has ".yg/facts.md:7: fact is cited by nothing: F1.1.1"
hasntre 'cited by nothing: F1\.1$'
hasnt "cited by nothing: F1.8"
has ".yg/bin/lonely.sh: script is named by nothing"
hasnt "used.sh: script is named by nothing"
hasnt "hook.sh: script is named by nothing"
hasnt "pre-commit: script is named by nothing"
has ".yg/default/config.conf:3: config key is read by nothing: wrap.unread"
hasnt "read by nothing: wrap.used"
hasnt "read by nothing: tooling.privacy"
# A namespace is read whole only where it is named as one, `ns.*`: `lone.**`, a dot before closing bold, does not name it.
has ".yg/default/config.conf:7: config key is read by nothing: lone.key"
# A default ledger folder inside the checkout must be ignored; one outside it is not the checkout's.
has ".yg/default/config.conf:9: review.content.ledger_location is not gitignored: .yg/ledgers/content"
hasnt "review.system.ledger_location is not gitignored"
hasnt "review.harness.ledger_location is not gitignored"
hasnt "wrap.commented"
has ".yg/technical-well.txt:2: docs: entry matches no tracked file: ^Retired/"
hasnt "matches no tracked file: ^\\.yg/agents/"
has ".yg/templates/unused.md: template is referenced by nothing"
has ".yg/agents/remembers.md:3: agent sets memory:, which grants Read, Write and Edit"
has ".yg/agents/remembers.md: agent is not listed in plugin.json, so it never loads"
# An agent holding a web tool sets omitClaudeMd: true; munin's does.
has ".yg/agents/remembers.md:4: agent holds a web tool without omitClaudeMd: true"
hasnt "munin.md:3: agent holds a web tool"
has ".yg/facts.md:46: id defined twice, first at line 12: F1.2"
has ".claude-plugin/plugin.json: lists an agent with no file: .yg/agents/retired.md"
hasnt ".yg/agents/munin.md: agent is not listed"
hasnt "lists an agent with no file: .yg/agents/munin.md"
hasnt ".yg/agents/munin.md:7:"
hasnt "default.md: template"
hasnt "typed.md: template"
has ".yg/templates/use.md: template is referenced by nothing"
has "notice: .yg/forge-catalog.md:4: decision is cited by nothing: D1.2"
hasnt "cited by nothing: D1.1"

# Coverage.
has ".yg/stray/notes.md: in no corpus set"
has ".claude/commands/odd.md: in no corpus set"
hasntre '(resolved|obsidian|local|lock|worktrees|agent-memory|scratch|gone\.md).*in no corpus set'
hasntre '(check-system|pre-commit|SKILL|munin|default|plugin\.json|hooks\.json).*in no corpus set'

# Record form.
has ".yg/facts.md:17: fact lacks a field: Trigger: F1.3"
has ".yg/facts.md:19: probe is none of the four states: F1.3"
has ".yg/facts.md:20: checkpoint is not \`tool @ version\`: F1.3"
hasnt "no bracketed date: F1.3"
# A date alone is a checkpoint when the claim rests on no versioned tool; a span without
# `@` beside a date is still a mistyped checkpoint, not an unversioned one.
hasnt "F1.7"
has ".yg/facts.md:15: checkpoint has no bracketed date: F1.2"
hasntre ': (fact lacks|probe is|checkpoint is) .*: F1\.(1|1\.1|2|4)$'
hasntre 'no bracketed date: F1\.(1|1\.1|4)$'
has ".yg/forge-catalog.md:7: decision names no rejected alternative: D1.3"
hasntre 'rejected alternative: D1\.[12]$'

# An unpinned sort orders by locale under GNU and by byte under uutils, so only a row
# can see it on a uutils machine. Code only; a test, a comment and a version probe are not.
has ".yg/bin/sorts.sh:2: unpinned sort: pin it with LC_ALL=C"
has ".yg/bin/sorts.sh:3: unpinned sort: pin it with LC_ALL=C"
has ".yg/bin/sorts.sh:8: unpinned sort: pin it with LC_ALL=C"
has ".yg/bin/sorts.sh:9: unpinned sort: pin it with LC_ALL=C"
hasntre 'sorts\.sh:[4-7]: unpinned sort'
has ".yg/githooks/pre-commit:2: unpinned sort: pin it with LC_ALL=C"
hasntre '(test-lonely\.sh|SKILL\.md):[0-9]+: unpinned sort'

# Every date is UTC (D11.2), in code and in prose alike, since a flow's prose fetches dates too.
has ".yg/bin/dates.sh:2: local date: pass -u"
has ".yg/bin/dates.sh:4: local date: pass -u"
has ".yg/bin/dates.sh:6: date -r: uutils ignores -u beside it (F17.1.1.1), so take the date from stat under TZ=UTC0"
has ".yg/bin/dates.sh:8: date -r: uutils ignores -u beside it (F17.1.1.1), so take the date from stat under TZ=UTC0"
hasntre 'dates\.sh:[3578]: local date'
hasntre 'facts\.md:[0-9]+: (date -r|local date)'
has ".yg/skills/dated/SKILL.md:2: local date: pass -u"
hasnt ".yg/skills/dated/SKILL.md:3: local date"

# A script records what it costs the user to wait on it, or why that is not timed (D23.1).
# The .awk behind a script is costed by the script.
has ".yg/bin/lonely.sh: script records no cost: add a Cost: line"
has ".yg/bin/sorts.sh: script records no cost: add a Cost: line"
has ".yg/hooks/hook.sh: script records no cost: add a Cost: line"
hasntre '(used\.sh|pre-commit|check-system\.sh|check-system\.awk|test-lonely\.sh): script records no cost'
# hooks.json sits among the hooks but is not a script.
hasnt "hooks.json: script records no cost"

# Version drift. A tool inside the checkpoint set is silent; a moved tool is one notice per
# run; a moved fact with a self-judging probe is re-run, silent if it holds and a finding if
# not; anything else is a question for the user, and so is a version that cannot be read.
has "question: .yg/facts.md:12: F1.2 — movedtool is at 9.0, checked at 2.50.0"
has "question: .yg/facts.md:21: F1.4 — ghosttool's version cannot be read here, checked at 1.3.4 20250131, cited by .yg/forge-mode.md"
hasnt "F1.1.1 —"
# F1.4 has no probe command and one citer, so a collapsed field would run the citer.
has "question: .yg/facts.md:21: F1.4 — movedtool is at 9.0, checked at 8.0, cited by .yg/forge-mode.md"
has "F1.8 — Obsidian is at 9.9.9, checked at 1.0"
hasnt "F1.5"
has ".yg/facts.md:31: probe no longer holds at movedtool 9.0: F1.6, cited by .yg/forge-mode.md"
has "notice: movedtool is at 9.0, in no fact's checkpoints"
hasnt "notice: fakeprobe"
hasnt "notice: ghosttool"

# Findings sort before notices, so the exit status and the head of the report agree.
last=$(printf '%s\n' "$out" | tail -n 1)
case $last in notice:*) ok ;; *) bad "notices last, got: $last" ;; esac

# Worklists: what each pass is handed, so the review can check what it walked against it.
tab=$(printf '\t')
run worklist facts
[ "$rc" = 0 ] && ok || bad "worklist facts exits 0, got $rc"
has "F1.1${tab}2${tab}.yg/forge-catalog.md, .yg/forge-mode.md"
has "F1.2${tab}12${tab}"
has "F1.7${tab}36${tab}.yg/forge-mode.md"
[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 9 ] && ok || bad "nine facts, one line each: $out"
hasnt "does not exist"
run worklist decisions
has "D1.1${tab}3"
has "D1.3${tab}7"
[ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 3 ] && ok || bad "three decisions, one line each: $out"
run worklist nonsense
[ "$rc" = 2 ] && ok || bad "unknown worklist exits 2, got $rc"

# Corpus sets.
run files prose
has ".yg/agents/munin.md"
has ".yg/skills/real/SKILL.md"
has ".claude/CLAUDE.md"
has ".yg/forge-catalog.md"
hasnt ".yg/bin/used.sh"
has ".yg/templates/README.md"
run files config
has ".claude/settings.json"
has ".yg/templates/default.md"
hasnt ".yg/templates/README.md"
run files code
has ".yg/bin/used.sh"
has ".yg/githooks/pre-commit"
has ".yg/hooks/hooks.json"
has ".claude-plugin/plugin.json"
hasnt "test-lonely.sh"
run files tests
has ".yg/bin/test-lonely.sh"
hasnt ".yg/bin/used.sh"
run files program
has ".yg/bin/used.sh"
has ".yg/forge-mode.md"
hasnt "test-lonely.sh"
hasnt "Docs/"
run files docs
has "Docs/Getting started.md"
run files nonsense
[ "$rc" = 2 ] && ok || bad "unknown set exits 2, got $rc"

# Briefs: one per pass in passes.md, paths absolute, the rows real, the newcomer read's
# only those naming a docs file. A pass with no recipe, or no short name, stops it.
b=$tmp/briefs
mkdir -p "$b" "$tmp/.yg/skills/system-review/references"
passes=$tmp/.yg/skills/system-review/references/passes.md
cat >"$passes" <<'MD'
# Passes

## Conduct — the head of every brief

- Read `.yg/forge-catalog.md` whole.

## Decisions

**Short name:** `decisions`. Run `git log -p -- .yg/forge-catalog.md`.

## Newcomer read

**Short name:** `newcomer-read`. Read the docs.

## Structure

**Short name:** `structure`. Judge placement.
MD
run briefs "$b"
[ "$rc" = 2 ] && ok || bad "briefs without check-leaks.sh exits 2, got $rc"
cp "$bin/check-leaks.sh" "$bin/check-leaks.awk" "$tmp/.yg/bin/"
cp "$tmp/.yg/technical-well.txt" "$tmp/well.keep"
printf '^/home/PH(/|$)\n' >>"$tmp/.yg/technical-well.txt"
run briefs "$tmp/nowhere"
[ "$rc" = 2 ] && ok || bad "briefs into a missing folder exits 2, got $rc"
run briefs "$b"
[ "$rc" = 0 ] && ok || bad "briefs exits 0, got $rc: $out"
has "$b/brief-decisions.md"
has "$b/brief-newcomer-read.md"
out=$(cat "$b/brief-decisions.md")
has "Read \`$tmp/.yg/forge-catalog.md\` whole."
has "git -C $tmp log -p -- $tmp/.yg/forge-catalog.md"
has "D1.1 (forge-catalog.md line 3)"
has "$tmp/.yg/forge-mode.md"
has "Docs/Getting started.md:2: path does not resolve"
hasnt "## Newcomer read"
out=$(cat "$b/brief-newcomer-read.md")
has "Docs/Getting started.md:2: path does not resolve"
hasnt "in no corpus set"
has "$tmp/Docs/Getting started.md"
out=$(cat "$b/brief-structure.md")
has "D1.1 (forge-catalog.md line 3)"
has "(facts.md line "
has "$tmp/.yg/facts.md"
cp "$passes" "$tmp/passes.keep"
printf '\n## Invented\n\n**Short name:** `invented`.\n' >>"$passes"
run briefs "$b"
[ "$rc" = 2 ] && ok || bad "a pass with no recipe exits 2, got $rc"
has "no brief recipe for the pass invented"
cp "$tmp/passes.keep" "$passes"
printf '\n## Unnamed\n\nNo short name.\n' >>"$passes"
run briefs "$b"
[ "$rc" = 2 ] && ok || bad "a section with no short name exits 2, got $rc"
mv "$tmp/passes.keep" "$passes"
rm -rf "$b" "$tmp/.yg/skills/system-review" "$tmp/.yg/bin/check-leaks.sh" "$tmp/.yg/bin/check-leaks.awk"
mv "$tmp/well.keep" "$tmp/.yg/technical-well.txt"

# Claude Code's manual facts are measured against the harness review's checkpoint, not
# the installed version: silent at it, one question past it, and never a row per fact.
# Its command probes still re-run.
cp "$tmp/.yg/facts.md" "$tmp/facts.keep"
{ printf -- '---\ncheckpoint: Claude Code @ 2.1.5 (2026-10-01)\n---\n'; cat "$tmp/facts.keep"; cat <<'MD'
### F1.10 — Claude Code, manual
**Statement.** x.
**Probe.** Manual — look.
**Checkpoints.** `Claude Code @ 2.1.1` (2026-09-01).
**Trigger.** None recorded.
### F1.11 — Claude Code, a command that no longer holds
**Statement.** x.
**Probe.** `false`
**Checkpoints.** `Claude Code @ 2.1.1` (2026-09-01).
**Trigger.** None recorded.
MD
} >"$tmp/.yg/facts.md"
printf '#!/bin/sh\necho "2.1.5 (Claude Code)"\n' >"$tmp/shim/claude"
chmod +x "$tmp/shim/claude"
run
hasnt "F1.10 —"
hasnt "Claude Code is at"
has "probe no longer holds at Claude Code 2.1.5: F1.11"
printf '#!/bin/sh\necho "2.1.6 (Claude Code)"\n' >"$tmp/shim/claude"
run
hasnt "F1.10 —"
has "question: .yg/facts.md:2: Claude Code is at 2.1.6, not the harness review's checkpoint 2.1.5: run the harness review"
[ "$(printf '%s\n' "$out" | grep -c 'Claude Code is at')" = 1 ] && ok || bad "one Claude Code row: $out"
cp "$tmp/facts.keep" "$tmp/.yg/facts.md"
cat >>"$tmp/.yg/facts.md" <<'MD'
### F1.10 — Claude Code, manual, and no harness review checkpoint
**Statement.** x.
**Probe.** Manual — look.
**Checkpoints.** `Claude Code @ 2.1.1` (2026-09-01).
**Trigger.** None recorded.
MD
run
has "question: .yg/facts.md:1: Claude Code is at 2.1.6, and facts.md records no harness review checkpoint"
mv "$tmp/facts.keep" "$tmp/.yg/facts.md"
rm "$tmp/shim/claude"

# A clean corpus exits 0.
clean=$(mktemp -d)
git -C "$clean" init -q
# The script is in its own corpus, so the paths its source names have to exist here too.
mkdir -p "$clean/.yg/bin" "$clean/.yg/default" "$clean/.yg/templates" "$clean/.yg/skills/system-review/references" "$clean/.claude"
: >"$clean/.yg/skills/system-review/references/passes.md"
for p in .claude/CLAUDE.md .claude/settings.json .yg/wiki.md .yg/config.conf .yg/technical-well.txt .yg/templates/README.md; do : >"$clean/$p"; done
printf '#!/bin/sh\n# Cost: x.\n' >"$clean/.yg/bin/check-vault.sh"
printf '#!/bin/sh\n# Cost: x.\n' >"$clean/.yg/bin/check-leaks.sh"
cp "$bin/check-system.sh" "$bin/check-system.awk" "$clean/.yg/bin/"
printf '# Facts\n## The four fields\n### F1.1 — x\n**Statement.** x.\n**Probe.** Unprobed.\n**Checkpoints.** None.\n**Trigger.** None recorded.\n' >"$clean/.yg/facts.md"
# The facts check-system.sh and check-system.awk themselves cite.
for id in F19.1 F17.1.1.1 F18.2 F8.5 F8.4 F6.1.1; do
	printf '### %s — x\n**Statement.** x.\n**Probe.** Unprobed.\n**Checkpoints.** None.\n**Trigger.** None recorded.\n' "$id" >>"$clean/.yg/facts.md"
done
# The decisions check-system.sh and check-system.awk themselves cite.
printf '# Catalog\n### D1.1 — x, explicitly not y. Rests on F1.1.\n### D1.2 — y, explicitly not z.\n' >"$clean/.yg/forge-catalog.md"
for id in D16.1 D16.1.1 D16.2 D18.3 D23.1 D11.2 D17.3; do
	printf '### %s — z, explicitly not w.\n' "$id" >>"$clean/.yg/forge-catalog.md"
done
printf '# Instruction\nSee D1.1 and check-system.sh.\n' >"$clean/.claude/CLAUDE.md"
printf 'a.key: 1\n' >"$clean/.yg/default/config.conf"
printf 'Reads a.key.\n' >"$clean/.yg/forge-mode.md"
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" 2>&1); rc=$?; set -e
# An uncited decision is a notice, and a notice alone does not fail the run.
[ "$rc" = 0 ] && ok || bad "corpus with only a notice exits 0, got $rc: $out"
has "notice: .yg/forge-catalog.md:3: decision is cited by nothing: D1.2"

# A failing awk pass is unknown too, and is not allowed to reach the report as no findings.
cp "$clean/.yg/bin/check-system.awk" "$clean/good.awk"
printf 'BEGIN {\n' >"$clean/.yg/bin/check-system.awk"
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" 2>&1); rc=$?; set -e
[ "$rc" = 2 ] && ok || bad "failing awk exits 2, got $rc"
mv "$clean/good.awk" "$clean/.yg/bin/check-system.awk"

# added: only the rows since the base, exit 1 for any, 0 for none, 2 when either end cannot check.
gc() { git -C "$clean" -c user.name=t -c user.email=t@example.com "$@"; }
gc add -A && gc commit -q -m base
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" added HEAD 2>&1); rc=$?; set -e
[ "$rc" = 0 ] && ok || bad "added with no change exits 0, got $rc: $out"
[ -z "$out" ] && ok || bad "added with no change prints nothing: $out"
cp "$clean/.yg/forge-catalog.md" "$clean/cat.keep"
awk 'NR == 1 { print; print "### D1.9 — new, explicitly not old."; next } 1' "$clean/cat.keep" >"$clean/.yg/forge-catalog.md"
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" added HEAD 2>&1); rc=$?; set -e
[ "$rc" = 1 ] && ok || bad "added with a new row exits 1, got $rc: $out"
has "decision is cited by nothing: D1.9"
# The pre-existing D1.2 notice moved down a line; with line numbers dropped it is not new.
hasnt "D1.2"
cp "$clean/cat.keep" "$clean/.yg/forge-catalog.md"; rm -f "$clean/cat.keep"
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" added nosuchref 2>&1); rc=$?; set -e
[ "$rc" = 2 ] && ok || bad "added at a missing base exits 2, got $rc"
gc rm -q .yg/facts.md && gc commit -q -m nofacts && gc checkout -q HEAD~1 -- .yg/facts.md && gc commit -q -m facts
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" added HEAD~1 2>&1); rc=$?; set -e
[ "$rc" = 2 ] && ok || bad "added at a base that cannot check exits 2, got $rc: $out"
[ -z "$(git -C "$clean" worktree list | sed 1d)" ] && ok || bad "added leaves no worktree behind"

# Without a repository nothing can say what is ignored, so the run is unknown; listing a
# set reads no file and still works.
# Git looks upward for a repository (F22.5), so the ceiling keeps it from finding one above.
mv "$clean/.git" "$clean/git.off"
set +e; out=$(GIT_CEILING_DIRECTORIES=$(dirname "$clean") sh "$clean/.yg/bin/check-system.sh" 2>&1); rc=$?; set -e
[ "$rc" = 2 ] && ok || bad "no repository exits 2, got $rc"
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" files forge 2>&1); rc=$?; set -e
[ "$rc" = 0 ] && ok || bad "files without a repository exits 0, got $rc"
has ".yg/forge-mode.md"
mv "$clean/git.off" "$clean/.git"

# A missing input is unknown, never clean: exit 2, not 0.
rm "$clean/.yg/facts.md"
set +e; out=$(sh "$clean/.yg/bin/check-system.sh" 2>&1); rc=$?; set -e
[ "$rc" = 2 ] && ok || bad "missing facts.md exits 2, got $rc"
rm -rf "$clean"

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
