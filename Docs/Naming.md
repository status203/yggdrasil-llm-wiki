---
type: reference
pitch: Why Yggdrasil's agents and parts have Norse names, which name goes with which role, and how to rename them.
volatility: low
checkpoint: 2026-10-06
---

# Naming

For anyone wondering *"whyTF is the librarian called Munin?"*

## The convention

*(Odin was a Claude suggestion for the orchestrator after taking suggestions of shortness and Dvorak keyboard usage preference as being all that mattered. But it fit. At the time Claude also suggested a bunch of non-themed names for other agents along the same lines. When the requirements were relaxed, Claude suggested Munin and Hugin for the librarian and researcher and the fit was too good to resist - everything else had to fit the theme. Apologies if it causes anyone difficulties. That's why this file exists - I refer to it myself!)*

The agents are named after figures in Norse mythology whose part in the myths matches their part in the system. The project takes its name from Yggdrasil, the world-tree connecting the nine realms. The session you talk to is **Odin**, king of the Æsir; the agents are figures Odin sends out, consults or relies on.

The names are decorative. Claude Code addresses each agent by the `name:` in its definition, and the lore is only a mnemonic (yeah, right). If you'd rather call them something else, renaming shouldn't break anything: ask Claude in a forge session.

## The pantheon

| Name | Role | Why |
| --- | --- | --- |
| **Odin** | The session you talk to; hands work to the others. | King of the Æsir, who sends out his ravens, consults Mimir, and watches all the worlds. The one who sees the whole picture and routes the work. |
| **Munin** (Old Norse *Muninn*, "memory") | Librarian: what the wiki already holds, and where new material belongs. | One of Odin's two ravens. Munin tends what is already held. |
| **Hugin** (Old Norse *Huginn*, "thought") | Researcher: answers from the web. | Odin's other raven, who flies the worlds each day and brings back news. |
| **Bragi** | Integrator: puts content into the page it belongs on. | God of poetry and eloquence, Odin's skald. Shapes material into lasting form; not research, not curation, but the craft of fitting the new to what's already written. |
| **Mimir** (Old Norse *Mímir*) | Teacher: tutorials, a step at a time. | The wise one at the well under a root of Yggdrasil. Odin gave an eye to drink from it, and after Mimir's death kept his head and consulted it for counsel. |
| **Tyr** (Old Norse *Týr*) | Reviewer: checks the work against a written test, and proposes changes. | God of law and justice, who gave his hand to bind the wolf Fenrir: the one who holds to the rule when it costs. |
| **Volund** (Old Norse *Völundr*; English *Wayland*) | Smith: makes, changes and retires the agents. | The master smith of Norse and Germanic legend. His work is fit-for-purpose tools, made deliberately. |

The Hugin and Munin pairing is the one that carries weight: *thought* and *memory*, fetching the new and tending the held, is exactly the split between researcher and librarian.

## The rest of the theme

A few other words in the system carry the theme on from the agents:

- **Forge.** Changing the system itself is *forge work*, done in a *forge session* under the *forge method*. The forge is Volund's smithy, where the system's own tools are made, as distinct from the everyday work of keeping a wiki.
- **Well.** Mimir's well is the one everything worth knowing is drawn from. The system has two of its own, both for forge work, so that nothing personal reaches the program's public files: the *common well* of example topics (cooking, chess and public speaking) that every illustration is drawn from, and the *technical well* of placeholder paths and example addresses that every literal value is drawn from. Anything from outside a well needs your say-so. Your own wiki uses neither. Set its `wiki.visibility` to `public` and you're asked, once, what that means for it: which topics its examples may come from, or any, where its review ledgers go, and whether wrap keeps session records in it.
