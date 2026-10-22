# Yggdrasil

Yggdrasil turns Claude Code into the maintainer of a wiki you read and edit in Obsidian.

You talk to Odin: think "Claude with a horned helmet on" (yes, I know that's not really a thing). [Naming](../Docs/Naming.md) answers "WhyTF Odin?".

What the conversation settles lands as pages in the right subject of your wiki, and ongoing learning and practice are tracked across sessions as tutorials, companions to a course or book, or practice logs. Specialist agents do the looking up, researching, writing, teaching and reviewing.

The system is built to be reshaped to your own needs by asking Odin. Its instructions are plain text and its scripts are short, and part of the system exists only to govern how it changes itself: a written method for where a new rule goes and how it is written, and a record of past decisions with what each ruled out.

## The program and your wikis

This repository is the **program**: installed once per machine as a Claude Code plugin, and updated with `git pull`. Each **wiki** is a folder of your own with its own git repository, which the program maintains. The two never share a repository, so your wiki stays yours while the program is public, and one program serves every wiki you have.

## What a session looks like

Start Claude Code in your wiki folder and talk. Odin answers, checks what the wiki already holds on the topic, and names the subject it thinks you're in. When something is settled, it adds it to the page it belongs on and says where. *"Teach me the basics of the endgame"* starts a tutorial; *"I'm working through a public-speaking course"* starts a companion page. When you're done, `/yggdrasil:wrap` keeps what's worth keeping and commits.

## Getting started

Yggdrasil is not a ready-to-run product. There's a genuine tinker tax: installing CLI tools, probably dealing with the odd platform quirk, and enough comfort with a terminal/Claude Code to look into it when something doesn't work first time.

Yggdrasil tries to keep things secure, but that's a best effort, not a guarantee. A basic grasp of security when working with LLMs is always worth having: what gets sent to the cloud, what auto mode lets Claude do without asking, and that text from a web page or an imported file can try to give Claude instructions.

You need Claude Code with a subscription or API credit, and git with your name and email set. Obsidian is recommended for reading the wiki. Transcribing audio and video also needs an engine you install yourself, outside Yggdrasil: whisper.cpp by default, or an adapter you write for a transcription API. Yggdrasil runs on Linux, macOS, and Windows through WSL2 (macOS and WSL2 thoroughly *untested*).

A later version will quite likely need Python 3 as well, because the shell tools the scripts use behave differently from one platform to the next in ways that keep causing bugs.

```
git clone <repository URL> yggdrasil
sh yggdrasil/.yg/bin/install.sh              # once per machine
sh yggdrasil/.yg/bin/init.sh <wiki folder>   # once per wiki
cd <wiki folder>
claude                                       # then: /yggdrasil:init
```

`/yggdrasil:init` asks what the wiki is for and sets up its first subjects. If you add a remote, make it a **private** repository: a push sends every page there.

### Recommended aliases

Two shell aliases save starting Claude Code in the right folder each time. `install.sh` and `init.sh` print them with your paths filled in. With auto mode added, for bash:

```
alias yg='cd "<wiki>" && claude --permission-mode auto'         # your wiki
alias ygf='cd "<program>" && claude --permission-mode auto'     # changing the system itself
```

The system was developed and tested in Claude Code's auto mode. Auto mode is already Claude Code's default, so the flag only matters if you've turned it off generally: then it turns auto mode back on for these sessions alone.

Yggdrasil works without auto mode, but it will be *very* noisy: expect to approve a stream of routine file writes, scripts and commits.

Name them as you like. If aliases are new to you, or you use another shell, ask Odin: it can explain what they do, what auto mode allows, and help you add them.

## Going deeper

- [Instructions](../Docs/Instructions.md) — setup in full, daily use, the commands, and caveats worth knowing.
- [Internals](../Docs/Internals.md) — the main ideas behind how it works, and how the program reaches a wiki.
- [Terminology](../Docs/Terminology.md) — the words the system uses.
- [Naming](../Docs/Naming.md) — why the agents have Norse names, and the rest of the theme.

Anything these don't cover, ask Odin: it has the files and can explain them in place.
