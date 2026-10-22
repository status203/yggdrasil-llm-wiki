---
type: reference
pitch: How to install Yggdrasil, set up a wiki, use it day to day, and what to know before depending on it.
volatility: medium
checkpoint: 2026-10-06
---

# Instructions

Yggdrasil turns Claude Code into the maintainer of a wiki you read and edit in Obsidian. 

You talk to Odin. See [[Naming]] if you care about "WhyTF Odin?", otherwise whenever you see Odin just think "Claude with a horned helmet on" (Yes. I know that's not really a thing). 

What the conversation settles lands as pages in the right subject of your wiki, and ongoing learning and practice are tracked across sessions as tutorials, companions to a course or book, or practice logs.

> **These instructions are intentionally brief.** For anything they don't cover, start Claude Code in your wiki or in the program's folder and ask Odin. The words the system uses are in [[Terminology]].

## The program and your wikis

Yggdrasil is two kinds of thing, kept apart:

- **The program** — this repository. Agents, rules, scripts and flows, installed once per machine as a Claude Code plugin. You update it with `git pull`.
- **A wiki** — a folder of your own, with its own git repository, that the program maintains. You can have several. Nothing of a wiki ever goes into the program's repository, and the program's files never go into a wiki.

The program's own folder is a wiki too, the *forge wiki*, which holds these pages along with a test subject and the research behind the design. A Claude Code session started there works on the program itself; one started in your wiki works on your pages.

## Getting started

### Prerequisites

- **Claude Code**, with a Claude subscription or API credit. The version the program was last checked against is the `checkpoint:` line at the top of `.yg/facts.md`; older versions may lack hooks or plugin features it relies on, and fail quietly.
- **git**, with `user.name` and `user.email` set. Every wiki is a git repository, and wrapping up a session commits whatever changed.
- **`sh` and `awk`**, which every supported platform already has.
- **Obsidian** (recommended), for reading and editing the wiki.
- For transcription only: `yt-dlp` and `ffmpeg` (with its `ffprobe`), `curl` or `wget` for downloading the speech models, plus an engine. The default engine is whisper.cpp, which **you install yourself**, outside Yggdrasil, so that `whisper-cli` is on your `PATH`. Yggdrasil doesn't install any of these. `/yggdrasil:transcribe` checks for them when it runs, and once whisper.cpp is there it offers to download the speech models, with your consent, the first time.
- A later version will quite likely need **Python 3** as well, because `sh`, `awk` and `sed` behave differently from one platform to the next in ways that keep causing bugs.

Yggdrasil is not a ready-to-run product. Expect some tinkering: installing CLI tools, the odd platform quirk, and enough comfort with a terminal to look into it when something doesn't work first time. The upside is that everything — agents, rules, flows — is something you can reshape by asking Odin.

Yggdrasil tries to keep things secure, but that's a best effort, not a guarantee, and a basic knowledge of security is always useful when working with LLMs: what reaches Anthropic (*Claude Code uses the cloud*, below), what auto mode allows, and keeping secrets out of the wiki.

### Steps

1. **Install the program, once per machine.** Clone this repository wherever you like, then run its installer. The commands on this page run from where you ran the clone, the folder holding `yggdrasil/`:

   ```
   git clone <repository URL> yggdrasil
   sh yggdrasil/.yg/bin/install.sh
   ```

   It checks the prerequisites, then registers the program with Claude Code as a plugin, at user level, telling you what it is about to register first. Run it again any time; it says when there is nothing to do.

2. **Set up a wiki.** Point the setup script at the folder you want the wiki in. It can be new or already hold notes:

   ```
   sh yggdrasil/.yg/bin/init.sh <wiki folder>
   ```

   It makes the folder a git repository, enables the plugin there, adds a `Misc` subject as the catch-all, and commits. If the folder is inside another git repository, or already holds files, it stops and asks how you want to go on.

3. **Start Claude in the wiki and run `/yggdrasil:init`.**

   ```
   cd <wiki folder>
   claude
   ```

   If you've turned auto mode off, read *Permission mode* below first. Then `/yggdrasil:init`. It asks what the wiki is for and proposes subjects, shows the few settings worth knowing about, and offers to connect a remote. If you add one, make it a **private** repository: a push sends every page there.

4. **Open the wiki in Obsidian.** Open the folder as a vault, or open a larger vault it sits inside. Within the vault, Yggdrasil only ever reads and writes inside the wiki's own folder, and the program's folder if you cloned it there. It finds the vault by its `.obsidian/` folder, so if you rename that folder in Obsidian's settings, leave the old `.obsidian/` in place; without it, the rest of the vault is not fenced.

Both scripts print a suggested shell alias for launching Claude Code in the right place. They never edit your shell's startup files; add the alias yourself if you want it.

### Permission mode

The system was developed and tested in Claude Code's **auto mode**, which is Claude Code's default. If you've turned auto mode off generally, start Claude Code with `claude --permission-mode auto`, or add the flag to the alias the scripts suggest, and it is on for those sessions alone. Yggdrasil works without auto mode, but it will be *very* noisy: expect to approve a stream of routine file writes, scripts and commits.

## Using it

Most of it is conversation. You talk; Odin answers, and in the background checks what the wiki already holds on the topic.

- **It names the subject** once the conversation has settled on one, so you can see when it has guessed wrong. Pages might be written at any point in a session, not only when you wrap, so correct a wrong subject when you see it.
- **It connects to what you already have.** If a page is the natural home for what was said, it adds it there and tells you where; other related pages get mentioned.
- **It saves what the conversation settled and what you asked and learned**, not every exchange: by default the back-and-forth around a point stays out, though a subject can say to keep a conversation near verbatim where it's the point. A small point with nowhere in the wiki to go is left out, and wrap names it so you can say to keep it.
- **Multi-session work** is tracked in `Progressions.md` at the wiki root:
  - *"Teach me the basics of the endgame"* starts a **tutorial**: a curriculum, then one step at a time.
  - *"I'm working through a public-speaking course"* starts a **companion**: a page that follows the course, grown as you go. A companion doesn't need Odin to be able to read the course. Where the course is openly on the web, Odin can look things up in it; where it isn't, such as a printed book or a course behind a login, the page holds only what you tell it or put in `import/`.
  - *"Help me practise culinary knife skills"* starts a **practice** page: running notes on what you're working on.
- **Files for context** — a PDF, a photo, notes from elsewhere — go in the wiki's `import/` folder. Mention them and Odin reads them. `import/` is never committed.

When you're done, say so or run `/yggdrasil:wrap`. It decides what the session produced that is worth keeping, places it, names what it left out, and commits if anything changed. By default it does not push.

### Where things land

- **Pages** — in subject folders at the wiki root. Each subject has a `.subject.md` saying what belongs in it and anything it does differently.
- **Backing material** — articles, transcripts, session records — in `.sources/`, which Obsidian doesn't show. Pages cite it under a `## Sources` heading.
- **Views** — `Index.md` at the root lists the subjects, each subject's own `Index.md` lists its pages, and `Progressions.md` lists what you're in the middle of. All of them are regenerated automatically, so any edits you make to them by hand will be lost.
- **Obsidian's settings** — in `.obsidian/`, or whatever you've renamed it to. The wiki never commits it, since plugins can keep tokens there: its `.gitignore` leaves out every top-level folder whose name starts with a dot except `.yg/`, `.claude/` and `.sources/`. To commit a dot folder of your own, add a `!/<name>/` line to it.

### Commands

**Every session**

- **`/yggdrasil:wrap`** — end a session: keep what's worth keeping, and commit.
- **`/yggdrasil:transcribe <file or URL>`** — turn audio or video into a transcript in `import/`, then file it: on a page it supports, or a placeholder page pointing at it. It doesn't read the transcript itself unless you ask, since a long one fills the session. It needs a transcription engine set up first, outside Yggdrasil: by default whisper.cpp, installed yourself (see *Prerequisites*). To use something else, a transcription API say, write an adapter for it in `~/.config/yggdrasil/engines/transcribe/` and name it in the `transcribe.engine` setting; Odin can help.

**Now and then**

- **`/yggdrasil:content-review`** — review a subject or topic for pages in the wrong place, pages covering the same ground, clusters that could be a subject of their own, and sources nothing cites. You choose which proposals to apply. Asked for the whole wiki, it scans every page's pitch for groups on one topic, and you pick one to review.
- **`/yggdrasil:staleness-review`** — check whether pages that teach something still hold up, and update the ones you pick. Pages opt in with a `volatility:` field.

**Once**

- **`/yggdrasil:init`** — set up a new wiki's subjects and settings, after `init.sh`.

**Working on the program** — only in a session started in the program's folder:

- **`/yggdrasil:system-review`** — check the program for drift across its files, and these pages against it.
- **`/yggdrasil:harness-review`** — check what a Claude Code update means for the program.
- **`/yggdrasil:integration-review`** — check one change against the rest of the program and these pages, before it is committed.

### Settings

Settings are `key: value` lines in three layers, each overriding the ones before:

- the program's defaults, `.yg/default/config.conf`, which you don't edit;
- your user layer, `~/.config/yggdrasil/config.conf`, which applies to all your wikis. Wherever these pages say `~/.config`, it means `$XDG_CONFIG_HOME` if you've set it;
- a wiki's own `.yg/config.conf`, for that wiki.

Each key's meaning is in a comment above it in the defaults file. Ask Odin to change one and it puts it in the right layer.

One to know about: every new wiki starts with `wiki.visibility: private`. Set it to `public` only for a wiki you mean to publish; Odin then walks you through what that exposes, its history included.

## Caveats

### Claude Code uses the cloud

Your wiki lives on your disk, and Yggdrasil uploads nothing itself. But Claude Code sends the conversation to Anthropic's API on every turn, including any page or file Claude Code reads to answer. Talking about a subject can put its pages in the request. Check Anthropic's data-use terms for your plan, and keep secrets out of the wiki: Yggdrasil records where a credential is kept, never the credential itself.

### Moving to another machine

A wiki is a git repository, so cloning it restores the pages. To restore everything:

1. Clone the program and run its `install.sh` on the new machine, as in *Getting started → Steps*.
2. Clone the wiki and start Claude Code in it. The wiki's own settings come with it.

These don't travel with either repository, so keep them with your own dotfiles if you want them:

- your user settings layer, `~/.config/yggdrasil/config.conf`;
- any transcription adapters of your own, in `~/.config/yggdrasil/engines/`;
- the system and harness reviews' ledgers and the forge's record of work in flight, which the program's folder holds but never commits;
- the wiki's Obsidian settings folder, and any top-level dot folder of your own you haven't un-ignored (*Where things land*);
- your shell aliases.

If a wiki is opened on a machine without the program, a note in the wiki's `.claude/` tells Claude Code to say so before touching anything.

### Platforms

Linux, macOS, and Windows through WSL2. Developed and tested on Linux; macOS and WSL are designed for but are completely untested. On WSL, keep wikis inside the WSL filesystem rather than on a Windows drive under `/mnt`, which is much slower. Native Windows without WSL is not supported.

### One person, one machine at a time

A wiki has one owner. Two machines working on the same wiki is fine through git, as with any repository, but nothing in Yggdrasil co-ordinates multiple sessions at once.

### Worth knowing

Simplifications Yggdrasil makes to stay small (or at least to stop it growing even larger); skim or skip. You're talking to Odin throughout, so where something isn't automatic, ask it.

- **Say when you're done.** Saving and committing happen when you tell Odin you're finished. Close the terminal mid-session and that session's material isn't saved.
- **Wrapping up commits everything.** The whole wiki goes into the commit, including edits made in Obsidian and anything another session left uncommitted; Odin names what isn't its own first.
- **Only subject folders count.** A folder without a `.subject.md` isn't indexed, checked or searched; ask Odin to make it a subject.
- **Keep private material outside the wiki folder.** Everything inside it may be read and included in the context.
- **Dates are UTC.** Near midnight a record can carry the wrong day.
- **Rename and move pages through Odin**, or in Obsidian, letting it update links. Obsidian misses a moved page's links into `.sources/`, which it doesn't see; Odin can find and repair them. Links between pages aren't checked, by a review or anything else, so a rename made any other way breaks them silently; if you spot one, Odin can usually find the old name in git's history and repair the links.
- **Web sources are links, not copies.** If a page disappears, its source goes with it, and nothing notices.
- **Written for Obsidian.** Links are bare page names, so in a wiki inside a larger vault a link can open a same-named page outside it. On most setups, matching ignores case only for plain ASCII letters, so `É` and `İ` keep theirs.
- **A pasted credential isn't caught.** Odin won't write one anywhere, but nothing detects it.
- **A step that fails needs you.** Flows don't recover on their own: Odin stops at the failure, says what was done and what wasn't, and waits for you to fix the cause, with its help if you like, before it carries on.

## Changing Yggdrasil

Everything is meant to be reshaped. Start Claude Code in the program's folder — a *forge session* — and ask for what you want changed. The session works on the program under its own method, kept in `.yg/forge-mode.md`.

If you commit changes of your own, push them to a remote of your own and wire its pre-commit hook once, so commits pass the check that refuses any path, address or host not among its placeholders and reserved example names:

```
git -C yggdrasil config core.hooksPath .yg/githooks && chmod +x yggdrasil/.yg/githooks/pre-commit
```

`install.sh` prints this, and a forge session's opening `Yggdrasil:` line says when it isn't wired. The check can't recognise a bare username or a private repository's name, so read your diff too.

## Going deeper

- [[Internals]] — the main ideas behind how it works, and how the program reaches a wiki.
- [[Terminology]] — the words the system uses.
- [[Naming]] — whyTF the agents have the names they do.
