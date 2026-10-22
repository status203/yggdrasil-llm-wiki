---
type: reference
pitch: What Obsidian's note sanitizer keeps and strips in inline SVG and HTML, and how standalone .html files and Mermaid render, as probed against Obsidian 1.12.7 with some findings re-checked at 1.13.7.
---

# Obsidian SVG and HTML Sanitization

This probe was run against Obsidian 1.12.7, in July 2026, with some findings re-checked against Obsidian 1.13.7 in September and October 2026; the page is a snapshot of those results, not maintained.

Obsidian sanitizes **all** inline SVG/HTML written into a note before rendering it, so a diagram authored outside what survives silently renders broken. This page records what survives, what's stripped, and where the boundaries actually are, for anyone authoring inline SVG or HTML in notes.

**Confirmation basis.** The config below was read directly from the DOMPurify call in the shipped `obsidian.asar` bundle (**Obsidian 1.12.7**), and the render behaviours were confirmed by rendering a probe note in Reading view at that version. **Re-verify at your Obsidian version** — Obsidian's sanitizer config is not published API and has changed across versions (e.g. the iframe→local-file bug [CVE-2023-2110](https://nvd.nist.gov/vuln/detail/CVE-2023-2110), fixed in 1.2.8). The exact-config claims are byte-level facts about 1.12.7; the "what renders" claims are observations at 1.12.7. Where a finding was re-checked at 1.13.7, it says so.

## The sanitizer

Obsidian's `sanitizeHTMLToDom()` wraps **DOMPurify** with this config at 1.12.7 (the whole customization — everything else is DOMPurify defaults):

```js
DOMPurify.sanitize(html, {
  ALLOW_UNKNOWN_PROTOCOLS: true,
  RETURN_DOM_FRAGMENT:     true,
  FORBID_TAGS: ["style"],
  ADD_TAGS:    ["iframe"],
  ADD_ATTR:    ["frameborder","allowfullscreen","allow","sandbox","data-tooltip-position"]
})
```

So relative to stock DOMPurify: `<style>` is **forbidden**, `<iframe>` is **added** (with framing attrs), unknown URL protocols are allowed, and the SVG allowlist is DOMPurify's **default profile, unmodified**. Sanitization is global and cannot be disabled. Mermaid is a separate path (see *Mermaid*).

At 1.13.7 (September 2026), `FORBID_TAGS:["style"]` was found in the bundle again; the rest of the config was not re-read at that version.

## What survives vs. what's stripped (inline SVG/HTML in a note)

**Survives:**

- SVG shapes/paths/text/gradients/filters/`clipPath`/markers/`<symbol>` *defs*.
- Styling via **presentation attributes** (`fill=`, `stroke=`, `opacity=`) and the **`style=` attribute**.
- `<a href>` with http(s); `<image>` element; `<iframe>` (with `sandbox`/`allow`/`allowfullscreen`/`frameborder`).
- HTML: `<u>`, `<s>`, `<span>`, `<div>`, HTML comments.

**Stripped:**

- `<script>` and all `on*` event handlers (`onclick`, `onload`, …).
- The **`<style>` element** — so CSS-class-based styling inside an SVG is silently dropped (the class stays, the rules vanish, the element renders unstyled). Use presentation attributes / `style=` instead. Re-confirmed at 1.13.7.
- `<foreignObject>` (and its HTML subtree) — in *raw note* SVG. See § *Mermaid*.
- `<use>` (so `<symbol>` + `<use>` reuse doesn't work — inline the shapes).
- Bare `<animate>` and `<set>`. (`<animateColor>`/`<animateMotion>`/`<animateTransform>` are in the allowlist and survive *sanitization* — but see the render note: they don't actually animate.)
  - **This held at 1.12.7 and did not hold when re-probed at 1.13.7 (2026-09-08).** What the 1.13.7 allowlist is for those three elements was not established. That nothing animates still held at 1.13.7 (see the render note).
- `javascript:` URIs (DOMPurify's URI scrubbing).

A **stripped element leaves an empty gap**, not a collapsed layout — the `<svg>` container keeps its declared width/height and its forbidden children are removed. Useful: a mistake shows up as obvious blank space when you review the rendered page rather than hiding.

## Render behaviours the config alone doesn't tell you

Confirmed by rendering, not derivable from the allowlist:

- **Inline SMIL animation does not run.** `<animateTransform>` survives sanitization at 1.12.7 (it's allowlisted) but a rotating square rendered *static* in Reading view. Whether it's inert-after-insert or effectively dropped doesn't matter — **treat inline SVG as static-only.** Motion goes in a sidecar (real browser). Re-confirmed static at 1.13.7 (2026-09-08).
- **At 1.12.7, a duplicate id blanked *both* diagrams.** Two SVGs on one page each defining `<linearGradient id="cg">` and referencing `url(#cg)`: **neither** painted. The same pair with namespaced ids (`cg-a`/`cg-b`) rendered correctly, and the two pairs are identical bar the id strings — so the duplicate id was the sole cause, and it cost both diagrams, not just the second. **Namespace every internal id per diagram** (`s3-g`, `s3-clip`). **Mechanism unestablished:** a blank is the *strip* signature (above), so the sanitizer plausibly drops the clashing `id` and leaves both `url(#…)` refs dangling — but "id removed" versus "reference unresolved" was not distinguished; a devtools look at the rendered `<linearGradient>` settles it.
  - **Correction, 2026-10-04:** at 1.13.7 the same pair was re-probed and **both diagrams paint**. Which definition a shared id resolves to where the two differ — each diagram's own, or the first on the page — is unestablished, so namespacing ids per diagram is still the safe choice.

## `.html` sidecars

Obsidian core **does not render standalone `.html` files** — a link to one opens the **system browser** (unsanitized, full-capability; in-app rendering needs a community plugin). Observed at 1.12.7. This is *why* a genuinely interactive visual is best kept as a separate `.html` file: it runs in a real browser where SMIL and JS both work, off the note-sanitizer surface entirely. A link to one is worth labelling as opening in the browser, and the file is checked in the browser, not the Obsidian pane. Author such files as trusted, self-contained content (inline all JS/CSS/assets — no remote references).

## Mermaid

Renders natively (no plugin), initialized `securityLevel: "strict"` (non-overridable via init directive), so author-controlled Mermaid is effectively XSS-safe — the concern is fidelity, not security. **Prefer Mermaid** over hand-rolled SVG where the diagram type allows: native, sanitizer-proof, and no id-management burden. One fork worth knowing: `<foreignObject>` is stripped in raw note SVG but **survives inside a Mermaid-rendered diagram**, because Mermaid sanitizes with its own DOMPurify config that re-adds it (that's how Mermaid does HTML labels). Observed at 1.12.7.

## Remote assets and CSP

At 1.12.7 there is **no restrictive resource CSP** — the only CSP is `style-src 'unsafe-inline' 'self' https://fonts.googleapis.com`; no `default-src`/`img-src`/`connect-src`. So a remote `<image href="http…">` or remote font is not blocked at the CSP layer. Still **inline all assets** (data: URIs) rather than referencing remote URLs: a remote fetch leaks a request to a third party (privacy) and breaks offline (reliability), and DOMPurify's separate href-scrubbing on remote refs isn't fully settled from the bytes.

## Not confirmed at runtime (bytes suggestive, render untested)

Cheap in-vault tests if ever load-bearing: a remote `<image href>` actually loading; the default `sandbox` applied to an allowed `<iframe>`. Both are untested.

## Sources

- [CVE-2023-2110, National Vulnerability Database](https://nvd.nist.gov/vuln/detail/CVE-2023-2110) (accessed 2026-10-06)
