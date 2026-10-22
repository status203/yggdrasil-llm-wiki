---
name: harness-review
description: In a forge session, check what Claude Code has gained, changed or removed since the program was last read against it — anything that breaks a program file, contradicts a recorded fact, or would let something Yggdrasil does be done more simply — and write a findings ledger; fixes nothing. Use when the user asks what a Claude Code update means for Yggdrasil, whether a new harness feature could replace something, or invokes /yggdrasil:harness-review. Not for re-checking facts one by one, which is the system review's, and not for wiki pages, which is the staleness review's.
---

# Harness review

The program against Claude Code (`D17.1`). `.yg/facts.md` carries a `checkpoint:` in its frontmatter — the version whose release notes the program was last read against — and the review asks **what has changed since**, then compares that with the program's files (`D17.2`). It writes a ledger, moves the checkpoint, and fixes nothing.

It runs in the checkout and names program files from there: it edits and commits the checkout's `facts.md`, and in a wiki the missing files stop it (`D3.1.2`). Every path in a brief is absolute, under `"$(git rev-parse --show-toplevel)"`.

## 1. Checkpoint

No `.yg/facts.md` or `.yg/bin/check-system.sh`, as in a wiki: say this is a forge-session review and stop.

Where the user named a feature, it is the one item, described from the source the user gave or else by a Hugin dispatch asking what it does: go to step 3, and the checkpoint stays where it is.

Otherwise read the checkpoint — `sed -n '2,/^---$/s/^checkpoint: //p' .yg/facts.md` — and the installed version, `claude --version`. The same version: nothing to review, say so and stop. No checkpoint: ask the user for the version to start from. `git status --porcelain -- .yg/facts.md` printing anything: the file holds uncommitted edits, which step 5's commit would carry — say so and stop, so they are committed first.

## 2. Research

Dispatch `yggdrasil:hugin`:

- **The question:** what changed in Claude Code after the checkpoint's version, up to and including the installed one.
- **What it is for:** checking a system built on the harness for what a change breaks, contradicts, or lets it do more simply. Its scope is what the system leans on — agents and dispatch, skills, plugins, hooks, settings and permissions, worktrees, web tools, questions to the user, and what a session or dispatch loads at start. Put `facts.md`'s Claude Code headings in the brief: `awk '/^## /{ cc = /^## F[0-9]+ — Claude Code/ } cc && /^#/' .yg/facts.md`.
- **Ask for:** each change as its own numbered item, one numbering across the whole range — the numbers are step 3's items — with its source and the version it landed in, and what it replaces or removes; and every version in the range accounted for, a version with no published notes named as such.

Only **Found** with every version accounted for goes on: to step 3, or, where it carries no change, to step 4 with no findings. Anything else stops the run with the checkpoint where it was: **Nothing**, since it means Hugin found no credible notes, not that nothing changed; a version left unaccounted for, by a **Failed** or otherwise; and a dispatch that did not return. A **Failed** that leaves every version accounted for is named with the findings.

## 3. Compare

Dispatch `yggdrasil:tyr`. The brief:

- **Items** — Hugin's changes, numbered, each with its source, version and any mark Hugin put on it.
- **Standard** — `.yg/facts.md` and `.yg/forge-catalog.md`, read whole, and the rest of the program, searched: the paths `sh .yg/bin/check-system.sh files program` prints, listed in the brief since Tyr holds no shell (`D16.2`).
- **Test** — for each change, does it **break** — change or remove something a program file relies on; **alter a fact** — contradict or narrow what a Claude Code entry states, or settle one recorded as unprobed; or **reopen** — offer a cheaper or simpler way to do what a program file does, including what a decision worked around, deferred with a trigger, or recorded as a fallback not built?
- **Finding fields** — **id** (`harness/<file>#<anchor>`, `<file>` from the checkout's root, the anchor a heading of a markdown file — its text lowercased, a leading step number such as `2.` dropped, every character but `a`–`z`, digits, spaces and hyphens dropped, each run of spaces or hyphens as one hyphen — or a fact or decision id the file holds, left off where the finding is the whole file or the file has no headings; never a label of your own or a line number; written in backticks first on the finding's bold opening line), **class** (break, alter a fact, or reopen), **where**, **claim** (one sentence), **evidence** (the change's source, and the program text it meets, the least that shows it), **change** (the item's number).

Check what came back: **Walked** short with nothing under **Not walked** or **Failed** to account for it — re-dispatch once with the missing items. **Failed** — re-dispatch those once. **Brief incomplete** — fix and resend. A second shortfall, or a dispatch that did not return (`F5.3`), stops the run with the checkpoint where it was — never *nothing changed*. **Noticed** goes to the user.

## 4. Ledger

Rank **break**, then **alter a fact**, then **reopen**.

Run `sh .yg/bin/review-status.sh "$(git rev-parse --show-toplevel)" ledger harness`. **`none`**: present from the session and write nothing — no ledger and no dispositions. **A refusal**: relay it and stop. **Otherwise** write the ledger at the path it printed. It holds the checkpoint and the installed version, or the named feature; the findings in rank order; every change with its verdict, a change touching nothing recorded as *none*, so the ledger shows the list was read whole; and what Hugin returned under **Failed** beside **Found**, since the checkpoint moves past it. Run `sh .yg/bin/review-status.sh "$(git rev-parse --show-toplevel)" marks <path>`, correct each id it reports **invalid** in the ledger, and run it again. Present from the ledger, each finding with its **before** — how the same place was last dispositioned — and after the findings, its **deferred** rows: findings earlier runs put off as *not yet*.

## 5. Close

A checkpoint run that got here moves the checkpoint, whatever the user does with the findings. Fetch the date with `date -u +%F` as its own step, then set the frontmatter line to `checkpoint: Claude Code @ <installed version> (<date>)`. `git diff -- .yg/facts.md` must show that line and nothing else; anything more stops the close uncommitted, named to the user. Commit the file alone, by path — `git commit -m 'Harness review: checkpoint to Claude Code @ <installed version>' -- .yg/facts.md` — whatever else the tree holds, since that is forge work in flight with its own commit. The ledger is never committed, wherever it lives.

## After the review

A finding the user takes up is forge work of its own — `.yg/forge-mode.md` — never applied inside this run; an *alter a fact* finding on a manual fact is where that fact is re-probed, and a manual Claude Code fact no finding names needs none (`D17.3`). When the user dispositions one, append a line to `harness-review-dispositions.md` beside the ledger, unless § 4 printed `none`, as `` - `<id>` — <disposition> — <date> — <reason> ``, the disposition take up, ignore or not yet and the date fetched with `date -u +%F` as its own step. Only `marks` reads it. A *not yet* is a deferral, since the same change is never walked twice: `marks` lists it for the next five runs, then drops it (`D18.1.1`).
