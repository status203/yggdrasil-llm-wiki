---
name: staleness-review
description: Check whether pages that teach something still hold up against the world, and update the ones the user chooses. Use when the user asks whether a tutorial or page is still current, what is due for a staleness check, or invokes /yggdrasil:staleness-review. Not for pages against each other, which is the content review.
---

# Staleness review

The wiki against the world, for pages carrying `volatility:`. A page says what it was last checked against in `checkpoint:` — a date, or `tool @ version (date)` — and the review asks **what has changed since**, then compares that with the page. **Propose, and apply on a yes.**

## 1. List

`sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/staleness.sh" "$(git rev-parse --show-toplevel)"`. A running progression is left out by design, and so is anything without `volatility:` bar the tutorials it names as **opted out**.

Where the user named a page, take its row: a **due** one is picked, and goes to step 3; a **no checkpoint** or **unreadable** one gets step 2's handling for that page first, then step 3. A named page with no row is out of scope: say which reason — no `volatility:`, still carrying `progress:`, not in a subject folder (a top-level folder holding a `.subject.md`), or not found — and stop.

## 2. Pick

Present the **due**, **no checkpoint** and **unreadable** rows in the script's order, and the opted-out tutorials in one line, since a field dropped by accident shows only here. Ask which to check. An **unreadable** row is fixed on the user's word before it can be checked. A **no checkpoint** page needs a date from the user — and a version, where the topic has one — before research.

## 3. Research

For each picked page, read its frontmatter and headings only — ``awk '/^```/ { fence = !fence; next } !fence && /^#+ /'`` on the file, since a bare `grep '^#'` also takes comments and example headings from code blocks — never the body. Dispatch Hugin per page, all in one message:

- **The question:** what has changed in the topic since the checkpoint — the version where it names one, the date otherwise.
- **What it is for:** checking a page written against that checkpoint, whose scope is its pitch and headings, which go in the brief.
- **Ask for:** each change with its source and date; what it replaces or removes; and the topic's current version, where it has one.

**Nothing** means Hugin found nothing credible: the page goes to the walk saying so and what Hugin searched, with a recommendation of **not now**. On **Nothing**, **no change** stays the user's to choose on their own word that the page is current — with the version, where the topic has one, for the checkpoint. **Found** that carries no change, sourced and with the topic's current version where it has one, goes to the walk with no findings and a recommendation of **no change**. **Failed** alone or beside a **Nothing**, or a dispatch that did not return (`F5.3`), is **not reviewed** — the page goes no further this run. A **Failed** beside a **Found**, such as one source out of reach, goes on with the Found, and the walk names what failed.

## 4. Compare

For each page Hugin found changes for, dispatch `yggdrasil:tyr`, all in one message. The brief:

- **Items** — Hugin's changes, numbered, each with its source and any mark Hugin put on it.
- **Standard** — the page itself, by path.
- **Test** — for each change: does the page teach something it alters or removes — **stale** — or leave it out though it falls inside what the page sets out to teach — **gap**? A gap is a finding only where a reader of this page would be worse off not knowing it.
- **Finding fields** — **id** (`staleness/<page path>#<section>/<change>`, unique per finding), **class** (stale or gap), **where** (the section), **claim**, **evidence** (quoted, the least that shows it), **change** (the item's number), **proposal** (what the section would need to say).

Check what came back: **Walked** short with nothing under **Not walked** or **Failed** to account for it — re-dispatch once with the missing items. **Failed** — re-dispatch those once. **Brief incomplete** — fix and resend. A dispatch that did not return is **not reviewed**, never *nothing changed* (`F5.3`). **Noticed** goes to the user.

## 5. Walk

Per page: the stale findings, then the gaps, then one recommendation from the five below, with its reason — how much has drifted, whether the user took in the old material (ask), and whether the page still earns its place as reference. The user can strike findings from an update.

- **Update in place**, carrying the findings the user keeps. The edits go first. A tutorial: Mimir, a replacement for each affected step, briefed as a staleness update with that step's findings and their sources — one at a time, since each writes the same page and its recaps. Any other page: Bragi, with the findings, stale ones as corrections and gaps as new material, and their sources. **Once every edit is reported written**, the **changes section** saying what moved, for someone who already completed the page (`${CLAUDE_PLUGIN_ROOT}/.yg/page-contract.md` § *Frontmatter*), with the new checkpoint for its heading: for a tutorial, Mimir's **Changes** operation, briefed with the kept findings and their sources and what each replacement reported; for any other page, only if the user wants one (ask), Bragi with the section alone — never in the same brief as the edits, which can come back part-written.
- **Follow-on** — a tutorial only: Mimir plans a new tutorial, briefed with the topic, the old page as what the learner already knows, and the changes with their findings. Once the plan is reported written, **the old page loses `volatility:`**, never a new checkpoint — re-stamping it would claim it current.
- **No change** — the checkpoint moves.
- **Stop reviewing** — the page loses `volatility:` and keeps its checkpoint.
- **Not now** — nothing is written, and the page stays due.

**Wait for each edit to be reported written.** A return from Mimir or Bragi listed below is settled here, not reported and left:

- **Needs a decision** alone — nothing was written. Put the question to the user; with an answer, dispatch again carrying it. Beside a **Wrote** from Mimir's plan, which returns both when it leaves the ordering open, the write counts as written, and the question goes to the user as a follow-up, explicitly not a reason to dispatch again. Beside a **Wrote** from Bragi, the items it did not write are unsettled: put the question to the user, and with an answer dispatch again carrying only those. Where the answer puts a Bragi item on a tutorial, its curriculum or its recaps, it goes to Mimir instead.
- **Declined** — say what stopped it. The same brief gets the same answer, so the choice is a different brief or a different choice for the page.
- **Wrote, with the target overridden** — the page under review was not the one updated. Put it to the user; the page counts as written only once an edit lands on it.

Where one stays unsettled, the checkpoint does not move and the page stays due; say which of its edits were written, and for an update, that its changes section is still owed.

**Moving a checkpoint:** fetch the date with `date -u +%F` as its own step — for an update, before the changes section, whose heading carries it — then write `checkpoint: <tool> @ <version> (<date>)` where Hugin reported a current version, `checkpoint: <date>` otherwise.

## 6. Close

`sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/regen-views.sh" "$(git rev-parse --show-toplevel)" stale --check`, reporting the rows that name a page the walk touched or a sidecar a write returned. A row on any other page predates the review and is not its to fix.

**Commit** the review's work now, once, in the wiki's repo, staging the whole tree:

```sh
git add -A && git diff --cached --stat
```

Check what staged against the review's own work. Anything else — a hand edit, another session's work — name it to the user and leave it for a commit of its own — a hand edit is wrap's to commit, as the session's — with `git restore --staged <path>`.

Commit only if anything staged. Report what the commit contained.
