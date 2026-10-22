---
type: reference
pitch: A taxonomy for classifying LLM chat sessions by research path, the shape of what the chat leaves behind, and when that content is committed, with named modes drawn from Diátaxis.
---

# Chat Classification

This research was done in May 2026, and the page is a snapshot of it as it stood then, not maintained.

A reference taxonomy for classifying LLM chat sessions: which research path is taken during the chat, what persistence shape the chat leaves behind, and how step-style content materialises (upfront vs JIT). It can inform:

- Which shapes are worth keeping from a chat.
- Page conventions (e.g. catalog-shaped pages support iterative co-authoring; narrative pages don't).

## The three dimensions

### A. Research path — what happens during the chat

What information is gathered, from where.

| Path | Description |
|---|---|
| External lookup | facts beyond what is already held — "what is X" / current state of the world |
| Vault recall | "do we already have this?" — answered from what the notes already hold |
| Synthesis | weighing existing + new — synthesising across sources, with existing notes as one input |
| Direct conversation | brainstorm, opinion exchange, journaling — no research needed |
| Material-in-hand | user dropped an article/transcript — processing it, alongside existing coverage |
| Codebase inspection | working on a code project — reading the code directly (or via code-discovery tools) |

### B. Persistence shape — what the chat leaves behind

Documentation shapes adopted from **Diátaxis** (Daniele Procida, [diataxis.fr](https://diataxis.fr)) — two perpendicular axes (Action↔Cognition × Acquisition↔Application) yielding four named modes. Further shapes added for non-documentation outputs.

#### Diátaxis-derived (documentation-shaped)

| Shape | Diátaxis cell | Audience | Outcome |
|---|---|---|---|
| **Tutorial** | Action × Acquisition | learner | understanding |
| **How-to** / **runbook** / **plan** | Action × Application | competent user | task done / artefact built |
| **Explanation** | Cognition × Acquisition | learner | conceptual grasp |
| **Reference** | Cognition × Application | competent user | precise lookup |

#### Non-documentation shapes

| Shape | When | Notes |
|---|---|---|
| **Decision row / ADR** | a decision was made or revisited | ADR conventions apply |
| **Source-only** | substrate worth preserving but no note crystallised | the saved chat itself is the deliverable |
| **Verbatim / discussion-preserved** | the dialogic form carries info summary would lose | chess post-mortems, ethical debates — narrow bucket |
| **MOC / catalog page** | iterative co-authoring of an entity-structured registry | chess opening catalogs; a repertoire registry with one opening per section |
| **Personal record** | fact-shaped personal info | kept outside the wiki |
| **Nothing** | not worth keeping | quick lookup, throwaway debug |

### C. Materialisation timing — when content commits

Cuts across some persistence shapes; pairs tutorials and iterative co-authoring on the same materialisation pattern despite different artefacts:

| Shape | Upfront-materialised | JIT-materialised |
|---|---|---|
| Ordered progression | plan, runbook, procedure | tutorial |
| Knowledge page | concept (one-shot summary) | MOC / catalog (iterative co-authoring) |
| Source | full source captured | (n/a) |
| Decision row | one-shot | (n/a) |
| Verbatim/discussion | (n/a — verbatim is JIT by nature) | the chat itself accreting |

Tutorial bridges: JIT during creation, accreting a step at a time, so the page *is* the artefact throughout rather than something assembled at the end. The curriculum behind it stays upfront throughout — distinct from the generic `plan` shape in the *Ordered progression* row.

## Named modes — convenience aliases

Sticky labels for common (A, B, C) combinations:

- `tutorial` = ordered-progression × JIT
- `plan` / `how-to` / `runbook` = ordered-progression × upfront
- `concept` = knowledge-page × upfront × research-needed
- `MOC-update` = knowledge-page × JIT × research-or-direct
- `decision` = decision-row × synthesis-research-path
- `discussion` = verbatim-preserved × direct-conversation
- `quick-lookup` = nothing × external-lookup-or-vault-recall
- `import` = source-capture / material-in-hand

Edge cases that don't fit a named mode declare their axis values explicitly.

## Cross-cutting observations

- **Iterative co-authoring is a page property, not a chat property.** PKM literature (digital gardens, evergreen notes, Maps of Content) treats this as page maturity / lifecycle. The chat is whatever it is (research, brainstorm, decision); the persistence target distinguishes "feeds existing MOC/catalog" from "produces new page."
- **Catalog-shaped pages support iterative co-authoring; narrative pages don't.** This works because catalogs are entity-structured (one section per entity) — additions land in their own sections without merge friction. Narrative prose lacks that property.
- **Verbatim criterion (narrow):** *"the dialogic form itself carries information that summary would lose."* Most chats fail this; chess post-mortems and ethical debates pass. Verbatim theatre and oral-history transcription sit in the same conceptual neighbourhood.
- **Tutorial vs how-to/plan are siblings, not parent-child.** Diátaxis splits on audience (learner vs competent user); materialisation timing splits the same pair on when content commits. Both cuts agree the shapes are distinct.
- **Some uses want named modes; others want axis-direct reads.** Single-tag classifiers want named modes. Deciding what to keep reads axis B directly; deciding what research to do reads axis A directly. The axes are the source of truth; named modes are surface convenience.

## Open questions / things to revisit

- **Empirical validation deferred.** The classification hasn't been pressure-tested against a varied chat corpus. Validate cell coverage as a corpus of saved chats accumulates variety.
- **Codebase inspection has no good prior art on axis A.** May need to invent. Currently sketched as its own slot; could fold into "material-in-hand" if structurally similar enough.
- **Naming collision with a page-type vocabulary.** Diátaxis terms (tutorial / how-to / explanation / reference) collide with a page `type:` vocabulary that uses the same words — `reference` and `plan`, for instance. A page type describes a *page*; persistence-shape names describe the *chat's output category*. Worth being explicit when both sets of names are in use.
- **Bloom's-flagged correlation risk.** Even apparently-orthogonal axes correlate in practice (Bloom's revised taxonomy: *contingency analysis on 940 assessment items found the dimensions are not in fact independent*, Lifescied 2020). When validation happens, expect strong A-B correlation; the orthogonality is conceptual, not statistical.
- **Iterative co-authoring as chat-class vs page-class.** Currently treated as a page property. If a classifier wants to flag "this chat is a co-authoring session against page X" up front, may want to elevate to a first-class axis-A category.

## Sources

Accessed while the research was done, May 2026; the day each was read was not recorded.

- **Diátaxis** (Daniele Procida, [diataxis.fr](https://diataxis.fr)) — primary precedent for the two-axis-with-named-modes pattern; provides Tutorial / How-to / Explanation / Reference cells.
- **DITA topic types** (Heretto / OASIS) — Concept / Task / Reference; alternative naming source.
- **Zettelkasten** (Sönke Ahrens, *How to Take Smart Notes*) — fleeting / literature / permanent / project; processing-stage axis (single-axis, maturity-flavoured).
- **Digital gardens / evergreen notes** ([Maggie Appleton on evergreens](https://maggieappleton.com/evergreens), [Andy Matuschak's evergreen-notes](https://notes.andymatuschak.org/Evergreen_notes)) — seedling / budding / evergreen; iterative co-authoring as page maturity.
- **Maps of Content** (Nick Milo et al.) — established name for the catalog/hub pattern.
- **NBER "How People Use ChatGPT"** ([w34255](https://www.nber.org/system/files/working_papers/w34255/w34255.pdf)) — Asking / Doing / Expressing intent + 22-category topic, used independently (not crossed).
- **DAMSL / SWBD-DAMSL** — multi-axis dialogue-act classification; lesson: granular schemes get unwieldy fast, deliberate collapse to a small named-mode set is normal.
- **Bloom's revised taxonomy** ([Lifescied 2020](https://www.lifescied.org/doi/10.1187/cbe.20-08-0170)) — empirical evidence "orthogonal" axes correlate.
- **Faceted classification** (Hedden, Wikipedia) — facets preferred for heterogeneous content.
- **Runbook / SOP / playbook** literature (Cutover, Glyde, Upstat) — distinguishes operational step-sequence flavours.
- **Oral history / verbatim theatre** (Smithsonian, Densho Guide, AIP Niels Bohr Library; Plato dramatised dialogues) — when "exactly what was said" is load-bearing.
