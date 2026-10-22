---
type: reference
pitch: A survey of the kinds of material people drop into LLM tools, why they do, how each kind tends to be kept, and where people disagree about keeping it.
---

# LLM Substrate Survey

Researched May 2026, filed 2026-05-06. A snapshot, not maintained: read it as a starting point to check again, not as a current account.

An external survey of the public PKM / LLM-productivity landscape: what people drop into LLM interfaces, and why.

## Summary

LLM-mediated capture is dominated by a handful of high-frequency substrate shapes — pasted/uploaded long-form documents (articles, papers, contracts, reports), code snippets and stack traces, screenshots and photos (UI, whiteboards, handwritten notes, plants/objects), spreadsheets and CSVs, audio (voice memos, meeting recordings, podcasts, lectures) and their transcripts, video transcripts (YouTube being the canonical case), and ad-hoc clippings (tweets/threads, Slack/email snippets, book highlights, RSS-newsletter posts, prior chat exports). NotebookLM's source-list UI converges on the same shape: PDF, .docx, .txt, .md, Google Docs/Slides/Sheets, web URL, public YouTube URL, audio file, image, EPUB, and direct paste. The reasons people drop these in cluster into a smaller set than the types themselves: summarise, extract action items / structured data, OCR or transcribe for downstream use, cite later, decide-input (compare options, evaluate clauses), critique or draft against, brainstorm partner, explain/teach, and "just-in-case archive." Reason and type are partly orthogonal: the same article PDF may be a cite-later substrate or a draft-critique target depending on intent, and the same screenshot may be an OCR job, a UI debugging job, or an "is this plant safe?" identification job. The PKM community treats this as the central capture problem ("capture everything, distill later") and has not converged on a single right answer; the contention is mostly about *density* (full text vs. summary vs. URL) and *atomicity* (one note per source vs. fragmented permanent notes).

## Findings — substrate inventory

### 1. Web article / blog post / news piece

- **Reasons.**
  - Summarise long-form content (most common single use case in the OpenAI study's "Writing → Summarising/Editing Provided Text" subgroup).
  - Extract claims for citation later.
  - Decision input ("is this product/service worth it?").
  - Just-in-case archive against link rot.
  - Translate.
  - Critique: "find the weak arguments here."
- **What captured looks like.** Two dominant shapes: (a) Readwise Reader / Pocket / Instapaper — full text snapshot + user highlights, kept indefinitely, with the original URL; (b) Obsidian Web Clipper — URL + auto-summary + extracted body in markdown, written into an inbox folder. NotebookLM's web-URL source extracts text only and pins to a notebook.
- **Contention.** Density argument: progressive-summarisation purists (Forte/PARA) say keep highlights only; Readwise-aligned users keep full body for re-summarisation. URL-only vs. full text is the recurring "first principle" question on r/PKMS and Obsidian forums.

### 2. Academic / scientific paper (PDF)

- **Reasons.**
  - "Explain this paper to me" tutoring.
  - Extract methods / claims / cite-as for literature review.
  - Compare and contrast multiple papers ("where do these authors disagree?").
  - Generate study notes, flashcards, exam prep.
  - Drop multi-paper bundles into Claude Projects / NotebookLM for cross-paper Q&A.
- **What captured looks like.** Whole-PDF retention is standard — Claude's 200K window (as of May 2026) allows ~10–15 papers in one conversation. NotebookLM and Perplexity Spaces both treat papers as a primary substrate. Zotero/Obsidian users keep PDF + literature note + metadata + highlights.
- **Contention.** LLM-generated citations are unreliable; community advice is to use Zotero/Mendeley for citations and treat LLM only as a reading aid. Whether to OCR scanned-image PDFs is also unsettled.

### 3. Book chapter / book highlights / EPUB

- **Reasons.**
  - Distill book into permanent notes (Zettelkasten literature notes).
  - Quote-mining for own writing.
  - "Quiz me on this chapter."
  - Re-engage with content read months/years ago.
- **What captured looks like.** Kindle/Apple Books/Kobo highlights flow through Readwise into Obsidian/Notion. NotebookLM added EPUB as a first-class type in late 2025. Permanent notes are typically rewritten in own words rather than verbatim.
- **Contention.** Progressive summarisation vs. atomic permanent notes: Forte's CODE keeps progressively bolded highlights inside the literature note; classical Zettelkasten splits each idea into its own permanent note.

### 4. Receipt / invoice / financial statement

- **Reasons.** OCR for expense reporting; extract line-items into a spreadsheet; categorise spending; tax-time aggregation.
- **What captured looks like.** Photo or scan + extracted line-item table; original receipt kept for audit trail. ChatGPT's vision OCR is now a common path. Note: image-generation models can also fake receipts, which has become a fraud concern (TechCrunch, 2025-03-31).
- **Contention.** Privacy/PII handling. Most PKM workflows do not retain receipt photos in the vault — they go to dedicated apps. When dropped into LLMs, the question is whether the extracted JSON is the artefact or whether the photo also persists.

### 5. Contract / legal document

- **Reasons.** First-pass review ("what should I worry about in this NDA?"); clause comparison; plain-language translation; drafting/redlining.
- **What captured looks like.** Whole-document upload — Claude's 200K window holds a full contract or deposition transcript. Practitioners are explicit that confidential documents must not go to public/unsecured tools.
- **Contention.** Privacy/compliance is the sharpest fault-line in the entire survey: legal/medical/HR substrate is uploadable in principle but not in practice for many users.

### 6. Spreadsheet / CSV / tabular data

- **Reasons.** Summarise data; generate charts; pivot/reshape/clean; run a small analysis (Code Interpreter / Claude code execution); Q&A against the table.
- **What captured looks like.** Direct file upload; for paste workflows, users convert to markdown tables for paste reliability. NotebookLM added Google Sheets as a source in November 2025.
- **Contention.** Whether the data itself or the result (chart, derived stats) is the capture-worthy artefact. Also whether structured data belongs in a notes vault at all.

### 7. Code snippet / file / repository

- **Reasons.** Debug/explain/fix; code review; refactor; generate tests; translate between languages.
- **What captured looks like.** For ad-hoc paste, snippet + surrounding caller (community advice: at minimum the function and one level up). For repo-scale, packers like Repomix flatten a tree into a single AI-friendly file; Claude Code reads files in place.
- **Contention.** Snippet-vs-repo: the right granularity depends on whether you want a localised fix or systemic understanding. Also whether to persist the LLM's fix alongside the snippet.

### 8. Error message / stack trace / log excerpt

- **Reasons.** Single dominant reason: debug. Subdivides into "what does this mean," "why is it happening," "give me a fix," "is this related to a known issue."
- **What captured looks like.** Almost never persisted. Pattern: paste → solution → resolved → discard. When persisted, it lands in a "things I've debugged" log or incident-postmortem note. Community advice: full trace + 10–20 lines of surrounding logs + implicated function + repro steps.
- **Contention.** Whether postmortems/debug-logs belong in a knowledge vault at all, or whether they're transient. Most PKM systems don't have an answer for "I learned something while debugging — where does that go?"

### 9. Screenshot of UI / app / error dialog

- **Reasons.** "What does this error mean?"; "How do I do X in this app?"; bug report / share with collaborator; extract text I can't easily copy (DRM-locked apps, native dialogs).
- **What captured looks like.** Either a one-shot paste (deleted after answered) or filed in a "screenshots" folder with date stamps, untriaged. ChatGPT vision OCR is reliable on digital screenshots due to clean fonts.
- **Contention.** PKM tools largely ignore screenshots — they pile up in the screenshots folder without being indexed. Known unsolved problem.

### 10. Photo of physical object (plant, food, label, error LED, sticker)

- **Reasons.** Identification ("what plant is this?"); look up nutrition/cost/origin; translate label; diagnose problem from a photo (mechanic, IT helpdesk).
- **What captured looks like.** Almost universally one-shot — photo deleted from chat, answer absorbed, original photo stays in camera roll. Plant identification is a documented popular use. NotebookLM added images in November 2025 specifically for handwritten-notes/brochures use.
- **Contention.** Volume vs. value: phone camera rolls have thousands of these; almost none are worth indexing, but the few that are (a serial-number sticker for warranty support, a receipt) are very valuable. PKM tools have no good triage story.

### 11. Handwritten notes / journal pages / scanned notebooks

- **Reasons.** OCR/digitise to make searchable; extract action items from meeting notes; migrate analog journal into digital vault; restore archival documents (genealogy).
- **What captured looks like.** Photo or scan + AI transcription + (sometimes) original photo retained for re-OCR later. Multiple Obsidian plugins target this — Scribe, vox, deepgram-based. Claude has been benchmarked stronger than ChatGPT on handwriting fidelity.
- **Contention.** Re-OCR over time as models improve (keep the photo) vs. trust today's transcription as the artefact (let the photo go).

### 12. Whiteboard / sketch / hand-drawn diagram

- **Reasons.** Convert to clean digital diagram (mermaid, draw.io, Lucidchart); capture meeting decisions before erasing; explain a concept ("what's wrong with this architecture?").
- **What captured looks like.** Photo + AI-extracted JSON/mermaid/markdown of the diagram structure. Sometimes the photo is then discarded; sometimes both kept.
- **Contention.** Same as handwriting. Diagram structure is also lossy: AI reconstructs boxes/arrows but typically loses the "feel" annotations (arrow weights, doodles).

### 13. Voice memo / dictation

- **Reasons.** Capture-on-the-go (commute, walk, gym); brain-dump after a meeting; talk-through a problem to think; translate dictation to clean prose.
- **What captured looks like.** Audio file → transcript → cleaned-up notes; usually all three retained. Whisper-based plugins for Obsidian are common. NotebookLM ingests audio directly. Wispr Flow targets the dictation flow.
- **Contention.** Whether to keep audio after transcription (storage, privacy) or discard. Also: stream-of-consciousness audio — verbatim transcript is noisy, but LLM-summarised version loses voice/nuance.

### 14. Meeting recording / transcript

- **Reasons.** "What did we decide?" / extract decisions; action items and owners; catch-up for someone who missed it; compliance/legal record.
- **What captured looks like.** Otter.ai and Fireflies produce a layered artefact: full transcript + auto-summary + action-item list with assignees + speaker analytics. The PKM-relevant subset is typically just the summary and action items; full transcript stays in the meeting tool.
- **Contention.** Atomicity: should each meeting be one note, or should action items be pulled into a tasks system and decisions into ADR-style decision logs? Both common.

### 15. YouTube video / lecture / online course

- **Reasons.** Skip the talking-head intro and get to the substance; extract notes for study; cite a specific timestamp; save for "I'll watch this later" but never actually watch.
- **What captured looks like.** Auto-fetched transcript (via youtube-transcript-api or similar) + LLM summary + URL + sometimes timestamps. Many Obsidian plugins target this — TubeSage, YouTube Summarizer. NotebookLM ingests via public YouTube URL, transcript only.
- **Contention.** Transcript-as-source (keep verbatim alongside summary) vs. summary-only (discard transcript). Obsidian plugin ecosystem leans transcript-as-source for re-summarisation later.

### 16. Podcast episode

- **Reasons.** Same as YouTube but specifically for audio-first content; the dominant additional reason is that the user listens passively (commute) and wants the option to deep-dive a particular point later.
- **What captured looks like.** Snipd is the canonical capture tool — share an episode link, get transcript with user-marked highlights pulled into Readwise → Obsidian/Notion. NotebookLM accepts podcast audio directly.
- **Contention.** Whether podcasts merit any PKM presence at all. Snipd users argue the snippet (a 30-second highlight + transcript) is the right unit; others say only the show-notes / one-line takeaway warrant capture.

### 17. Tweet / X thread / social post

- **Reasons.** Save a contrarian or insightful thread; quote later; build a research file on a topic; just-in-case before the author deletes it.
- **What captured looks like.** Native bookmarks (lossy — link rot risk), Thread Reader unrolls (clean reader text), screenshot+text dual-capture, dewey for cross-platform bookmark management. Screenshot+text is increasingly preferred because of frequent deletions.
- **Contention.** Volume problem — bookmarks pile up unread. The usefulness of "saved tweets" without summarisation is openly questioned on r/PKMS and r/ObsidianMD.

### 18. Reddit thread / forum post

- **Reasons.** Synthesise community consensus on a question; find lived-experience anecdotes a search engine misses; capture a particularly good answer for later.
- **What captured looks like.** No clean tooling. NotebookLM users explicitly note that no Reddit→NotebookLM one-click exists; the workaround is a Google Doc paste or Myndo extension. NotebookLM's Discover Sources can search "Reddit threads only" as a source-discovery prompt.
- **Contention.** Reddit threads are deeply contextual (votes, replies, subreddit norms) and lossy when flattened to text — the community consensus is that capturing Reddit well is unsolved.

### 19. Email thread / Slack thread

- **Reasons.** Preserve decision context across a thread that mixed Slack and email; extract action items; send a summary to someone joining late.
- **What captured looks like.** Slack's built-in saved-messages "Later" feature, Slack→email forwards to bring threads into PKM via email-in inboxes, Slack thread-export tools. Email threads are often forwarded to Readwise Reader (which has a per-user email address) for the same workflow as newsletters.
- **Contention.** Confidentiality — most workplace threads can't legally cross into a personal vault. Hybrid users keep work-substrate in work-tools and don't try to PKM it.

### 20. Newsletter / Substack post / RSS item

- **Reasons.** Catch up on a backlog without inbox-clogging; extract a specific argument worth keeping; cite/quote in own writing.
- **What captured looks like.** Inbox-rules forwarding to Readwise Reader (each user gets an `@reader.io` address), or RSS into Feedly/Inoreader with AI summary digest. The artefact in PKM is usually URL + summary + highlights.
- **Contention.** Same density question as web articles.

### 21. ChatGPT / Claude / Gemini chat export

- **Reasons.** Preserve a long debugging or planning thread for later reference; share a chat as a source with collaborators; mine a chat for substantive output, discarding back-and-forth; re-feed into a different model.
- **What captured looks like.** OpenAI's built-in export produces JSON/HTML; community tools (chatgpt-exporter) export to PDF/Markdown/JSON/CSV.
- **Contention.** Verbatim deliberation vs. distilled output — should the chat survive as substrate (for "why did we decide X?" later) or only the conclusion?

### 22. Slide deck / presentation

- **Reasons.** Extract speaker-notes and slide content for study; convert to a written summary; repurpose into a different format (blog post, doc).
- **What captured looks like.** PPTX upload to ChatGPT/Claude/NotebookLM; Google Slides as a NotebookLM source. Often the slides are the output artefact, not just the input — bidirectional.
- **Contention.** Slides without the speaker is lossy; transcripts of the talk are usually a better substrate when both are available, but rarely both are.

### 23. Job description / résumé / cover letter

- **Reasons.** Tailor résumé to a specific posting; critique own résumé; generate cover letter; compare multiple postings.
- **What captured looks like.** One-shot paste, both documents into one chat; rarely retained in a vault. Some users keep a master résumé as a Claude project.
- **Contention.** Privacy/visibility — a tailored cover-letter draft is often considered ephemeral working-substrate, not vault-worthy.

### 24. Recipe / how-to / instructional content

- **Reasons.** Convert to a personal version (scaled, ingredient-substituted); photo of the dish → reverse-engineered recipe; translate units/language; plan a meal from "what's in my fridge" photos.
- **What captured looks like.** Often saved as a clean rewritten note in the vault; the original URL/photo discarded once the personal version is complete. The OpenAI study identifies "recipes" inside Seeking Information and Practical Guidance as a high-frequency consumer use.
- **Contention.** None significant. Recipe-management is a well-understood domain.

### 25. Personal documents (medical records, tax forms, ID-sticker photos, warranty registrations)

- **Reasons.** Explain in plain language ("what does this lab result mean?"); extract structured data ("when does my passport expire?"); aggregate across years (tax history).
- **What captured looks like.** Highly varied — most users don't trust cloud LLMs with PII for this. Local-LLM workflows on r/LocalLLaMA explicitly target this.
- **Contention.** Privacy is the dominant constraint; capture model has to allow "this stays local" as a first-class option.

## Cross-cut analysis

### Reason-clusters that span multiple types

- **"Long-form input I'll cite later or re-read."** Web article + academic paper + book chapter + podcast transcript + lecture transcript + meeting transcript share a capture treatment: full body retained + extracted highlights + summary + URL/source pointer. This is the Readwise/NotebookLM/Claude-Project shape and the PKM literature-note shape. The substrate types differ in *where they came from* but not in how they want to be stored.
- **"Visual artefact I want digitised."** Screenshot + handwritten notes + whiteboard + photo of physical document all want OCR-or-structure-extraction + (often) original retained for re-processing.
- **"Decision input."** Contract clause + product reviews + Reddit consensus + multiple research papers compared. They diverge in retention: contracts live in compliance archives, product reviews are usually discarded post-decision, papers stay for cite-later.
- **"Brain-dump-and-organise."** Voice memo + fleeting notes + scratch chat + sketch share "capture before I forget, distill later." The PKM canon (Forte CODE, Zettelkasten fleeting/literature/permanent) explicitly models this lifecycle.
- **"One-shot lookup."** Error message + plant photo + receipt OCR + UI screenshot + recipe scaling share "answer this question and discard the artefact." These are *not* capture-worthy in most users' practice — they're query-shaped, not substrate-shaped, even though they pass through the same upload UI.

### Where reason dominates type

The OCR cluster (screenshots, handwriting, whiteboards, document photos, handwritten labels) is mostly reason-driven: the *type* of image barely matters compared to "extract structured text from this." Similarly, the long-form-cite-later cluster is reason-dominated.

The OpenAI economic study found the highest-level structuring of usage is by *intent* (Asking 49%, Doing 40%, Expressing 11%) rather than by *content type*, corroborating that "what are you trying to do" is more discriminating than "what kind of file is this" for most consumer interactions.

### Where type dominates reason

- **Spreadsheets and code** are type-defined: their capture treatment hinges on format-specific tooling (pandas/Code Interpreter for spreadsheets, file-tree packers for code) rather than user reason.
- **Contracts and legal documents** are type-defined by the privacy/compliance regime around them.
- **Personal/medical/financial documents** are similarly type-defined by privacy.
- **Audio** is type-defined by the transcription pipeline being a hard prerequisite.

### Substrate types surprisingly common in the wild but missing from typical PKM taxonomies

- **Stack traces / error messages.** The most common technical-substrate paste, and almost no PKM tool has a place for them.
- **Screenshots of arbitrary apps and dialogs.** The phone/desktop screenshot folder is "outboard memory" for most knowledge workers — invisible to almost every PKM tool.
- **Photos of physical objects.** Plants, food, error LEDs, serial-number stickers, parking-lot location markers — high frequency in actual phone use, almost zero PKM adoption.
- **Slack/email threads.** PKM tools mostly assume the user lives in markdown, not in threaded messaging. Email-into-vault is a known workflow (Readwise's `@reader.io`); Slack-into-vault is much rarer.
- **Prior LLM chats.** Readwise/Obsidian don't natively treat prior chats as substrate; they appear as exported markdown if at all. Karpathy-style LLM-Wiki workflows explicitly mention "transcripts" as a raw input.
- **Receipts / structured personal-life records.** Captured by dedicated apps (Expensify, MyFitnessPal) but rarely surface in PKM vaults despite carrying real signal.

## Alternatives weighed in the search strategy

- **Going deep on a single platform's user-survey data instead of a broad scan.** Considered the OpenAI economic paper as a sole anchor — it has the most rigorous public dataset (1.5M conversations, 700M weekly users). Rejected because the paper's category schema is intent-based (Asking/Doing/Expressing) not substrate-based, and the substrate detail sought ("photo of error LED", "ID-sticker photo") is below its resolution. Used it as one corroborating data point.
- **Organising the inventory by reason rather than by type.** Inventory entries are type-keyed with reasons as bullets; reasons cluster *across* types in a way better expressed in the cross-cut analysis than in the primary structure.
- **Splitting "academic paper" from "scientific paper" or "PDF" from "scanned PDF."** Kept merged — divergence is in *capture treatment* (OCR step) not in *reason*.
- **Splitting "voice memo" from "meeting recording."** Kept separate because their reasons genuinely diverge: voice memo is solo brain-dump; meeting recording is multi-speaker decision-extraction with named outputs.
- **Including LLM-generated artefacts (e.g. ChatGPT outputs) as substrate.** Included "prior chat exports" as type 21 — they are increasingly imported back into vaults — but excluded one-shot in-flight LLM responses (those are the *output* of capture, not the *substrate*).
- **Surveying enterprise/RAG knowledge-base substrate (Confluence dumps, Jira tickets, internal wiki exports).** Mentioned briefly but not given separate entries; the survey is consumer/PKM focused.
- **Going deeper on tooling per type (e.g. comparing transcription tools).** Held to inventory-level naming.

## Uncertainty / gaps

- **The OpenAI usage paper's substrate-level breakdown.** The PDF didn't parse and CNBC's coverage was 403'd, so the high-level intent split (Asking 49% / Doing 40% / Expressing 11%) is recorded but not the per-substrate-type frequencies the paper reportedly contains. A direct read would let actual frequency-weights be assigned to types in this inventory.
- **Reddit demographic and substrate-type frequency** is reported indirectly through aggregator articles. r/notebooklm's 45%-education / 50k-member figures come from a third-party guide rather than verified subreddit metrics. Treat as approximate.
- **Frequency-weighting across types is qualitative.** This survey orders types roughly by what comes up most in PKM/LLM writing; no clean "of all uploads, X% are Y type" data exists publicly.
- **Privacy-constrained substrate** (medical, legal, financial) is under-represented because users discuss it less publicly. Local-LLM communities (r/LocalLLaMA, the privacy-focused PKM substack scene) would surface more.
- **Multilingual / non-English substrate.** All findings are anglosphere-biased — Substack/Reddit/Obsidian-forum/YouTube English content. International PKM communities (Japanese Scrapbox/Cosense, Chinese-language Obsidian users, German Zettelkasten purists) may have different dominant substrate types.
- **The "captured-as" descriptions are normative.** In practice, individual users improvise. A user-study (interviews, vault audits) would give richer ground truth than the secondary literature surveyed here.

## Sources

Accessed while the research was done, May 2026; the day each was read was not recorded.

### Vendor / tool documentation

- [NotebookLM Help — Add or discover new sources](https://support.google.com/notebooklm/answer/16215270)
- [Google Blog — NotebookLM Deep Research and new file types (2025-11-13)](https://blog.google/innovation-and-ai/models-and-research/google-labs/notebooklm-deep-research-file-types/)
- [NotebookLM — Add and manage data sources (API)](https://docs.cloud.google.com/gemini/enterprise/notebooklm-enterprise/docs/api-notebooks-sources)
- [NotebookLM Sources & Uploads Guide](https://notebooklm.gr.com/sources-uploads.html)
- [Anthropic — Upload files to Claude](https://support.claude.com/en/articles/8241126-upload-files-to-claude)
- [Anthropic — What are projects?](https://support.claude.com/en/articles/9517075-what-are-projects)
- [Anthropic — RAG for projects](https://support.claude.com/en/articles/11473015-retrieval-augmented-generation-rag-for-projects)
- [OpenAI Help — File Uploads FAQ](https://help.openai.com/en/articles/8555545-file-uploads-faq)
- [OpenAI — Use ChatGPT with PDFs](https://chatgpt.com/use-cases/chat-with-pdfs/)
- [OpenAI Help — Export ChatGPT history](https://help.openai.com/en/articles/7260999-how-do-i-export-my-chatgpt-history-and-data)
- [Perplexity — What are Spaces?](https://www.perplexity.ai/help-center/en/articles/10352961-what-are-spaces)
- [Perplexity — Internal Knowledge Search](https://www.perplexity.ai/help-center/en/articles/10352914-what-is-internal-knowledge-search)
- [OpenAI Help — Deep research in ChatGPT](https://help.openai.com/en/articles/10500283-deep-research-in-chatgpt)

### Empirical studies / data

- [OpenAI — How people are using ChatGPT (Sep 2025)](https://openai.com/index/how-people-are-using-chatgpt/). Underlying NBER PDF unfetchable; corroborated via the [Grounding Page summary](https://groundingpage.com/facts/nber-wp-34255-2025/) and the [Forklightning summary by David Deming](https://forklightning.substack.com/p/how-people-use-chatgpt).
- [NBER WP 34255](https://www.nber.org/papers/w34255) — abstract page; PDF binary did not parse.
- [Anthropic Education Report — University Students](https://www.anthropic.com/news/anthropic-education-report-how-university-students-use-claude)
- [Anthropic Education Report — Educators](https://www.anthropic.com/news/anthropic-education-report-how-educators-use-claude)
- [Epoch AI — Half of employed AI users now use it for work](https://epoch.ai/blog/half-of-employed-ai-users-now-use-it-for-work)
- [Microsoft Work Trend Index — AI at Work](https://www.microsoft.com/en-us/worklab/work-trend-index/ai-at-work-is-here-now-comes-the-hard-part)
- [arXiv — Current and Future Use of LLMs for Knowledge Work](https://arxiv.org/html/2503.16774v1)

### PKM community / blog / forum

- [Tiago Forte — Building a Second Brain Overview](https://fortelabs.com/blog/basboverview/)
- [Building a Second Brain — PARA](https://www.buildingasecondbrain.com/para)
- [Parazettel — Information Capture Workflow](https://parazettel.com/articles/obsidian-information-capture-workflow/)
- [Readwise](https://readwise.io/) and [Reader docs — Adding new content](https://docs.readwise.io/reader/docs/faqs/adding-new-content)
- [Readwise — Email newsletters](https://docs.readwise.io/reader/docs/faqs/email-newsletters)
- [Bryan Jenks — 2021 Comprehensive Obsidian Zettelkasten Workflow](https://www.bryanjenks.dev/blog/my-2021-comprehensive-obsidian-zettelkasten-workflow)
- [Obsidian Forum — Web Clipper + AI capture](https://forum.obsidian.md/t/obsidian-web-clipper-ai-capture-summarise-web-content-youtube-reddit-books-more/100599)
- [aitooldiscovery — NotebookLM Reddit Review (50k users)](https://www.aitooldiscovery.com/guides/notebooklm-reddit)
- [aitooldiscovery — NotebookLM Prompts](https://www.aitooldiscovery.com/guides/notebooklm-prompts)
- [xda-developers — Pairing NotebookLM with Reddit](https://www.xda-developers.com/pairing-notebooklm-with-reddit/)
- [Karpathy LLM-Wiki gist (MarkBruns)](https://gist.github.com/MarkBruns/469e193ab090ce1ff3f70fc2d08ad1f6)
- [NicholasSpisak/second-brain](https://github.com/NicholasSpisak/second-brain)
- [HN — Ask HN: Local RAG with private knowledge base](https://news.ycombinator.com/item?id=41968366)
- [nashsu/llm_wiki](https://github.com/nashsu/llm_wiki)

### Tooling-specific

- [Whisper Obsidian plugin](https://github.com/nikdanilov/whisper-obsidian-plugin); [Scribe plugin](https://www.obsidianstats.com/plugins/scribe); [VOX plugin](https://github.com/vincentbavitz/obsidian-vox); [Wispr Flow + Obsidian](https://wisprflow.ai/use-cases/obsidian)
- [TubeSage](https://github.com/rmccorkl/tubesage); [YT Video Summarizer plugin](https://www.obsidianstats.com/plugins/yt-video-summarizer)
- [Otter.ai](https://otter.ai/); [Fireflies.ai](https://fireflies.ai/)
- [Hypothesis](https://web.hypothes.is/)
- [Repomix](https://repomix.com/)
- [chatgpt-exporter](https://github.com/pionxzh/chatgpt-exporter)
- [getDewey — Managing saved Twitter threads](https://getdewey.co/blog/how-to-manage-saved-twitter-threads-for-future-reference-your-ultimate-guide/); [recurpost — Unroll Twitter threads](https://recurpost.com/blog/unroll-twitter-threads/)

### Use-case write-ups

- datastudios.org — ChatGPT image/screenshot OCR; Claude spreadsheet uploading; ChatGPT file upload.
- [Spellbook — Can ChatGPT review contracts?](https://www.spellbook.legal/learn/can-chatgpt-review-contract); [Claude vs ChatGPT for Lawyers](https://spellbook.com/briefs/claude-vs-chatgpt-for-lawyers)
- [Rankings.io — Claude for Lawyers](https://rankings.io/blog/claude-for-lawyers/)
- [howtogeek — Uses for ChatGPT image recognition](https://www.howtogeek.com/uses-for-chatgpt-image-recognition-feature/)
- [familylocket — Handwritten Text Recognition by Claude 3.5 Sonnet](https://familylocket.com/handwritten-text-recognition-by-claude-3-5-sonnet/); [Transcribing Document Images](https://familylocket.com/transcribing-document-images-with-chatgpt-and-claude/)
- [techcrunch — ChatGPT image generator faking receipts (2025-03-31)](https://techcrunch.com/2025/03/31/chatgpts-new-image-generator-is-really-good-at-faking-receipts/)
- [aidiagrammaker — Image to flowchart AI](https://www.aidiagrammaker.com/blog/image-to-flowchart-ai)
- [dev.to/devprompts — 10 Claude Prompts for Faster Debugging](https://dev.to/devprompts/10-claude-prompts-for-faster-debugging-with-examples-329a)
- [dev.to/nextools — Claude Code Debugging Workflow](https://dev.to/nextools/claude-code-debugging-workflow-how-i-diagnose-and-fix-production-issues-3x-faster-2l11)
- [jobscan — ChatGPT cover letter](https://www.jobscan.co/blog/use-chatgpt-to-generate-a-cover-letter/); [tealhq — ChatGPT cover letter](https://www.tealhq.com/post/how-to-use-chatgpt-to-write-your-cover-letter)
- [afterhoursai — Newsletter overwhelm + AI RSS setup](https://afterhoursai.substack.com/p/how-i-escaped-newsletter-overwhelm)

### Sources searched-for and not productively retrieved

- Full NBER WP 34255 PDF — fetch returned a corrupted binary parse; substituted with the Grounding-Page summary and the OpenAI landing page.
- CNBC's coverage of the OpenAI study — 403 forbidden.
- Direct Reddit-search queries on r/PKMS, r/Anthropic, r/ClaudeAI returned thin results; substituted with secondary write-ups summarising those communities.
