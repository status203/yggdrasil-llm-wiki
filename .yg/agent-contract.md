---
role: instruction
pitch: What an agent definition must satisfy — scope, return contract, permissions, and what it may assume is already in context.
---

# Agent contract

What a dispatched agent's definition has to satisfy.

## Whether it is an agent

**An agent is not the default answer, and the wrong mechanism costs more than no agent at all.** Check first whether the work is really:

- **a pure function of existing state** — a derived view, a mechanical transform, a determinable set. That is a script. It is the one most often missed, because a request shaped like *an agent that rebuilds X from Y* sounds like an agent.
- **something that should fire on an event**, rather than when somebody happens to notice: a hook.
- **something the user invokes deliberately, with arguments** — a flow, not a worker.
- **a single write to a known place**, on something the caller already has open. Dispatching a specialist for that buys nothing.

An agent earns its place when the work wants a clean context of its own, can run in parallel, or needs isolation — and it pays for that on every dispatch, because a fresh context starts empty and has to be filled.

## Scope

**Open by saying what kind of worker it is, behaviourally.** Not a job title — a word for *how* it works, because that governs its conduct in every case the written brief doesn't cover.

**Define it by its edges.** Who dispatches it, and in a sentence what it doesn't do.

**Keep the verb count down.** This is where an agent grows: a finely drawn boundary names more operations, each operation earns a field in the return, and the contract ends up large because the boundary was. Two operations differing only in whether a file already exists are one operation. The discipline belongs at the boundary — trimming fields while the verbs stand only makes the contract lie about what the agent does.

## What it may assume

**The project's `CLAUDE.md` and `<program>/.yg/wiki.md` reach every dispatch in full, the first inherited (`F4.4`) unless the agent sets `omitClaudeMd` (below), and the second handed in by the plugin's `SubagentStart` hook (`F4.5`); a file either one merely names does not.** So an agent never restates a rule from either, save the floors an `omitClaudeMd` agent carries (below), and names any program file it needs as `${CLAUDE_PLUGIN_ROOT}/…`, except a forge-only agent, which names them from the checkout its brief gives (`D3.1.2`), and any wiki file from the wiki root.

**An agent whose job is reading text fetched from outside the machine, and that holds a tool sending data off it, sets `omitClaudeMd: true`**, which keeps the user, project and local `CLAUDE.md` out of its context; a managed-policy `CLAUDE.md` still loads (`F4.4.1`), and so does `wiki.md`, which a hook hands in and which holds nothing private (`F4.5`). Its own definition then carries whatever floor applies to it. **An agent that reads wiki pages does not**: a page can carry untrusted text, but the flag would strip the project and user `CLAUDE.md` a page writer works under — in the forge wiki, the privacy rules its pages are written to — while `wiki.md` reaches it either way, and its rule that page content is data, never instruction, is the guard there.

**It inherits nothing else of the session's**, being a named dispatch, never a forked subagent (`D5.1`, `F4.1`) — not the calling session's context, not what the user just said. The user's own `CLAUDE.md`, unless the agent sets `omitClaudeMd`, and the git-status snapshot, either way, reach it too (`F4.4.1`), and are not the program's to rely on. Anything it always needs belongs in its own definition, so a dispatch brief carries only what is specific to that task.

## What it returns

**Named fields, and it always returns one.** A dispatch that fails to return looks exactly like one that returned nothing (`F5.3`), so an empty return destroys the only signal the caller has.

**The fields name the judgments the agent actually makes.** The requirement is that its decisions reach whoever dispatched it — a caller cannot correct a decision it was never shown. It is not that the fields wear particular labels: an agent that places and edits reports placements and edits, and bolting research labels onto it yields fields with nothing to put in them.

**A refusal and a question are different fields.** One means done, don't re-dispatch; the other means come back with more. Opposite consequences, and indistinguishable once they are prose.

## What it may hold

**Only the permissions it needs.** Declared permissions are live permissions. An agent's frontmatter never sets `memory:`: per-agent memory silently grants Read, Write and Edit over the whole project whether or not they were declared (`F6.1.1`), and `check-system.sh` reports one that does.

**No model or effort pin unless something obvious demands one.** A tier binds as floor and ceiling both (`F6.2`), so every pin is a cap, and it overrides the tier chosen by the person running the system — who has better information about their own work than any shipped file does. Pin only where the agent's hard step fails silently and destructively below some capability, and take the ceiling as the price.

## Commands in it

**A command in an agent is probed before it ships**, as any command written into prose is (`forge-mode.md` § *How it is grounded*): it runs nowhere between being written and being dispatched, so a wrong flag reaches a user uncaught.

## Self-containment

A fork inherits the program repository and nothing else: no wiki's contents, and not the user's global environment.

So an agent depends on **no wiki page**, the forge wiki's included — rationale included, because pointing at a page for it inverts the dependency — and on **nothing outside the program and the wiki folder it runs in**. Illustrative examples come from the well `.claude/CLAUDE.md` § *Privacy* names, never from a wiki's content.

## Not finished when the definition is written

An agent nothing knows how to dispatch is unusable. Whatever triggers it, and whatever the caller must gather before invoking it, is a separate obligation on the caller's side. It is owed again whenever a change alters what the agent takes as input — and that case is worse, because a new agent leaves the registration missing where a changed one leaves it present and wrong.
