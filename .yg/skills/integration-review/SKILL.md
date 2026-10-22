---
name: integration-review
description: In a forge session, check a change to how Yggdrasil operates against the rest of the program, mid-work — which files still describe what it replaced, cite what it removed, or need to say something new — and fix what the user accepts in the same change. Use when forge mode's change criteria call for it, when the pre-commit hook's integration-review notice names it, or when the user invokes /yggdrasil:integration-review. Not for the program as a whole, which is the system review's.
---

# Integration review

A change, read against the rest of the program while it is still open (`D19.1`). It runs in the checkout the change is in, and names program files from there: it checks the checkout its diff is in, and in a wiki the missing script stops it (`D3.1.2`). It finishes the change rather than recording on it: findings the user accepts are fixed in the same change, and nothing is written of the review's own.

## 1. The change

The base is `HEAD` — the uncommitted work — unless the user names one, or the pre-commit's integration-review notice fired on a commit already made, which names its base. A walk's worth of commits takes the commit before the walk. Fetch a scratch path, `<tmp>`, with `mktemp -d` as its own step.

- **The diff:** `git diff <base> -- .yg .claude .claude-plugin .gitignore .gitattributes`, and the untracked files `git ls-files --others --exclude-standard -- .yg .claude .claude-plugin .gitignore .gitattributes` lists, read whole. Those three folders are the program (`D4.1.1`), with the two root files that change how it behaves; the forge wiki's pages change nothing the program does, and are out — the usage docs too, which reader one reads against the change instead (`D16.2`). Nothing on either: say so, report the rows below, and stop. Otherwise save the diff to `<tmp>/diff`, for the readers to read.
- **The catalog entries it touches**, each read whole from `.yg/forge-catalog.md`.
- **The rows it added:** `sh .yg/bin/check-system.sh added <base>`, which runs the base's own copy in a throwaway worktree and prints only the rows since. A missing script, as in a wiki, stops the review: say so. The same goes for an empty `files` list in step 2.

## 2. Read

Dispatch two `yggdrasil:tyr`s in parallel, one per share of the prose (`D19.2`). Their items are:

- **one:** the paths `sh .yg/bin/check-system.sh files forge docs` prints;
- **two:** the paths `sh .yg/bin/check-system.sh files instruction agents flows` prints.

Mark in each list the files the diff itself changed; a changed file in neither list, such as a script, is marked into reader one's (`D19.2`). Every path in a brief is absolute, under `"$(git rev-parse --show-toplevel)"`: a reader's own `<program>` is the loaded plugin, which in a worktree is not the checkout the diff is in (`D3.1.2`). The rest of each brief is the same:

- **Standard** — the diff, by its file's absolute path, and the untracked files; a sentence saying what the change does; the catalog entries it touches; and `.yg/forge-mode.md`.
- **Test** — for each file, does it
  - **contradict** — state or assume the behaviour, or the reason, that the change replaced;
  - **dangle** — cite a name, path, id or step the change removed or renamed;
  - **lack** — need to say something new for the change to hold? That takes in the catalog, where the change makes a decision that neither a catalog entry nor the working file records with its rejected alternative.

  And for a file the diff changed, does a line it adds
  - **misstate** — say how another file, script or setting behaves, or cite a fact or decision, where what it names says otherwise? Read only what the line names, a fact or decision by its id.

  Where a changed flow hands off to another — a close that points at a skill, a script another reads — follow the hand-off into that file for every mode or path the change leaves, since a file can fit one of them and not another.

  Also search the rest of the mechanism — the paths `sh .yg/bin/check-system.sh files program` prints, listed in the brief since Tyr holds no shell (`D16.2`) — for the names the change removed or renamed **and the wording of any reason it replaced**, since a reason travels further than the behaviour it explains. A hit there is a finding on that file.
- **Already reported** — step 1's rows.
- **Finding fields** — **id** (`integration/<file>#<anchor>`, the anchor a section, fact or decision id, never a line number), **class** (contradict, misstate, dangle or lack), **where** (file and line), **claim** (one sentence), **evidence** (the least of the file's text and the diff that shows it), **edit** (the change proposed, as replacement text).

Check what came back: **Walked** short with nothing under **Not walked** or **Failed** to account for it — re-dispatch that reader once with the missing items. **Failed** — re-dispatch those once. **Brief incomplete** — fix and resend. A second shortfall, or a dispatch that did not return (`F5.3`), stops the run: say which files went unread, never that the change fits. **Noticed** goes to the user.

## 3. Merge and present

The two returns are one review. Where both propose the same new line for different files, keep the one where it most directly belongs and drop the other, since content lands in one place; where two edits overlap, make them one. Rank **contradict**, then **misstate**, then **dangle**, then **lack**. Present each finding with its edit, and step 1's rows beside them. The user answers per finding.

## 4. Fix

Apply each edit the user accepts. A finding the user declines **because the old text is meant to stand** is a decision: add it to the catalog entry the change touches, as its rejected alternative, or where it touches none, by narrowing the rule's wording in the file that holds it so the reading no longer fits, else as an *explicitly not* beside it, so the next review finds it settled. One declined for *not now* goes nowhere.

Then re-run `check-system.sh added <base>` and report what the change still adds. There is no second read.

## 5. Hand back

The forge work carries on to its commit, the fixes with it; with a committed base, they are a commit of their own.
