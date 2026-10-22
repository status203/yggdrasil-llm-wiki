# System review — the passes

A finite worklist, a standard and a written test per pass, one pass per class (`D16.1.1`); a pass whose test is its own standard says so. A pass that cannot name its class does not belong here.

Each pass names the sets it reads, from `check-system.sh` (`D16.2`). `check-system.sh briefs` lists every path a pass reads in its brief, absolute, and needs a recipe for every pass here: a new pass gets one there; a pass never runs `check-system.sh` itself.

## Conduct — the head of every brief

- **Read `.yg/forge-catalog.md` whole before anything else**, unless your section says otherwise. It, with any *explicitly not* a program file states beside its own rule, is what is already settled. Where a finding would re-propose an alternative either names as ruled out, do not file it — list it under **SETTLED** with the decision's id, or the file where there is none, since a quietly reversed decision and an already-answered one look the same until someone compares them.
- **Read only the files your brief lists**, and judge against the standard your section names rather than your own sense of good practice. Where your section names none, say what you judged against.
- **The scripts' rows are already reported.** Do not re-file them.
- **Walk every worklist item.** Return each one you walked, even where it held; the review checks what you walked against what you were given.
- **Change nothing.**
- **Return**, and nothing else:

```
WALKED: <every item, comma-separated>
FINDING
class: <your class>
where: <file> § <the heading exactly as the file writes it, or a fact or decision id the file holds — the file alone where the finding is the whole file or it has no headings>
claim: <one sentence>
evidence: <the two things that conflict, quoted — or the reference that resolves to nothing>
test: <the test from your section it failed>
(one FINDING block per finding)
SETTLED: <decision id, the file holding the rule, or what guards a copy — the finding it would have been> (or omit)
```

or, where nothing was found, `WALKED: …` then `NONE FOUND`. Never *clean*: a pass is a sample (`F1.1.1`).

## Decisions

**Short name:** `decisions`. **Class:** a decision re-litigated or quietly reversed. **Worklist:** `worklist decisions`. **Reads:** `program`. **Standard:** the entry itself — each names what it chose and what it ruled out.

**Test:** does the program still do what the decision chose, and does it anywhere now do what it names as ruled out? Where `git log -p -- .yg/forge-catalog.md` shows the entry edited, read the whole entry as it stands and check that its choice, its ruled-out alternative and its reason still agree with each other — an edit to one clause can orphan the others.

## Facts to files

**Short name:** `facts-to-files`. **Class:** mechanism resting on a fact it no longer matches. **Worklist:** `worklist facts` — each fact and the files citing it. **Reads:** `.yg/facts.md` and the citing files. **Standard:** `.yg/facts.md`.

**Test:** does each citing rule match what the fact claims, including its modal words — a rule saying *never* where the fact says *sometimes*, a rule that survived its fact being narrowed, a rule citing a parent fact where a nested one is the claim it rests on?

## Files to facts

**Short name:** `files-to-facts`. **Class:** a rule branching on something about the world without citing the fact it rests on. **Worklist:** `instruction forge agents flows code`. **Reads:** `.yg/facts.md` and each file. **Standard:** `.yg/facts.md`.

**Test:** which facts should this file's rules rest on, and does it cite them? Also: which facts does it cite that none of its rules rest on? Return nominations only where you would defend them to the user — this is the noisy direction, and a pass like it was previously observed having most of its candidates dropped. Add a block after your findings: `NOMINATES: <file> → <fact ids>` and `NOT NEEDED: <file> → <fact ids>`, which triage cross-references with the facts-to-files pass.

## Structure

**Short name:** `structure`. **Class:** a fact or decision filed where it does not belong. **Worklist:** every fact and decision. **Reads:** `.yg/facts.md` and `.yg/forge-catalog.md`. **Standard:** `D24.1` and `D24.2` in `.yg/forge-catalog.md`.

**Test:** does each entry narrow the one above it — a case of it, an exception to it, or a detail of how it is done — rather than sit beside it on a related subject, which makes it a sibling? Is it under the group its subject belongs to? Propose a move only where the current place is wrong, explicitly not where another is marginally better: an entry with two plausible homes stays where it is (`D24.2`). Name the place it belongs, by the parent's id or the group's heading.

## Rule homes and form factor

**Short name:** `rule-homes`. **Class:** a rule in the wrong home. **Worklist:** `instruction forge agents flows`. **Reads:** those files. **Standard:** `.yg/forge-mode.md` § *Where a rule goes*.

**Test:** the four-home ladder — is a rule here that is enumerable and belongs in a script, is sited and belongs as a note where the mistake is made, or is detectable only across files and belongs to this review? A rule for a rare path, stated in a line where it is acted on, stays prose even where its cases can be listed, as the standard's first home says. And is prose doing a job code should do, or does its owner's trigger fire at a different moment from when the behaviour should run?

## Prose bar

**Short name:** `prose-bar`. **Class:** prose specifying procedure where an outcome would do. **Worklist:** `instruction forge agents flows`. **Reads:** those files. **Standard:** `.yg/forge-mode.md` § *How it is written*.

**Test:** does each rule state an outcome, or a procedure where the steps are not load-bearing? Is a criterion stated twice in one file? Is elaboration justified by the case, or assumed? A file drifting toward process is a defect on the program's own terms; a long sentence is not.

## Error and edge-case paths

**Short name:** `edge-cases`. **Class:** a step that assumes its happy path. **Worklist:** `flows`, `agents`, and the header comment of each file in `code`. **Reads:** those. **Standard:** none — the test is its own.

**Test:** where a step assumes its happy path, is the plausible default reaction a silent wrong guess that is costly — corrupts content, cannot be undone, or is confidently wrong? Is a confirmation incomplete, or a handoff between two pieces fragile? A failure no step branches on is Odin's to stop at and resume (`D2.2.1`), so it is a finding only where that cannot recover: the state it leaves is outside the wiki's git, a step that cannot be undone has already run, or the flow carries on past it.

## Consistency and modality

**Short name:** `consistency`. **Class:** one rule stated two ways. **Worklist:** build it — every rule stated in more than one file — and return it as your walked list. **Reads:** `program`. **Standard:** none — the test is its own.

**Test:** do the statements agree, including their modal words — a *never* in one place against a *by default* in another? Does a term mean the same thing everywhere? Does one file leave to discretion a convention another assumes is fixed?

## Forkability

**Short name:** `forkability`. **Class:** one person's fingerprint in a program file. **Worklist:** `mechanism` — the tests too, since a fixture is published like any other line. **Reads:** those. **Standard:** `.claude/CLAUDE.md` § *Privacy*.

**Test:** `check-leaks.sh` finds values by shape; this pass reads for what a shape cannot reach. Is an illustrative example drawn from outside the standard's well, or does detail around a well topic read as one person's? Does a name with no shape to check appear: a username or hostname as a bare word, a credential or where one is stored, a private repository or service, or a page or subject name from a wiki? Does a motivating case read as it was told? Does the program depend on a tool outside this repository, configure one, or record where one keeps its files? Is behaviour expected somewhere and written nowhere, so a fork would not know to supply it? **An example with the mark `well exception: <reason>` on its line or the line above it is an agreed exception: skip it**, whatever you make of the reason.

## Duplication

**Short name:** `duplication`. **Class:** one fact or rule with several copies, explicitly not a phrasing. **Worklist:** build it — every fact or rule stated in more than one file — and return it as your walked list. **Reads:** `program`. **Standard:** `.yg/forge-mode.md` § *How it is written*, its first rule, and `.yg/forge-mode.md` § *Scripts*, its rule on a script's own helpers: what they let a file keep is settled.

**Test:** rank by copy count: several copies of a fact or rule are a drift risk however short, since one will be corrected and the others will not. **A small helper a script carries itself is kept by the standard: list it under SETTLED with the rule.** **A copy that a script or test already compares with the others, or that cites the fact or decision it copies, is guarded: list it under SETTLED with what guards it** — the facts-to-files and decisions passes read every citing file against what it cites.

## Docs currency

**Short name:** `docs-currency`. **Class:** a usage doc that no longer matches the program. **Worklist:** `docs`. **Reads:** `docs` and `program`. **Standard:** the program — what its files say the system does.

**Test:** does each claim a doc makes about how the system works — an agent, a skill, a command, a path, a config key and its default, a count — still hold? Is something a user or forker needs before they can ask Claude — a prerequisite, an install or launch step — absent from every doc? A tool most environments already have is a name in the prerequisites list, qualified only where the program needs a particular one, as *<what it must support> <tool>*; the installer's own check and asking Claude cover the rest. Past that point the docs say they are intentionally brief and send the reader to Claude, so a gap there is not a finding; a claim that misleads still is. Does a doc point at something that does not exist? The script has already resolved every path the docs cite.

## Newcomer read

**Short name:** `newcomer-read`. **Class:** a doc that blocks or misleads a reader who has only the docs. **Worklist:** `docs`. **Reads:** `docs`, and nothing else — not the catalog, which the conduct's first line gives way to here, and not the wiki rules or project instructions the harness hands this dispatch: set them aside, since a newcomer has read neither. **Standard:** none — the test is its own.

**Test:** read as someone who has just cloned the program and has nothing but these docs. Where would they be stuck or misled — a step missing or out of order, a prerequisite used before it is stated, a passage dense enough to lose them? The docs say they are intentionally brief and send the reader to ask Claude for anything they don't cover: once a reader can launch Claude, a gap that asking fills is not a finding; a claim that misleads still is. Where you are confused, they would be too: your lack of the program is the point of the pass, so do not resolve a confusion by guessing what the program does.

## Residue

**Short name:** `residue`. **Class:** what the other passes do not cover — anything here contradicting anything else here. **Worklist:** none. **Reads:** `program`. **Standard:** none — the test is its own.

**Test:** read for contradictions between files that no other pass's class names. **Report at most five**, the ones you would most defend: this pass's output is the one expected to vary run to run, so volume here is noise.
