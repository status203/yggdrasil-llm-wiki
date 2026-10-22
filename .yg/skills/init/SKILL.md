---
name: init
description: Set up a new Yggdrasil wiki's settings, subjects and remote — the conversation after init.sh has wired the folder. Use when the user invokes /yggdrasil:init, or asks to set up or start their wiki.
---

# Init

`init.sh` has already made this folder a wiki: its repository, settings, config, `Misc` and first commit. This is the conversation that follows. Wiki paths are relative to the wiki root, the session's project folder. In every question, the option that changes nothing comes first (`F9.3`).

## Check the wiring

Run `sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/init.sh" check "$(git rev-parse --show-toplevel)"`. On `wired: no`, the folder was never set up: tell the user to run `sh ${CLAUDE_PLUGIN_ROOT}/.yg/bin/init.sh <this folder>` in a terminal, where the script asks its nesting and populated-folder questions, and stop.

Welcome them in the first question rather than in passing: the wiki is theirs, and `Misc` is already there as the catch-all for anything that doesn't fit a subject yet.

## Settings

Show one block of current values from `.yg/resolved/config.conf`: the `tooling.*` positions, `wiki.visibility`, and `wrap.save_session_records`. Nothing needs setting. Write any value the user volunteers at once, only with Write or Edit, so the on-write hook re-resolves (`F11.5`), replacing that key's line or adding one:

- `tooling.*` and `transcribe.*` to the user layer, the path `echo "${XDG_CONFIG_HOME:-$HOME/.config}/yggdrasil/config.conf"` prints, since the positions are the person's and apply to every wiki, and the engine is the machine's;
- everything else to this wiki's `.yg/config.conf`.

Where this wiki's `.yg/config.conf` already sets the `tooling.*` key, ask first whether the value is this wiki's, written there, or the user's own for their other wikis, written to the user layer, which this wiki's keeps overriding.

Then say where each went, and that they can ask to have one moved — a wiki a group maintains may want its positions in the wiki layer instead. Where `wiki.visibility` changed, go through § *Visibility* next. Where it is `private`, say in a line that going public later publishes everything committed by then, its history included — the content review's ledgers and session records among it — so a wiki that may go public is better pointing `review.content.ledger_location` outside it, and setting `wrap.save_session_records` to `off`, from the start.

## Visibility

Session start points here too, whenever a wiki's visibility and its `wiki.public_answered` disagree. A session sent here runs this section alone; either way, it commits what it wrote at once, `Visibility: <public|private>`, since a later commit — a review's, transcribe's or init's own § *Commit* — would unstage a `git rm --cached` as not its own. It stages what it wrote with `git add` and commits with no paths, explicitly not `git commit -- <paths>`, which takes each named path from the working tree and puts back a folder `git rm --cached` just took out; anything else already staged is named to the user and unstaged first. Read both from `.yg/resolved/config.conf`; a marker counts only from this wiki's own layer, which the resolver enforces. Write with Write or Edit, as in § *Settings*.

**Going public** — `public`, no marker. First say that everything already written becomes public with the wiki, its git history included, naming the content review's ledgers and session records where any are committed, and that cleaning that up means rewriting history or starting a fresh repository, theirs to decide; they can ask for any part of the wiki to be read for personal detail. Where any are committed, ask whether to go on, stopping first: a stop writes nothing, so the next session asks again. Then one block of questions, each showing the current value and the layer it comes from, default, user or this wiki, with keeping it first:

- **Examples**, `wiki.well`: keep, name the wiki's own topics, or `any`.
- **Review ledgers**, where `review.content.ledger_location` points inside the wiki and outside an ignored dot folder: the content review's ledgers, and the reason given for each disposition, are published with it. Keep, which publishes them; keep them local, a line for the folder in the wiki's `.gitignore`, plus `git rm -r --cached` on it if already committed; a folder outside the wiki, which must exist and be empty, the ledger folder's contents already here moving into it and untracked here; or `none`, which loses the history later runs mark against. Pointing outside or at `none` already is shown, not asked.
- **Session records**, where `wrap.save_session_records` is `on`: none in a public wiki, or `always`, which publishes each record. `off` and `always` are shown, not asked.

Write only the answers that change something to `.yg/config.conf` — keeping a user-layer value writes nothing, so that layer stays in charge — then `wiki.public_answered:` listing each key written, and `gitignore` where a line was added, or `none`.

**Going private** — not `public`, with a marker. Name what it lists and ask of each whether to undo it, keeping first: remove the key from `.yg/config.conf`, or the `.gitignore` line. A removed key falls back to what the other layers give, not to a value this wiki held before going public: the marker names the keys, explicitly not the values they replaced, which a public wiki would publish. So the question shows what the key will fall back to and says any earlier value of the wiki's own is not known; one the user gives is written instead. For `review.content.ledger_location`, the folder's contents then move to where it resolves, named in the question, and only into an empty folder: where it resolves to `none`, or to a folder that is not empty, that is named and nothing moves. Then remove the marker either way, so going public again asks afresh.

## Subjects

Ask what the wiki is for, and propose subjects from the answer, each with a one-line pitch; the user edits the list. Then one question over the whole list, never one per subject: does any of them work differently — a page shape of its own, material kept together by where it came from or what it is for rather than by what it is about, a structure inside it?

Mint each per `${CLAUDE_PLUGIN_ROOT}/.yg/page-contract.md` § *The subject*, which splits what the user described between its `.subject.md` and any templates. Then `sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/regen-views.sh" "$(git rev-parse --show-toplevel)" stale`.

## Commit

One commit in the wiki's repository, `Init: first subjects`, with `git add -A`. Check what staged against this conversation's own work: the settings, subjects and regenerated views. Anything else — a hand edit, another session's work — name it to the user and leave it for a commit of its own — a hand edit is wrap's to commit, as the session's — with `git restore --staged <path>`. Skip the commit when nothing of init's staged.

## A remote

Only where `git remote` lists none. Advise an empty **private** repository at a host of their choosing, and ask for its URL, with "not now" first. Only the user supplies it: never propose one or look for one. Add it with `sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/init.sh" origin "$(git rev-parse --show-toplevel)" '<url>'`, which refuses a URL carrying a credential. On that refusal the value is already in the conversation, so say so under the credentials floor and offer an SSH address or a credential helper. Once added, tell them `git push -u origin HEAD` sends the wiki there.

## Close

- Open the vault in Obsidian: the folder `check`'s `vault:` line names, this folder where it says `self`. Where it says `none`, no folder here or above holds `.obsidian/`, usually because Obsidian has never opened a vault here: they open this folder, or the folder above it they want as the vault. A vault above whose config folder was renamed, and whose old `.obsidian/` was then removed, reads the same, and its other folders go unfenced (`F13.2`): say so if the user names one.
- Within the vault, Yggdrasil reads and writes only inside this folder, and the program's own folder should it sit there; the vault's other folders are never touched.
- Just start talking. Existing notes go in `import/`.
- Anything can be asked to work differently.
