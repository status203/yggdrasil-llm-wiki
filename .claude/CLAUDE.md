# Yggdrasil

Yggdrasil is a program for LLM wikis: a person reads and edits a wiki directly in Obsidian, and an LLM maintains it alongside them. Each wiki is its own folder and repository, an *external wiki*. This repository holds the program, and its root is a wiki too, the *forge wiki*, which holds what work on the program needs, its docs, the test bed and the research behind its design, and changes with it.

Anything here could be had by asking for it from scratch each time. Yggdrasil exists to make doing it *repeatedly* cheap — so a mechanism that doesn't lower that cost doesn't belong.

## The forge wiki

A session launched here is a forge session: Odin working on the forge wiki, with this file's forge rules on top. The forge wiki keeps the rules every wiki keeps, `.yg/wiki.md`, which the plugin's hooks hand to every session and dispatch. **In the session itself**, if no `Yggdrasil: forge session` line naming this checkout is in context, the plugin didn't load from here: say so, and point at `sh .yg/bin/install.sh`, which says what to do. A named dispatch never gets that line (`F4.1.2`), and checks nothing here.

**`Test bed/` is the test subject for forge work.** Try page mechanics there, never on the real pages.

## How the system is built

- **Mechanise what can be mechanised.** If a rule's cases can be listed and checked, or its result is a pure function of existing state, it is a script, not prose. A script costs no context and cannot drift, and a model re-deriving a pure function only adds variance (`F1.1`). A rare path its prose covers in a line is the exception, since a script there costs more to keep than it saves (`D1.1`).
- **Where it has to be prose, state the outcome.** Give procedure only where the steps are load-bearing: an ordering that fails badly if inverted, or a gate that must come before a destructive act.
- **Scripts are POSIX `sh`, run through `sh` rather than by path, with a `test-<name>.sh` beside them, or the test that covers them named in their header.** Run what you write against an adversarial input rather than reasoning about what a flag does.
- **The rest of the method is `.yg/forge-mode.md`. Read it before changing the program.**

## Privacy

Treat every system commit as potentially public.

- **Nothing from an external wiki, or from the conversation behind a change, goes into a system commit.** That covers page and subject names, page content, a motivating case as it was told, and anything that reads as one person's interests even when it names nothing. The forge wiki's pages are system commits.
- **Illustrative examples come from a common well: cooking, chess and public speaking.** The bar is disclosure, not name collision: a well topic can still leak if the detail around it is one person's.
- **An example from outside the well is an exception, and every exception is put to the user**, never decided silently, so a fingerprint can't pass as a neutral choice. This includes examples that must contrast along some axis the well can't cover. Mark an agreed exception where it sits. The mark gives the reason the example is needed and never says what a wiki holds. It is the literal `well exception: <reason>`, in an HTML comment in Markdown and a `#` comment in code, on the example's line or the line above it, so the system review skips it; a file with no comment syntax can't carry it, so an example there is replaced.
- **Literal values come from the technical well, `.yg/technical-well.txt`:** placeholders and reserved example names for paths, email addresses, URL hosts and IP addresses. The pre-commit hook refuses any other, except in the root `LICENSE`, which it skips as the licence's text verbatim, and a named URL host in a forge-wiki folder the well lists under `docs:`, which it lets through as a `notice:` row: read each one for a private repository or service, and put any in doubt to the user before the commit is pushed. Additions to the well go to the user; a forge session's start line says when a checkout has not wired the hook.
- **Watch for what has no shape to check:** usernames and hostnames as bare words, credentials and where they are stored, and the names of private repositories and services.
- **Tools outside this repository are not part of the system.** Nothing here depends on them, configures them, or records where they keep their files.
