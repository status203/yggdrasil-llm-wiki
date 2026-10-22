---
type: reference
pitch: The main ideas behind how Yggdrasil works, how the program reaches a wiki, and the principles it is built on.
volatility: low
checkpoint: 2026-10-06
---

# Internals

The ideas behind Yggdrasil, and how its parts fit together. Deliberately kept high-level; for anything else, ask Claude: it has the files and can explain them in place.

## A program, and wikis it maintains

The program is installed once per machine. Each wiki is a folder of your own, with its own git repository. The two never share a repository, so a wiki can stay private while the program is public, and one program serves every wiki you have.

The program's own folder is also a wiki, the forge wiki, which holds what work on the program needs: these pages, a test subject to try page mechanics on, and the research behind the design. Where you start Claude decides what the session works on: in a wiki, your pages; in the program's folder, the program itself.

The program is written to be changed. Its instructions are plain text, and part of it exists only to govern how to write its own rules: a method for where a new rule goes and how it's written, and a record of past decisions with what each ruled out. A session in the program's folder works under that method, so your changes fit with what's there rather than quietly undoing it.

## How they're joined

Installing the program registers its folder with Claude Code as a plugin. A wiki joins by enabling the plugin by name in its Claude Code settings, `.claude/settings.json`, with no path, so the same wiki works on any machine where the program is installed. Nothing of the program is copied into a wiki, so updating the program with `git pull` updates every wiki at once. Each wiki records the layout it was set up in as a format number, and every session checks it against the one the program reads; where they differ, the session's opening `Yggdrasil:` line says which is newer and what to do, such as pulling the program again.

From then on the program reaches a session through hooks, small scripts Claude Code runs at fixed moments, wired in the program's `.yg/hooks/hooks.json`:

| When | What |
| --- | --- |
| Every session start, a resume, `/clear` and compaction included | Merge the config layers into the wiki's `.yg/resolved/config.conf`, decide whether this is a forge or a wiki session (below), and check the wiki's format against the program's. Regenerate any view that is out of date. Hand the session the wiki rules, `wiki.md`. |
| A new session's start only | One line on how long since each review last ran. |
| An agent is dispatched | Hand it the wiki rules too. |
| Before a file or shell tool | Refuse anything reaching outside the wiki's folder into the rest of an Obsidian vault, save the program's own folder should it sit there. A shell command is judged by the paths it can read from the command's words. |
| After Claude writes or edits a file | Re-merge the config if it was a config layer. |

The session-start hook prints the line marked `Yggdrasil:` that says which kind of session this is. A session started in the program's own folder is a **forge session**, which works on the program; in a wiki, a **wiki session**, which works on pages. A wiki session asked to change the program says so, and points you to a session started in the program's folder.

### Who reads what

Each rule lives in the one file read by everyone it binds, every one of them in the program's folder, not a wiki's own `.yg/`:

| File | Read by |
| --- | --- |
| `.yg/wiki.md` | Every session and every agent, in every wiki |
| `.yg/output-styles/odin.md` | Odin, the session you talk to, only: the plugin forces it as the session's output style, the part of Claude Code's instructions that sets Claude's role |
| `.yg/page-contract.md` | Whoever writes, edits or moves a page |
| `.yg/agent-contract.md` | Whoever writes an agent |
| `.claude/CLAUDE.md`, `.yg/forge-mode.md` | Forge sessions only |

## Agents and skills

Both keep work out of the main conversation until it's needed, and both route it. Claude Code sees each one's short description, though a skill's can drop out after the conversation is compacted, or on a smaller context window. It loads the rest only when the work in hand matches it, so the instructions for a task are in context only while that task is.

- **Skills** are the slash commands and flows, such as wrap, transcribe and the reviews. When one runs, its instructions load into the session.
- **Agents** do specialist work: looking up what the wiki holds, researching on the web, writing pages, teaching, reviewing. Each works in its own context and hands back only its result, so the conversation doesn't fill up with the files it read, and each has only the tools its job needs.

## What it's built on

**Mechanise what can be mechanised.** A rule whose cases can be listed and checked is a script, not an instruction: building indexes, moving a page and fixing its links, checking page metadata, keeping personal details out of commits. A script costs little to load, runs fast (if written properly), and can't forget a rule halfway through a long session. A rare case that one line of instruction already covers stays an instruction, since a script there would cost more to keep than it saves.

**Prose states the outcome.** Where a rule has to be instruction, the default states what should be true, not how to get there. Steps are spelled out only where their order matters, such as a check that has to come before something destructive (and that still doesn't guarantee an llm will do it :( ).

**Bounded variance.** An LLM model can give a different answer each time. That's kept to the judgement calls that need it, and fenced by everything around them: scripts for what's decidable, written tests for reviews, contracts for what a page or an agent must be.

**Keep load off the frequent paths.** What every session reads is kept short. The method for changing the program loads only in a forge session, and reviews only when you start one. Rules are paid for where they're used.

**Every mechanism has to earn its place.** Anything here could be had by asking Claude from scratch each time. The program exists to make keeping a wiki *repeatedly* cheap, so a part that doesn't lower that cost doesn't belong.

**Small over complete.** A rare failure that shows itself and is easy to put right may not be guarded, and left to the user and Odin to sort out; mechanism goes on failures that are silent or costly.

**Decisions keep what they ruled out.** A settled choice is recorded as "this, not that, because…", so a later change can see the alternative was considered rather than re-deciding it, possibly the other way. Where rewording the rule itself shuts the alternative out, the rule is reworded and nothing more is kept. This makes forge work heavier on context than wiki work: a forge session reads the method and the record of work in progress before changing anything, and looks up past decisions as questions come up.

**Claims about the tools are tested, not assumed.** What the program relies on Claude Code, git or Obsidian to do is recorded with the probe that would show it wrong, and re-checked when the tool moves on — for Claude Code, where a release's changes touch it.

**A failure never passes for a clean result.** A check that couldn't run says so; it never reports "nothing found".

**Safe by default.** Wikis are private unless you say otherwise. Anything that can't be undone should be confirmed first, and the default answer should be the safe one. The wiki's structure is always your call.
