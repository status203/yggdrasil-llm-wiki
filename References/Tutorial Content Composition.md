---
type: reference
pitch: Research on what kinds of material a single tutorial draws on — knowledge types, history, motivation — their canonical names, and how they sit alongside subject shape and teaching strategy.
---

# Tutorial Content Composition

Researched in May 2026. This page is a snapshot of that research and is not maintained.

Companion to [[Tutoring Pedagogy]]. That page covers two axis families — **subject shape** (the structural shape of what's being taught) and **strategy** (how content is sequenced and scaffolded). This page covers a third, orthogonal family: **content composition** — what *kinds* of material a single tutorial draws on, and what the recognised vocabulary is for naming them.

The motivating observation: a tutorial on a single subject can vary along axes that have nothing to do with the subject's shape or the chosen strategy. A tutorial on (say) a chess opening can be heavy on technical mechanism with no history, or balanced between mechanism and the lineage of ideas, or organised around aesthetic/cultural reception of the opening. Same shape, same strategy, very different content mix.

## The three established frames

### 1. Knowledge-type taxonomies — naming the kinds of substantive content

The dominant family in instructional design. All four taxonomies below are widely cited; pick whichever matches the granularity your design needs.

| Taxonomy | Categories | Use it for |
|---|---|---|
| **Anderson & Krathwohl** revised Bloom's (2001) | Factual / Conceptual / Procedural / Metacognitive (× cognitive process — remember/understand/apply/analyse/evaluate/create) | A 2D matrix for planning which cells a unit hits. Descriptive, broadly useful. |
| **Merrill Component Display Theory** (1983) | Content × performance: (Fact / Concept / Procedure / Principle) × (Remember / Use / Find) | Prescribes a *mix* of presentation forms (rule, example, recall, practice) for a target cell — closest classical theory to "checklist of what content kinds a unit should contain." |
| **de Jong & Ferguson-Hessler** *Types and Qualities of Knowledge* (1996) | Types: situational / conceptual / procedural / strategic. Qualities (each varies along): depth, structure, automation, modality, generality. | The most directly compositional framework. The "qualities" idea — same content kind presented at different depths or structural integrations — is the main thing. *Situational* knowledge (when/where the topic applies) is a category absent from Bloom and CDT. |
| **Paris, Lipson & Wixson** (1983) | Declarative / Procedural / **Conditional** | Strategy/metacognition lineage. Conditional knowledge ("when and why to use it") is the bit most often missing from tutorials and the bit most predictive of transfer. |

Subtypes worth flagging:

- Anderson & Krathwohl's **Conceptual** splits into classifications, principles/generalisations, and theories/models/structures.
- Anderson & Krathwohl's **Factual** splits into terminology and specific details (attribution-of-ideas content sits here).
- Merrill's **Principle** is "predictions of why things happen" — closest to causal/explanatory content.

Status: well-established. None of these prescribes a mix calculus ("at level L, X% factual / Y% conceptual"); they give vocabulary for a designer's judgement.

### 2. Technical-vs-historical content — the genetic method and HPS pedagogy

The single most-developed sub-question, with a clean name and a century-old tradition.

**The genetic method** (mathematics teaching). Coined by **Otto Toeplitz** in 1927 (*Das Problem der Universitätsvorlesungen über Infinitesimalrechnung…*); roots in **Felix Klein**'s 1895 Göttingen lectures and *Elementarmathematik vom höheren Standpunkte aus*; modern form in **Hans Freudenthal**'s "guided reinvention" / didactical phenomenology (1978–). Toeplitz's posthumous *The Calculus: A Genetic Approach* (English 1963) is the canonical worked example.

The literature distinguishes:

- **Direct (historical) genetic method** — teach the topic in the order it was historically developed, with attribution.
- **Indirect / pseudo-historical / conceptual genetic method** — teach in a *plausible* order of conceptual emergence that is curated for pedagogy and not strictly historical. Freudenthal's guided reinvention is roughly this.

Underlying intuition (Klein, sharing logic with Haeckel's recapitulation theory in biology): ontogeny of the learner mirrors phylogeny of the discipline. The biological version is repudiated. The strong pedagogical claim ("teach in historical order because that's how minds work") is no longer defended; the **weak claim** ("history reveals which steps were genuinely conceptually hard, and that's pedagogically informative") is mainstream.

**The broader research subfield is HPS in science education** (History and Philosophy of Science in science teaching). Michael Matthews edits the Springer *International Handbook* (2014); the journal *Science & Education* has been the field's main venue since 1992. The mathematics-side analogue is the **ICMI Study** *History in Mathematics Education* (Fauvel & van Maanen 2000).

What does the evidence say about *when* including history helps?

- **Reported benefits** cluster on (a) motivation/interest (history humanises the subject), (b) epistemological understanding (history shows knowledge as constructed and revised), (c) "permanent understanding" claims from teacher surveys.
- **Reported costs** cluster on (a) curriculum-time tradeoff, (b) teacher under-preparation, (c) age-related: contextualised material engages younger/novice learners but advanced learners often *prefer* decontextualised problems.
- The evidence base is **patchy and largely qualitative.** Treat as design substrate, not a deciding study.

The age/level effect mirrors the **expertise-reversal effect** already in [[Tutoring Pedagogy]]: contextualisation that helps novices is redundant load for advanced learners. The cross-axis implication is important — see § *Cross-axis principles*.

**Adjacent: narrative pedagogy.** Storytelling content broader than literal history (a "biography of an idea" whose protagonist is a concept). Active research strand in science education; empirical claims: stories aid encoding, retention, and motivation for novices; mixed results for transfer.

### 3. Motivation-as-content — ARCS, SDT, interest development

Motivation is content, not framing. Three named frameworks:

- **Keller's ARCS** (1987) — Attention / Relevance / Confidence / Satisfaction. Treats motivational design as a parallel concern to cognitive design. Useful for naming "Attention" content (curiosity-grabbing surprises, perceptual hooks) and "Relevance" content ("here's what this is for, why it matters to you") as content kinds in their own right. Modest but consistent empirical support.
- **Self-determination theory** — Deci & Ryan; autonomy / competence / relatedness as basic psychological needs. Content choices that support autonomy ("here's why people use this; choose your own example") and competence ("a starter you can succeed at") are independently motivating. Theory of motivation more than a content checklist; well-established.
- **Hidi & Renninger four-phase interest model** (2006) — triggered situational → maintained situational → emerging individual → well-developed individual. The compositional implication: early-phase learners need *situational* triggers (visual hooks, surprising examples), later-phase learners self-sustain interest and the situational hooks become redundant. Same expertise-reversal shape, restated for affect.

### Curiosity gaps — the substance-pointing counterpart

Loewenstein's *information-gap theory of curiosity* (1994, *Psychological Bulletin*) — establishing an unresolved question and signalling that it's about to be resolved drives engagement and improves encoding when the resolution arrives. Berlyne's earlier work on **epistemic curiosity** (1954, 1960) is the same lineage; "collative variables" (novelty, surprise, complexity) prime exploration.

Compositionally, curiosity gaps are useful at **transitions** — particularly the end of a step, looking forward to the next. A pointed forward-reference ("this works fine until X; we'll see what breaks when X is added") is engagement that pre-loads the next step's content. The criterion that distinguishes a curiosity gap from a seductive detail is *substance-pointing vs flavour-pointing*: the gap should hint at the actual content of what's next, not at a vivid tangent. Same forward-reference shape, different content target.

Status: well-established within motivation and curiosity research; the substance-vs-flavour distinction is the design judgement.

### The seductive-details caution

The standing rebuttal to "if it engages the learner it must be helping." Garner, Gillingham & White (1989) and Harp & Mayer (1998, *Journal of Educational Psychology*) showed that adding interesting-but-instructionally-irrelevant content — colourful anecdotes, vivid asides — *hurts* learning of the target material. The mechanism: working-memory capture plus distraction from the schema being built. Replicated across domains and treated as well-established.

Implications for tutorial composition:

- "Interesting" does not entail "good." Engagement and learning can pull apart.
- **Diagnostic:** if a learner is consistently engaged but failing the next step's content, the engaging material is functioning as a seductive detail rather than a foundation. Check the content mix.
- The seductive-details effect and motivational framing are not the same thing — the former is irrelevant detail, the latter is *Relevance* content (ARCS) or *situational interest* (Hidi-Renninger). Distinguishing them in practice is the design judgement: relevance content explains why the learner should care about the target material; seductive details are entertaining tangents next to it.

## Diátaxis as the dominant counter-position

[Diátaxis](https://diataxis.fr) (Daniele Procida) splits documentation into **tutorial / how-to / reference / explanation** as separate documents. The framework is openly hostile to within-document mixing — it treats mixing types as the most common cause of confusing documentation, and routes history, motivation, design rationale, and "why is this so" content explicitly *out of* tutorials and into **explanation** pages.

In Diátaxis's prescription, a tutorial that mixes "how the opening works" (tutorial), "originator and lineage of ideas" (explanation), and "variation reference" (reference) is malformed — these should be three separate documents, linked.

This matters because Diátaxis is the de facto standard in the OSS documentation world (Django, Numpy, Cloudflare, GitLab, others). It is the dominant counter-position to within-document content mixing, and the framework with the loudest "don't do this" voice. A tutorial designed to mix content kinds is consciously departing from Diátaxis and leaning on the educational-research literature instead, which is permissive about mixing.

The educational-research literature does not directly engage with Diátaxis — they are different discourses. Diátaxis is not from the educational-research tradition; its empirical base is light but its practitioner adoption is strong.

## Composition-as-design — partial answers

The user-facing question — *"how much of each content kind goes in this tutorial?"* — is not directly solved in the literature. Closest answers:

- **van Merriënboer 4C/ID** (already in [[Tutoring Pedagogy]]) is the most explicit content-mix design model. Its four components — learning tasks, **supportive information** (the *why* — concepts, mental models, causal-historical context), **just-in-time information** (the exact step), **part-task practice** — are *defined as* a mix to be designed. Most history/causal-context content sits in *supportive information*.
- **Reigeluth elaboration theory** (already in [[Tutoring Pedagogy]]) offers supporting-content categories (prerequisite, principle, supportive analogy) — content-mix vocabulary, sequencing-focused.
- **Cognitive load theory** (Sweller) is the best-developed *constraint* on mixing — redundant content kinds compete for working-memory bandwidth (the **redundancy effect**). This is the closest thing to an evidence-based brake on adding more content kinds: at some point, more content of any kind hurts.

What is missing: a quantitative or even semi-quantitative framework that names a fixed set of content axes (mechanism / history / aesthetic-cultural / theoretical / pragmatic / philosophical / motivational) and gives composition guidance ("at level L, include roughly X of each"). This is a genuine gap, not an oversight to dig harder for.

## Mapping common content axes to canonical names

Useful when surfacing the choice to a learner:

| Folk axis | Closest canonical name |
|---|---|
| Technical mechanism | Procedural + conceptual knowledge (Anderson-Krathwohl); CDT facts/concepts/procedures |
| Historical / academic attribution | Genetic method; HPS-in-science-education |
| Worked applications / case studies | Situational knowledge (de Jong & Ferguson-Hessler); Merrill's instance forms |
| Aesthetic / cultural reception | Situational interest (Hidi-Renninger) + community-of-practice content (Lave-Wenger) — weakest fit, no clean canonical name |
| Mathematical / theoretical underpinnings | Conceptual knowledge (Anderson-Krathwohl); Reigeluth theoretical elaboration |
| Pragmatic "use today" | Conditional knowledge (Paris-Lipson-Wixson); situated knowledge |
| Philosophical "why does this matter" | ARCS *Relevance* + SDT *Autonomy* + HPS *nature of science* |

The "aesthetic/cultural reception" axis is the only one without a clean canonical name — it sits in the overlap of situational interest and community-of-practice content but is not a named category in either lineage.

## Formative assessment — calibrating the mix mid-tutorial

The up-front plan is a starting point, not a contract. Content-mix decisions made up front are calibrations against an estimate of the learner's preferences; the in-flow data is the corrective.

The educational-research home is **formative assessment** (assessment-for-learning) — Black & Wiliam *Inside the Black Box* (1998) and *Assessment and Classroom Learning* (1998, *Assessment in Education*) being the canonical citations. Their meta-analytic finding: regular feedback loops between learner and teacher are among the highest-effect interventions in education research, comparable in size to one-on-one tutoring effects. Treating tutorial design as a one-shot up-front decision leaves this on the table.

### Two flavours of feedback

- **Calibration questions** ("how was the pace, was the balance right?") — fill in the model of the learner. Front-load.
- **Triggered re-asks** — fire when in-flow signal contradicts the model. Episodic, not periodic.

### Convergence

Calibration questions follow an expertise-reversal-shaped curve like everything else: necessary early when the model is essentially blind, redundant once the model has stabilised. A reasonable cadence, as an untested heuristic:

- **Step 2's transition:** ask. The model has one data point; calibration is most informative now.
- **Step 3's transition:** light/optional ask, picking the dimension still least certain.
- **Step 4 onward:** default off. Rely on in-flow signal capture.
- **Triggered re-ask:** fires whenever in-flow signal from the previous step indicates miscalibration (engagement drop, "I'm lost", surprise pushback). Overrides the convergence default.

The convergence is conditional on a stable learner. If the learner is themselves shifting (gaining competence, which is the point), the in-flow signals carry that — explicit asks are not needed for level-tracking.

### Timing — post-recap, before next step content

Three candidate placements for the calibration ask, compared as a design note rather than from a study:

| Placement | Pro | Con |
|---|---|---|
| End of completed step | Recency: highest hot-signal availability | Overconfidence bias — immediately post-task, learners systematically overestimate landing |
| At next-step request | Operationally tight — answer arrives just before it's used | Interrogates someone who has already decided to continue; friction on commitment |
| **After the prior-step recap, before the new content** | Retrieval-grounded judgement (the recap reactivates content); positioned to immediately influence the upcoming step | Requires the step delivery to pause for the answer |

The third placement looks strongest. The recap functions as a memory cue, so the learner's answer reflects what they actually retained — closer to a retention signal than fresh post-step self-report. The pause is genuine friction but pedagogically aligned: the recap is already an advance organiser; the calibration ask is a retrieval prompt before the new content lands.

### Framing — comparative, not absolute

Comparative judgements ("was that step about right *relative to the last one*, or do you want to shift?") are more reliable than absolute ones ("was the level right?"). Rating-scale research is generally taken to show this — humans tend to be better at comparative than absolute judgements — though no source for it was recorded here. Phrase calibration questions as relative shifts whenever a prior step exists.

### Storage

Calibration answers should persist through the tutorial, surviving pause-and-resume, so they are visible when the next step is prepared and a recurring mismatch shows ("dense" said three times running is much stronger evidence than once).

Cross-tutorial learner profile (does this learner generally prefer light history, fast pace, comparative organisers?) is a separable open question — see *Open questions*.

## Per-learner state — what to know and how to learn it

Content-composition decisions are conditioned on the learner. The state that matters:

| Attribute | Drives | Notes |
|---|---|---|
| Stated level (novice / intermediate / advancing) | Fading rung; scaffolding intensity; advance-organiser density | Sets the starting point on Kalyuga's fading ladder |
| Goal for the tutorial ("be able to do X" vs "understand X") | Entry-point choice; conditional-knowledge depth; mechanism-vs-application bias | The single most-important up-front decision; rarely inferable |
| Prior knowledge in adjacent areas | Comparative vs expository advance organisers; what to skip | Comparative organisers ("X is like Y you already know") work *only* if Y is held |
| Appetite for history / lore | Content-mix balance on the technical-vs-historical axis | The biggest single content-composition decision; learners vary substantially |
| Pace preference | Step granularity; spiral vs deep on a branch | Practical; affects time-budget more than learning outcomes |
| Aesthetic appetite (cultural/visual angle) | Whether to surface the cultural / aesthetic content kind | Slippery; better captured as in-flow signal than extracted up-front |

### Inferable vs extracted

Reliably inferable from what the tutor already has of the learner — earlier sessions and their notes:

- Adjacent prior knowledge — what the learner has demonstrated in prior tutorials or notes.
- Pace tolerance — past tutorial cadence, how much they discussed each step.
- Style preference — past tutorial discussions, what kinds of digressions they engaged with.

Must be extracted directly:

- Goal for *this* tutorial — almost never inferable; the same topic can be approached for very different reasons.
- Self-rated level — subjective and revisable; the learner is the only source.
- History / lore appetite — sometimes inferable from past tutorials but often topic-specific (a learner might want history on one topic, mechanism-only on another).

### Three extraction mechanisms

Ranked by friction (lowest first):

1. **Use ordering options as the extraction probe.** When offering the learner a choice of orderings, differentiate the candidates by content emphasis; the learner's pick reveals preference without requiring them to introspect on abstract content kinds. Lowest-friction extraction available.
2. **Short structured intake before the tutorial starts.** At most one to three questions: level, goal, and one composition question if not resolved by the ordering pick. More than three feels like a survey before the tutorial starts. Surface "we can change this later" so the learner doesn't over-commit.
3. **In-flow signal capture.** The formative-assessment loop catches drift — particularly content-mix appetite that shifts as the learner discovers what they actually want. See § *Formative assessment — calibrating the mix mid-tutorial*.

Operating principle: front-load the one decision hardest to revise (goal — it shapes the whole plan), infer what's inferable (adjacent prior knowledge), let the rest emerge as signal during the tutorial.

## Optional content primitives in Obsidian

The within-tutorial mixing problem has a tooling dimension. Obsidian gives three primitives for "content that's in the page but optional to read":

| Primitive | Best for | Cost |
|---|---|---|
| Footnote (`[^1]`) | Attribution, dates, short asides ("originally proposed by X in Y") | Reading-view jump only; no margin/sidenote rendering native; intra-page only |
| Callout (`> [!note] …`) | Substantive optional content where the reader should see it in context but visibly marked as aside | Renders inline as a styled box; can start collapsed (`> [!note]-`) or expanded and foldable (`> [!note]+`) |
| Sub-page (wikilink) | Standalone-worthy material — full historical narrative, alternative-perspective treatment | Splits the page; requires the sub-page to stand alone |

Corrected 2026-10-06: the callout row said callouts cannot be collapsed by default; they can start collapsed with `-` after the type.

A reasonable convention: **attribution → footnotes; substantive optional content → callouts; standalone-worthy material → linked sub-page.** Three primitives matching three densities of secondary content. Worth piloting before formalising.

Forward/back navigation in Obsidian is page-level, not anchor-level — footnote jumps may not create history entries. This is fine for short asides, brittle for substantive content the reader might want to leave open while moving on.

## Cross-axis principles

A small set of principles cut across content-composition, strategy, and subject-shape — worth foregrounding because they bind the three families.

- **Expertise reversal applies to all content kinds, not just procedural scaffolding.** Historical context, motivational framing, and worked-example density all show the same shape: helpful for novices, redundant load for advanced learners. The fading ladder in [[Tutoring Pedagogy]] extends to history and motivation, not only to scaffolding intensity.
- **Concepts and procedures interleaved with causal links beats sequential-then** (Rittle-Johnson's "integrated for causation"). The same likely holds for mechanism and history — interleaving "this works because of X *and historically came from Y trying to solve Z*" probably beats "lecture history first, mechanism second."
- **Cognitive-load redundancy is the brake.** Every content kind added competes for working memory. The right number of content kinds in any given step is "fewer than you want to put in."
- **Content composition interacts with subject shape, not just strategy.** Linear-procedure subjects tolerate less history than well-structured-network subjects — in a procedure, history is digression; in a network, history can shape entry-point choice. Default content mixes per shape are a worth-developing heuristic but not in the literature.

## Open questions

- **Default content mix per subject shape.** A working heuristic — e.g. linear procedures lean mechanism-only, well-structured networks tolerate genetic-method framing — would be useful for setting tutorial defaults. Not in the literature; develop empirically.
- **Conditional knowledge in tutorials.** The Paris-Lipson-Wixson trichotomy says conditional ("when/why") is most predictive of transfer and most often absent. Concrete techniques for surfacing conditional knowledge in tutorial form — beyond appended "when to use this" sections — are underdeveloped.
- **Footnotes / sidebars / call-outs as composition primitives.** A tutorial that interleaves mechanism with attribution-as-footnotes is making a composition choice the literature doesn't directly address. Worth treating as design substrate.
- **HPS-in-CS-education** is much less developed than HPS-in-science-education or HPS-in-mathematics-education. CS-tutorial design wanting genetic-method framing imports from those neighbour fields.
- **Diátaxis criticism** is mostly practitioner-level pushback ("too rigid"); rigorous critique is thin. The strongest counter-arguments come from educational-research literature on integrated content, not from documentation-research.
- **Cross-tutorial learner profile.** Formative assessment within a tutorial calibrates the model of *this* learner for *this* tutorial. Whether to keep a profile across tutorials (e.g. "this learner prefers light history, fast pace, comparative organisers") is an open design question — a profile risks staleness and miscalibration but saves recalibration cost on each new tutorial.

## Sources

Accessed while the research was done, May 2026; the day each was read was not recorded.

Knowledge-type taxonomies:

- **Anderson & Krathwohl** (2001) revised Bloom's taxonomy. [Krathwohl 2002 overview](https://cmapspublic2.ihmc.us/rid=1Q2PTM7HL-26LTFBX-9YN8/Krathwohl%202002.pdf).
- **Merrill Component Display Theory** (1983). [InstructionalDesign.org summary](https://www.instructionaldesign.org/theories/component-display/).
- **de Jong & Ferguson-Hessler** (1996) *Types and qualities of knowledge*. [T&F abstract](https://www.tandfonline.com/doi/abs/10.1207/s15326985ep3102_2).
- **Paris, Lipson & Wixson** (1983) declarative/procedural/conditional knowledge.
- **Shulman** (1986) pedagogical content knowledge — meta-knowledge for teachers; relevant scaffolding for thinking about content choice.

History in teaching:

- **Toeplitz** (1927/1963) *The Calculus: A Genetic Approach*; commentary in Fried & Jahnke 2015.
- **Felix Klein** (1895; *Elementarmathematik vom höheren Standpunkte aus*).
- **Freudenthal** didactical phenomenology / guided reinvention (1978–).
- **Matthews et al.**, Springer *International Handbook of Research in History, Philosophy and Science Teaching* (2014); journal *Science & Education* (1992–).
- **Fauvel & van Maanen** (2000) *History in Mathematics Education* — ICMI Study.
- [Wikipedia: Genetic method](https://en.wikipedia.org/wiki/Genetic_method).

Motivation:

- **Keller** (1987) ARCS model. [eLearning Industry summary](https://elearningindustry.com/arcs-model-of-motivation).
- **Deci & Ryan** self-determination theory. [Ryan & Deci 2000 PDF](https://selfdeterminationtheory.org/SDT/documents/2000_RyanDeci_SDT.pdf).
- **Hidi & Renninger** (2006) four-phase model of interest development.

Documentation genre:

- **Procida** Diátaxis — [diataxis.fr](https://diataxis.fr).

Adjacent / cited in passing:

- **Lave & Wenger** (1991) *Situated Learning: Legitimate Peripheral Participation*.
- **Sweller** cognitive load theory — covered in [[Tutoring Pedagogy]].
- **van Merriënboer 4C/ID** — covered in [[Tutoring Pedagogy]].
- **Reigeluth elaboration theory** — covered in [[Tutoring Pedagogy]].
- **Rittle-Johnson** concepts/procedures iterative interleaving — covered in [[Tutoring Pedagogy]].

Seductive details and formative assessment:

- **Garner, Gillingham & White** (1989) — original seductive-details effect.
- **Harp & Mayer** (1998) — replication and extension; *Journal of Educational Psychology*.
- **Black & Wiliam** *Inside the Black Box* (1998) and *Assessment and Classroom Learning* (1998, *Assessment in Education*) — canonical formative-assessment citations.

Curiosity:

- **Loewenstein** (1994) *The Psychology of Curiosity: A Review and Reinterpretation*, *Psychological Bulletin* — information-gap theory.
- **Berlyne** (1954, 1960) — epistemic curiosity and collative variables.
