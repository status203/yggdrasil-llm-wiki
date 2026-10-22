---
role: instruction
pitch: The method for working on Yggdrasil itself — where a rule goes, how it is written, how it is grounded.
---

# Forge mode

Read in a forge session, when the work is the program rather than a wiki's content — its **mechanism**, which splits, where a rule needs it to, into **prose**, what an LLM reads and follows, and **code**, what executes. This file is the method. The settled decisions it applies live in `.yg/forge-catalog.md`, looked up when a question resurfaces rather than read now.

**Read the forge ledgers before changing the program.** A forge session's start line names them, from `forge.ledger_location`; they hold the decisions and open questions of work still in flight, which reach this file and the catalog only as that work settles.

## How the program reaches a wiki

- **The program is a plugin each wiki enables (`D3.1`), and its root is a wiki too, the forge wiki (`D4.1`).** Every program folder sits inside a dotfolder, with `.claude-plugin/plugin.json` pointing at it (`D4.1.1`): anything else at the root is a folder of the forge wiki. A new top-level dotfolder is un-ignored in the root `.gitignore`, which ignores every other one so Obsidian's config folder stays out whatever it is called (`F13.2`); left off, none of its files is ever committed.
- **Pick the file by who must follow the rule.** Every agent, Odin included: `.yg/wiki.md`, which the plugin's hooks hand to every session and dispatch. Odin alone: `.yg/output-styles/odin.md`. Forge sessions alone: `.claude/CLAUDE.md` or this file. Page writers: `.yg/page-contract.md`. (`D3.1.1`)
- **The session-start hook decides the kind and prints the program root** (`D4.1.2`). A wiki session hands forge work to a forge session.
- **Name the program root `${CLAUDE_PLUGIN_ROOT}` in a skill or agent definition and `<program>/` anywhere else read at runtime** (`D3.1.2`), except a forge-only flow, which names program files from the checkout it runs in and writes them as absolute paths in its dispatch briefs, and a forge-only agent, which names them from the checkout its brief gives. Wiki files are named from the wiki root, the session's project folder.
- **Of the vault, nothing outside the wiki folder is read or written** (`D3.2`), save the program's own folder, which `wiki-boundary.sh` never refuses should it sit inside the vault; the user config layer and a tool's cache are outside this rule because they sit outside the vault, as they usually do. How a script finds the wiki root is § *Scripts*'s.

## Where a rule goes

Four homes, sorted by what it takes to act on the rule rather than by what the rule is about. Check in order; the first that fits wins, because each is cheaper than the next where it fits, and 1 says where a script does not.

1. **Enumerable → a script.** The class can be listed and checked mechanically. Costs no context and cannot drift. Enumerable is not enough on its own: a rule for a rare path, stated in a line where it is acted on, stays prose, since a script, a mode or a hook branch costs more to keep than the prose's occasional miss (`D1.1`).
2. **Sited → a note where the mistake gets made.** One identifiable place gets it wrong; the warning goes there, and nowhere else.
3. **Shapes writing, and a session can act on it holding only the file it is editing → this file.**
4. **Detectable only across files or over time → the system review.** A contradiction between two files, a cross-reference to something deleted, a decision quietly re-litigated into its opposite.

Between 3 and 4, cost does not decide; 3's own test does. Reasoning and the rejected alternative are in `.yg/forge-catalog.md` § *Where an instruction lives*.

## How it is written

- **State the criterion once.** A second statement of it in the same file is redundancy, not emphasis. Wording aimed at another reader — a description's trigger phrasing, copy the user is shown — is not a second statement, since each changes for its own reader's sake. Nor is wording that a file read alone — a flow, an agent, a script's header — repeats from another file: it keeps its copy, though a copied fact or rule is still a drift risk (`D7.1`), and stays the duplication pass's.
- **Minimal is the default size.** Elaboration is justified per case, never assumed. A case the program already admits — a setting it ships, a path it supports — justifies it though no wiki has met it yet, where a gap would fail silently or cost something hard to put right; YAGNI rules out cases the program doesn't admit. Take the form that costs least unused, a key defaulting to today's behaviour before new machinery, and where owners reasonably differ, default safe and ask rather than build one answer in (`D2.1`).
- **The program doesn't have to be perfect.** A failure that is rare, shows itself, and is easy to fix when it happens gets no rule or guard (`D2.2`). A script failing at its own job is corrected instead, unless the fix is new mechanism for a rare path (`D1.1`).
- **Cost of expression follows how often the file is read** — an always-loaded file carries the crisp rule.
- **Don't hand-list what a search recovers.** Name the pattern instead.
- **No hard line breaks.** One line per paragraph and per list item; tables, code fences and frontmatter keep their own structure.

## How it is grounded

The record form is fact → consequence → decision. Collapsing them is what turns a settled record back into an argument.

- **A fact** is a falsifiable claim about the world — the harness, a tool, a cost. It carries the probe that would refute it, as the command where one exists, and what it was last checked against, in the record form `.yg/facts.md` states.
- **A consequence** is mechanism forced by one or more facts, and cites them. A second claim about the world is never a consequence of the first, however derived from it — that relation is nesting.
- **A decision** is what was chosen where more than one thing was possible, and it names what was ruled out: *do X, explicitly not Y, because Z*. A bare directive stays re-interpretable, and a later reading can land on the opposite.
- **A record sits under the record it narrows, and its id carries the place**: decisions nest as facts do, under group headings that are never cited, `.yg/facts.md` § *The four fields* giving the form. A ruling of an overgrown decision is an entry of its own. Moving a record renames it (`D24.1`).

What earns a record, for facts and decisions alike:

- **Instruction lives in the file that does the work, and its reason there only where the instruction cannot be followed well without it.** Every other reason goes in the catalog. A script's header comment is its working file. A rejected alternative goes there only where the ruled-out reading is the one its reader would take by default, a review's re-raise included, and only where narrowing the rule's own wording cannot rule that reading out (`D1.1.1.1`); one the narrowed wording rules out needs no record, and the rest stay in the catalog. The rejected alternatives are `D1.1.1`.
- **A ground is stated as it holds now.** A past observation is *previously observed*, its history left to git.
- **A question only whoever built the thing would ask earns no record.**

Two disciplines:

- **Ground a rule in evidence independent of it.** Corpus usage produced *by* the rule under review evidences compliance, not convergence. So does a test written in the same commit as the claim it grounds.
- **Probe a command written into prose, as well as a script.** Prose that encodes a command runs nowhere between authoring and shipping, and nothing downstream catches a wrong flag.

## Scripts

- **Portability is per tool, not per OS** (`F17.1`). Three userlands are live — Linux, macOS, WSL — and three implementations of the tools across them (`F17.1.1`). awk implementations diverge in ways the gawk-or-not split misses (`F18.1`), and macOS's is the floor (`F18.2`): what it rejects, don't write.
- **Run a probe from a file, not from a shell you issue yourself.** Claude Code shadows `grep` and `find` with `ugrep` and `bfs` inside its own Bash calls, so an in-session probe measures the wrong tool (`F9.4`).
- **A script takes the wiki root as its argument.** A hook passes `$CLAUDE_PROJECT_DIR`, which reaches a hook's environment and not a Bash call's (`F7.1`); a skill line passes `"$(git rev-parse --show-toplevel)"`, explicitly not `${CLAUDE_PROJECT_DIR}`, which stays on the launch folder after a mid-session `EnterWorktree` while Bash's working directory follows it (`F7.2`). The program and the files it ships are found from where the script sits.
- **A script carries its own small helpers — a loop over subjects, a grep, a date function —** so each runs on its own; a helper whose copies must agree is tested against the others instead.
- **A script that reads pages is tested over the wiki `fixture-awkward-wiki.sh` builds as well as its own, and a valid page in a shape found to break one reader is added there**, since a shape was previously observed found in one reader at a time and tested only where it was found. The fixture is shared by tests, which no wiki runs, so the rule above on a script's own helpers stands.
- **A git hook is the exception to running through `sh`**, since git runs it directly. An exec bit belongs to the checkout rather than the repository (`F22.1`), and git skips a hook without its bit and commits anyway (`F22.2`), so wiring `core.hooksPath` includes checking the bit.
- **After editing a script, run the tests of what depends on it.** A caller may read a script's output as well as rely on what it does — the pre-commit hook reads `check-leaks.sh`'s exit code — so an edit that changes either breaks the caller with nothing failing at the edit. A search of the program for the script's name finds them.
- **A script the user waits on, reading something that grows, is timed before it settles — when it is written, when an edit changes what it loops over, and when a new caller makes the user wait on it.** Waiting means a session-start hook, the after-write steps, anything run mid-turn, and not a review, which the user starts knowing it takes a while; count every run within one wait. Scale each input it loops over on its own, at several sizes up to several times today's largest wiki: the ratios show how it grows on any machine, the times whether the wait is acceptable. Look for where the time goes only when either looks bad. A comment line opening `Cost:` records the result, or why the script isn't timed.

## Destructive flows

**Order the steps by what can be undone.** Anything that removes history — re-initialising, amending, a hard reset, a force-push — runs last, after every other destructive step and every check that can stop the run. History is what a stop returns to, and a repository without it refuses the re-run as well, reporting every file as untracked (`F22.3`).

## Seams

**A seam's contract is closed in what it requires and open in what it carries** (`D20.1.3`). Each direction across it has an open part, settings and inputs going in and results coming out, where the receiver ignores a key it does not know and never fails on one; an implementation's settings are its own, `<seam>.<name>.*`, save a credential reference, which is keyed by the service it authenticates to (`D22.1.2`). Adding a key to an open part leaves the version where it is, and adding, changing or removing a requirement raises it. What only some implementations can do is a declared capability, and the contract says what the caller needs, never what one implementation does by default.

## Changes that alter how it operates

**Run `/yggdrasil:integration-review` before the change is done** when it reverses, amends or corrects the reason for a catalog decision; renames, removes or changes the behaviour of something shipped files rely on; or adds a new kind of file, state or per-session behaviour. A file resting on the old behaviour rarely names what changed, so a search for the name does not find it.

## Agents

**Writing or changing an agent: `.yg/agent-contract.md` first**, whoever is writing: Volund, dispatched (`D5.2`). Agents live in `.yg/agents/`, each listed by file in `plugin.json` (`F8.4`).

A wording fix or a single wrong fact in an agent is made directly: Volund declines it. Volund never dispatches its own output, so verifying a new agent falls to whoever asked for it. In a worktree the loaded program is another checkout (`D3.1.2`), so an agent written there runs only once the change reaches it.

The roster's design: Munin `D6.1`, `D6.1.1`; Hugin `D6.3`; Bragi `D7.1`; Mimir `D8.1`; Tyr `D14.2`, `D15.2`; Volund `D5.2`.

## Positions are the user's

`tooling.*` in `.yg/resolved/config.conf` records where the user stands on privacy, sovereignty, cost and cross-platform tooling. Read the namespace whole before recommending a tool or service for the program. Where a position excludes the best option, surface the trade-off and offer to revise the position — never route around one silently. Attribute it as theirs: *this runs against your sovereignty position*, not *this violates the principle*.

## Altitudes

Object-level flows and agents; the apparatus that builds them; the method the apparatus applies. A change at a higher altitude settles before lower work proceeds against it — don't move the measuring stick mid-measurement.
