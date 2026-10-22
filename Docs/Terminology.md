---
type: reference
pitch: A glossary of the words Yggdrasil uses in conversation and in its files.
volatility: low
checkpoint: 2026-10-06
---

# Terminology

Words you'll meet in conversation and in the files. For what each part *does*, see [[Internals]]; for the agents' names, see [[Naming]].

## Where things live

- **Program** — the Yggdrasil repository: agents, rules, scripts and flows. Installed once per machine as a Claude Code plugin.
- **Wiki** — a folder of yours, with its own git repository, that the program maintains. Also called an *external wiki* when it needs telling apart from the forge wiki.
- **Forge wiki** — the program's own folder, read as a wiki. It holds what work on the program needs: these pages, a test subject, and the research behind the design.
- **Vault** — Obsidian's word for the folder it opens. A wiki can be a whole vault, or one folder inside a larger one.
- **Subject** — a folder at the wiki's root grouping pages. Its `.subject.md` says what belongs in it and anything it does differently.
- **Page** — a markdown file in a subject, carrying a `type:` and a one-sentence `pitch:` in its frontmatter, the properties block at the top of the file. A page you make by hand needs them too; Claude can add them. The type says how new material joins the page: most pages are `concept`, `reference` or `log`, besides the kinds below, and a subject's `.subject.md` can add its own.
- **Pitch** — one sentence, saying what a page or subject is. The indexes are built from pitches.
- **Source** — backing material kept in `.sources/`, such as an article, a transcript or a session record. Pages cite it; it isn't a page itself.
- **View** — a file generated from the pages, such as `Index.md` or `Progressions.md`. Hand edits will be lost.
- **`import/`** — a wiki's drop-zone for files to talk about. Never committed.

## Kinds of page

- **Tutorial** — the system teaches a topic, a step at a time, from a curriculum.
- **Companion** — a page that follows an external course, book or series, which does the teaching.
- **Practice** — your own running notes on something you're working at.
- **Progression** — any of the three above while it's in progress. They're listed in `Progressions.md`.
- **Placeholder** — a page standing in for material that's worth keeping but hasn't been worked into a page yet, such as a transcript or an imported document. It says what the material is and links to it, usually in `.sources/`, without summarising it. When the material is worked through, the real page replaces it under the same name, so links to it keep working.
- **Tombstone** — a page left where another one moved from, pointing to its new place.

## Sessions

- **Odin** — the session you talk to.
- **Wiki session** — a session started in a wiki. It works on pages.
- **Forge session** — a session started in the program's folder. It works on the program. *Forge work* is changing how Yggdrasil itself works.
- **Wrap** — ending a session: keeping what's worth keeping, then committing. "Let's wrap" works as well as `/yggdrasil:wrap`.
- **Save bar** — the test for what's worth keeping: what the conversation settled, or a question you asked and got an answer to, that you'd want to find again. By default it leans to keeping when unsure.

## Settings and changing the system

- **Config layers** — default (the program's), user (yours, for every wiki), and wiki (one wiki's). Each overrides the one before.
- **Tooling positions** — your stated preferences on privacy, sovereignty (how far you'll depend on services you don't control), cost and cross-platform tools. They shape what the system recommends when it changes itself. They're the `tooling.*` settings, with defaults in the program's defaults file; `/yggdrasil:init` shows them, and you set your own in your user layer, or ask Claude to.
- **Volatility** — how fast a page's topic dates: `high`, `medium` or `low`. It decides when a (requested, not automatic) staleness review looks at the page.
- **Catalog** — the program's record of settled design decisions, each with what it ruled out, in `.yg/forge-catalog.md`.
- **Technical well** — the list of literal values the program's files may carry, such as placeholder paths and example addresses. The pre-commit hook refuses anything else.
