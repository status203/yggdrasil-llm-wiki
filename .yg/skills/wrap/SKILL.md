---
name: wrap
description: End an Yggdrasil session — decide what it produced that is worth keeping, place that, and commit. Use when the user says they are done, wrapping up, or invokes /yggdrasil:wrap.
---

# Wrap

Three steps, and the first is the point.

**In a forge session, wrap does not run**: forge work, test-bed pages included, ends in a commit of its own (`D10.9`). Say so and stop.

**A dispatch or a background command still running is put to the user before anything else**: say what it is and what wrapping now costs, since a researcher's findings would go unplaced and a writer's edit would land after the commit, left uncommitted. Wait for it or go ahead, as they choose.

## 1. Decide what the session produced

The save bar, applied to the whole session rather than to one exchange. Read `wrap.save_bar_calibration` in `.yg/resolved/config.conf` and apply it: the key holds free text, and the description **is** the setting.

Ask what the session established, not what it covered. A conclusion reached, a decision settled with its alternative, something learned that changes how a thing is done, a question the user asked and got a substantive answer to — those clear the bar. An answer counts whatever it came from, the model's own knowledge as much as a source, and however easily it could be asked again: the wiki keeps what the user learned, whichever service they learned it through. Answering a question from what the wiki already holds does not clear it; neither does the shape of the conversation itself.

**Where it would land decides whether it is kept.** Look each candidate up through `index.query_provider` in `.yg/resolved/config.conf`, in parallel, unless a lookup this session already answered for it — never skipped, because the strongest-looking keeper is often already written down. Material with a page it belongs on is kept, however small. With none, it is kept where it would stand as a page of its own, its subject proposed where none fits; a small point with no page to hold it is not kept (`D10.3`).

**Of the two failures, dropping what the user wanted is the worse**: a page they didn't want is reported and removed in a moment, while a dropped answer leaves with the conversation. **When nothing is kept, say so and go to step 3.**

## 2. Place it

**Write the session record first** where something was kept and `wrap.save_session_records` allows one: under `always` in any wiki, its owner choosing to publish it; under `on` unless `wiki.visibility` is `public`, where it would publish the conversation; under `off` never.

Session records live in `.sources/chats/`. Name it `<YYYY-MM-DD>-<kebab-slug>.md` and carry `captured:`, `source_type: claude-code-conversation`, `pitch:` and `abstract:`, matching the records already there. **Fetch the date** — run `date -u +%F`. **The session writes this, not Bragi:** Bragi is a named dispatch, which inherits none of the conversation (`F4.1`, `D10.1`).

**A web source keeps its full URL and the day it was accessed — the UTC date fetched for this record — and a claim keeps any mark Hugin put on it.** With no record, the Bragi brief carries these itself, since nothing else does.

**An item from the model's own knowledge says so in the brief**, with your model's id and the date fetched for the record, or by `date -u +%F` where there is none, so Bragi cites it as the page contract says; a claim you said at the time you were unsure of carries that as its mark.

**Then dispatch Bragi**, once per page, carrying each item kept for it, with its material and the source path to cite, and the other pages this wrap is writing. Bragi decides whether that page is really where it goes, so name the target as a proposal — and say which kind of arrival each item is, because they join differently: new material, or a correction sharpening something the page already claims.

**A tutorial step the session discussed goes to Mimir instead**, as a fold-in, one per step, sent in turn where a tutorial has more than one, alongside the Bragi dispatches to other pages: what the discussion settled about the step, and what the user said about it, the questions they asked included. **Guidance the user gave for a step not yet written goes to Mimir as a plan revision**, once per tutorial, carrying each piece of guidance and the step it is for, so that step finds it on the curriculum when it is written. Where the tutorial also has a fold-in, the revision goes once the fold-ins are reported written, since both write the curriculum.

**A page Bragi wrote earlier this session**, where a record was written, gets a correction brief too, in the brief already going to that page where there is one: add the record as its source, with each web source's access date the record's.

**A return listed below is settled here, not reported and left** — wrap is the session's end, so what is unplaced now is lost. Settle each item by its own outcome, and a brief sent again carries only the items not yet written.

- **Needs a decision** — put the question to the user; with an answer, dispatch again carrying it, to Mimir as the operation it fits where the answer puts it on a tutorial, its curriculum or its recaps.
- **Declined** — say what stopped it. The same brief gets the same answer, so the choice is a different brief or leaving it unwritten.
- **After-writing steps not clean** — fix what this session's writing caused before the commit. A row that predates the session is named, not fixed; it is the content review's.

Where a session record was written and nothing ended up citing it, ask whether to move it into `import/`, where the drop-zone check names it as pending until a later session places it, or remove it, so no source nothing cites is committed.

## 3. Close out

**The drop-zone.** Run `ls import/ 2>/dev/null`. Anything there is undisposed scratch — name it and let the user say whether it belongs in the wiki, waits for next session, or goes. A transcript kept goes by transcribe's routes and their order, `${CLAUDE_PLUGIN_ROOT}/.yg/skills/transcribe/SKILL.md` § *Disposing of it* and `${CLAUDE_PLUGIN_ROOT}/.yg/skills/transcribe/SKILL.md` § *The order, on the two keep routes*, read before acting, with the transcript itself left unopened; its commit is the one below.

**Commit**, once, in the wiki's repo:

```sh
git add -A && git diff --cached --stat
```

Check what staged against the work this session did. A hand edit the user made in Obsidian is the benign case and belongs in the commit, since wrap is where the session's hand edits are committed — say it is there and carry on. Anything else — an earlier session that did not wrap, or one still working — name it to the user and ask before committing; `git restore --staged <path>` leaves it for a commit of its own.

Commit only if anything staged. Report what the commit contained, and **each candidate step 1 did not keep**, in a line saying why and that saying so keeps it.

**Push**, where `wrap.push` is `on` and the session committed or the branch is ahead of its upstream (`git rev-list --count @{u}..` prints more than 0), so commits an earlier failed push left behind still go: `git push`. A push that fails is only reported.
