---
type: reference
pitch: A May 2026 survey of how personal knowledge management projects wire LLMs into their notes, from Karpathy's LLM wiki and Open Brain to Obsidian plugins, MCP servers and the stack patterns they share.
---

# PKM Second-Brain Survey

Researched 1 May 2026. This is a snapshot and is not maintained: figures, prices and project states are as of then.

A landscape survey of personal knowledge management projects that integrate LLMs, across 30+ consulted sources. Focuses on how others wire the *automated* layer — ingestion, RAG, agents, sync, and architecture — into an Obsidian-based vault.

This document is structured for chunkable re-reading: each H2 stands alone, each H3 within it stands alone. It does not propose a design.

---

## 1. The Karpathy LLM Wiki

Andrej Karpathy posted the seed idea as a tweet in early April 2026 and followed with a [GitHub gist titled "llm-wiki"](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) on 2026-04-04. It triggered a wave of clones and write-ups; what follows separates Karpathy's stated design from the community elaborations.

### What Karpathy actually says

- The vault is a folder of plain markdown with wikilinks.
- An LLM (Karpathy uses Claude Code) acts as a **research librarian** that ingests raw sources and incrementally builds and maintains the wiki — summaries, entity pages, cross-references, deduplication.
- Recommended structural files: `index.md` (content-oriented catalog) and `log.md` (chronological append-only ledger of ingests/changes).
- A schema/instruction file (e.g. `CLAUDE.md`) governs how the LLM is allowed to edit.
- He browses the result in **Obsidian** and mentions optional CLI tools like `qmd` for local markdown search.
- He reports one research topic grew to ~100 articles / ~400,000 words without writing any of it himself.

### What's notable about the design

- **No vector database, no RAG.** The wiki itself is the index. At 400k words an `index.md` of titles + short descriptions still fits in a long-context model (Karpathy's framing: "compile-time vs query-time knowledge assembly").
- **Three layers:** raw sources (immutable), wiki (LLM-maintained), schema (instructions). The clones consistently preserve this triad — see [Codersera writeup](https://ghost.codersera.com/blog/karpathy-llm-knowledge-base-second-brain/) and [VentureBeat](https://venturebeat.com/data/karpathy-shares-llm-knowledge-base-architecture-that-bypasses-rag-with-an).
- **Compounding artifact thesis:** "the wiki itself becomes a compounding artifact" — a once-derived synthesis page costs less than re-deriving from sources every query.
- The "70x more efficient than RAG" figure circulating in third-party blog posts is unverified; treat as marketing math.

### Public clones / scaffolds inspired by it

- [kfchou/wiki-skills](https://github.com/kfchou/wiki-skills) — Claude Code Skills implementing the pattern.
- [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) — Claude + Obsidian persistent wiki vault, `/wiki` `/save` `/autoresearch` commands.
- [ScrapingArt/Karpathy-LLM-Wiki-Stack](https://github.com/ScrapingArt/Karpathy-LLM-Wiki-Stack) — a build-ready reference pairing Obsidian and Claude Code.
- [eugeniughelbur/obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain) — Claude Code skill, 31 commands as of May 2026, scheduled agents.

---

## 2. Nate B. Jones' Open Brain (OB1)

Nate B. Jones (creator-economy / AI commentator) released [OB1 / Open Brain](https://github.com/NateBJones-Projects/OB1) in March 2026. Where Karpathy treats the wiki as the index, OB1 treats a vector database as the index and exposes it over MCP.

### Verified stack

- **Database:** PostgreSQL with the **pgvector** extension.
- **Hosting:** [Supabase](https://supabase.com) by default; "fully self-hosted K8s deployment with PostgreSQL + pgvector — no Supabase required" is documented as an alternative.
- **Languages in repo:** TypeScript (~51%), JavaScript (~21%), Python (~16%), PL/pgSQL (~9%), Svelte (~2%).
- **Interface:** MCP server with four tools — semantic search, browse recent thoughts, stats, capture.
- **Cost:** Jones claims ~$0.10–0.30/month at typical personal volume, ~45-min setup.

### Design ideas worth lifting

- **One database, many clients.** The same Postgres+pgvector store is consumed by Claude, ChatGPT, Cursor, etc. via MCP — the "any AI you use can query your accumulated context through a single open protocol" framing.
- **Capture from anywhere.** A thought typed in Slack is embedded, classified, and searchable from any MCP-connected tool seconds later.
- **Companion prompts as scaffolding.** Five lifecycle prompts: migrate existing AI memories in, bring an existing second brain in, daily-capture habit, weekly review, fit-it-to-your-workflow discovery.

The exact embedding model is **not** explicitly documented, per the repo's top-level docs; flag as unverified.

Sources: [Open Brain setup guide](https://promptkit.natebjones.com/20260224_uq1_guide_main), [Nate's Substack post](https://natesnewsletter.substack.com/p/every-ai-you-use-forgets-you-heres), [SimpleNews summary](https://www.simplenews.ai/news/ob1-open-brain-offers-dollar010month-personal-knowledge-infrastructure-for-ai-agents-ssf5).

---

## 3. Other notable public examples

### 3.1 Obsidian plugins doing RAG inside the vault

- **[Smart Connections](https://github.com/brianpetro/obsidian-smart-connections)** — Local-first. Generates embeddings on-device using small transformer models, stores them locally, surfaces semantically related notes, supports a chat interface. Can also call cloud LLMs as the generator. Privacy stance: indexing and retrieval are local; only generation hits an API if you choose one.
- **[Copilot for Obsidian (logancyang)](https://github.com/logancyang/obsidian-copilot)** — Vault QA with RAG, plus a "Copilot Plus" tier with agentic tools, web/YouTube context, multimodal. Free tier sends only to your configured LLM provider.
- **[obsidian-mcp-tools (jacksteamdev)](https://github.com/jacksteamdev/obsidian-mcp-tools)** — Bridges Obsidian to any MCP client and adds semantic search and Templater prompt tools.

### 3.2 Standalone "second brain" apps with LLMs baked in

- **[Khoj](https://github.com/khoj-ai/khoj)** — Self-hostable, modular pipeline (retrieval / indexing / fusion / generation as substitutable modules). Ingests PDFs, Markdown, Notion, Word, org-mode. Clients: web, desktop, Obsidian plugin, Emacs, WhatsApp. Bring-your-own-LLM (local via Ollama, or cloud).
- **[Reor](https://github.com/reorproject/reor)** — Desktop app, Obsidian-like markdown editor. Stack: **Llama.cpp + Transformers.js + LanceDB**, all in-process. Auto-links notes by vector similarity, RAG Q&A. Strict local-first.
- **[Basic Memory](https://github.com/basicmachines-co/basic-memory)** — MCP-first. Python. SQLite (or Postgres) index over markdown files; FastEmbed for embeddings; markdown stays the source of truth. Exposes `write_note`, `read_note`, `edit_note`, `build_context`, `recent_activity`, `search`, `canvas`, etc. Designed so notes Claude writes appear immediately in Obsidian and vice versa.
- **[SilverBullet](https://github.com/silverbulletmd/silverbullet)** — Browser-based, self-hosted, programmable (Lua). Has a separate [AI plug](https://ai.silverbullet.md/). Different philosophy — "notes as a programmable system" — but worth knowing about.
- **[Anytype](https://github.com/anyproto/anytype-mcp)** — Encrypted local-first Notion-alike with an official MCP server.
- **[Atomic (kenforthewin)](https://github.com/kenforthewin/atomic)** — Markdown notes auto-chunked, embedded, tagged, linked by similarity; agentic chat.

### 3.3 Obsidian MCP servers (the "vault as tools" layer)

A field of overlapping implementations. Pick on tool surface and transport. Tool counts are as of May 2026.

- **[cyanheads/obsidian-mcp-server](https://github.com/cyanheads/obsidian-mcp-server)** — 14 tools, requires the Local REST API plugin; surgical edits to notes/tags/frontmatter.
- **[MarkusPfundstein/mcp-obsidian](https://github.com/MarkusPfundstein/mcp-obsidian)** — list/read/search/patch/append/delete via Obsidian REST API.
- **[StevenStavrakis/obsidian-mcp](https://github.com/StevenStavrakis/obsidian-mcp)** — read/create/edit/delete/move/search + tag management.
- **[rps321321/obsidian-mcp-pro](https://github.com/rps321321/obsidian-mcp-pro)** — 23 tools incl. link analysis, graph traversal, canvas.
- **[eddmann/obsidian-mcp](https://github.com/eddmann/obsidian-mcp)** — Git-backed; supports stdio, HTTP, and AWS Lambda remote deployment.
- **[bitbonsai/mcpvault](https://github.com/bitbonsai/mcpvault)** — Lightweight, safety-focused.

### 3.4 Logseq-side equivalents

- **[twaugh/logsqueak](https://github.com/twaugh/logsqueak)** — LLM+RAG that takes journal chaos and files extracted insights into the graph. Closest to a "daily-notes-as-buffer" automation.
- **[calvincchan/logseq-rag](https://github.com/calvincchan/logseq-rag)** — Local LLM, later iteration uses Qdrant for vectors.
- **Joel Hooks' Logseq Knowledge Graph MCP Server** — referenced widely; positions MCP as the read/write upgrade over read-only RAG.

### 3.5 Commercial / closed

- **[Mem.ai](https://productivitystack.io/guides/mem-ai-guide/)** — AI-native, no folders/hierarchies, "Mem Chat" against your captures. Mem 2.0 shipped early 2026. As of May 2026, cloud-only, individual focus.
- **[Notion AI](https://www.eesel.ai/blog/best-ai-for-notion)** — Workspace-scoped Q&A and writing.

---

## 4. Tech-stack patterns

### 4.1 Embedding & vector storage

| Layer | Common picks | Notes |
|---|---|---|
| Embedded / single-process | **LanceDB**, **sqlite-vec** (formerly sqlite-vss), in-memory FAISS | LanceDB is the de-facto pick for desktop apps; ~4 MB idle / ~150 MB active per third-party benchmarks. Reor uses it. sqlite-vec is the "ship a `.db` file" option — runs in WASM, on Pi. |
| Local server | **Qdrant**, Chroma | Qdrant is fast but eats ~400 MB RAM constantly. Logseq-rag moved to it. |
| Networked / hybrid | **pgvector** (Postgres), Pinecone, Weaviate | OB1 picks pgvector specifically because Supabase makes it cheap personally. |
| Skip vectors | **None** — Karpathy-style | Viable when corpus fits in long-context, or when an LLM-maintained `index.md` does the work of an index. |

Sources: [sqlite-vec](https://github.com/asg017/sqlite-vec), [LanceDB vs Qdrant benchmarks](https://www.threads.com/@bsunter/post/DQfwyv-iX5z/), [Encore vector DB comparison](https://encore.dev/articles/best-vector-databases).

### 4.2 RAG framework vs hand-rolled

- **LlamaIndex** dominates the "I want a pipeline I didn't write" crowd; common for Ollama-backed self-hosted setups.
- **LangChain** appears more in tutorials than in actually maintained personal projects.
- **Hand-rolled** is the norm for the apps with strong opinions (Reor, Khoj, Smart Connections, Basic Memory) — they all wire embeddings, chunking, and retrieval themselves rather than depend on a heavy framework.
- **No-framework / Karpathy-style** — just a folder, a model, and a CLAUDE.md.

### 4.3 Ingestion pipelines

- **ChatGPT exports** — The official Settings → Data Controls → Export emits JSON. Tools like [daugaard47/ChatGPT_Conversations_To_Markdown](https://github.com/daugaard47/ChatGPT_Conversations_To_Markdown) convert to Obsidian-friendly md. [ChatKeeper](https://www.martiansoftware.com/chatkeeper/) attempts continuous sync of ongoing ChatGPT conversations into a local md archive.
- **Web clippings** — Obsidian Web Clipper (official) for pages; readwise/omnivore-style hooks for highlights. Smart Connections / Copilot can ingest URLs ad-hoc.
- **PDFs / papers** — Most apps (Khoj, Reor, Copilot Plus) parse PDFs natively; Karpathy-style setups typically convert PDFs to markdown first (e.g. via `marker`, `pdfminer`, or an LLM pre-pass).
- **Recordings / transcripts** — Whisper (local or API) is the default; some users pipe through Otter/Fireflies and re-import the markdown.
- **Email** — Less standardized; Khoj has connectors; otherwise IMAP-to-md scripts.

### 4.4 Local vs cloud (privacy posture)

A spectrum, not a binary:

1. **Pure local** — Reor, Khoj+Ollama, Smart Connections w/ local embeddings. No data leaves the box.
2. **Local index, cloud generation** — Smart Connections default, Copilot free tier, most "RAG with Claude API" setups. Embeddings stay local; the chunks sent at query time go to the LLM provider.
3. **Cloud index, cloud generation** — OB1 on Supabase, Mem.ai, Notion AI. Trust depends on hosting model.
4. **Hybrid** — Khoj cloud or self-host as a deployment knob; OB1 with the K8s self-host alternative.

The honest tradeoff: pure-local capability is better than two years ago, but frontier reasoning still lives in the API. Most public setups accept the cloud-generation step.

### 4.5 Agent / assistant integration

- **Claude Code** — The dominant pattern for the markdown-vault crowd. Reads/writes files, Skills + slash-commands organize behaviors, MCP extends to tools.
- **MCP servers** — The interop layer. A vault MCP server makes the same notes addressable from Claude Desktop, Claude Code, Cursor, ChatGPT (via desktop connectors), Continue, etc.
- **Custom GPTs** — Largely supplanted for this use case; OK for share-with-team scenarios.
- **Obsidian plugins** — In-vault assistants (Smart Connections, Copilot, Khoj) trade flexibility for tight UI integration.
- **CLI** — Simon Willison's [llm](https://github.com/simonw/llm) + sqlite-utils + Datasette is the dominant Unix-y stack: every command logged to SQLite, queryable via Datasette. Closer to "tools for thinking" than a complete second brain, but composes well.

### 4.6 Sync & multi-device

- **Syncthing** — The community-favored free option. P2P, syncs `.obsidian/` cleanly, "just works" for most.
- **Git** — Version history is the win; mobile is the pain. Tolerable for desktop-only users; conflict-prone if the same file is edited concurrently. eddmann's MCP server bakes git sync in.
- **Self-hosted LiveSync (CouchDB plugin)** — Live, conflict-free, near-paid-Sync experience. Setup is the trade.
- **Obsidian Sync (official)** — $5/mo as of May 2026, end-to-end encrypted, lowest-friction.
- **iCloud / Dropbox / OneDrive** — Common but flaky with `.obsidian/` folder; not recommended for plugin-heavy vaults.

Sources: [Sean Susmilch's Syncthing guide](https://seansusmilch.github.io/posts/obsidian-syncthing-private-sync-guide/), [Obsidian Forum: Syncthing or Git on Oracle Free Tier](https://forum.obsidian.md/t/setting-up-syncthing-or-git-on-oracle-cloud-free-tier-for-a-similar-setup-to-obsidian-sync/102633).

---

## 5. Architectural patterns recurring across projects

### 5.1 Raw / processed separation

Karpathy's three-layer model (raw sources → wiki → schema) is the most discussed instance, but Khoj's modular pipeline and Basic Memory's "markdown is canonical, SQLite is derived index" implement the same idea. The principle: **what the human authored** and **what the LLM derived** should be visually and physically distinguishable, so the LLM never accidentally overwrites your prose.

A common variant: raw sources live in a folder *outside* the Obsidian vault entirely, and only stubs/summaries land inside. Keeps the vault graph clean.

### 5.2 Atomic vs literature notes

The Zettelkasten distinction (one idea per note, source-faithful summaries vs original synthesis) maps cleanly onto the LLM-era setup. The LLM is good at literature notes (summarize this PDF) and mediocre at atomic notes (which idea exactly belongs in its own page?). Most working setups have the LLM produce literature notes, and humans (or a higher-quality model with a careful prompt) carve out atoms.

### 5.3 Daily notes as ingestion buffer

Recurring pattern: an `Inbox/YYYY-MM-DD.md` file that captures everything raw, plus a session protocol where the agent reads the most recent inbox file at start, processes unprocessed items, and files them. See [bitsofchris on running AI agents from Obsidian](https://bitsofchris.com/p/how-i-run-ai-agents-from-my-obsidian) and [eric m. jl's PKM-with-AI post](https://ericmjl.github.io/blog/2026/3/6/mastering-personal-knowledge-management-with-obsidian-and-ai/). Daily notes work because they're cheap to skim and have a natural processing rhythm.

### 5.4 Map-of-Content (MOC) structures

MOCs (a manually curated index note linking related notes) predate LLMs and have become *more* useful with them, not less. The `index.md` Karpathy specifies is essentially an LLM-maintained MOC. The LLM can keep MOCs honest (auto-add new pages, prune dead links), which is the upkeep that historically rotted manual MOCs. The mental model: **MOCs emerge bottom-up; the LLM is the gardener that prunes and replants**.

### 5.5 Embedding-on-write vs batch

- **On-write** (Smart Connections, Reor, Basic Memory): file event → re-embed that file. Index stays warm. Cost is invisible per-edit but adds up; throttled in most implementations.
- **Batch** (DIY scripts, some LlamaIndex setups): periodic reindex, nightly cron. Simpler, cheaper, but searches against stale data between runs.
- The Karpathy approach sidesteps both — there *is* no embedding step; the LLM rebuilds the index file when it ingests new sources.

### 5.6 Bidirectional sync between tools

Basic Memory is the sharpest example: Claude writes via MCP, Obsidian reads the same `.md`, both views stay coherent. The pattern generalizes — the markdown file is the contract, every tool agrees not to introduce its own database as the source of truth. This is why the markdown-first projects compose well and the database-first ones (Mem, Notion AI) don't.

### 5.7 Schema/instruction file as policy layer

`CLAUDE.md`, `AGENTS.md`, or equivalent at the vault root, telling the agent: where new notes go, what format, what to never touch, what naming convention. Karpathy's "schema layer." The non-obvious bit: this file is the closest thing to **versioned governance** of an LLM-maintained system. When behavior drifts, you edit the schema, not chase prompts.

---

## 6. Patterns worth considering

Opinionated takeaways for design work. Flagged as working vs cargo-culted, with the assessment stated rather than hedged.

### 6.1 The markdown-as-contract pattern is real and worth defending

Every project that decouples cleanly across tools (Basic Memory, the various MCP servers, Karpathy's wiki, Khoj) treats markdown files as the source of truth and any database as derived/disposable. Every project that doesn't (Mem, Notion AI) locks you in. **Working.**

### 6.2 Vector RAG is not a foregone conclusion

The Karpathy bet — "long context + a maintained index file beats a vector DB at personal scale" — looks credible up to several hundred thousand words. Below that, a vector DB is overhead. Above it, you'll want either RAG *or* hierarchical summaries. The decision is corpus-size-dependent, not aesthetic. **Genuinely contested; not cargo-cult.**

### 6.3 Three layers (raw / processed / schema) keep you sane

Even if you don't follow Karpathy's exact files, the pattern of physically separating "what I dumped in" from "what got synthesized" from "what governs the synthesis" prevents the agent eating your authored prose. **Working; cheap to adopt.**

### 6.4 MCP is the right interop bet right now

Picking a vault MCP server — even just `MarkusPfundstein/mcp-obsidian` plus the Local REST API plugin — gets you Claude Code, Claude Desktop, and Cursor-side access for free. Don't custom-build read/write tools per agent. **Working.**

### 6.5 Daily-notes-as-inbox is durable

It pre-dates LLMs, scales down to "I forgot for a week," and gives the agent a natural processing handle. The variants that fail are the ones with no scheduled processing trigger — captures pile up forever. **Working when paired with a regular review.**

### 6.6 Skip the sync stack you don't need

Syncthing for two devices, Obsidian Sync if you want to pay $5 to not think about it. Self-hosted LiveSync is real-time but fragile with heavy plugins. Git is great for history, terrible alone for mobile. **The hot setups are not the right setups; pick on your actual device count.**

### 6.7 Local embeddings are good enough; local generation usually isn't

Reor and Smart Connections demonstrate that on-device embeddings are fast, private, and competitive. Local generation (Llama 3.x via Ollama) is *usable* but visibly weaker than the frontier APIs at the synthesis tasks that matter for a second brain. **Hybrid (local embed, cloud generate) is the realistic privacy sweet spot.**

### 6.8 Watch out for the "AI second brain" demo trap

Many of the public writeups (especially the Medium/Substack genre) are demos that haven't been lived in for six months. The projects with sustained development and real users are: Khoj, Smart Connections, Copilot, Basic Memory, Reor, the Logseq RAG efforts, and Karpathy's pattern as practiced (not just blogged about). Weight your borrowing accordingly. **Active filter.**

---

## 7. Gaps and caveats

- **Karpathy's exact tool list is partially community-reconstructed.** The gist itself is short. "qmd" / Obsidian / Claude Code are mentioned by him; some specifics in third-party blog posts (e.g. exact CLAUDE.md content) are extrapolated. Treat the gist as canon.
- **OB1's embedding model is not explicitly documented** in the top-level GitHub README sections checked. Likely an OpenAI or open-source embedding model called from the Supabase edge function, but unverified here — read the migration scripts to confirm.
- **Mem.ai internals are not public.** All claims about Mem are based on user-facing behavior described in 2026 reviews.
- **The "70x more efficient than RAG" figure** circulating about the LLM Wiki appears in third-party blog posts; the survey did not find it in Karpathy's own writing. Treat as unverified hype.
- **Maggie Appleton's stack:** searches did not surface a public, current LLM-integrated PKM setup specifically by her. Her digital-garden writing is foundational but outside this survey's scope. Excluded.
- **Logseq AI ecosystem** is moving but smaller and noisier than Obsidian's; coverage here is selective rather than exhaustive.
- **Time horizon:** this snapshot is May 2026. As of then, the MCP server space in particular was ~6 months from settling; expect consolidation around 2–3 dominant Obsidian MCP implementations within the year.

---

## Sources

Accessed while the research was done, May 2026; the day each was read was not recorded.

### Primary (creators' own writing)

- Andrej Karpathy — [llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- Andrej Karpathy — [year-in-review 2025](https://karpathy.bearblog.dev/year-in-review-2025/)
- Andrej Karpathy — [tweet on context engineering](https://x.com/karpathy/status/1937902205765607626)
- Nate B. Jones — [OB1 GitHub](https://github.com/NateBJones-Projects/OB1)
- Nate B. Jones — [Open Brain setup guide](https://promptkit.natebjones.com/20260224_uq1_guide_main)
- Nate B. Jones — [Substack: every AI starts from zero](https://natesnewsletter.substack.com/p/every-ai-you-use-forgets-you-heres)

### Project repositories

- [kfchou/wiki-skills](https://github.com/kfchou/wiki-skills)
- [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)
- [ScrapingArt/Karpathy-LLM-Wiki-Stack](https://github.com/ScrapingArt/Karpathy-LLM-Wiki-Stack)
- [eugeniughelbur/obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain)
- [brianpetro/obsidian-smart-connections](https://github.com/brianpetro/obsidian-smart-connections)
- [logancyang/obsidian-copilot](https://github.com/logancyang/obsidian-copilot)
- [khoj-ai/khoj](https://github.com/khoj-ai/khoj)
- [reorproject/reor](https://github.com/reorproject/reor)
- [basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory)
- [silverbulletmd/silverbullet](https://github.com/silverbulletmd/silverbullet)
- [SilverBullet AI plug](https://ai.silverbullet.md/)
- [anyproto/anytype-mcp](https://github.com/anyproto/anytype-mcp)
- [twaugh/logsqueak](https://github.com/twaugh/logsqueak)
- [calvincchan/logseq-rag](https://github.com/calvincchan/logseq-rag)
- [kenforthewin/atomic](https://github.com/kenforthewin/atomic)
- [cyanheads/obsidian-mcp-server](https://github.com/cyanheads/obsidian-mcp-server)
- [MarkusPfundstein/mcp-obsidian](https://github.com/MarkusPfundstein/mcp-obsidian)
- [StevenStavrakis/obsidian-mcp](https://github.com/StevenStavrakis/obsidian-mcp)
- [rps321321/obsidian-mcp-pro](https://github.com/rps321321/obsidian-mcp-pro)
- [eddmann/obsidian-mcp](https://github.com/eddmann/obsidian-mcp)
- [bitbonsai/mcpvault](https://github.com/bitbonsai/mcpvault)
- [jacksteamdev/obsidian-mcp-tools](https://github.com/jacksteamdev/obsidian-mcp-tools)
- [asg017/sqlite-vec](https://github.com/asg017/sqlite-vec)
- [daugaard47/ChatGPT_Conversations_To_Markdown](https://github.com/daugaard47/ChatGPT_Conversations_To_Markdown)
- [ChatKeeper](https://www.martiansoftware.com/chatkeeper/)
- [simonw/llm](https://github.com/simonw/llm)

### Third-party analysis / writeups

- VentureBeat — [Karpathy bypasses RAG with evolving markdown library](https://venturebeat.com/data/karpathy-shares-llm-knowledge-base-architecture-that-bypasses-rag-with-an)
- Codersera — [Karpathy LLM knowledge base writeup](https://ghost.codersera.com/blog/karpathy-llm-knowledge-base-second-brain/)
- Atlan — [LLM Wiki vs RAG](https://atlan.com/know/llm-wiki-vs-rag-knowledge-base/)
- SimpleNews — [OB1 Open Brain summary](https://www.simplenews.ai/news/ob1-open-brain-offers-dollar010month-personal-knowledge-infrastructure-for-ai-agents-ssf5)
- Eric Ma — [Mastering PKM with Obsidian and AI](https://ericmjl.github.io/blog/2026/3/6/mastering-personal-knowledge-management-with-obsidian-and-ai/)
- bitsofchris — [Running AI agents from Obsidian](https://bitsofchris.com/p/how-i-run-ai-agents-from-my-obsidian)
- Sean Susmilch — [Syncthing for Obsidian](https://seansusmilch.github.io/posts/obsidian-syncthing-private-sync-guide/)
- Obsidian Forum — [Syncthing or Git on Oracle Cloud Free Tier](https://forum.obsidian.md/t/setting-up-syncthing-or-git-on-oracle-cloud-free-tier-for-a-similar-setup-to-obsidian-sync/102633)
- bsunter on Threads — [LanceDB vs Qdrant benchmarks](https://www.threads.com/@bsunter/post/DQfwyv-iX5z/)
- Encore — [Vector database comparison](https://encore.dev/articles/best-vector-databases)
- Productivity Stack — [Mem.ai 2026 review](https://productivitystack.io/guides/mem-ai-guide/)
- eesel — [Best AI for Notion](https://www.eesel.ai/blog/best-ai-for-notion)
- MotherDuck — [Obsidian RAG with DuckDB](https://motherduck.com/blog/obsidian-rag-duckdb-motherduck/)
