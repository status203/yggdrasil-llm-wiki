---
type: reference
pitch: A survey of the MCP servers that give an LLM access to an Obsidian vault, comparing how each is built, what it can do (especially renaming a note and updating links to it), and whether it needs Obsidian running.
---

# Obsidian MCP Servers

Researched 2026-05-04. A snapshot, not maintained: the space had not settled when this was done, so read it as a starting point to check again, not as a current account.

Survey of Model Context Protocol servers that target an Obsidian vault, looking at whether an LLM working on a vault is better served writing to its files directly or going through an MCP.

## Headline

**Vault-wide renames are the case an MCP handles more cleanly than plain filesystem writes**, and several such servers already exist. The choice splits along one architectural axis:

- **Filesystem-direct servers** — work without Obsidian running (good for headless / remote / CI). Must reimplement Obsidian's link-rewrite logic, so edge-case fidelity depends on the maintainer.
- **Obsidian-plugin servers** — call Obsidian's own `fileManager.renameFile` API, so link updating is GUI-perfect for free. But Obsidian must be running on the same machine.

Of the popular Local REST API servers, none currently expose rename-with-link-update — so popularity isn't a guide here.

A relevant Obsidian-side gotcha: `Vault.rename` does **not** update links; only `fileManager.renameFile` does. Any plugin-based MCP must use the latter to deliver the capability.

## Capability matrix

Last-push dates and star counts as of 2026-05-04.

| Server | Architecture | Obsidian must run? | Rename + auto link-update | Folder rename | Backlinks/orphans | Last push | Stars |
|---|---|---|---|---|---|---|---|
| [obsidian-mcp-pro](https://github.com/rps321321/obsidian-mcp-pro) | Filesystem | No | **Yes** (regex+parser, parity claim) | No (loop `move_note`) | Yes | 2026-05-01 | 10 |
| [aaronsb/obsidian-mcp-plugin](https://github.com/aaronsb/obsidian-mcp-plugin) | Obsidian plugin (HTTP) | **Yes** | **Yes** (native `fileManager.renameFile`) | Unverified | Yes (graph) | 2026-05-04 | 301 |
| [StevenStavrakis/obsidian-mcp](https://github.com/StevenStavrakis/obsidian-mcp) | Filesystem | No | **Yes** (regex on `[[…]]` and `[…](…)`) | No | No | 2025-06-23 | 696 |
| [MarkusPfundstein/mcp-obsidian](https://github.com/MarkusPfundstein/mcp-obsidian) | Local REST API | **Yes** | No | No | No | 2025-06-28 | 3,572 |
| [cyanheads/obsidian-mcp-server](https://github.com/cyanheads/obsidian-mcp-server) | Local REST API | **Yes** | No | No | Search only | 2026-05-04 | 488 |
| [bitbonsai/mcpvault](https://github.com/bitbonsai/mcpvault) | Filesystem | No | No (move only, no relink) | No | No | 2026-04-27 | 1,195 |
| [jacksteamdev/obsidian-mcp-tools](https://github.com/jacksteamdev/obsidian-mcp-tools) | Plugin + REST | **Yes** | No | No | No | unmaintained | 797 |

## Notable servers

### obsidian-mcp-pro — filesystem, full link maintenance

Filesystem-direct Node.js. 23 tools incl. `move_note` (default `updateLinks: true`), `delete_note` (with optional `removeReferences`), `find_orphans`, `find_broken_links`, `get_graph_neighbors`, frontmatter, daily-note, canvas read/edit. Vault discovery via env var or `obsidian.json`. Rewrites wikilinks (preserving aliases & fragments), markdown links, and canvas refs; v1.6 changelog explicitly claims parity with Obsidian's "Automatically update internal links". Optional HTTP transport with bearer auth, rate limits, CORS allowlist, and DNS-rebinding protection for remote use.

**Caveats:** young (Mar 2026), 10 stars, single primary author — non-trivial bus factor. No dedicated folder-rename tool (would need a loop of `move_note` calls).

### aaronsb/obsidian-mcp-plugin — plugin, native API

Runs as a community plugin; HTTP on 3001/3443. Eight semantic tool groups: vault (list/read/create/search/**move/rename**/split/combine), edit, view, graph, workflow, dataview, bases, system. `move` and `rename` both call `app.fileManager.renameFile` — Obsidian-perfect link updating for free, with a copy-and-delete fallback for AbstractFile lookup misses.

**Caveats:** Obsidian must be running and unlocked. Folder rename uses a separate code path (only file rename was source-confirmed to use the native API). Single author, 301 stars.

### StevenStavrakis/obsidian-mcp — filesystem, regex rewriter

12 tools incl. `move-note`, multi-vault support, tag ops. Source confirms `updateLinksInFile` / `updateVaultLinks` handles four scenarios with regex on `[[note]]` and `[text](note.md)` forms. README warns users to back up before use.

**Caveats:** ~11 months without a commit (borderline stale). Regex parser less battle-tested than mcp-pro's; behaviour inside fenced code blocks, embeds (`![[…]]`), and complex aliases not verified to match Obsidian.

### MarkusPfundstein/mcp-obsidian — Local REST API, no rename

Most popular Obsidian MCP (3.5k stars), but exposes only 7 tools (list / read / search / patch / append / delete). **No rename, no move, no link tools.** Disqualified for a rename-heavy workflow.

### cyanheads/obsidian-mcp-server — Local REST API, polished, no rename

Best-polished Local REST API surface: 14 tools across readers/writers/managers/UI, including frontmatter and tag managers, plus opt-in `obsidian_execute_command`. Active and well-maintained. **No rename or move tool.**

## Local vs remote vault

- **Same-machine only:** all Local REST API servers and the in-Obsidian plugin assume Obsidian is running on the host where the MCP server runs. They can be exposed to a remote MCP *client* by tunnelling, but vault and Obsidian process stay co-located.
- **Headless / remote vault:** filesystem servers (`obsidian-mcp-pro`, `StevenStavrakis/obsidian-mcp`, `mcpvault`) work over SSH, in Docker, in CI, on a server with the vault on a mounted volume. `obsidian-mcp-pro` additionally hardens its HTTP transport for remote-MCP-server deployment.

If LLM action on the vault ever needs to happen when Obsidian isn't open (cron, server agents, CI doc-gen), only the filesystem servers fit.

## Implications for an LLM-maintained vault

- Large structural renames (folder reorganisations, vault-wide file renames) are mostly handled by `obsidian-mcp-pro` or `aaronsb/obsidian-mcp-plugin`. Plain filesystem writes leave broken wikilinks that subsequent passes have to clean up.
- The popular Local REST API servers do **not** solve this — popularity isn't the guide.
- Folder renames aren't a first-class capability of any surveyed server; they'd still come down to looping per-file moves or a regex pass plus filesystem `mv`.
- Both leading candidates have a bus-factor concern (single primary author). `obsidian-mcp-pro` is younger but does the job filesystem-direct; `aaronsb/obsidian-mcp-plugin` has higher fidelity but couples to a running Obsidian process.

## Uncertainty / not-investigated

- Folder-rename behaviour of `aaronsb/obsidian-mcp-plugin` — file rename was source-confirmed; folder path uses a separate code path that wasn't verified.
- Edge-case fidelity of the `StevenStavrakis/obsidian-mcp` regex rewriter inside fenced code, embeds, and aliases vs Obsidian's GUI behaviour.
- Whether either Local REST API server could compose existing primitives (or `obsidian_execute_command`) to back into a rename-with-relink — possible in principle, not exposed today.
- Smaller forks/alternates skipped to keep scope: `ToKiDoO/mcp-obsidian-advanced`, `OleksandrKucherenko/mcp-obsidian-via-rest`, `j-shelfwood/obsidian-local-rest-api-mcp`, `aaronsb/obsidian-semantic-mcp` (predecessor), `Ar9av/obsidian-wiki`.

## Sources

Accessed while the research was done, May 2026; the day each was read was not recorded.

- [Obsidian forum: Vault.rename doesn't trigger link update](https://forum.obsidian.md/t/vault-rename-file-path-doesnt-trigger-link-update/32317) — confirms `fileManager.renameFile` is the only API path that updates links.
- [Obsidian forum: MCP server experiences](https://forum.obsidian.md/t/obsidian-mcp-servers-experiences-and-recommendations/99936) — community thread; rename-with-link-update isn't a common discussion point, suggesting most users haven't framed the question this way.
- [morphllm.com — Obsidian MCP server survey (2026)](https://www.morphllm.com/obsidian-mcp-server) — independent survey cross-referencing the same five core servers (validates the candidate set).
- Per-server READMEs and source files linked inline in § *Capability matrix*.
