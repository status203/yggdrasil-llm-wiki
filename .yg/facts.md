---
role: instruction
pitch: Facts the system's mechanism branches on — what is true of the substrate, how it was checked, and what would make it worth checking again.
checkpoint: Claude Code @ 2.1.299 (2026-10-14)
---

# Facts

Looked up by id, not read start to finish. A rule that branches on a limit — a `cannot` or a `never` about the model, the harness, an external tool or the substrate — cites the id here, so the premise is auditable rather than buried in prose.

The `checkpoint:` above is the Claude Code version whose release notes `/yggdrasil:harness-review` last read the mechanism against, distinct from each entry's checkpoints, which say what one claim was probed at. A manual Claude Code entry is measured against it rather than against the installed version: its drift asks only that the harness review be run, and it is re-tested only where a harness review finding names it (`D17.3`).

A fact is a falsifiable claim about the world, and only that. Where we *chose* something, the record is a decision and lives in `.yg/forge-catalog.md`; where we built mechanism on top of a fact, that mechanism lives in the file that does the work. Nothing here holds a list of what reads it — the live set is whatever cites the id, recoverable with a search, and a hand-list goes stale silently while reading as complete.

**Don't mint** where a claim is re-probeable in one command and nothing would ever trigger a re-verification, and nobody would get it wrong: POSIX behaviour one command shows, this repository's own code — explicitly not what a POSIX edition leaves out, which no installed tool shows, since the userlands implement more than it (`F17.2`, `F17.3`). Record the non-mint in the entry that rests on it.

## The four fields

**Statement** — one falsifiable claim. Where an entry would carry two, it is two entries.

**Probe** — how the claim would be refuted. Four states, and they must stay distinguishable:

- a **command** — one command and nothing else, whose exit status is the verdict, so a script can re-run it unattended and drift is handled silently on a match and surfaced on a change; a command with prose around it needs a reader to say whether it held, and is handled as **manual**, explicitly not re-run;
- **manual —** followed by prose — probeable, but not by a script, so drift asks the user once whether to redo the check, save on a Claude Code entry, as above;
- **not probeable here —** followed by why — the platform or the event is out of reach, a stated limit rather than a gap;
- **unprobed** — nobody checked. A gap. Never tidy a bare entry into *not probeable here*: that asserts a limit which may not exist, and the two states never separate again.

**Checkpoints** — the **set** of versions the claim was checked at, never a range. A range asserts coverage across an interval the probes never established, and a reader interpolates from the notation alone. The form is `` `tool @ version` ``, comma-separated, with the date of the check in brackets after it; `@ unrecorded` where a check happened but the version was not written down, and `(on or before <date>)` where only a bound on the date is known. A claim resting on no versioned tool — the model's own behaviour — carries the bracketed date alone, and drift has nothing to compare. A re-check that matches **expands** the set; a re-check that differs **replaces** the claim and the set, and git carries the prior. The whole query a reader needs is *is the installed version in the set, and if not is it above the maximum*.

**Trigger** — what would make it worth re-checking. *None recorded* means the source stated none; it does not mean nothing would.

Nesting is structural. A group is a `##` heading whose id has one part, and is never cited; a fact is a heading one level below the group or fact it narrows, its id the parent's with a part added, as `F7.4.1` sits under `F7.4`. A fact narrows its parent when it is a case of it or an exception to it; two claims needing different evidence to refute are two entries, and one merely related to another is its sibling. Moving a fact renames it, with `sh .yg/bin/rename-ids.sh <map> [<path>…]`, never by hand (`D24.1`, `D24.1.1`).

The probes below marked *headless run* share one setup: `claude -p` in a throwaway wiki folder that is its own git repo, with a throwaway plugin loaded by `--plugin-dir`, both outside every other repo. Each claim was checked by planting a distinct canary token in one channel and asking the main session, and each kind of dispatch, which tokens it could see without reading a file.

## F1 — The model

### F1.1 — the same instruction over the same input can't be relied on to return the same result

**Statement.** Nothing in Claude Code or the Messages API pins a model's output: there is no seed, models released after Claude Opus 4.6 accept only a temperature of 1.0, and Anthropic's docs state that even a temperature of 0 is not fully deterministic. So a result that must be repeatable can't rest on a model producing it, however constrained the task; runs that agree show only that they agreed.

**Probe.** Manual — read Claude Code's CLI flags, settings, environment variables and agent frontmatter, and the Messages API's parameters, for a seed, temperature or determinism control, and the API glossary's temperature entry for its caveat that temperature 0 is not fully deterministic.

**Checkpoints.** `Claude Code @ 2.1.303` (2026-10-22), its docs and the API's read then, save part of the environment-variable table, which could not be fetched. Observed: F1.1.1's classification runs, verdicts differing on 7 of 65 (2026-09-08, 2026-09-09).

**Trigger.** A seed, temperature or determinism setting appearing in Claude Code or the API, which the harness review would raise.

#### F1.1.1 — an LLM sweep for a pattern is a sample, not an enumeration

**Statement.** An LLM pass searching text for instances of a pattern returns a sample of them: the same pass over identical text returns a substantially different set, so a pass that finds nothing is not evidence the pattern is absent. The variance sits mostly in what a pass chooses to raise, rather than in applying a written test to an item it is handed.

**Probe.** Manual — run the same pass twice over a byte-identical corpus and compare what each raised; separately, hand the same enumerated items and written test to independent runs and compare their verdicts.

**Checkpoints.** Two open sweeps over one corpus, 96 and 132 findings at about 40% overlap (2026-08-21); three classification runs over 65 enumerated entries, verdicts agreeing on 58 and discretionary lists overlapping about 50% (2026-09-08, 2026-09-09).

**Trigger.** A model generation change, or the system review's residue pass run twice, which re-measures it.

## F2 — Cost and context

### F2.1 — a turn re-sends the whole conversation

**Statement.** An in-session turn re-sends the entire accumulated conversation, so a session's token cost grows super-linearly with its length.

**Probe.** Unprobed.

**Checkpoints.** None.

**Trigger.** None recorded.

## F3 — Claude Code — what a session loads

### F3.1 — a definition's name and description are auto-loaded; its body is not

**Statement.** The harness loads every agent and skill definition's `name` and `description` into a session automatically, without any of them being invoked, and loads no more than that: the body arrives only on invocation.

**Probe.** Manual — in a session that has invoked no skill and dispatched no agent, read the harness's own agent-type and skill listings and check that each entry carries its description and none carries its body.

**Checkpoints.** `Claude Code @ 2.1.268` (2026-09-10); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

#### F3.1.1 — compaction drops the skill listing, and not the agent listing

**Statement.** After a compaction the harness sends the agent listing and the output style again, and not the skill listing, which `/reload-skills` sends again. A skill the listing dropped is still invoked by name. Whether auto-compaction drops it as a manual `/compact` does is unprobed.

**Probe.** Manual — `/compact` a session and look in its transcript, after the compaction boundary, for a `skill_listing` attachment beside the agent listing, and then for one after `/reload-skills`; and, with none re-sent, have the session invoke a skill its output style names, and look for the Skill call.

**Checkpoints.** `Claude Code @ 2.1.299` (2026-10-14) — three manual compactions, on 1M and 200K windows, and one session invoking wrap by name after two; auto-compaction never fired.

**Trigger.** A harness change.

#### F3.1.2 — a 200K-token window lists skills by name only

**Statement.** In a session on a 200K-token window, the skill listing carries each skill's name without its description; the agent listing keeps its descriptions.

**Probe.** Manual — read both listings in the transcript of a session on a 200K-window model.

**Checkpoints.** `Claude Code @ 2.1.299` (2026-10-14) — one session.

**Trigger.** A harness change.

### F3.2 — an `@`-import from outside the project loads only once the user approves it

**Statement.** An `@`-import in the project `CLAUDE.md` naming a file outside the project loads only after the user approves external imports for that folder. An interactive session asks once, defaulting to *No*, and saves the answer per folder, either way. Until it is approved the session sees the raw `@` line, and a headless session in a folder never approved does not load it. Once approved, the content reaches the main session and dispatches.

**Probe.** Manual — headless run with a canary in a file imported by absolute path from outside the project; then interactive sessions in a fresh folder, approving the dialog, with the main session and a dispatched plugin agent each asked for the canary.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-04, headless and interactive), `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or a design that leans on an external import in a headless session.

## F4 — Claude Code — what reaches a dispatch's context

### F4.1 — a named dispatch starts without the parent's conversation or session-start context

**Statement.** A dispatch of a named agent, plugin-defined or `general-purpose`, starts without the parent's conversation or session-start context. A fork dispatch differs: it inherits the parent's conversation up to, not including, the message that launches it.

**Probe.** Manual — in an interactive session, two dispatches launched in one message, a fork and a `general-purpose` agent, each asked without tools to quote any marker string and any session-start line in its context, say whether it sees earlier user turns, and print the UTC time.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-05); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

#### F4.1.1 — a `SessionStart` hook's `additionalContext` reaches no named dispatch

**Statement.** The `additionalContext` a `SessionStart` hook returns reaches the main session's context and no named dispatch's, plugin-defined or `general-purpose`. A fork dispatch inherits the parent's conversation, and that context with it.

**Probe.** Manual — headless run, with a canary in a plugin `SessionStart` hook's `additionalContext`. The fork half: in an interactive session, two dispatches launched in one message, a fork and a `general-purpose` agent, each asked without tools to quote any marker string and any session-start line in its context, say whether it sees earlier user turns and whether `AskUserQuestion` and `SendMessage` are in its tools, and print the UTC time.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.289` (2026-10-05), the fork against a `general-purpose` dispatch; `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

#### F4.1.2 — a `SessionStart` hook's plain stdout reaches no named dispatch, too

**Statement.** Plain stdout from a `SessionStart` hook's command reaches the main session's context, as a line prefixed `SessionStart:<source> hook success: `, and no named dispatch's, plugin-defined or `general-purpose`. A fork dispatch inherits the parent's conversation (`F4.1`).

**Probe.** Manual — a plugin `SessionStart` hook echoing a line; the main session asked to quote it, headless and interactive, then to dispatch a `general-purpose` subagent asked the same without tools.

**Checkpoints.** `Claude Code @ 2.1.287` (2026-10-01); `Claude Code @ 2.1.289` (2026-10-04), headless, the dispatch half; `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F4.2 — an appended system prompt reaches the main session only

**Statement.** Text given with `--append-system-prompt` reaches the main session and no dispatched subagent, whether plugin-defined or `general-purpose`. A fork dispatch is not probed.

**Probe.** Manual — headless run, with a canary in the appended prompt.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F4.3 — a plugin's forced output style reaches the main session only

**Statement.** An output style a plugin ships with `force-for-plugin: true` applies to the main session with no setting selecting it, and reaches no dispatched subagent, whether plugin-defined or `general-purpose`. The harness's documentation says the same of output styles in general. A fork dispatch is not probed.

**Probe.** Manual — headless run, with a canary in the body of a forced plugin output style.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09; the body now arrives as an `output_style_instructions` reminder in the first user turn, not in the system prompt, and the init event's `output_style` reads `default`).

**Trigger.** A harness change.

### F4.4 — a named dispatch inherits the project `CLAUDE.md`, and nothing it merely names

**Statement.** A named dispatch inherits the project `CLAUDE.md` in full, save a plugin agent that sets `omitClaudeMd` (`F4.4.1`), and none of the files it merely names: those reach it only if its definition or brief has it read them.

**Probe.** Unprobed — manual if taken: dispatch an agent and ask it to quote a line of `CLAUDE.md` and a line from a file `CLAUDE.md` only names, without reading either.

**Checkpoints.** None.

**Trigger.** A harness change.

#### F4.4.1 — `omitClaudeMd` keeps the user, project and local `CLAUDE.md` out of a plugin agent's context

**Statement.** A plugin agent whose definition sets `omitClaudeMd: true` receives neither the project `CLAUDE.md` with what it imports nor the user's own `~/.claude/CLAUDE.md`, nor a local one. A managed-policy `CLAUDE.md` still loads. Without the flag, a dispatched plugin agent receives the project and user files. The git-status snapshot reaches it either way.

**Probe.** Manual — headless runs in a scratch wiki whose `CLAUDE.md` imports `wiki.md`, the plugin agent dispatched with and without the flag and asked, without tools, whether it can see the `wiki.md` floors and the user's `CLAUDE.md` heading.

**Checkpoints.** `Claude Code @ 2.1.287` (2026-10-02); `Claude Code @ 2.1.289` (2026-10-04), the project and user `CLAUDE.md` and the snapshot; the managed-policy and local files from the 2.1.271 release note, not probed; `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F4.5 — a `SubagentStart` hook's `additionalContext` reaches the dispatched agent

**Statement.** The `additionalContext` a `SubagentStart` hook returns reaches the dispatched agent's context, plugin-defined and built-in agents alike, one setting `omitClaudeMd: true` included, in its first user turn after the brief, labelled `SubagentStart hook additional context:`.

**Probe.** Manual — headless run, a throwaway plugin whose `SubagentStart` hook returns a canary as `additionalContext`; a plugin agent and a built-in agent each dispatched and asked, without tools, to quote any marker string in their context. The `omitClaudeMd` half: in a scratch wiki made by `init.sh`, Munin, Bragi and Hugin dispatched together and asked, without tools, to quote the injected line and the first sentence of `wiki.md`'s credentials floor.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-05), both halves; `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

## F5 — Claude Code — running a dispatch

### F5.1 — a dispatch's working directory is the session's launch folder

**Statement.** A dispatched subagent's Bash calls start in the folder the session launched in, both for a plugin-defined agent and for `general-purpose`. Whether one dispatched after a mid-session `EnterWorktree` starts there or in the worktree is unprobed.

**Probe.** Manual — headless run, each dispatch reporting `pwd`.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F5.2 — a named dispatch cannot ask the user, and reaches the parent through its return

**Statement.** A dispatch of a named agent, plugin-defined or `general-purpose`, has no `AskUserQuestion` tool, so it cannot ask the user mid-run; it reaches the parent through its return. It does hold `SendMessage`, and the harness can resume a returned subagent by message. A fork dispatch differs: it holds `AskUserQuestion`.

**Probe.** Manual — in an interactive session, two dispatches launched in one message, a fork and a `general-purpose` agent, each asked without tools whether `AskUserQuestion` and `SendMessage` are in its tools, and to print the UTC time.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-05); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F5.3 — a dispatch is not guaranteed to return

**Statement.** A dispatch is not guaranteed to return: a dispatched subagent can drop, error, or come back with nothing usable, and the parent sees no distinct signal — an agent that ran and found nothing and an agent that never ran both arrive as an absent finding, so *the batch is done* is not inferable from the batch not having complained.

**Probe.** Unprobed — a drop cannot be induced on demand, so there is no run to make.

**Checkpoints.** None.

**Trigger.** A harness change.

### F5.4 — in an interactive session, dispatches run in the background and do not block the parent

**Statement.** In an interactive session, subagent dispatches run in the background: the dispatch returns at once, several launched in one message run in parallel, and the parent keeps working, taking each result as it arrives rather than halting at the dispatch. A headless `claude -p` run is not probed.

**Probe.** Manual — in an interactive session, two dispatches launched in one message, one sleeping 20 seconds, each printing the UTC time: both dispatch calls returned at once as background tasks, the parent ran a Bash call while both were running, and their finishing times overlapped it.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-05); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F5.5 — a file changed between a read and an edit: Edit applies over the change with a note, Write is refused

**Statement.** Where a file changes between a reader's Read and its Edit — by a parallel dispatch (`F5.4`), another Claude Code process, a shell write or a save from Obsidian — Edit applies its replacement to the file as it now is, and returns success with only a note that the file had been modified on disk since it was read: edits to separate text both land, and an edit whose old text still matches inside the other's new text lands inside it, leaving text neither writer meant, with no error. The change is noticed by its modification time: one that leaves the time as it was gets no note. Write is refused once a parallel dispatch has changed the file; Write after another process's change is not probed. Obsidian reloads an open page changed on disk; a change made while the user is typing is not probed.

**Probe.** Manual — in an interactive session, two `general-purpose` dispatches per case, launched in one message, each reading one scratch file, meeting at a file barrier so both reads precede both writes, then writing without re-reading: Edit on separate lines (`alpha`→`alpha-A`, `beta`→`beta-B`), Edit on one line (`alpha`→`alpha-A` and `alpha`→`alpha-B`), and Write of the file as read plus one line each. Results: `alpha-A` and `beta-B` with a changed-since-read note; `alpha-A-B` with no error; one Write landed and the other returned `File has been modified since read`. Manual — from one session, a scratch file per case, read and then changed from outside before an Edit `alpha`→`alpha-A`: a `sed` on another line, a `sed` on the same line, a headless `claude -p` Edit on another line, a `sed` issued straight after the Read, and a `sed` with the time put back by `touch -r`, beside a control with no change, and a page in the forge wiki with another line changed and saved in Obsidian. Results: the note on every case but the control and the restored time; `alpha-A-B` on the same line; Obsidian showed the edit without being reloaded by hand.

**Checkpoints.** `Claude Code @ 2.1.295` (2026-10-09); `Claude Code @ 2.1.303` (2026-10-22); `Obsidian @ 1.14.4` (2026-10-22).

**Trigger.** A harness change, or a write that lands as text no writer meant.

### F5.6 — a dispatch can dispatch in turn

**Statement.** A dispatched `general-purpose` subagent carries the Agent tool and can dispatch a subagent of its own, which returns to it rather than to the session. Whether a named agent can depends on whether its definition lists the tool.

**Probe.** Manual — dispatch a `general-purpose` agent asked to list its tools, dispatch one `general-purpose` agent that replies with a single word, and report what came back.

**Checkpoints.** `Claude Code @ 2.1.280` (2026-09-22) — one nested dispatch, launched in the background, which returned; `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or a design that leans on a dispatch fanning out.

#### F5.6.1 — a dispatch that ends its turn to wait on its own background child hands back early

**Statement.** A dispatch whose child runs in the background, and which ends its turn to wait for it, has that waiting line delivered to the session as its final report. Its later hand-back is refused as already delivered, so the child's real result reaches the session only if the dispatch sends it by `SendMessage`.

**Probe.** Manual — dispatch a `general-purpose` agent asked to dispatch a background `general-purpose` child that replies with one word, wait for it, and report the word; read what the session receives, and when.

**Checkpoints.** `Claude Code @ 2.1.295` (2026-10-09), one observation.

**Trigger.** A harness change, or a design that leans on a dispatch fanning out.

## F6 — Claude Code — an agent's definition

### F6.1 — a plugin agent's `tools:` list is honoured

**Statement.** A plugin agent whose frontmatter lists `tools:` is dispatched with exactly those tools.

**Probe.** Manual — headless run, an agent declaring `tools: Bash, Read` reporting its tool names.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

#### F6.1.1 — per-agent memory grants an agent Read, Write and Edit

**Statement.** A plugin agent whose definition sets `memory:` gains Read, Write and Edit whatever its `tools:` declares, and they reach any project file, not only its memory folder.

**Probe.** Manual — headless run, two plugin agents declaring only `WebSearch`, one with `memory: project`, each asked to read an existing project file and create a new one; the one with memory listed Read, Write and Edit, read the file and wrote the new one, and the other had WebSearch alone.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-04); `Claude Code @ 2.1.295` (2026-10-09, accept-edits mode).

**Trigger.** A harness change, or an agent definition that sets `memory:`.

### F6.2 — a tier pin binds in both directions

**Statement.** A tier pin binds absolutely in both directions: it lifts an agent above a cheaper session model *and* caps it below a richer one. There is no floor-only primitive — `inherit` is not one either, since it takes whatever the session runs — so any floor is bought together with a ceiling.

**Probe.** Unprobed — refuting it needs a dispatch under a session model richer than the pin, observed uncapped.

**Checkpoints.** None.

**Trigger.** A model-roster change.

## F7 — Claude Code — where the `CLAUDE_*` paths reach

### F7.1 — `CLAUDE_PROJECT_DIR` reaches a hook, not a Bash tool call

**Statement.** Claude Code exports `CLAUDE_PROJECT_DIR` into a hook command's environment and does not export it into Bash tool calls.

**Probe.** `printenv CLAUDE_PROJECT_DIR` from a hook command, against the same from a Bash tool call.

**Checkpoints.** `Claude Code @ 2.1.226` (2026-08-10), `Claude Code @ 2.1.286` (2026-10-01), the second from a plugin hook and from Bash calls in the main session and in dispatches; `Claude Code @ 2.1.289` (2026-10-04), the same; `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F7.2 — `CLAUDE_PROJECT_DIR` names the launch folder, which `claude -w` makes the worktree

**Statement.** `CLAUDE_PROJECT_DIR`, in a hook's environment and in skill text, names the folder the session launched in. Under `claude -w` that is the new worktree. A mid-session `EnterWorktree` moves the Bash working directory into the worktree and leaves the variable on the launch folder.

**Probe.** Manual — two headless runs in a wiki repo, one launched with `claude -w` and one calling `EnterWorktree` first, each logging the variable from a `SessionStart` hook and reporting `pwd` and a skill's `${CLAUDE_PROJECT_DIR}`.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F7.3 — `CLAUDE_PLUGIN_ROOT` reaches a hook, not a Bash tool call

**Statement.** A plugin hook's environment carries `CLAUDE_PLUGIN_ROOT`, naming the plugin's folder, and a Bash tool call's does not, in the main session or a dispatch.

**Probe.** Manual — headless run, a plugin `SessionStart` hook logging the variable, against `printenv` from Bash calls.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F7.4 — a plugin skill or agent body has the plugin and project paths substituted

**Statement.** `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` written in the body of a plugin skill or a plugin agent are replaced by absolute paths when it loads: the plugin's folder, and the folder the session launched in.

**Probe.** Manual — headless run, a skill and an agent each asked to repeat both references literally.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

#### F7.4.1 — and not in a plugin output style or a project `CLAUDE.md`

**Statement.** Written in a plugin output style's body, or in a project's `.claude/CLAUDE.md`, `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` reach the model as literal text, unexpanded.

**Probe.** Manual — headless run, a plugin with a forced output style and a project `CLAUDE.md`, each carrying a line with both references; the main session asked to quote both lines.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-04); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

## F8 — Claude Code — loading a plugin

### F8.1 — once the machine knows the marketplace, a path-free `enabledPlugins` line is enough

**Statement.** With the marketplace in the user's plugin config (`~/.claude/plugins/known_marketplaces.json`), a project `.claude/settings.json` holding only `"enabledPlugins": {"<plugin>@<marketplace>": true}`, with no `extraKnownMarketplaces` entry and no path, loads the plugin, even headless in a folder never trusted. Neither the user's settings nor the project's name the marketplace's folder.

**Probe.** Manual — two fresh scratch folders, each a git repo with a `.yg/config.conf`, one with that settings line and one with `{}`; `claude -p` in each asked for the plugin's `SessionStart` line and whether its agents are available, and `.yg/resolved/` checked. The first had both and a resolved config; the control had neither.

**Checkpoints.** `Claude Code @ 2.1.288` (2026-10-03); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F8.2 — an `enabledPlugins` entry for a marketplace the machine doesn't know is skipped silently

**Statement.** A project settings line enabling `<plugin>@<marketplace>` where the machine has registered no such marketplace is skipped with nothing said to the model, nothing in a headless run's output and nothing in `claude plugin list`; the only trace is a debug-log line, `Skipping orphaned enabledPlugins entry …: marketplace not registered`. An interactive startup is unprobed.

**Probe.** Manual — headless run with debug logging in a scratch folder whose `.claude/settings.json` holds only that line, on a machine without the marketplace; the session asked whether a plugin's session-start line is in context, then the debug log and `claude plugin list` read.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-05); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or a report that a wiki opened without the program said nothing.

### F8.3 — `/reload-plugins` picks up a plugin file edited in place

**Statement.** After a plugin skill's file is edited on disk mid-session, `/reload-plugins` makes the next invocation of that skill use the edited body, with the plugin loaded by `--plugin-dir`. Without the reload, the next invocation still used the old body.

**Probe.** Manual — interactive session, a skill invoked, a line added to its file, the skill invoked again and the old body returned, then `/reload-plugins`, the skill invoked a third time and the new line returned.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.289` (2026-10-04), both halves, interactive; `Claude Code @ 2.1.295` (2026-10-09, interactive, `--plugin-dir`).

**Trigger.** A harness change.

### F8.4 — a plugin's components load from paths inside a dotfolder

**Statement.** `.claude-plugin/plugin.json` may point `hooks` and `outputStyles` at paths inside a dotfolder (`./.yg/hooks/hooks.json`, `./.yg/output-styles/`), and both load from there: the hooks run and a forced style applies. `agents` loads from there too, but only as a list of `.md` files: a folder path fails validation ("must end with `.md`"), and under `--plugin-dir` the whole plugin is then missing from the session, not just its agents. `skills` loads from a folder path there (`./.yg/skills/`), each skill in its own subfolder.

**Probe.** Manual — headless run on a copy of the program, with no `hooks/` folder at its root, the session asked for its `SessionStart` line, the role its output style gives it, the agent types it has, and the `yggdrasil:` skills it has; `claude plugin validate .` for the folder form of `agents`.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-04, the folder form drops the whole plugin from the init plugin list), `Claude Code @ 2.1.287` (2026-10-02); `Claude Code @ 2.1.295` (2026-10-09, the folder form fails validation and the whole plugin goes missing).

**Trigger.** A harness change.

### F8.5 — plugin agents and skills are named with the plugin's prefix

**Statement.** A plugin's agents and skills are listed and dispatched as `<plugin>:<name>`, where `<plugin>` is the manifest's `name`.

**Probe.** Manual — headless run, the main session listing the agent and skill names it sees.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F8.6 — a folder loaded with `--plugin-dir` is a protected path, so a session whose project is that folder cannot use Write or Edit in auto mode

**Statement.** The docs say Claude Code hot-reloads a plugin loaded with `--plugin-dir` when a file in it changes, and treat the folder as a protected path for that reason, which allow rules can't pre-approve; an edited skill body, though, was not picked up before `/reload-plugins` (`F8.3`). Where the project folder is that root, Write and Edit on any project file are refused in auto mode with "the server-side auto mode classifier gave no verdict", and in accept-edits mode ask for permission as edits to "a sensitive file". An `Edit(...)` allow rule does not lift it, nor do `--add-dir .`, `additionalDirectories`, or loading the plugin through a symlink. The same write succeeds in that folder with no plugin loaded, and into the plugin's folder from a session whose project is elsewhere. Bash is judged as usual.

**Probe.** Manual — headless `claude -p` runs on a copy of the program asking for one Write: auto mode without and with `--plugin-dir` (relative and absolute), with an `Edit` allow rule, with `--add-dir .`, with `additionalDirectories` and allow rules in `--settings`, through a symlinked plugin path, in accept-edits mode, and from another project folder targeting the plugin's folder. The cause is the docs' *Create a mod* page ("A directory you load with `--plugin-dir` is a protected path"), read 2026-10-02.

**Checkpoints.** `Claude Code @ 2.1.287` (2026-10-02); `Claude Code @ 2.1.289` (2026-10-04), the auto-mode refusal and its no-plugin control only, the variants not re-run; `Claude Code @ 2.1.295` (2026-10-09, the refusal, its control and the allow-rule, `--add-dir`, accept-edits and other-project variants; `additionalDirectories` and the symlinked path not re-run).

**Trigger.** A harness change, or a forge session where Write succeeds.

### F8.7 — a folder installed from a directory marketplace is not protected, and loads in place

**Statement.** With the folder registered as a directory marketplace and its plugin installed at local scope (`claude plugin marketplace add <folder> --scope local`, then `claude plugin install <plugin>@<marketplace> --scope local`, which write `.claude/settings.local.json`), and no `--plugin-dir`, a session whose project is that folder can Write and Edit any file in it in auto mode. The install copies the folder into the plugin cache and records it in `installed_plugins.json`, but the session still runs the folder's own files: its hooks run from there, and an uncommitted change to an agent's description shows in the next session. Changes don't hot-reload; they reach a session at its start or at `/reload-plugins`. The same holds registered at user level and enabled only by the project's path-free `enabledPlugins` line (`F8.1`), with no local-scope install.

**Probe.** Manual — on a copy of the program: a headless Write and an Edit to `.yg/agents/munin.md` in auto mode; the session-start hook's printed program root; an agent description changed on disk without committing, quoted back by a fresh session; and a Bragi dispatch writing a new `Test bed/` page, regenerating its index and passing `check-vault.sh`. The user-level half: in the program checkout itself, with no `settings.local.json`, a headless auto-mode Write and Edit of a scratch file at the root, and the session-start line read back as `forge`.

**Checkpoints.** `Claude Code @ 2.1.287` (2026-10-02); `Claude Code @ 2.1.289` (2026-10-05), the user-level half.

**Trigger.** A harness change, or a forge session where Write is refused.

## F9 — Claude Code — the built-in tools

### F9.1 — `WebFetch` returns a long page in parts

**Statement.** A `WebFetch` return covers at most 100,000 characters of a page: a longer one comes back with a note giving the page's length and the characters the answer covers, and the tool takes an `offset` to read on. The return is a second model's answer about the page. Once, a page on Anthropic's own documentation domain came back verbatim instead; a later fetch from the same domain did not reproduce it, so whether some pages skip the summarising pass is open.

**Probe.** Manual — `WebFetch` a page over 100,000 characters, such as a long page of Claude Code's own documentation, with a prompt asking for a one-sentence answer: read the parts note, check whether the one sentence or the whole page came back, and fetch again with the note's `offset`.

**Checkpoints.** `Claude Code @ 2.1.295` (2026-10-09), a 160,149-character docs page: the parts note and `offset` held, and the answer was one sentence, not the page.

**Trigger.** A harness change, or a return that contradicts it.

### F9.2 — a foreground Bash call that outlasts its timeout moves to the background

**Statement.** A Bash call's timeout defaults to 120,000 ms and can be set up to 600,000 ms. In the main session, a foreground call that outlasts its timeout is not killed: it moves to the background, runs to completion with its output written to a file, and the session is notified when it ends. Whether a dispatch or a headless `claude -p` run does the same is unprobed.

**Probe.** Manual — in a session, run `sh -c "sleep 8; touch <scratch>/done"` with a 3,000 ms timeout and check that `<scratch>/done` appears; read the default and maximum from the Bash tool's description.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-05, main session, auto mode); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or a flow leaning on a long call in a dispatch or a headless run.

### F9.3 — Enter takes the first option in a question

**Statement.** `AskUserQuestion` has no default field, and in the Claude Code terminal pressing Enter selects the first option. So a flow controls what an accidental keystroke picks by the order of its options and in no other way.

**Probe.** Manual — ask a question and press Enter in the terminal. Observable only there: a session sees the selection, never the keystroke, and a non-terminal client may behave differently.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-04, Enter with the cursor unmoved took the first option), `Claude Code @ unrecorded` (2026-09-05); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or use from an IDE or web client.

### F9.4 — Claude Code shadows `grep` and `find` inside its own Bash sessions

**Statement.** Claude Code installs shell *functions* shadowing `grep` and `find` in its own Bash sessions, to `ugrep` and `bfs`, so an in-session `--version` reports the wrong tool where `sh -c '…'` and every script on disk get the GNU one.

**Probe.** `sh -c 'grep --version'` and `sh -c 'find --version'` compared with the same commands run inside a Bash tool call.

**Checkpoints.** `bfs @ 4.1.1` in-session against `GNU findutils @ 4.10.0` under `sh -c` (2026-08-29, re-confirmed 2026-09-08); re-confirmed with `bfs @ 4.1.1`, `GNU findutils @ 4.10.0` (2026-10-09).

**Trigger.** A harness change.

## F10 — Claude Code — session and dispatch start hooks

### F10.1 — a `SessionStart` hook's context reaches the model again after resume, clear and compaction

**Statement.** A synchronous `SessionStart` hook with no matcher fires on `resume`, `clear` and `compact` as well as `startup`, and its context reaches the model each time; after compaction it lands after the compaction boundary. An async one's context, unchanged since it was last added, is not added again on resume.

**Probe.** Manual — a throwaway plugin whose `SessionStart` hook logs its source and returns a canary; headless runs resumed and compacted, the session asked for the canary each time. The `clear` half was seen interactively.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-05); the async case from the 2.1.295 release note, not probed; `Claude Code @ 2.1.295` (2026-10-09, resume, compact and clear; the async case still not probed).

**Trigger.** A harness change.

### F10.2 — a `SessionStart` hook's output is shown to the user at `startup`, not at `clear`

**Statement.** A `SessionStart` hook that prints JSON with a top-level `systemMessage` has it shown to the user on a `startup` session start, as `SessionStart:startup says: <message>`, in the terminal and in the session's transcript when it is opened with `/rc` in the desktop app's Code tab. On a `clear` session start nothing the hook emits is shown: neither the `systemMessage` nor stderr from an exit 2. At `startup` an exit 2's stderr is shown, but as `SessionStart:startup hook error` followed by the hook's command and the message. The harness's documentation does not say what `SessionStart` does with `systemMessage`, and says an exit 2's stderr is shown to the user without telling sources apart.

**Probe.** Manual — a plugin with three `SessionStart` hooks: a `{"systemMessage": "<marker>"}` on the matcher `startup|clear`, and an exit 2 with a stderr marker on each of `startup` and `clear`; start an interactive session and look, `/clear` and look again, then open the session with `/rc` in the Code tab and look. A headless run cannot show it: there the message only comes back as the hook's raw output.

**Checkpoints.** `Claude Code @ 2.1.283` (2026-09-26), from a `settings.local.json` hook on `startup` only; `Claude Code @ 2.1.289` (2026-10-04), a plugin hook on `startup` and `clear`, exit 2 included, in the terminal; the Code tab not rechecked; `Claude Code @ 2.1.295` (2026-10-09, the terminal at startup and after `/clear`; the Code tab not rechecked).

**Trigger.** A harness change.

### F10.3 — a `SessionStart` hook's `systemMessage` is not given to the model

**Statement.** On a `startup` or a `clear` session start, a `SessionStart` hook's `systemMessage` does not reach the model's context, where the same hook event's plain stdout does (`F4.1.2`).

**Probe.** Manual — headless run, with a canary in a plugin hook's `systemMessage` and a control canary in another hook's plain stdout; for `clear`, `--input-format stream-json` sending `/clear` before the question. The main session quotes the control and not the canary.

**Checkpoints.** `Claude Code @ 2.1.283` (2026-09-26), interactive, a `settings.local.json` hook on `startup`; `Claude Code @ 2.1.289` (2026-10-04), headless, a plugin hook on `startup` and on `clear`; `Claude Code @ 2.1.295` (2026-10-09, headless at startup and at `clear`).

**Trigger.** A harness change.

### F10.4 — a dispatch fires `SubagentStart`, not `SessionStart`

**Statement.** Dispatching a subagent fires the `SubagentStart` hook event, carrying the agent's type, and does not fire `SessionStart` again.

**Probe.** Manual — headless run, a plugin logging every `SessionStart` and `SubagentStart` invocation across two dispatches.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

## F11 — Claude Code — tool-call hooks

### F11.1 — a plugin `PreToolUse` hook can refuse a `Write`

**Statement.** A plugin `PreToolUse` hook matched on `Write|Edit` that returns `permissionDecision: "deny"` stops the write, and the model is shown the hook's reason.

**Probe.** Manual — headless run, a hook denying any `file_path` under `CLAUDE_PLUGIN_ROOT`, and a `Write` aimed there; the file was not created.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F11.2 — a `PreToolUse` refusal stops a Bash call too

**Statement.** A plugin `PreToolUse` hook matched on `Bash` that returns `permissionDecision: "deny"` stops the command: it does not run, and the model is shown the hook's reason.

**Probe.** Manual — headless run, a hook denying any Bash command carrying a marker, and a marked `echo ok > <file>`; the file was not created.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-04); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change.

### F11.3 — a `PreToolUse` hook fires on a dispatched agent's tool calls too, and its refusal holds there

**Statement.** A plugin `PreToolUse` hook runs for every tool call a dispatched agent makes, whether the agent is the plugin's own or a built-in one, and a `deny` refuses the call inside the dispatch just as in the main session. The payload then carries `agent_id` and `agent_type` (the plugin-prefixed name for a plugin agent), and `permission_mode`.

**Probe.** Manual — headless run, a plugin hook logging every call and denying `Read` of one file, the main session dispatching a plugin agent and then `general-purpose` to read it; both were refused with the hook's reason, and the log showed each agent's `Read` calls under its own `agent_type`.

**Checkpoints.** `Claude Code @ 2.1.288` (2026-10-03); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or a design that relies on a hook to fence what an agent can touch.

### F11.4 — the `PreToolUse` payload carries each tool's arguments as flat strings

**Statement.** The `PreToolUse` payload carries `cwd` and `tool_name` at the top level and the call's own arguments inside `tool_input`, as unescaped strings a flat extraction reaches: `file_path` for Read, Write and Edit, absolute; `pattern` and `path` for Glob and Grep, the pattern as the model wrote it; `command` for Bash, verbatim; `notebook_path` for NotebookEdit, absolute. No MultiEdit tool exists, so a matcher naming it matches nothing.

**Probe.** Manual — headless run, a plugin hook matched on `Read|Write|Edit|Glob|Grep|Bash` logging each payload, and one call of each tool. NotebookEdit and MultiEdit: the session's own tool definitions, read with `ToolSearch`.

**Checkpoints.** `Claude Code @ 2.1.289` (2026-10-04); `Claude Code @ 2.1.295` (2026-10-09). `Claude Code @ 2.1.296` (2026-10-10), NotebookEdit and MultiEdit from the tool definitions only: NotebookEdit's input schema names `notebook_path` as an absolute path, and no MultiEdit tool is defined; no payload logged. `Claude Code @ 2.1.303` (2026-10-21), Write and Edit from the tool definitions only: each names `file_path` as an absolute path; `tool_name` unprobed, no payload logged.

**Trigger.** A harness change, or a hook reading a key this does not list.

### F11.5 — `PostToolUse` fires per tool call and gates on the tool name

**Statement.** `PostToolUse` fires per tool call and its `matcher` gates on the tool name, so a file changed by any route other than a matched tool — through Bash, or by an application outside the session — produces no event a `Write|Edit` matcher can see.

**Probe.** Manual — read the `PostToolUse` payload and its matcher selector out of the installed bundle: the payload carries `tool_name` and the matcher is selected from it, so nothing in the event exposes a non-tool write.

**Checkpoints.** `Claude Code @ 2.1.247` (2026-08-27); `Claude Code @ 2.1.295` (2026-10-09, end to end; the bundle not read).

**Trigger.** A harness change.

### F11.6 — the `PostToolUse` payload shape

**Statement.** The `PostToolUse` payload delivers `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `tool_name`, `tool_input`, `tool_response` and `tool_use_id`, plus optional `prompt_id` and `duration_ms`, and `permission_mode`; at `Claude Code @ 2.1.295`, also a top-level `effort` object such as `{"level":"medium"}`, which `PreToolUse` carries too; `file_path` is not a top-level field but arrives nested inside `tool_input`, absolute on a Write or an Edit, and the values are unescaped strings reachable by a flat extraction that knows nothing of JSON nesting. A Write that names its path under the alias `path`, relative, reaches both the `PreToolUse` and `PostToolUse` payloads as `file_path`, absolute; `filePath`, `file` and `filename` are refused before any hook fires.

**Probe.** Manual — read the payload schema out of the installed bundle, and end-to-end: a real Write to a decoy config path outside the checkout, checking that the hook parses `file_path`, takes its absolute branch, and derives the right root.

**Checkpoints.** `Claude Code @ 2.1.247` (2026-08-27); `Claude Code @ 2.1.289` (2026-10-04), the fields end to end, `permission_mode` new; the bundle-schema read and the decoy-config check not redone. `Claude Code @ 2.1.289` (2026-10-05), the alias: a headless run told to Write under `path`, `filePath`, `file` and `filename`, with `PreToolUse` and `PostToolUse` hooks logging their payloads and the transcript confirming what the model sent; `Claude Code @ 2.1.295` (2026-10-09), the fields and the alias end to end, `effort` new; the decoy-config root derivation approximated.

**Trigger.** A harness change.

## F12 — Claude Code — permissions

### F12.1 — a `Read` deny rule also refuses Bash reads of that path

**Statement.** A `Read(<path>/**)` deny rule in project settings refuses the `Read` tool on that path and also Bash `cat` and `head` of a file there, even with Bash allowed outright. Bash reads of an undenied file outside the project succeed under the same settings.

**Probe.** Manual — headless run with Bash in `--allowedTools`, reading a denied file three ways, and an undenied file outside the project as the control.

**Checkpoints.** `Claude Code @ 2.1.286` (2026-10-01); `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or a design that leans on a deny rule to keep a folder out of context.

### F12.2 — auto mode lets a session read and write outside its project without asking

**Statement.** In auto mode, with no allow or deny rules, a session reads and writes files in a sibling folder of its project, through the `Read` and `Write` tools and through Bash `cat` and `echo >`, with no prompt and no refusal, in a headless run and an interactive session alike; the ask-once prompt before a first outside read, in the 2.1.257 release notes, did not appear. Being outside the project does not by itself fence a folder off. A write that reaches the outside folder through a symlink inside the project is refused, though: `Write` through a symlinked directory and `Edit` through a symlinked file, judged by where the write lands rather than its in-project path (the 2.1.280 changelog, which says auto mode "no longer approve[s] one landing outside"); a read through the same symlinks succeeds.

**Probe.** Manual — headless run in auto mode from a project folder beside a sibling folder holding one file, asking for those four calls on the sibling; all succeeded and both files were created. Run twice, with the folders under the system temp area and under the home folder, with the same result. Interactive: a fresh session in a real external wiki, in auto mode, asked to `Read` a file in a sibling folder under the home folder, `Write` a file there and `cat` the first in Bash; the user watched for a prompt. Symlinks: the headless run with user settings skipped (`--setting-sources project`), the project a git repo holding a symlink to the sibling folder and one to a file in it, adding a `Write` through the first, an `Edit` through the second and a `Read` through the first, the files on disk checked after.

**Checkpoints.** `Claude Code @ 2.1.288` (2026-10-03); `Claude Code @ 2.1.289` (2026-10-05), interactive, reads only: in real external-wiki sessions in auto mode, the main session and its dispatches read the program's page contract, outside the project, through `Read` with no prompt and no refusal (transcripts, and the user saw none). `Claude Code @ 2.1.289` (2026-10-05), interactive, the sibling folder: all three calls succeeded with no prompt, the write marked allowed by the auto-mode classifier. `Claude Code @ 2.1.295` (2026-10-09), headless, under the system temp area and under the home folder, with the symlink calls: the four direct calls succeeded with no prompt, both symlinked writes were refused and left the files unchanged, and the symlinked read succeeded.

**Trigger.** A harness change, or a design that leans on the project boundary to keep a folder out of reach.

#### F12.2.1 — `permissions.blockReadsOutsideWorkingDirectories` fences every read outside the working directories, the plugin's own folder included, and no write

**Statement.** In auto mode with the setting on, every read outside the working directories is refused in a headless run, through `Read`, Bash `cat` and a script run by path, by the main session and a dispatched agent alike. A plugin loaded from outside the project is refused along with everything else, until its folder is listed in `additionalDirectories`. Writes outside the working directories still pass, into a folder whose reads are refused. Which outside folder it is makes no difference: the setting has no notion of a vault. Whether an interactive session prompts rather than refusing is unprobed; the changelog speaks of a prompt (2.1.257, 2.1.284).

**Probe.** Manual — headless run with the setting in `--settings`, in a wiki folder beside a sibling inside a scratch vault, the plugin by `--plugin-dir` outside the vault, asking for a `Read`, a `sh <plugin>/bin/x.sh` and a `cat` of a plugin file, a `Read` and a `cat` of a sibling file, a `Read` of a file outside the vault, a plugin agent's `Read` of the plugin file, and a `Write` into the sibling. Three runs: the setting off as the control, on, and on with the plugin's folder in `additionalDirectories`.

**Checkpoints.** `Claude Code @ 2.1.295` (2026-10-09).

**Trigger.** A harness change, or a design that leans on the setting to fence a folder.

## F13 — Obsidian — dotfolders and config

### F13.1 — Obsidian ignores a dotfolder entirely, and *Excluded files* does not hide a folder

**Statement.** A folder whose name starts with `.` is neither shown in Obsidian's file explorer nor indexed. The *Excluded files* setting hides matching files from search, the graph and unlinked mentions and demotes them in the quick switcher and link suggestions, but leaves them in the file explorer. No built-in setting hides a folder whose name does not start with `.`.

**Probe.** Unprobed in the app. Obsidian staff state the dotfolder behaviour as deliberate on the forum, and the help's Settings page lists what *Excluded files* hides without the file explorer.

**Checkpoints.** None.

**Trigger.** A materially different Obsidian.

#### F13.1.1 — a wikilink does not resolve into a dotfolder

**Statement.** Obsidian keeps dotfolders off the vault graph: a wikilink does not resolve into one, so nothing under `.sources/` is reachable as `[[…]]`.

**Probe.** Unprobed.

**Checkpoints.** None.

**Trigger.** A materially different Obsidian.

### F13.2 — a vault's config folder can be renamed

**Statement.** Obsidian's *Override config folder* setting, under Settings → Files and links, gives a vault a config folder other than `.obsidian`, under any name starting with a dot, and Obsidian writes the same files there, `app.json` among them. The old `.obsidian/` is left where it was, so a vault so set may hold both.

**Probe.** Manual — set *Override config folder* on a vault, then list its top-level dot folders and what each holds.

**Checkpoints.** `Obsidian @ 1.14.4` (2026-10-11, set to `.obsidian-moved`, which then held `app.json`, `appearance.json`, `core-plugins.json` and `workspace.json`, beside the old `.obsidian/`).

**Trigger.** A materially different Obsidian.

## F14 — Obsidian — links

### F14.1 — a wikilink resolves against any trailing path suffix

**Statement.** Obsidian resolves a `[[wikilink]]` against any trailing path suffix of a page's vault-relative path: a page at `Cooking/Bread/Sourdough` is reachable as `Sourdough`, `Bread/Sourdough` or the full path. A bare basename is the degenerate case of that rule, not the rule.

**Probe.** Manual — write a cross-subject partial link (`[[Bread/Sourdough]]` from a page under a different subject) and confirm it opens the right page. That is the one shape that discriminates: neither basename matching nor resolution relative to the source page's folder can reach it.

**Checkpoints.** `Obsidian @ 1.13.4` (2026-08-24); `Obsidian @ 1.13.7` (2026-10-04), a cross-folder partial-path link on a probe page; `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** A materially different Obsidian.

#### F14.1.1 — same-folder wins on ambiguity, then the shortest vault-relative path

**Statement.** Where pages share a suffix, a same-folder candidate wins: a bare link written from the folder holding one of them opens that one, whatever else exists. With no same-folder candidate the **shortest vault-relative path** wins, and neither creation nor modification order has any bearing. It is not alphabetical in either direction, not the nearest candidate before or after the linking page in path order, not the oldest or newest by either birth or modification time, and does not walk up the tree — a link from a subfolder does not prefer its own parent subject. What counts as shortest is **character length among candidates at equal depth**; whether depth or characters decides between candidates at different depths, and what breaks a tie in length, are unprobed.

**Probe.** Manual, and it takes three rounds, because no one round separates shortest-path from path order and from recency together. Round one: two subjects, one alphabetically first *and* shorter, each holding a page of the same title, linked bare from a subfolder of the other — it lands in the short one, which kills walking up the tree. Round two: four subjects holding the title, named so that alphabetically-first, nearest-preceding, nearest-following and shortest are four *different* subjects, linked from a fifth between them — it lands in the shortest. A same-folder copy alongside confirms the first rule still overrides. Round three separates shortest-path from recency, which rounds one and two cannot: write the short-path candidate first, leave real time, then write a long-path one, and link from a neutral subject — it lands in the short one. **Build round three deliberately, because recency is the easy confound to introduce by accident:** rewriting a probe file, as renaming its subject will, resets its mtime, and the first two rounds both happened to leave the shortest candidate also the most recently written.

**Checkpoints.** `Obsidian @ 1.13.7` (2026-09-12); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** A materially different Obsidian.

### F14.2 — a wikilink target matches with or without `.md`, and in any letter case

**Statement.** `[[Sourdough.md]]` and `[[Sourdough]]` are the same link, path-qualified or not, and a target differing from the page's name only in letter case, `[[sourdough]]`, resolves to it too. Both halves are probed, a path-qualified link aside. Which page a bare link opens where two names differ only in case is reported as unpredictable, in forum reports and a 2024 bug report of Obsidian's own link updater rewriting a case-variant link on a move, and is not probed.

**Probe.** Manual — on a test page, link `[[<Page>]]`, `[[<Page>.md]]`, `[[<page in lower case>]]` and `[[<PAGE IN UPPER CASE>.md]]` to an existing page; check that each opens it and that it lists all four as backlinks.

**Checkpoints.** `Obsidian @ 1.14.4` (2026-10-11, the four bare forms; path-qualified forms and case-only twins not probed).

**Trigger.** A materially different Obsidian.

### F14.3 — the editor writes a link bare or absolute, never subject-qualified

**Statement.** Obsidian's *New link format* (`newLinkFormat` in `app.json`) has exactly three values, and none writes a subject-qualified link. `absolute` emits the full vault-relative path; `relative` a `../`-prefixed path from the source file; `shortest` the bare basename where it is unambiguous and the full vault path where it is not — never an intermediate suffix. Where the wiki sits as a folder inside a larger vault, as probed, pages sit at `<folder>/<Subject>/<Page>`, so every qualified form the editor writes carries the folder as a leading segment. Autocomplete separately appends `|<basename>` as a display alias whenever the inserted linktext for a non-image file contains a `/`. Where the vault is the wiki root itself, as for the forge wiki, `absolute` emits `<Subject>/<Page>`, so there the absolute form is subject-qualified: the claim that no value writes one holds, as probed, for a wiki that sits as a folder inside a larger vault.

**Probe.** Manual — read the `newLinkFormat` option enum, `fileToLinktext` and the autocomplete alias branch out of the installed app bundle.

**Checkpoints.** `Obsidian @ 1.13.7` (2026-08-26); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** A materially different Obsidian.

### F14.4 — a rename updates links on a prompt, and only *Always update* persists

**Statement.** *Automatically update internal links* (`alwaysUpdateLinks` in `app.json`) is off by default. With it on, renaming or moving a file rewrites the links to it without asking. With it off, a rename that has links to update opens a prompt with three answers: *Always update* updates them and turns the setting on; *Just once* updates them; *Do not update*, or dismissing the prompt, leaves them and stores nothing, so the next rename asks again. A rename with no links to update asks nothing.

**Probe.** Manual — read the `alwaysUpdateLinks` default, `updateAllLinks` and its prompt's three buttons out of the installed app bundle.

**Checkpoints.** `Obsidian @ 1.14.4` (2026-10-19).

**Trigger.** A materially different Obsidian.

## F15 — Obsidian — frontmatter

### F15.1 — a frontmatter value breaking strict YAML fails to parse or loses content

**Statement.** Obsidian parses frontmatter as strict YAML, and a bad value breaks it in one of two ways. It **fails to parse** when it contains `: ` (colon-space) or ends with `:`, leads with `,` `[` `]` `{` `}` `*` `!` `%` `@` or `` ` ``, leads with `-` or `?` and a space, leads with `|` or `>` with text on the same line, or opens a quote it never closes. It **parses but loses content** when it contains ` #` (space-hash), which cuts the value off at the comment, or leads with `#`, which leaves it empty, or `&`, which takes its first word as an anchor name: a one-word value is left empty, and a longer one loses its first word. A value leading with `-`, `?` or `:` directly followed by text parses as written, as do a closed quoted scalar and a bare `|` or `>` opening a block scalar.

**Probe.** Manual in Obsidian — one page per shape, each with a second, valid key, read in the Properties panel. Or `python3` with PyYAML as Obsidian's proxy: `yaml.safe_load('k: ' + v + '\nz: 1\n')` for each shape `v`, a failure being an exception and a loss a value other than `v`.

**Checkpoints.** `Obsidian @ 1.14.4` (2026-10-09, one page per shape: colon-space and inline `>` lost the block, ` #` cut the value at the comment, leading `#` left it empty, `&anchor value` showed `value`, `-x` read as written), `PyYAML @ 6.0.3` (2026-10-09, agreeing; 2026-10-11, a trailing colon failing and a closed quoted scalar holding `: ` or ` #` read whole, neither yet checked in Obsidian).

**Trigger.** None recorded.

#### F15.1.1 — a parse failure costs the whole property block

**Statement.** A strict-YAML parse failure makes Obsidian reject the *whole* property block: the Properties panel is gone and the raw frontmatter shows as red text, with no message naming the failure, so one bad value costs the page every field it has.

**Probe.** Manual — open a page whose frontmatter fails strict YAML, with a second, valid key beside the bad one, and read the page in Obsidian.

**Checkpoints.** `Obsidian @ 1.13.7` (2026-10-05, a colon-space value and an inline `>` value each removed the panel; the valid key went with it); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** None recorded.

### F15.2 — frontmatter is read only between two lines of exactly `---`

**Statement.** Obsidian reads a page's frontmatter only where its first line and the line closing the block are each exactly `---`: a trailing space on either costs the page every property, with no Properties panel and the block shown as text.

**Probe.** Manual — two pages in a test subject, one opening `--- ` with a trailing space and one closing with it, each read in Obsidian.

**Checkpoints.** `Obsidian @ 1.14.4` (2026-10-19, the opener rendered as a rule with the keys as body text; the closer left the block as raw text).

**Trigger.** A materially different Obsidian.

### F15.3 — frontmatter keys differing only in case are one property

**Statement.** Obsidian treats frontmatter keys that differ only in case, `Pitch:` and `pitch:`, as one property: each page shows its own spelling, and the *All properties* view lists one row counting both.

**Probe.** Manual — two pages in a test subject, one with `pitch:` and one with `Pitch:`; check whether the *All properties* view lists one property or two, and what it counts.

**Checkpoints.** `Obsidian @ 1.13.7` (2026-10-05, one `pitch` row whose count took in the `Pitch:` page); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** None recorded.

## F16 — Obsidian — rendering

### F16.1 — an HTML comment is invisible in Obsidian's Reading view and stays in the file

**Statement.** An HTML comment is dropped entirely from Obsidian's rendered Reading view while remaining in the file. It spans lines freely, and everything inside it — markdown, blank lines, code fences — is dropped unparsed rather than half-rendered. It is visible in editing view. Obsidian's native `%%…%%` hides in both views but is Obsidian-proprietary, so a file carrying it stops being portable markdown.

**Probe.** Manual — put a multi-line HTML comment holding markdown and a code fence into a page, then open that page in Reading view and in editing view.

**Checkpoints.** `Obsidian @ unrecorded` (on or before 2026-09-08); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** An Obsidian major or minor release; any change to how it renders raw HTML.

### F16.2 — an unescaped `|` in a table cell is a column break

**Statement.** Obsidian's markdown-table parser reads an unescaped `|` inside a cell as a column break and silently drops the overflow: in a two-column table a cell written `a | b` renders as `a` alone, with `b` absent rather than moved into a third column. The rule reaches a wikilink's alias separator — `[[Page|Alias]]` in a cell renders as the literal text `[[Page`, not a link and with the alias lost, while `[[Page\|Alias]]` renders as a working link displaying `Alias`. Outside a table the backslash is absorbed and both forms render identically.

**Probe.** Manual — render all seven pipe cases in reading view: free text escaped and unescaped; a wikilink in a cell escaped, unescaped and bare; the same link escaped and unescaped outside a table.

**Checkpoints.** `Obsidian @ 1.13.7` (2026-10-04, overflow still dropped; the stray empty trailing column seen at 1.13.4 no longer renders), `Obsidian @ 1.13.4` (2026-08-26); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** A materially different Obsidian.

### F16.3 — Obsidian renders diagrams natively and statically

**Statement.** Obsidian renders a Mermaid fence and inline SVG natively in Reading view, and renders them statically: nothing in a rendered diagram animates or runs, including animation elements that survive sanitization.

**Probe.** Manual — open a page carrying a Mermaid fence and an inline SVG holding an `<animateTransform>` in Reading view, and watch whether anything moves.

**Checkpoints.** `Obsidian @ 1.12.7`, `Obsidian @ 1.13.7` (2026-09-08); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** A materially different Obsidian.

### F16.4 — the note sanitizer forbids `<style>`

**Statement.** Obsidian sanitizes a note's inline HTML and SVG with DOMPurify and adds `<style>` to what it forbids, so a `<style>` element is stripped and class-based styling inside an SVG renders unstyled, while presentation attributes and the `style=` attribute survive.

**Probe.** `grep -a -o 'FORBID_TAGS:\[[^]]*\]'` over the installed app bundle, `obsidian.asar`, in the install's `app/resources/` folder, expecting `FORBID_TAGS:["style"]`.

**Checkpoints.** `Obsidian @ 1.12.7`, `Obsidian @ 1.13.7` (2026-09-15); `Obsidian @ 1.14.4` (2026-10-09, `FORBID_TAGS:["style"]` in the bundle).

**Trigger.** A materially different Obsidian.

### F16.5 — two inline SVGs sharing an internal id resolve it to the first definition

**Statement.** Where two inline SVGs on one page define the same internal id — a gradient referenced by `url(#…)`, say — at `Obsidian @ 1.12.7` neither painted, not only the second, while the same pair with distinct ids rendered correctly. At `Obsidian @ 1.13.7` both paint. At `Obsidian @ 1.14.4`, where the two definitions differ, the id resolves to the first on the page, so the second diagram wears the first's styling with nothing to say so.

**Probe.** Manual — one page, two SVGs each defining `<linearGradient id="cg">` with different colours and filling with `url(#cg)`; then the same pair with `cg-a` and `cg-b`. Compare in Reading view, noting which colours the second diagram shows.

**Checkpoints.** `Obsidian @ 1.12.7` (on or before 2026-09-08); `Obsidian @ 1.13.7` (2026-10-04), the same pair, on a probe page; `Obsidian @ 1.14.4` (2026-10-09, two differing definitions: the second diagram took the first's).

**Trigger.** A materially different Obsidian.

### F16.6 — a link to a standalone `.html` file opens the system browser

**Statement.** Obsidian core does not render a standalone `.html` file: a link to one opens it in the system browser, outside the note sanitizer, where scripts and animation run.

**Probe.** Manual — link a self-contained `.html` file beside a page by relative path and follow the link from Reading view.

**Checkpoints.** `Obsidian @ 1.12.7` (on or before 2026-09-08); `Obsidian @ 1.14.4` (2026-10-09).

**Trigger.** A materially different Obsidian.

## F17 — Shell and userland — portability

### F17.1 — a flag is portable per tool, not per OS

**Statement.** A coreutils, findutils or grep flag is portable per **tool**, not per OS: the same command name resolves to a different implementation depending on platform *and* distribution, and a flag present in one is regularly absent from — or means something else in — another.

**Probe.** Unprobed as a general claim; it is carried by its children, and no single run refutes it.

**Checkpoints.** None.

**Trigger.** A distribution change or a coreutils swap.

#### F17.1.1 — three implementations are live, and packaging is per-tool

**Statement.** Three implementations are live across Yggdrasil's targets: GNU, the BSD userland macOS ships, and uutils (the Rust reimplementation, Ubuntu's coreutils default since 25.10). On Ubuntu 25.10 `sort`, `date`, `mktemp`, `cut` and `basename` are uutils while `sed`, `grep`, `find`/`xargs` and `gawk` are GNU — so packaging is per-tool, and *Linux* no longer implies GNU coreutils.

**Probe.** Manual — from a script on disk, never in a session, where Claude Code shadows `grep` and `find` (`F9.4`): `for t in sort date mktemp cut basename sed grep find xargs gawk; do sh -c "$t --version" | head -1; done`. The BSD instance is **not probeable here**: there is no macOS in reach, so read a specific BSD claim as re-checkable rather than settled.

**Checkpoints.** `Ubuntu @ 25.10`, `uutils coreutils @ 0.2.2`, `GNU findutils @ 4.10.0`, `sed @ 4.9`, `grep @ 3.11`, `gawk @ 5.3.2` (2026-08-29).

**Trigger.** A distribution change or a coreutils swap.

##### F17.1.1.1 — uutils `date` ignores `-u` beside `-r`

**Statement.** uutils `date -u -r <file>` prints the file's modification time in the local zone: `-u` has no effect when `-r` is given. So a UTC date from a file's mtime cannot come from `date -r` on such a machine.

**Probe.** `f=$(mktemp) && touch -d @1577838600 "$f" && d=$(TZ=America/Los_Angeles date -u -r "$f" +%F); rm -f "$f"; [ "$d" = 2019-12-31 ]`

**Checkpoints.** `uutils coreutils @ 0.2.2` (2026-09-28).

**Trigger.** A distribution change or a coreutils swap.

### F17.2 — POSIX `find` has no `-maxdepth`, `-mindepth` or `-quit`, its 2024 edition included

**Statement.** None of `-maxdepth`, `-mindepth` and `-quit` is a primary of POSIX `find`, POSIX.1-2024 (Issue 8) included, though GNU findutils, the BSDs, macOS and BusyBox all implement `-maxdepth`. A portable script stays out of a subtree with `-prune`, and skips the levels above one by starting `find` below them.

**Probe.** Manual — read the `find` page of POSIX.1-2024's Shell and Utilities volume for the primaries it lists. `-mindepth` was last found absent from a summary of the page, explicitly not its raw text.

**Checkpoints.** Read against POSIX.1-2024, a standard with no installed version to compare (2026-10-11).

**Trigger.** A new POSIX edition.

### F17.3 — POSIX `readlink` has no `-f`

**Statement.** POSIX.1-2024 (Issue 8) is the first edition to specify a `readlink` utility, and its one option is `-n`: `-f` was left out on purpose, with a new `realpath` utility specified in its place. Earlier editions have neither utility, so a script that must run on them resolves a symlink by hand.

**Probe.** Manual — read the `readlink` and `realpath` pages of POSIX.1-2024's Shell and Utilities volume, their synopses and rationale.

**Checkpoints.** Read against POSIX.1-2024, a standard with no installed version to compare (2026-10-11).

**Trigger.** A new POSIX edition.

## F18 — awk

### F18.1 — awk implementations diverge on features and on escaping

**Statement.** awk implementations diverge on language features, and the split is **not** gawk-versus-the-rest.

**Probe.** Unprobed as a general claim; it is carried by its children.

**Checkpoints.** None.

**Trigger.** None recorded.

#### F18.1.1 — `ENDFILE` is gawk-only and its absence is silent

**Statement.** `ENDFILE` is gawk-only, and its absence is silent: mawk and busybox awk parse the bare word as an uninitialised variable, so the rule never matches and both exit 0 with no output and no diagnostic — a per-file hook that simply never runs, reading downstream as a file with nothing in it.

**Probe.** `for a in gawk mawk busybox-awk; do "$a" 'ENDFILE{print "fired"}' f1 f2; done` and check for output.

**Checkpoints.** `gawk @ 5.3.2`, `mawk @ 1.3.4 20250131`, `busybox awk @ 1.37.0` (2026-09-04).

**Trigger.** None recorded.

#### F18.1.2 — a backslash in a `gsub` replacement comes out differently in each awk

**Statement.** The same backslashes in a `gsub` replacement string give three different results. A replacement written `"\\\\"` doubles a backslash in gawk and mawk and leaves it single in busybox awk; written `"\\\\\\\\"`, it gives two in gawk and busybox and four in mawk. So escaping by `gsub` is not portable, and a character-by-character copy is.

**Probe.** `for a in gawk mawk 'busybox awk'; do printf 'a\\b\n' | $a '{ s = $0; gsub(/\\/, "\\\\", s); print s }'; done` prints `a\\b`, `a\\b`, `a\b`.

**Checkpoints.** `gawk @ 5.3.2`, `mawk @ 1.3.4 20250131`, `busybox awk @ 1.37.0` (2026-10-09).

**Trigger.** None recorded.

### F18.2 — the awk macOS ships is the real floor

**Statement.** The awk that actually constrains this corpus is the one macOS ships — a 2007 one-true-awk predating POSIX character classes, `nextfile` and NUL `RS`.

**Probe.** Not probeable here — no macOS in reach.

**Checkpoints.** None.

**Trigger.** A macOS coming into reach, or a change in what macOS ships.

## F19 — Text outside ASCII, by locale

### F19.1 — uutils `sort` ignores `LC_COLLATE`

**Statement.** uutils `sort` ignores `LC_COLLATE` entirely and always collates by byte, so an unpinned `sort` behaves exactly like an `LC_ALL=C`-pinned one on such a machine; GNU `sort` 9.5 does not — the same input under a UTF-8 locale reorders, and that output then fails an `LC_ALL=C sort -c` check. `sort -u` drops no distinct rows under either, so the hazard is order, not loss.

**Probe.** `printf 'apple pie\nApple-pie\n'` sorted under a UTF-8 locale `locale -a` lists, such as `LC_ALL=en_US.utf8`, by each implementation, then checked with `LC_ALL=C sort -c`. A locale that is not installed falls back to C collation, and the probe then shows nothing.

**Checkpoints.** `uutils coreutils @ 0.2.2`, `GNU coreutils @ 9.5`, `Ubuntu @ 25.10` (2026-08-31); `uutils coreutils @ 0.2.2`, `GNU coreutils @ 9.5` (2026-10-09, GNU installed as `gnusort`).

**Trigger.** A distribution change or a coreutils swap.

### F19.2 — gawk counts characters where mawk and busybox awk count bytes

**Statement.** In a UTF-8 locale, gawk's `index()`, `length()` and `substr()` count characters, while mawk and busybox awk count bytes. So a position or length is only meaningful to the awk that measured it, and a separator holding a multibyte character, such as an em dash, has a different length in each.

**Probe.** `for a in gawk mawk 'busybox awk'; do echo 'a — b' | LC_ALL=C.UTF-8 $a '{ print index($0, "b"), length(" — ") }'; done` prints `5 3`, `7 5`, `7 5`.

**Checkpoints.** `gawk @ 5.3.2`, `mawk @ 1.3.4 20250131`, `busybox awk @ 1.37.0` (2026-10-09).

**Trigger.** None recorded.

### F19.3 — only gawk and GNU grep, in a UTF-8 locale, fold the case of a letter outside ASCII

**Statement.** `tolower()` and `toupper()` fold a letter outside ASCII, such as `É`, only in gawk under a UTF-8 locale. mawk and busybox awk leave it as it is in any locale, and so does gawk under the C locale. `grep -i` splits the same way: GNU grep folds it under a UTF-8 locale and not under C, and busybox grep does not fold it at all. So a match made "in any letter case" is case-blind for ASCII everywhere, and for other letters only where the tool and the locale meet, each tool on its own: gawk folding says nothing of the grep beside it. A fold can land in ASCII: gawk lowers `İ` to `i` and the Kelvin sign to `k`, so a slug that lowercases before keeping `[a-z0-9]` keeps a letter there that it hyphenates under C.

**Probe.** Manual — from a file, since a session's `grep` is another tool (`F9.4`): `for a in gawk mawk 'busybox awk'; do printf '\303\211clair\n' | LC_ALL=C.UTF-8 $a '{ print tolower($0) }'; done` prints `éclair`, `Éclair`, `Éclair`; `printf '\303\211clair\n' | LC_ALL=C gawk '{ print tolower($0) }'` prints `Éclair`. `for g in grep 'busybox grep'; do printf '\303\251clair\n' | LC_ALL=C.UTF-8 $g -ciF "$(printf '\303\211clair')"; done` prints `1`, `0`; GNU grep under `LC_ALL=C` prints `0`. `printf '\304\260stanbul \342\204\252elvin\n' | LC_ALL=C.UTF-8 gawk '{ print tolower($0) }'` prints `istanbul kelvin`; mawk, busybox awk, and gawk under `LC_ALL=C`, print it unchanged.

**Checkpoints.** `gawk @ 5.3.2`, `mawk @ 1.3.4 20250131`, `busybox awk @ 1.37.0` (2026-10-11); `grep @ 3.11`, `busybox grep @ 1.37.0` (2026-10-11).

**Trigger.** None recorded.

### F19.4 — GNU sed's `[a-z]` takes in accented letters under a language locale

**Statement.** Under a language locale such as `en_US.UTF-8`, GNU sed's bracket range `[a-z]` matches accented letters such as `è`; under `C` and `C.UTF-8` it matches ASCII only. So a range means ASCII only where the locale is pinned.

**Probe.** `for l in en_US.UTF-8 C.UTF-8 C; do printf 'crème\n' | LC_ALL=$l sed 's/[^a-z0-9][^a-z0-9]*/-/g'; done` prints `crème`, `cr-me`, `cr-me`. A locale that is not installed falls back to C, and the probe then shows nothing.

**Checkpoints.** `sed @ 4.9` (2026-10-16).

**Trigger.** None recorded.

## F20 — whisper.cpp

### F20.1 — `whisper-cli` accepts or refuses an input by its (container, codec) pair, never by its extension

**Statement.** `whisper-cli` decides whether it can read an input from the container and codec it actually finds, and never consults the filename. The same codec is taken in one container and refused in another — vorbis is read in Ogg and refused in Matroska — and bytes that are MP4/AAC are refused whatever they are named, including `.wav`. So no extension test and no container allowlist is sound, and unconditional normalisation is the only cheap answer.

**Probe.** `ffmpeg -f lavfi -i "sine=f=300:r=44100:d=3" -ac 1 a.wav`, then the same audio as `-c:a libvorbis` into `.ogg` and into `-f matroska`, and as `-c:a aac` into `.m4a` copied to `mislabelled.wav`; run `whisper-cli -np -m <model> -osrt -of p -f <each>` and test for `p.srt`. The Ogg writes an SRT; the Matroska, the MP4 and the mislabelled copy each write none, all at rc=0.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54` (2026-09-22).

**Trigger.** A whisper.cpp upgrade, above all one adding its own demuxing.

### F20.2 — `whisper-cli` exits 0 having written no SRT, in four distinct ways

**Statement.** rc=0 from `whisper-cli` does not mean a transcript was produced. It exits 0 having written nothing when the input is one it cannot decode, when `-of` names a directory that does not exist, when it is given an argument it does not recognise, and when `-l` names a language code it does not know — the last two because it prints its usage and stops. A code it does not know includes a region-qualified one such as `en-US`: it knows only its own bare codes and language names, in either case, and `auto`. A caller reading the exit status alone cannot tell any of the four from success, so the post-condition has to be a test on the output file.

**Probe.** Manual — with `<model>` a real model and `a.wav` real audio: `whisper-cli -np -m <model> -osrt -of p -f bad.m4a`, `… -of nodir/p -f a.wav`, `… --no-such-flag -of q -f a.wav`, and `… -l en-US -of r -f a.wav`. All four print rc=0 and leave no `.srt`.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54` (2026-09-22; the `-l` case 2026-10-09).

**Trigger.** A whisper.cpp upgrade, or a new flag being passed to it.

### F20.3 — without VAD a recording carrying no speech yields a fabricated transcript; with VAD it yields nothing

**Statement.** Given a readable input holding no speech, `whisper-cli` without VAD exits 0 and writes a short plausible sentence that was never spoken — 45 bytes from six seconds of digital silence. The same input with VAD on exits 0 and writes a zero-byte SRT. No size test catches the first, because the file is not empty; the difference between the two is the whole reason VAD is not optional here. The fabricated text is model-dependent, so the exact output is not part of the claim — only that non-empty plausible output is produced. **Its limit:** VAD has been seen to cost words. On a synthetic file of 213 butt-joined identical sentences it lost words, which did not reproduce on real speech — nine minutes of it came out improved, with hallucinated and repeated sentences removed. Whether a real hour-long recording loses words is unmeasured, the measurement declined by the user rather than missed: an issue to fix if it arises.

**Probe.** `ffmpeg -f lavfi -i "anullsrc=r=16000:cl=mono" -t 6 silence.wav`, then `whisper-cli -np -m <model> -osrt -of s1 -f silence.wav` and the same with `--vad -vm <vad-model> -of s2`. `s1.srt` is 45 bytes; `s2.srt` is 0.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54`, model `large-v3-turbo` (2026-09-22).

**Trigger.** A whisper.cpp upgrade, or a change to `transcribe.whisper.model`.

### F20.4 — a VAD model `whisper-cli` cannot load fails loudly

**Statement.** Where the VAD model cannot be loaded at all, `whisper-cli` says so and stops: rc=10 when the file is absent, when it is not a model at all, and when it is truncated far enough to damage its header. A file of the wrong type — a speech model passed as the VAD model — aborts instead at rc=134 on a `GGML_ASSERT` in `ggml.c`.

**Probe.** `whisper-cli -np -m <model> --vad -vm <file> -osrt -of o -f a.wav` with `<file>` in turn absent, a text file, `head -c 40000` of the real VAD model, and the speech model itself. The first three give rc=10; the last gives rc=134.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54` (2026-09-22).

**Trigger.** A whisper.cpp upgrade.

#### F20.4.1 — a VAD model truncated only in its tail loads at rc=0 and degrades quality silently

**Statement.** Narrowing `F20.4`: a VAD model missing only its tail still loads. At 800000 of 885098 bytes it runs at rc=0, still filters a speechless input to a zero-byte SRT, and still transcribes real speech — but transcribes less of it, 457 bytes against the intact model's 558 over the same twenty seconds. So the residual quiet failure costs transcript content and does **not** reach the guarantee that a speechless recording produces no transcript. An existence test on the model file cannot see this; nothing short of a checksum can.

**Probe.** `head -c 800000 <vad-model> > trunc.bin`, then run `whisper-cli -np -m <model> --vad -vm trunc.bin` against six seconds of silence and against twenty seconds of speech, comparing SRT sizes with the intact model.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54`, model `large-v3-turbo` (2026-09-22).

**Trigger.** A whisper.cpp upgrade, or a VAD model reaching a machine by any route other than the atomic fetch in `.yg/engines/transcribe/whisper.sh`.

### F20.5 — `whisper-cli` exits 3 when the speech model cannot be loaded

**Statement.** Given a `-m` file that is not a loadable speech model, `whisper-cli` prints `failed to initialize whisper context`, writes no SRT and exits 3 — a number low enough to collide with a caller's own statuses, so a caller passing it through reads a corrupt or truncated model as whatever its own 3 means.

**Probe.** `printf 'not a model\n' > fake.bin`, then `whisper-cli -np -m fake.bin -osrt -of o -f a.wav` with `a.wav` real audio: rc=3, and no `o.srt`.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54` (2026-09-29).

**Trigger.** A whisper.cpp upgrade.

### F20.6 — `whisper-cli` prints the transcript to stdout and its diagnostics to stderr

**Statement.** Even under `-np`, `whisper-cli` prints each segment to stdout as it decodes it, timestamps and text, so a run killed partway has already printed the transcript so far. Its diagnostics go to stderr: errors, the usage an unrecognised argument prints, and the line naming the SRT it saves. A caller capturing stderr alone holds no transcript.

**Probe.** `timeout -s KILL 6 whisper-cli -np -m <model> -l en -osrt -of o -f <a minute of speech> >out 2>err`: `out` holds the segments decoded so far, `err` none. Then `whisper-cli --no-such-flag >out 2>err` and `whisper-cli -np -m /nonexistent.bin -f a.wav >out 2>err`: `out` is empty, and `err` holds the error.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54`, model `large-v3-turbo` (2026-10-19).

**Trigger.** A whisper.cpp upgrade.

### F20.7 — `whisper-cli` has no end-of-options marker

**Statement.** `whisper-cli` has no end-of-options marker: `--` is itself an argument it does not recognise, so a filename beginning `-` given as a positional is read as a flag, and like any argument it does not recognise it prints its usage and exits 0.

**Probe.** Manual — with `a.wav` real audio, `whisper-cli -- a.wav` and `whisper-cli -x.wav`: each prints `error: unknown argument` and the usage, rc=0.

**Checkpoints.** `whisper.cpp @ v1.8.4-326-gafa2ea54` (2026-10-11).

**Trigger.** A whisper.cpp upgrade, or a new flag being passed to it.

## F21 — yt-dlp

### F21.1 — yt-dlp's `--sub-langs` entries are regexes, matched whole

**Statement.** Each comma-separated entry of `--sub-langs` is a regular expression matched against the whole language key, not a literal and not a prefix. `e` selects nothing where an `en` track exists; `e.` and `e.*` both select `en`. So a language list taken from configuration is a list of patterns, and a stray metacharacter widens or empties the selection with nothing reporting it.

**Probe.** Manual — against a saved info-JSON: `yt-dlp --load-info-json <file> --skip-download --write-subs --sub-langs <pattern> --print '%(requested_subtitles)j'` prints `NA` for `e` and an `en` entry for `e.` and for `e.*`.

**Checkpoints.** `yt-dlp @ 2026.08.19` (2026-10-04), `yt-dlp @ 2026.07.04` (2026-09-22).

**Trigger.** A yt-dlp release changing subtitle selection.

### F21.2 — yt-dlp's `--print` format fields describe the selected format, not the source

**Statement.** Fields such as `%(vcodec)s` are read off whichever format yt-dlp's selection picked, so the same info-JSON answers differently under a different `-f`. The same saved metadata gives `av01.0.08M.08` under default selection and `none` under `-f bestaudio`. The coupling is silent: the wrong answer is a well-formed value, never an error.

**Probe.** `yt-dlp --load-info-json <file> --skip-download --print '%(vcodec)s'` against the same file with `-f bestaudio` added.

**Checkpoints.** `yt-dlp @ 2026.08.19` (2026-10-04), `yt-dlp @ 2026.07.04` (2026-09-22).

**Trigger.** A yt-dlp release changing format selection or output templates.

### F21.3 — for the generic extractor `webpage_url` is the post-redirect URL, not the one requested

**Statement.** Where a real extractor handles an input, `webpage_url` is that site's canonical URL for the item, which is what turns a short form or a tracking-laden paste into a stable reference. Where the generic extractor handles it — any direct media URL — there is nothing to canonicalise and `webpage_url` is simply the URL arrived at after redirects. On a CDN that is a node-specific hostname: a request for `example.org/download/…` records something like `node7.cdn.example.org/0/items/…`, which no later citation resolves. `%(extractor)s` is `generic` exactly in the case where this holds.

**Probe.** `yt-dlp --skip-download --print '%(extractor)s|%(webpage_url)s' <direct-media-url>` against a download URL that a public archive redirects to a CDN node prints `generic|` followed by the node's hostname; the same call on a YouTube watch URL prints `youtube|` followed by the canonical watch URL.

**Checkpoints.** `yt-dlp @ 2026.08.19` (2026-10-04), `yt-dlp @ 2026.07.04` (2026-09-22).

**Trigger.** A yt-dlp release changing the generic extractor's metadata.

### F21.4 — yt-dlp's field paths cannot reach a key containing a hyphen

**Statement.** In `--print` and output templates, a dotted field path stops working at a key with a hyphen in it: `%(automatic_captions.en-orig)s` prints `NA` even where the key exists, while `%(automatic_captions.en)s` prints its value. A key with a hyphen has to be read from the info JSON itself.

**Probe.** `yt-dlp --load-info-json <file> --skip-download --print '%(automatic_captions.en-orig)s'`, over an info JSON whose `automatic_captions` holds `en-orig` and `en`, prints `NA`; the same with `.en` prints the track list.

**Checkpoints.** `yt-dlp @ 2026.08.19` (2026-10-05, a hand-made info JSON).

**Trigger.** A yt-dlp release touching output templates.

### F21.5 — yt-dlp lists a video's caption tracks without fetching them

**Statement.** For a YouTube video, `yt-dlp -J --skip-download` lists every subtitle and automatic-caption track with a `url` and no body, and sends no request for any caption: the track list comes from the page's player response. So a caption fetch that fails later cannot empty the list.

**Probe.** Manual — `yt-dlp -J --skip-download --print-traffic <url>` on a captioned video: every entry under `subtitles` and `automatic_captions` carries `url` and no `data`, and no request goes to the caption endpoint, `timedtext`.

**Checkpoints.** `yt-dlp @ 2026.08.19` (2026-10-05, 1,139 entries over three requests, none for a caption).

**Trigger.** A yt-dlp release, or the site changing its player response.

## F22 — git

### F22.1 — an exec bit belongs to the checkout, not the repository

**Statement.** Git records a file's mode, but whether a working tree carries the exec bit depends on how it arrived: a Windows extractor, a `noexec` mount or a clone with `core.fileMode=false` can leave it cleared where git recorded it set.

**Probe.** Unprobed — the clearing routes are documented rather than observed; no Windows host or `noexec` mount has been in reach.

**Checkpoints.** None.

**Trigger.** A new route by which a copy arrives.

### F22.2 — git ignores a hook that has no exec bit, and the commit proceeds

**Statement.** A hook file without its exec bit is not run: git prints a hint naming it, suppressible with `advice.ignoredHook`, and the commit completes as though no hook existed. So a check wired through `core.hooksPath` is silently absent on a checkout that lost the bit.

**Probe.** `t=$(mktemp -d) && git init -q "$t" && mkdir -p "$t/h" && printf '#!/bin/sh\nexit 1\n' > "$t/h/pre-commit" && git -C "$t" config core.hooksPath h && git -C "$t" -c user.name=t -c user.email=t@t commit -q --allow-empty -m x; echo $?` prints `0`; after `chmod +x "$t/h/pre-commit"` the same commit prints `1`.

**Checkpoints.** `git @ 2.51.0` (2026-09-16, 2026-10-02).

**Trigger.** A git upgrade.

### F22.3 — a repository with no commits reports every file as untracked

**Statement.** A repository holding no commit reports every file in its tree as untracked, so a guard that requires a clean tree refuses to run. That is the state a re-initialise leaves behind while nothing has been committed yet.

**Probe.** `t=$(mktemp -d) && cd "$t" && echo a > a && git init -q && git status --porcelain` prints `?? a`.

**Checkpoints.** `git @ 2.51.0` (2026-09-20, 2026-10-02).

**Trigger.** A git upgrade.

### F22.4 — a checkout dates every file it writes to the moment of writing

**Statement.** Git records no modification times, so every file a checkout writes — a clone, `git worktree add`, a switch, a merge — carries the moment it was written. A fresh linked worktree dates every file to its creation, whatever the same file's mtime is in the main checkout.

**Probe.** `t=$(mktemp -d) && git init -q "$t/m" && echo a > "$t/m/a" && git -C "$t/m" add a && git -C "$t/m" -c user.name=t -c user.email=t@t commit -qm a && touch -t 202001010000 "$t/m/a" && git -C "$t/m" worktree add -q "$t/w" HEAD && ls -l "$t/m/a" "$t/w/a"` shows 2020 for the first and today for the second. `test-regen-views.sh` asserts the consequence.

**Checkpoints.** `git @ 2.51.0` (2026-09-23).

**Trigger.** A git upgrade.

### F22.5 — git finds a repository by walking upward

**Statement.** A git command run in a directory with no repository of its own uses the nearest enclosing one, so `git rev-parse --show-toplevel` run inside an unrelated checkout names that checkout rather than failing. With no enclosing repository it prints nothing to stdout and exits 128.

**Probe.** `t=$(mktemp -d) && git init -q "$t" && mkdir "$t/inner" && git -C "$t/inner" rev-parse --show-toplevel` prints the outer directory.

**Checkpoints.** `git @ 2.51.0` (2026-08-15, 2026-09-16).

**Trigger.** A git upgrade.
