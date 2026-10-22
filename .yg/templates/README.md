---
role: instruction
pitch: Convention guide for Yggdrasil page templates — two markers, two jobs, with a worked example for substantial subject-specific shapes.
---

# `<program>/.yg/templates/` — page templates

Templates are skeletal page files, used when a page has to be created rather than added to. Paths are written as in `<program>/.yg/page-contract.md`: a program file under `<program>/`, a wiki file bare from the wiki root. The universal fallback `default.md` lives here. Type-specific project defaults get added lazily — only when a shape genuinely differs from the universal fallback (e.g. the `progression/*` kinds, which carry a `progress:` slot `default.md` lacks). Whatever `.md` files sit in this folder *are* the set. A template supplies frontmatter and a skeleton, what every page of its type starts with, and the rest of a page's shape comes from the subject and its siblings (`<program>/.yg/page-contract.md` § *The subject*, which also says when a subject's type gets a template); for a type on the fallback that is nearly all of it, since the fallback bottoms out at little more than a title. Nor does it carry how new material joins the page, which is `<program>/.yg/page-contract.md` § *How new material joins* or the subject's `.subject.md`: meta-text is read only as a page is made, so a join rule there would reach no later edit (`D7.3`). Per-subject overrides live in the wiki at `<Subject>/.templates/<type>.md`.

Lookup chain: subject override → project type-specific default (if any) → `default.md`. The `<type>` key in that chain is the **leaf segment** of a page's `type` — a path-form type resolves by its last segment (`progression/companion` → `companion.md`), so templates stay flat here even though the genus is path-form.

Naming asymmetry, intentional: subject-level templates are *type-named* (`<subject>/.templates/<type>.md`) because they exist precisely when every page of a real type starts with the same fields or sections (`<program>/.yg/page-contract.md` § *The subject*). The project-level fallback is *role-named* (`default.md`) because its job is "use me when nothing more specific applies" — that's a role, not a type. Don't pre-create empty type-named project defaults; the universal fallback covers them.

## Two markers

Templates use two distinct markers for two distinct jobs.

### `<placeholder>` — substitution slot

A single short value the agent drops in at instantiation. Lives in YAML frontmatter values, in headings, and in short labelled body lines (`companion.md`'s `**Source**:` line, `placeholder.md`'s pointer). Replaced by the substituted value; the marker disappears once filled.

```markdown
---
type: <Type>
pitch: <one sentence saying what the page is>
---

# <Title>
```

(That's `default.md` — the universal fallback — verbatim. `<Type>` is filled with the page's type, which is settled before the template is reached.)

### `<!-- meta-text -->` — instructions for making the page

Instructions for whoever makes the page from the template. Can be multi-line — HTML comments span lines fine, so substantial guidance fits without hacks.

**Removed as the page is made, explicitly not kept on the page.** A comment left there stays in the file and shows in editing view (`F16.1`), where it reads as a control: editing it looks like changing how the page is handled, and it changes nothing, since a comment on a page is content, never instruction. Guidance every later edit needs goes in the subject's `.subject.md`, or for a template the program ships, in `<program>/.yg/page-contract.md`, and how new material joins a section, ordering included, is `<program>/.yg/page-contract.md` § *How new material joins* or `.subject.md`, never meta-text.

`subject.md` is the exception: the file it makes, `.subject.md`, is instruction itself, so its meta-text stays there, where a convention added by hand meets it (`D12.1.1`).

## Worked example: a recipe template

Shows both markers together. Lives at `<Subject>/.templates/recipe.md` — `recipe` is a food-specific type the subject introduces (subjects may extend the project-wide type vocabulary; see `<program>/.yg/page-contract.md` § *Frontmatter*).

```markdown
---
type: recipe
pitch: <one sentence saying what the page is>
---

# <Recipe name>

## Tags
<!-- comma-separated; cuisine, meal type, dietary tags. e.g. "italian, dinner, vegetarian". -->

## Ingredients
<!-- list with quantities; preserve source measurement units. -->

## Process
<!--
Ordered or numbered steps. Preserve original instruction granularity —
don't collapse multi-step technique into one-liners. Timings stay literal.
-->

## Nutrition
<!-- per-portion: calories, carbs, protein, fat. Leave the section blank if not provided. -->
```

Its units and granularity rules bind every later edit of those sections too, so the subject's `.subject.md` states them as well; the meta-text guides the page's first writing.

## Authoring guidance

- Keep frontmatter to fields the page genuinely needs. For a content-page template, `type` and `pitch` are both required — they drive template resolution, index rows, and recall.
- **Frontmatter describes the produced page, not the template file.** `subject.md` is the special case that makes this visible: it produces a subject's `.subject.md`, so it carries `role: instruction` and no `type` at all. (This README isn't a template, so its own frontmatter is self-describing.)
- Use `<placeholder>` only where a value gets substituted at instantiation. If the value is "whatever the populator writes", that's a body section, not a placeholder.
- Use `<!-- meta-text -->` to tell the populator what shape, what to keep, what to drop. Be specific — vague instructions produce vague pages.
- Add meta-text only where the section needs guidance the heading doesn't already give; meta-text that merely repeats its heading is noise.
