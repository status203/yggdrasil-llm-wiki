---
type: reference
pitch: Research on how to tutor subjects of different shapes — four subject shapes, techniques for each, expertise reversal and adaptive fading, and what makes recaps work.
---

# Tutoring Pedagogy

Researched in May 2026. This page is a snapshot of that research and is not maintained.

Research on how to teach subjects of different shapes, when to adapt strategy as the learner progresses, and what makes recaps work.

## Subject shapes

Four shapes to classify a subject by, drawn from instructional-design literature. Most real subjects mix shapes; classify by primary, then by modifiers.

| Shape | Example | Closest theoretical home |
|---|---|---|
| **Cumulative-skill (pyramid)** | Cooking, musical instrument fluency <!-- well exception: the pyramid row needs a second member unlike cooking --> | Reigeluth theoretical/procedural elaboration; Gagné intellectual-skills hierarchy |
| **Linear procedure** | Surgical procedure, recipe | Procedural-skill training (medical-ed lineage) |
| **Well-structured network** | Chess opening theory, geography, anatomy | Reigeluth conceptual elaboration; Ausubel meaningful learning |
| **Ill-structured network** | Clinical reasoning, ethics, "is this investment good" | Spiro cognitive flexibility theory |

The well-structured / ill-structured distinction matters because hierarchical curricula *help* the former and actively *hurt* the latter — an ill-structured domain teaches that the same factor applies differently per case, and a hierarchy implies the wrong shape.

## Strategy per shape

### Cumulative-skill (pyramid)

- **Whole-task-but-simplified first** — Reigeluth's simplifying conditions method; van Merriënboer's 4C/ID. Don't teach foundations in isolation before any working end-to-end experience. First milestone in a cooking course = a real edible dish, not a lecture on knife-grip theory.
- **Worked examples** — for novices, studying solved problems beats solving equivalents. Among the most replicated findings in instructional psychology.
- **Scaffolding with fading** — heavy guidance early, withdrawn as competence grows. Fading is non-optional; leaving it up triggers expertise reversal (see § *Adaptive considerations*).
- **Mastery learning** — don't move on until the prerequisite is solid.
- **Spaced + retrieval practice** under the skills (Dunlosky 2013 — the two highest-utility study techniques in the field).

### Linear procedure

- **Demonstration loops over flat lists** — Peyton's four-step (full-pace demo → demo with explanation → learner explains while instructor performs → learner performs while explaining) outperforms unstructured demonstration in trials. Translates to chat: full overview first, then per-step expansion, then "say it back."
- **Deliberate practice** (Ericsson) — focused effort on a specific aspect with immediate feedback and high repetition. Hard to do faithfully via chat alone.
- **Checklists** — for procedures where omission is the failure mode.
- **Surface branch points explicitly** — divergence-points are conditional knowledge, not procedural; teach them in their own mode.

### Well-structured network

- **Advance organisers** (Ausubel) — a brief higher-abstraction frame given *before* new content, providing the slot the new material attaches to. Two flavours: **expository** (unfamiliar topic — supply the scaffold) and **comparative** (familiar analogue — bridge to it).
- **Concept maps**, especially constructed by the learner — externalise the network. Evidence is for *building*, not *consuming*.
- **Goal-driven entry** — pick where to start from what the learner says they want to do or understand.
- **Spiral over topical** — several quick passes at increasing depth across the whole network beats mastering one topic before moving to the next; risk of dead-ending without broader framing is too high.

### Ill-structured network

- **Multiple traversals through the same content from different organising perspectives.** Don't impose a hierarchy. Casebooks, not textbooks.
- **Deliberately revisit cases that contradict each other** — exposure to how the same factor cuts differently in different contexts is the point.
- *Tutor caution*: an ill-structured subject misclassified as well-structured produces fluent-sounding content that fails on transfer. The risk is sharpest in domains like ethics, design judgement, or clinical reasoning.

## Hybrid subjects (the common case)

- **Concepts and procedures interleaved, with explicit causal links, beats sequential-then.** Rittle-Johnson's "integrated for causation" sequencing wins on transfer. Don't lecture concepts in step 1 then run commands in step 2 — weave "this works because…" into each step.
- **4C/ID** is the dominant synthesis for hybrid skills:
  1. Whole authentic learning tasks, in classes of increasing complexity.
  2. Supportive information (the *why*) — available as needed; cumulative.
  3. Just-in-time information (the *exact step*) — faded as internalised.
  4. Part-task practice — only when automaticity matters.
- **Iterative knowledge development** — gains in concepts drive gains in procedures and vice versa; expect zigzag, not monotonic mastery.

## Sequencing & entry points

| Shape | Sequencing approach |
|---|---|
| Pyramid | Simplifying conditions method — strip the task to its representative epitome, teach end-to-end, add complexity back |
| Linear | Mostly forced by the procedure; refinements: macro→micro demo cycles; conditional branches taught in their own mode |
| Well-structured network | Advance organiser → spiral; goal-driven entry; constructed concept maps |
| Ill-structured network | Multi-perspective traversal; deliberately mixed cases |

Entry-point selection for networked subjects has the weakest evidence base — much more tradition than data. Goal-driven entry ("why are you interested in X?") is the most-defensible default.

## Adaptive considerations

### Probe prior knowledge before strategy selection

The single biggest reason: the **expertise-reversal effect** (Kalyuga, Sweller).

### Expertise reversal — the core finding

Instructional support that helps novices (worked examples, heavy scaffolding, advance organisers, explicit guidance) can **hurt** more knowledgeable learners. The expert already has schemas; redundant guidance creates extra cognitive load that interferes rather than helps.

A tutor that runs the same scaffolded mode regardless of learner state will help novices and bore-or-hurt intermediates. Naïve "always provide worked examples" rules harm past the novice stage.

### Adaptive fading — the response

Move scaffolding down a notch as the learner's signals indicate readiness:

1. **Full worked examples** (study only).
2. **Completion problems** (last steps blanked out, learner fills in).
3. **Faded examples** (more steps blanked each iteration).
4. **Problem-solving with backup** (full problems, hints available).
5. **Open exploration** (problems only).

Signals to watch for: learner finishes steps before being shown how, predicts the next step correctly, asks "but what about Y?", reports the example as obvious.

Coarse learner-state levels (novice / intermediate / advancing) suffice; probabilistic knowledge tracing isn't needed.

## Recaps and retrieval practice

The Dunlosky 2013 review puts **retrieval practice** and **spaced practice** as the two highest-utility study techniques across the field. Both bear on recap design.

- **Retrieval-style recap > summary-style recap.** "Can you tell me what we just did?" beats "here's what we just did" for retention. The act of recall is what consolidates.
- A written recap shown pre-next-step functions as summary-style. Mitigations: (a) phrase it as an **advance organiser** ("here's the slot the next step fits into"), not a regurgitation; (b) precede it with a retrieval prompt the learner answers before seeing it.
- Post-step recaps also support **spaced practice** when the learner returns and re-reads them — tutorials outlive the chat that produced them.

## Open questions / things to revisit

- **Subject-shape classifier.** Classifying by primary shape and noting modifiers is the simple approach; a heuristic classifier is open, as is how to catch a silent misclassification before a strategy is committed to.
- **Strategy switch within a tutorial.** When the procedural-recipes part finishes and the conditional-when-to-substitute-ingredients part begins, the teaching mode should shift. Detection mechanism is unclear; ITS literature on "pedagogical decision-making" may have leads.
- **Engagement / motivation frameworks** (self-determination theory, ARCS) deliberately not covered here. If engagement reasoning is wanted later, separate research pass.
- **LLM-tutor-specific pedagogy.** All frameworks above are pre-LLM. Whether retrieval-practice-via-chat is comparable to retrieval-practice-with-paper is genuinely open.
- **Replication caveats.** Cognitive load theory and worked-example effect are widely cited as well-supported, but have a substantive critique literature (de Jong 2010, others) not reflected here. Treat strength-of-evidence labels as ballpark.

## Sources

Accessed while the research was done, May 2026; the day each was read was not recorded.

Most relevant theoretical frames:

- **Reigeluth elaboration theory** — three sequencing types (theoretical / procedural / conceptual); simplifying conditions method; zoom-lens metaphor. [InstructionalDesign.org](https://www.instructionaldesign.org/theories/elaboration-theory/).
- **van Merriënboer 4C/ID** — dominant model for complex/hybrid skills. [4cid.org](https://www.4cid.org/).
- **Sweller cognitive load theory** — worked-example effect, redundancy effect. [NSW Dept of Ed summary](https://education.nsw.gov.au/content/dam/main-education/about-us/educational-data/cese/2017-cognitive-load-theory.pdf).
- **Kalyuga expertise reversal effect** — core finding for adaptive fading. [Wikipedia](https://en.wikipedia.org/wiki/Expertise_reversal_effect).
- **Spiro cognitive flexibility theory** — ill-structured-domain prescription. [InstructionalDesign.org](https://www.instructionaldesign.org/theories/cognitive-flexibility/).
- **Ausubel meaningful learning + advance organisers**. [Distance Learning Institute](https://distancelearning.institute/instructional-design/ausubel-advance-organizers-learning/).
- **Gagné conditions of learning + nine events of instruction** — varieties of learning, intellectual-skills hierarchy. [InstructionalDesign.org](https://www.instructionaldesign.org/theories/conditions-learning/).
- **Rittle-Johnson** — concepts/procedures iterative interleaving. [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC6544739/).
- **Merrill First Principles of Instruction** — problem-centred / activation / demonstration / application / integration. [MyBrainIsOpen](https://mybrainisopen.net/merrill-first-principles-of-instruction-intro).
- **Ericsson deliberate practice**. [StatPearls](https://www.ncbi.nlm.nih.gov/books/NBK554558/).
- **Dunlosky et al. 2013** — *Improving Students' Learning With Effective Learning Techniques* — utility-rated review of study techniques. [PDF](https://www.whz.de/fileadmin/lehre/hochschuldidaktik/docs/dunloskiimprovingstudentlearning.pdf).
- **Anderson & Krathwohl 2001** — revised Bloom's taxonomy (knowledge × cognitive-process grid). [Krathwohl 2002 overview](https://cmapspublic2.ihmc.us/rid=1Q2PTM7HL-26LTFBX-9YN8/Krathwohl%202002.pdf).
