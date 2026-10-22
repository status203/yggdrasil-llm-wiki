---
name: system-review
description: In a forge session, review Yggdrasil's program for drift across files — contradictions, dead references, reversed decisions, facts whose tool has moved, one person's fingerprint in a program file, usage docs that no longer match it or lose a newcomer — and write a findings ledger; fixes nothing. Use when the user asks for a system review or to check the program for drift, or invokes /yggdrasil:system-review. Not for one change mid-work, which is the integration review's, and not for other wiki pages, which are the content review's.
---

# System review

Finds the drift `.yg/forge-mode.md` § *Where a rule goes* sends to home 4. The scripts decide everything enumerable; dispatched passes judge the rest, each handed a finite worklist and a written test (`D16.1`, `D16.1.1`). The run writes a ledger and nothing else — fixing is a separate act, after it.

It runs in the checkout and names program files from there; in a wiki the missing scripts stop it (`D3.1.2`). Every path in a brief is absolute, under `"$(git rev-parse --show-toplevel)"`.

## 1. Run the scripts

No `.yg/bin/check-system.sh`, as in a wiki: say this is a forge-session review and stop. `git status --porcelain -- .yg .claude .claude-plugin .gitignore .gitattributes Docs` printing anything: the tree holds uncommitted work, which the reviewed commit can't account for — say so and stop, so it is committed or stashed first; program work mid-change is the integration review's.

`sh .yg/bin/check-system.sh`, then `sh .yg/bin/check-leaks.sh "$(git rev-parse --show-toplevel)"`, the leak check over the tree. Exit 0 and 1 both continue.

`check-system.sh`'s rows are three kinds: unprefixed rows are findings; `question:` rows are facts whose tool moved and which the script cannot re-check, and the one row saying Claude Code is past the harness review's checkpoint or has none (`D17.3`); `notice:` rows are signal that is not a defect — another tool moved, a decision nothing cites. Keep them apart. Every `check-leaks.sh` row is a finding: a value outside the technical well that reached the tree past the pre-commit hook.

## 2. Ask the drift question

A row saying Claude Code is not at the harness review's checkpoint, or that `facts.md` records none, is re-checked by running `/yggdrasil:harness-review` (`D17.3`); that run moves and commits the checkpoint itself, the one write to `facts.md` a re-check makes, and this ledger records its ledger's path or the decline. Where there are `question:` rows, ask about all of them **once**, as one grouped question — **not now** first (`F9.3`), then re-check all, then choose which.

A re-check runs the fact's probe, or asks the user to where it needs them. What it establishes goes to the ledger — the version it held at, or what changed — and not into `facts.md`, which is the fixer's. **A decline is recorded in the ledger as deliberately unverified at the installed version**, never left looking checked.

## 3. Dispatch the passes

Fetch a scratch folder with `mktemp -d` as its own step, then run `sh .yg/bin/check-system.sh briefs <folder>`. It writes one brief per pass in `references/passes.md` and prints their paths. Each brief holds the conduct block, the pass's section, its worklist, the files it reads and both scripts' rows, every path absolute; the newcomer read gets only the rows that name a `docs` file. Then dispatch every pass, all in one message, as `general-purpose` dispatches, each told to read its brief file first and do what it says.

## 4. Check what each pass walked

A pass returns the items it walked alongside its findings. **One that returns no walked list, or walks fewer items than it was given, is re-dispatched once** with the missing items; a dropped dispatch and an empty pass are otherwise the same observation (`F5.3`). A second shortfall goes in the ledger as a gap in coverage, named.

## 5. Triage

- **Merge** a finding raised by two passes into one, noting both.
- **Cross-reference the two facts passes.** A citation the files pass says a file does not need, which `worklist facts` lists the file as making, is a citation that is not load-bearing. A fact several files were nominated for and none cites is a silent fact — one strong finding, and the fact itself is probably wrong or its mechanism was never written.
- **Rank** by what goes wrong if it is left: corrupted content or an irreversible act first, a confidently wrong output next, drift that only costs reading last.
- **Drop nothing.** What triage would have dropped goes in its own section with the reason, including a finding that re-proposes an alternative the catalog, or the file holding the rule, ruled out — name the decision or the file — and every entry a pass returned under SETTLED, with the decision, file or guard it names.
- **Present** in rank order and stop where findings stop being plausible.

## 6. Write the ledger, then present from it

Run `sh .yg/bin/review-status.sh "$(git rev-parse --show-toplevel)" ledger system`. **`none`**: present from the session and write nothing — no ledger and no dispositions. **A refusal**: relay it and stop. **Otherwise** write the ledger at the path it printed.

The ledger holds, in order: the commit the run reviewed (`git rev-parse --short HEAD`) and both scripts' row counts; the drift question's outcome per fact, and for the Claude Code row; the findings in rank order; the would-have-dropped section; both scripts' rows verbatim; and what each pass walked, with a nil pass recorded as *none found*. A finding carries six fields —

- **id** — `<pass>/<file>#<anchor>`, `<pass>` the pass's name lowercased and hyphenated, `rule-homes` say; `<file>` from the checkout's root; the anchor a heading of a markdown file — its text lowercased, a leading step number such as `2.` dropped, every character but `a`–`z`, digits, spaces and hyphens dropped, each run of spaces or hyphens as one hyphen — or a fact or decision id the file holds, left off where the finding is the whole file or the file has no headings; never a label of your own or a line number, so the same drift found twice carries the same id; written in backticks first on the finding's bold opening line
- **class** — the pass's class
- **where** — file and section heading, or a fact or decision id, or the file alone where the finding is the whole file or it has no headings; never a line number
- **claim** — one sentence
- **evidence** — the two things that conflict, quoted, or the citation that resolves to nothing
- **test** — the written test it failed

— and three checks left unfilled for whoever fixes it: **premise** (is it still live, dated against commits since), **remedy** (does the replacement survive being tested as a claim, and what does it cost elsewhere), **siblings** (what else sits in the set this site belongs to). A finding of the first two ranks also carries **follows from**: the commit since the previous system ledger's reviewed commit whose diff added what its evidence rests on, or *none*, read from `git log -p <that commit>..<this one>`.

Then run `sh .yg/bin/review-status.sh "$(git rev-parse --show-toplevel)" marks <path>`. Correct each id it reports **invalid** in the ledger and run it again. Present the findings of the first two ranks from the ledger, so a fix worked later in a fresh context reads the same thing, each with its mark: **held** — a *not yet* raised again, shown and not walked; **promote** — a *not yet* raised twice since, walked for fix or ignore; **before** — how the same place was last dispositioned; **redesign** — a *before* on a place fixed three times or more since its last redesign (`D18.1.2`). The third rank is presented as its count, and the would-have-dropped section as one line, a count per decision, file or reason it was dropped on (`D16.1.1`); each is opened only when the user asks.

The ledger is never committed, wherever it lives.

## After the review

The first two ranks' findings are walked with the user, each fix **proposed and applied on a yes** — never applied and then reported. Each fix is proposed from the first of these that holds, naming which, with its net word change in prose, a script's code counted apart, one marked *redesign* below taking only the first or a redesign: **leave it**, since the failure is rare, shows itself and is easy to fix when met (`D2.2`), an *ignore* for this case alone, and for a script failing at its own job only where its fix would be new mechanism for a rare path (`D1.1`); **correct or delete in place**, adding nothing to prose, which in a script means making it do its job, whatever code that takes; **generalise**, where the finding is one of a set in this file or across files (its *siblings* check) and one rule covers the set and removes the copies it replaces; **add**, minimally, only then. **A finding that follows from a change is proposed against that change**: **finish** it, fixing what it missed; **rework** it, where the parts surfacing suggest an approach that would not have needed them; or **undo** it, where its original finding is one `D2.2` would leave — each with its net word change, and the one that fits recommended (`D16.5`). Then ask whether they want to see the third rank, and walk it only on a yes (`D16.4`). **A finding marked *redesign*, at any rank,** is a place patched three times and wrong again: propose redesigning it — its cases listed once, the states and what each leads to, as a table, or a script where they can be enumerated, or the section rewritten from what it is for — since a procedure patched per run was previously observed taking one more fix each run (`D18.1.2`). A fix is forge work, `.yg/forge-mode.md`'s. A structure finding's move is a rename: `sh .yg/bin/rename-ids.sh <map> <folder>`, the folder the one § 6 printed the ledger's path in, so the ledger and `system-review-dispositions.md` move with the ids (`D24.1.1`); with `none` there is nothing to hand it. Once fixes land, run `/yggdrasil:integration-review` over the walk, its base the reviewed commit: its readers and its `check-system.sh added` rows are what catch a fix's own breakage (`D16.5`).

An off-well example the user keeps is an agreed exception: the fix is the mark `.claude/CLAUDE.md` § *Privacy* gives, and its disposition is *ignore* with that reason (`D16.3`).

**An ignore whose reason is a rule that stands, rather than this run's judgment of one case, is also settled at that rule: its wording narrowed so the misreading no longer fits, else an *explicitly not* beside it** — in the file that holds it, or the catalog entry where it is a decision — so the next run's passes don't raise it again (`D1.1.1.1`). Propose the change with the ignore and write it on a yes, as forge work; an ignore for this case alone goes only in the record.

When the user dispositions a finding, append a line to `system-review-dispositions.md` beside the ledger, unless § 6 printed `none`, as `` - `<id>` — <disposition> — <date> — <reason> ``, the disposition fix, ignore, not yet, or redesign where the fix was one, and the date fetched with `date -u +%F` as its own step. Only `marks` reads it, and never to filter what a run reports (`D18.1`).
