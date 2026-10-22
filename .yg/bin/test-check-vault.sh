#!/bin/sh
# Self-check for check-vault.sh. Builds a throwaway wiki holding one instance of each
# defect plus clean controls, runs the script in place against it, and asserts what is and
# is not reported.

set -eu
script=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/check-vault.sh
W=$(mktemp -d)
quiet=$(mktemp -d)
trap 'rm -rf "$W" "$quiet"' EXIT

mkdir -p "$W/Misc"
git -C "$W" init -q

page() { mkdir -p "$(dirname "$W/$1")"; { echo '---'; printf '%s\n' "$2"; echo '---'; } >"$W/$1"; }

page Misc/Clean.md 'type: concept
pitch: An ordinary pitch, with a dash - and a hash# that are fine mid-value.'
page Misc/Colon.md 'type: concept
pitch: Broken: because colon-space voids the block.'
page Misc/TrailingColon.md 'type: concept
pitch: The steps are as follows:'
page Misc/Hash.md 'type: concept
pitch: Broken because of a trailing comment #like this.'
page Misc/Indicator.md 'type: concept
pitch: @handle leads with an at sign.'
page Misc/Quoted.md 'type: concept
pitch: "A quoted scalar parses, but is banned by house style."'
page Misc/Shapes.md 'type: concept
pitch: Each other key is one YAML shape (F15.1).
lead-hash: #empties it
lead-amp: &anchor keeps the rest
lead-dash: -parses as text
dash-space: - voids it
block-text: >voids it
block-bare: >
quoted-colon: "Openings: a survey"
quoted-hash: "Step #2 of the opening"
open-quote: "never closed'
page Misc/Untyped.md 'pitch: Has no type.'
page Misc/Index.md 'role: derived
pitch: An index needs no type.'
printf '| [[Misc/Clean]] | a nested page, linked by path |\n' >>"$W/Misc/Index.md"
page Misc/.subject.md 'role: instruction
pitch: A machine file needs no type.'
printf 'no frontmatter here\n' >"$W/Misc/Bare.md"
# A delimiter with a trailing space is no delimiter to Obsidian (`F15.2`).
printf -- '--- \ntype: concept\npitch: Opens with a trailing space.\n---\n' >"$W/Misc/Spaced open.md"
printf -- '---\ntype: concept\npitch: Closes with a trailing space.\n--- \n\nBody.\n' >"$W/Misc/Spaced close.md"

# Only a subject folder holds pages. A folder with no .subject.md, and a file at the root,
# are not read, however broken.
page import/Stray.md 'pitch: Imported: and broken in every way.'
printf '[a dead link](nowhere-at-all.md) and [[wiki/Imported/Thing]]\n' >>"$W/import/Stray.md"
printf '# Notes for the session\n\nNo frontmatter, [a dead link](gone-from-root.md).\n' >"$W/CLAUDE.md"

# Relative links. The source exists; the citations differ in whether they reach it.
mkdir -p "$W/.sources/chats"
: >"$W/.sources/chats/a-chat.md"
page Misc/Links.md 'type: concept
pitch: Carries every link shape the check has to tell apart.'
cat >>"$W/Misc/Links.md" <<'MD'
A [resolving citation](../.sources/chats/a-chat.md) and a [dead one](../.sources/chats/gone.md).
An [external link](https://example.com/nope) and an [anchor](#heading) are not paths.
```markdown
An [example](docs/images/filename.png) inside a fence is not a reference.
```
A `[span example](docs/images/spanned.png)` in inline code is not one either, but a [dead link](../.sources/chats/after-span.md) after it is.
MD
page Misc/Nested/Deep.md 'type: concept
pitch: A page one folder deeper, whose citation was written at the shallower depth.'
printf 'A [citation that lost a level](../.sources/chats/a-chat.md).\n' \
	>>"$W/Misc/Nested/Deep.md"

# The fence flag is per-file, but one batched awk sees every page, so a page that leaves a
# fence open would silence the next page's links unless the flag resets. Both pages below
# leave one open, which makes the failure deterministic: whichever the batch reaches second
# has its own link suppressed if the reset is missing, whatever order find walks them in.
page Misc/FenceA.md 'type: concept
pitch: Leaves a fenced block open, to prove the fence flag resets per file.'
cat >>"$W/Misc/FenceA.md" <<'MD'
A [dead link](../.sources/chats/missing-a.md) sits before the fence.
```markdown
An [example](docs/images/never-checked.png) inside a block that is never closed.
MD
page Misc/FenceB.md 'type: concept
pitch: The same, so that whichever page the batch reaches second proves the reset.'
cat >>"$W/Misc/FenceB.md" <<'MD'
A [dead link](../.sources/chats/missing-b.md) sits before the fence.
```markdown
An [example](docs/images/never-checked.png) inside a block that is never closed.
MD

# Sources. A source is cited when anything links to it — a page, or another source, as an
# image is cited by the note describing it. Files loose at the root of .sources/ are
# uncited by design, and are not checked.
mkdir -p "$W/.sources/images"
: >"$W/.sources/chats/orphan.md"
: >"$W/.sources/images/pic.jpg"
printf 'The [picture](pic.jpg).\n' >"$W/.sources/images/pic-note.md"
printf 'A [note](../.sources/images/pic-note.md).\n' >>"$W/Misc/Clean.md"
printf 'A [dead link inside a source](nowhere.md) is the record, not a defect.\n' >"$W/.sources/chats/a-chat.md"
: >"$W/.sources/loose.md"

# Keys differing only in case are two properties to Obsidian.
page Misc/UpperStatus.md 'type: concept
pitch: Carries the capitalised spelling.
Status: active'
page Misc/LowerStatus.md 'type: concept
pitch: Carries the lower-case spelling.
status: active'

# A wikilink is written bare (`D7.4`); Obsidian writes a qualified one on its own (`F14.3`),
# subject-first where the wiki is the vault and folder-first where it sits inside one.
# A name two pages share, and a subject's Index, need the path.
page Misc/Absolute.md 'type: concept
pitch: Holds qualified wikilinks and a bare one.'
cat >>"$W/Misc/Absolute.md" <<'MD'
See [[Misc/Clean\|Clean]], [[wiki/Misc/Hash]] and [[Colon]].
Also [[Other/Twin]], [[Misc/Index|Misc]] and [[Elsewhere/Nothing]].
```markdown
[[Misc/Quoted]] inside a fence is an example.
```
So is `[[Misc/Untyped]]` in inline code.
MD

# A page carrying volatility: is dated by its checkpoint:, in the form staleness.sh reads.
# A running tutorial is checked too: it is written with both, and finishes carrying them.
page Misc/VolDate.md 'type: concept
pitch: Dated by a plain date.
volatility: high
checkpoint: 2024-02-29'
page Misc/VolTool.md 'type: progression/tutorial
pitch: Dated by a tool version, and still running.
volatility: low
checkpoint: Stockfish @ 17 (2026-09-23)
progress: step 2/9'
page Misc/VolNone.md 'type: progression/tutorial
pitch: Carries volatility and no checkpoint.
volatility: low
progress: step 1/15'
page Misc/VolOdd.md 'type: concept
pitch: A volatility the review has no threshold for.
volatility: sometimes
checkpoint: 2026-09-01'
page Misc/VolBadDate.md 'type: concept
pitch: A checkpoint that is not a date.
volatility: high
checkpoint: 2026-02-30'
page Misc/VolLoose.md 'type: concept
pitch: A checkpoint in words.
volatility: medium
checkpoint: last spring'
page Misc/VolFuture.md 'type: concept
pitch: A checkpoint after today.
volatility: medium
checkpoint: 2999-01-01'
page Misc/OptedOut.md 'type: progression/tutorial
pitch: Opted out, so its checkpoint stays as the date it is current as of.
checkpoint: 2026-01-01'

# Two subjects may rightly share a title, so a shared filename is a notice, not a finding.
page Other/.subject.md 'role: instruction
pitch: A second subject.'
page Other/Twin.md 'type: concept
pitch: One of two pages sharing a title.'
page Misc/Twin.md 'type: concept
pitch: The other.'
page Other/Index.md 'role: derived
pitch: Every subject has an Index, which is not a shared title.'
page import/Twin.md 'type: concept
pitch: A third, outside any subject, so not a page.'

# An unescaped alias pipe drops the rest of a table cell (`F16.2`), and only there: outside a
# table both forms render the same. The delimiter row brings in the header above it.
page Misc/Tables.md 'type: concept
pitch: Carries alias pipes in and out of tables.'
cat >>"$W/Misc/Tables.md" <<'MD'
| Opening | Note |
| --- | --- |
| [[Clean|Cell]] | unescaped |
| [[Colon\|Escaped]] | escaped |
| `[[Hash|Spanned]]` | inline code |

Outside a table, [[Hash|Prose]] renders the same.

[[Quoted|Header]] | b
--- | ---
plain | row

```markdown
| [[Hash|Fenced]] | x |
| --- | --- |
```
MD

# A <style> element is stripped (`F16.4`); attributes are not.
page Misc/Diagram.md 'type: concept
pitch: Carries inline SVG styled both ways.'
cat >>"$W/Misc/Diagram.md" <<'MD'
<svg><style>.a { fill: red }</style><rect class="a"/></svg>
<svg><rect style="fill: red" fill="red"/></svg>
Quoting `<style>` in inline code is not one.
```html
<style>.b { fill: blue }</style>
```
MD

# A sidecar is named <page-slug>--<what>.html for a page in its own folder (`D9.2`).
: >"$W/Misc/clean--board.html"
: >"$W/Misc/Nested/deep--board.html"
: >"$W/Misc/Clean--cased.html"
: >"$W/Misc/board.html"
: >"$W/Misc/deep--elsewhere.html"
: >"$W/Misc/nobody--here.html"
# A capital some locales lower to ASCII is a hyphen in the slug, wherever it is read.
page 'Misc/İstanbul Kebab.md' 'type: concept
pitch: A page whose name lowers differently by locale.'
: >"$W/Misc/stanbul-kebab--map.html"
: >"$W/Misc/istanbul-kebab--map.html"
: >"$W/import/stray.html"
page 'Misc/Pipe|name.md' 'type: concept
pitch: A page name no wikilink reaches.'
mkdir -p "$W/Misc/.hidden"
: >"$W/Misc/.hidden/unread.html"

out=$(sh "$script" "$W" || true)

fail=0
want() { if printf '%s' "$out" | grep -Fq -- "$1"; then echo "ok    — $2"; else echo "FAIL  — $2"; fail=1; fi; }
deny() { if printf '%s' "$out" | grep -Fq -- "$1"; then echo "FAIL  — $2"; fail=1; else echo "ok    — $2"; fi; }
# A row assertion matches the whole line, so a path is asserted wiki-relative.
row() { if printf '%s\n' "$out" | grep -qxF -- "$1"; then echo "ok    — $2"; else echo "FAIL  — $2"; fail=1; fi; }

row 'Misc/Colon.md: pitch — value contains ": ", which voids the whole property block' 'colon-space is caught, the path wiki-relative'
row 'Misc/TrailingColon.md: pitch — value ends with ":", which voids the whole property block' 'a trailing colon is caught (F15.1)'
want 'Hash.md: pitch — value contains " #"' 'space-hash is caught'
want 'Indicator.md: pitch — value leads with YAML indicator `@`' 'a leading indicator is caught'
want 'Quoted.md: pitch — value leads with' 'a quoted scalar is reported as house style'
want 'Quoted.md: pitch — value leads with `"`: parses cleanly' 'and is distinguished from a parse failure (`D21.1`)'
want 'Hash.md: pitch — value contains " #", which cuts the value off' 'space-hash is a loss, not a parse failure (F15.1)'
want 'Shapes.md: lead-hash — value leads with YAML indicator `#`, which leaves the value empty' 'a leading hash empties the value'
want 'Shapes.md: lead-amp — value leads with YAML indicator `&`, which takes its first word as an anchor name' 'a leading ampersand loses its first word (F15.1)'
want 'Shapes.md: lead-dash — value leads with `-`: parses cleanly' 'a dash before text parses, banned by house style (D21.1)'
want 'Shapes.md: dash-space — value leads with YAML indicator `-`, which voids' 'a dash before a space voids the block'
want 'Shapes.md: block-text — value leads with `>` and has text after it, which voids' 'a block indicator with text after it voids the block'
want 'Shapes.md: block-bare — value leads with `>`: parses cleanly' 'a bare block indicator parses, banned by house style'
want 'Shapes.md: quoted-colon — value leads with `"`: parses cleanly' 'a closed quote holding colon-space is house style'
deny 'Shapes.md: quoted-colon — value contains' 'and not a parse failure, since it reads whole (F15.1)'
deny 'Shapes.md: quoted-hash — value contains' 'nor is a closed quote holding space-hash a loss'
want 'Shapes.md: open-quote — value opens a `"` quote it never closes' 'an unclosed quote voids the block'
want 'Untyped.md: missing type' 'a content page without type is caught'
want 'Bare.md: no frontmatter' 'a page with no frontmatter is caught'
want 'Spaced open.md: no frontmatter' 'a first line of "--- " opens no frontmatter (F15.2)'
want 'Spaced close.md: frontmatter never closed' 'a closing line of "--- " closes nothing (F15.2)'
row 'Misc/Links.md: link does not resolve: ../.sources/chats/gone.md' 'a citation to a missing source is caught'
want 'Deep.md: link does not resolve:' 'a citation at the wrong depth is caught — the move hazard'
deny 'a-chat.md) ' 'a resolving citation is not reported'
deny 'example.com' 'an external link is not a path'
deny 'filename.png' 'a link inside a fenced block is an example, not a reference'
deny 'spanned.png' 'and so is one inside inline code'
want 'Links.md: link does not resolve: ../.sources/chats/after-span.md' 'a link after inline code on the same line is still checked'
deny 'Clean.md' 'a clean page is not reported'
deny 'Index.md' 'an index is exempt from type'
deny 'subject.md' 'a machine file is exempt from type'
deny 'import' 'a folder with no .subject.md is not read, named, or reported'
deny 'CLAUDE.md' 'a root-level file is not read as a page'
deny 'gone-from-root' 'nor are its links checked'
want 'FenceA.md: link does not resolve: ../.sources/chats/missing-a.md' 'a page that leaves a fence open still reports its own link'
want 'FenceB.md: link does not resolve: ../.sources/chats/missing-b.md' 'and does not silence the other — the fence flag resets per file'
deny 'never-checked.png' 'a link inside the unclosed fence is still skipped'
row '.sources/chats/orphan.md: source nothing cites' 'a typed source nothing links to is caught'
deny 'a-chat.md: source' 'a source a page cites is not reported'
deny 'pic.jpg' 'a source cited only by another source is not reported'
deny 'nowhere.md' 'a dead link inside a source is not checked'
deny 'loose.md' 'a file loose at the root of .sources/ is not checked'
want 'frontmatter key in more than one case: Status (1), status (1)' 'keys differing only in case are caught'
want 'Absolute.md: qualified wikilink, write it bare (D7.4): [[Misc/Clean\|Clean]]' 'a subject-qualified wikilink is caught'
want 'Absolute.md: qualified wikilink, write it bare (D7.4): [[wiki/Misc/Hash]]' 'and a folder-qualified one'
deny '[[Colon]]' 'a bare wikilink is not reported'
deny '[[Other/Twin' 'a qualified link to a shared name needs its path'
deny '[[Misc/Index' 'and so does one to a subject Index'
deny '[[Elsewhere/Nothing' 'a qualified link to no page is not this check'
deny '[[Misc/Quoted' 'a qualified wikilink inside a fence is an example'
deny '[[Misc/Untyped' 'and so is one inside inline code'
deny 'Index.md: qualified' 'a generated view links nested pages by path, its own choice (`F14.1`)'
deny 'VolDate.md' 'a page dated by a plain date is not reported'
deny 'VolTool.md' 'nor one dated by a tool version, running or not'
want 'VolNone.md: volatility without a checkpoint' 'volatility without a checkpoint is caught'
want 'VolOdd.md: volatility — not high, medium or low: sometimes' 'a volatility with no threshold is caught'
want 'VolBadDate.md: checkpoint — not a date or tool @ version (date): 2026-02-30' 'an impossible date is caught'
want 'VolLoose.md: checkpoint — not a date or tool @ version (date): last spring' 'a checkpoint in words is caught'
want 'VolFuture.md: checkpoint — after today: 2999-01-01' 'a checkpoint after today is caught'
deny 'OptedOut.md' 'a checkpoint without volatility is an opt-out, not a finding'
row 'notice: shared filename Twin.md: Misc/Twin.md, Other/Twin.md' 'a shared filename is a notice, naming only pages'
deny 'shared filename Index.md' 'every subject having an Index is not a shared filename'
row 'Misc/Tables.md: unescaped alias pipe in a table, which drops the rest of the cell (F16.2): [[Clean|Cell]]' 'an unescaped alias pipe in a table cell is caught'
want 'alias pipe in a table, which drops the rest of the cell (F16.2): [[Quoted|Header]]' 'and in the header row of a table without outer pipes'
deny 'Escaped]]' 'an escaped alias pipe is not reported'
deny 'Spanned]]' 'nor one in inline code'
deny 'Prose]]' 'nor one outside a table'
deny 'Fenced]]' 'nor one inside a fence'
deny 'Misc/Index|Misc' 'an unescaped alias outside a table, as Obsidian writes it, is not this check'
row 'Misc/Diagram.md: <style> element, which Obsidian strips (F16.4): style with attributes instead' 'a <style> element is caught'
if [ "$(printf '%s\n' "$out" | grep -c '^Misc/Diagram.md:')" -eq 1 ]; then echo "ok    — style attributes, inline code and a fence are not reported"; else echo "FAIL  — style attributes, inline code and a fence are not reported"; fail=1; fi
side=': sidecar not named <page-slug>--<what>.html for a page in its folder, so no move carries it (D9.2)'
deny 'clean--board.html' 'a sidecar named for its page is not reported'
deny 'deep--board.html' 'nor one beside a page in a nested folder'
row "Misc/Clean--cased.html$side" 'a sidecar whose slug keeps capitals is caught'
row "Misc/board.html$side" 'a sidecar with no page slug is caught'
row "Misc/deep--elsewhere.html$side" 'a sidecar named for a page in another folder is caught'
row "Misc/nobody--here.html$side" 'a sidecar named for no page is caught'
deny '/stanbul-kebab--map.html' 'a non-ASCII capital is a hyphen in the slug, in any locale'
row "Misc/istanbul-kebab--map.html$side" 'and not the ASCII letter a locale lowers it to'
deny 'unread.html' 'a dotfolder holds no sidecars'
row 'Misc/Pipe|name.md: page name holds |, which no wikilink can reach' 'a page name holding | is caught'

# A notice alone does not fail the check: a writer after writing reads exit 0 as clean.
for s in A B; do
	mkdir -p "$quiet/$s"
	printf -- '---\nrole: instruction\npitch: A subject.\n---\n' >"$quiet/$s/.subject.md"
	printf -- '---\ntype: concept\npitch: A twin.\n---\n' >"$quiet/$s/Twin.md"
done
if sh "$script" "$quiet" >/dev/null; then echo "ok    — a notice alone exits 0"; else echo "FAIL  — a notice alone exits 0"; fail=1; fi

# A wiki with no subject yet is clean, and the check does not wander into the working
# directory looking for pages.
empty=$quiet/empty
mkdir -p "$empty/import"
printf 'no frontmatter\n' >"$empty/import/Stray.md"
rc=0; o=$(cd "$W/Misc" && sh "$script" "$empty") || rc=$?
if [ "$rc" -eq 0 ] && [ -z "$o" ]; then echo "ok    — a wiki with no subject is clean"; else echo "FAIL  — a wiki with no subject is clean (exit $rc)"; fail=1; fi

# A page can be written before /yg-init has made a repository.
rm -rf "$W/.git"
out=$(sh "$script" "$W" 2>&1 || true)
want 'Colon.md: pitch' 'the check runs in a copy with no repository'

# The wiki root is the first argument, never found from the working directory.
rc=0; (cd "$W" && sh "$script") >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 2 ]; then echo "ok    — no wiki root is a usage error"; else echo "FAIL  — no wiki root is a usage error (exit $rc)"; fail=1; fi
rc=0; out=$(sh "$script" "$W/nowhere" 2>&1) || rc=$?
case "$rc $out" in "2 "*"no wiki at"*) echo "ok    — a wiki root that is no directory is refused" ;; *) echo "FAIL  — a wiki root that is no directory is refused (exit $rc)"; fail=1 ;; esac

# The shared awkward wiki (fixture-awkward-wiki.sh): valid pages in every awkward shape
# give no row but the case-only twin's notice, in a UTF-8 locale and under LC_ALL=C.
A=$(mktemp -d)
sh "${script%/*}/fixture-awkward-wiki.sh" "$A" >/dev/null
for loc in "${LANG:-C.UTF-8}" C; do
	out=$(LC_ALL=$loc sh "$script" "$A" 2>&1) || :
	if [ "$out" = 'notice: shared filename opening.md: Chess/opening.md, Cooking/Opening.md' ]; then
		echo "ok    — the awkward wiki gives only the twin's notice ($loc)"
	else echo "FAIL  — the awkward wiki gives only the twin's notice ($loc): $out"; fail=1; fi
done
rm -rf "$A"

# A wiki inside a larger vault: Obsidian qualifies a link whose name a page outside the wiki
# shares (`F14.3`), which the check cannot see (`D3.2`), so no qualified link is reported there.
V=$(mktemp -d)
mkdir -p "$V/Wiki/Misc"
cp "$W/Misc/.subject.md" "$W/Misc/Absolute.md" "$W/Misc/Clean.md" "$W/Misc/Hash.md" "$V/Wiki/Misc/"
out=$(sh "$script" "$V/Wiki" 2>&1) || :
want 'qualified wikilink, write it bare (D7.4): [[Misc/Clean\|Clean]]' 'the same wiki with no vault above it reports the link'
mkdir "$V/.obsidian"
out=$(sh "$script" "$V/Wiki" 2>&1) || :
deny 'qualified wikilink' 'a wiki inside a larger vault reports no qualified link (D7.4)'
rm -rf "$V"

exit $fail
