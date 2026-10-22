#!/bin/sh
# Self-check for move-page.sh. The cases the logic turns on are the link forms -- the
# escaped pipe above all, which a rewrite that splits on `|` corrupts -- and the two halves
# a move breaks that a rename does not: relative links, which resolve by path and so change
# with depth, and sidecars, which stay where they were while the page walks off. Literal
# matching is asserted with a name whose characters are regex metacharacters.
#
# Runs the script in place against a throwaway wiki, except the exec-bit case, which needs
# a regenerator without its bit and so works on copies of both scripts.

set -eu
bin=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

W=$tmp/wiki
mkdir -p "$W/Sub/Cluster" "$W/Bystander" "$W/.sources/chats" "$W/import"
git -C "$W" init -q
git -C "$W" config user.email t@example.com
git -C "$W" config user.name t

mv_page() { sh "$bin/move-page.sh" "$W" "$@"; }

printf -- '---\nrole: instruction\npitch: a subject\n---\n\nsee [[Old]]\n' > "$W/Sub/.subject.md"
printf -- '---\nrole: instruction\npitch: a subject that links to nothing\n---\n' > "$W/Bystander/.subject.md"
printf -- '---\ncaptured: 2026-09-16\nsource_type: chat\npitch: backing\n---\n' > "$W/.sources/chats/note.md"
printf -- '---\ncaptured: 2026-09-16\nsource_type: chat\npitch: a record\n---\n\nthe chat said [[Old]]\n' > "$W/.sources/chats/record.md"
printf -- '---\ntype: concept\npitch: unrelated\n---\n\n# Unrelated\n' > "$W/Bystander/Unrelated.md"
printf -- '---\ntype: concept\npitch: a twin\n---\n\n# Twin\n' > "$W/Bystander/Twin.md"
printf -- '---\ntype: concept\npitch: a twin\n---\n\n# Twin\n' > "$W/Sub/Twin.md"
mkdir -p "$W/Bystander/.templates"
printf -- '---\ntype: concept\npitch: alone\n---\n\n# Lone\n' > "$W/Sub/Lone.md"
printf -- '# lone\n' > "$W/Bystander/.templates/lone.md"
for p in 'Old timer' 'A.B+C' 'AxBC'; do
	printf -- '---\ntype: concept\npitch: %s\n---\n\n# %s\n' "$p" "$p" > "$W/Sub/$p.md"
done
printf 'outside the wiki\n' > "$tmp/outside.md"
printf -- '---\ntype: concept\npitch: a dropped note\n---\n\n# Loose\n' > "$W/import/Loose.md"

# The page that moves: a sidecar by the contract's naming pattern, a source citation that
# resolves by path, an external link, an absolute one, and a fenced example of each.
P=$W/Sub/Old.md
cat > "$P" <<'EOF'
---
type: progression/tutorial
pitch: the page under test
---

# Old

sidecar [the animation](old--anim.html)
anchored [the animation, mid-way](old--anim.html#phase2)
external [a site](https://example.com/old--anim.html)
absolute [a path](/dev/null)

```
fenced [not a link](old--anim.html)
fenced cite [not a citation](../.sources/chats/note.md)
```

## Sources

- [a chat](../.sources/chats/note.md)
EOF
printf -- '---\ntype: progression/practice\npitch: linked only from its index\nprogress: step 2\n---\n' > "$W/Sub/Lonely practice.md"
printf '<!doctype html><title>anim</title>\n' > "$W/Sub/old--anim.html"
printf '<!doctype html><title>orphan</title>\n' > "$W/Sub/unrelated--anim.html"

L=$W/Sub/Links.md
cat > "$L" <<'EOF'
---
type: concept
pitch: every link form at once
---

bare [[Old]]
alias [[Old|display]]
escaped [[Old\|display]]
heading [[Old#Section]]
qualified [[Sub/Old]]
embed ![[Old]]
combined [[Sub/Old#Section]]
anchor [[#Section]]
decoy [[Old timer]]
dirseg [[Old/Inner]]
two [[Old]] and [[Sub/Old\|x]]
unterminated [[Old
meta [[A.B+C]]
metadecoy [[AxBC]]
dotmd [[Old.md]] and [[Sub/Old.md#Section]]
lower [[old]] and [[OLD|shout]]
EOF

git -C "$W" add -A
git -C "$W" commit -qm base

fail=0
want() { if [ "$1" = "$2" ]; then echo "ok    — $3"; else echo "FAIL  — $3"; echo "        got [$1] want [$2]"; fail=1; fi; }
has() { if grep -qxF -- "$2" "$1"; then echo yes; else echo no; fi; }
there() { if [ -e "$1" ]; then echo yes; else echo no; fi; }

sh "$bin/regen-views.sh" "$W" all >/dev/null
bystander_before=$(cat "$W/Bystander/Index.md")
record_before=$(cat "$W/.sources/chats/record.md")

# --- a rename in place, run from outside the wiki -------------------------------------
out=$(cd / && sh "$bin/move-page.sh" "$W" Sub/Old.md New)
P=$W/Sub/New.md

want "$(has "$L" 'bare [[New]]')"                    yes 'bare link rewritten'
want "$(has "$L" 'alias [[New|display]]')"           yes 'aliased link keeps its display text'
want "$(has "$L" 'escaped [[New\|display]]')"        yes 'escaped pipe survives, alias intact'
want "$(has "$L" 'heading [[New#Section]]')"         yes 'heading anchor preserved'
want "$(has "$L" 'qualified [[Sub/New]]')"           yes 'a rename keeps the path prefix'
want "$(has "$L" 'embed ![[New]]')"                  yes 'embed rewritten'
want "$(has "$L" 'combined [[Sub/New#Section]]')"    yes 'prefix and anchor together'
want "$(has "$L" 'anchor [[#Section]]')"             yes 'same-page anchor untouched'
want "$(has "$L" 'decoy [[Old timer]]')"             yes 'a longer name containing the old one is untouched'
want "$(has "$L" 'dirseg [[Old/Inner]]')"            yes 'the old name as a directory segment is untouched'
want "$(has "$L" 'two [[New]] and [[Sub/New\|x]]')"  yes 'two links on one line'
want "$(has "$L" 'unterminated [[Old')"              yes 'an unterminated link is left alone'
want "$(has "$L" 'dotmd [[New.md]] and [[Sub/New.md#Section]]')" yes 'a link written with .md is rewritten and keeps it'
want "$(has "$L" 'lower [[New]] and [[New|shout]]')" yes 'a link in another letter case is rewritten (F14.2)'
want "$(has "$W/Sub/.subject.md" 'see [[New]]')"     yes "a link in a subject's .subject.md is rewritten"

want "$(there "$P")" yes 'the page moved'
want "$(there "$W/Sub/Old.md")" no 'the old path is gone'
want "$(printf '%s\n' "$out" | grep -cxF 'Sub/Old.md -> Sub/New.md')" 1 'the move is reported wiki-relative'
want "$(there "$W/Sub/new--anim.html")" yes 'the sidecar took the new name'
want "$(there "$W/Sub/old--anim.html")" no 'and left the old one'
want "$(has "$P" 'sidecar [the animation](new--anim.html)')" yes "the page's link followed the sidecar"
want "$(has "$P" 'anchored [the animation, mid-way](new--anim.html#phase2)')" yes 'an anchor on that link survives'
want "$(there "$W/Sub/unrelated--anim.html")" yes 'a sidecar belonging to another page is left alone'
want "$(has "$P" '- [a chat](../.sources/chats/note.md)')" yes 'a rename leaves a citation alone'
want "$(has "$P" 'external [a site](https://example.com/old--anim.html)')" yes 'a URL is not a path'
want "$(has "$P" 'absolute [a path](/dev/null)')" yes 'an absolute path is left alone'
want "$(has "$P" 'fenced [not a link](old--anim.html)')" yes 'a fenced example is not a link'
want "$(cat "$W/Bystander/Index.md")" "$bystander_before" 'a subject with no link to the page is not churned'
want "$(cat "$W/.sources/chats/record.md")" "$record_before" 'a source is a record, and its wikilinks are not rewritten'

# --- a rename whose only inbound links are the views ---------------------------------
# The views are regenerated, never link-rewritten: an index the rewrite touched would read
# fresh, keeping its row where the old name sorted, and the progressions view at the wiki
# root would name a page that is gone.
out=$(mv_page 'Sub/Lonely practice.md' 'Zed practice')
want "$(grep -cF '| [[Zed practice\|Zed]] | step 2 |' "$W/Progressions.md")" 1 'the progressions view names the renamed page'
want "$(printf '%s\n' "$out" | grep -cxF 'Progressions.md')" 0 'and was not link-rewritten'
want "$(printf '%s\n' "$out" | grep -cxF 'wrote Progressions.md')" 1 'but regenerated'
cp "$W/Sub/Index.md" "$tmp/index-after-move"
sh "$bin/regen-views.sh" "$W" subject Sub >/dev/null
want "$(cmp -s "$W/Sub/Index.md" "$tmp/index-after-move" && echo same)" same 'the subject index is as a regeneration writes it'

# --- a move that changes depth ------------------------------------------------------
mv_page Sub/New.md 'Sub/Cluster/' >/dev/null
P=$W/Sub/Cluster/New.md

want "$(there "$P")" yes 'the page moved into the cluster'
want "$(there "$W/Sub/Cluster/new--anim.html")" yes 'the sidecar went with it'
want "$(has "$P" 'sidecar [the animation](new--anim.html)')" yes 'a same-folder sidecar link is unchanged by the move'
want "$(has "$P" '- [a chat](../../.sources/chats/note.md)')" yes 'the citation was rebased to the new depth'
want "$(has "$P" 'fenced cite [not a citation](../.sources/chats/note.md)')" yes 'a fenced citation is not rebased'
want "$(has "$L" 'bare [[New]]')" yes 'a bare link survives a move untouched'
want "$(has "$L" 'qualified [[Sub/Cluster/New]]')" yes 'a qualified link is repointed at the new folder'
want "$(has "$L" 'two [[New]] and [[Sub/Cluster/New\|x]]')" yes 'and keeps its alias'
want "$(git -C "$W" status --porcelain -- 'Sub/Cluster/New.md' | cut -c1)" 'A' \
	'git followed the page rather than seeing a delete and an add'

# --- a move and a rename together ---------------------------------------------------
mv_page 'Sub/Cluster/New.md' 'Bystander/Renamed' >/dev/null
want "$(there "$W/Bystander/Renamed.md")" yes 'moved and renamed in one call'
want "$(there "$W/Bystander/renamed--anim.html")" yes 'the sidecar took both changes'
want "$(has "$L" 'qualified [[Bystander/Renamed]]')" yes 'the qualified link took both changes'
want "$(has "$W/Bystander/Renamed.md" '- [a chat](../.sources/chats/note.md)')" yes \
	'the citation was rebased back up'

# --- names of regex metacharacters ---------------------------------------------------
mv_page 'Sub/A.B+C.md' D >/dev/null
want "$(has "$L" 'meta [[D]]')"          yes 'a name of regex metacharacters matches literally'
want "$(has "$L" 'metadecoy [[AxBC]]')"  yes 'and does not match what it would as a regex'

# --- refusals -------------------------------------------------------------------------
rc=0; mv_page Sub/Twin.md Untwinned >/dev/null 2>&1 || rc=$?
want "$rc" 2 'renaming one of two pages sharing a name is refused'
rc=0; mv_page Sub/Twin.md 'Sub/Cluster/' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'and so is moving it, which retargets a bare link just as silently'
want "$(there "$W/Sub/Twin.md")" yes 'a refused move changed nothing'
rc=0; mv_page Bystander/Renamed.md 'Old timer' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a name already used by another page is refused'
rc=0; mv_page Bystander/Renamed.md 'old TIMER' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'and so is that name in another letter case'
rc=0; mv_page Sub/Lone.md Alone >/dev/null 2>&1 || rc=$?
want "$rc" 0 'a name only a file in a nested dotfolder shares is no twin'
rc=0; mv_page Bystander/Renamed.md 'Nowhere/' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a destination subject that does not exist is refused'
rc=0; mv_page Bystander/Renamed.md 'Bystander/Renamed' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'moving a page to where it already is is refused'
rc=0; err=$(mv_page ../outside.md X 2>&1) || rc=$?
want "$rc" 2 'a file outside the wiki is refused'
want "$(printf '%s\n' "$err" | grep -c 'not under the wiki')" 1 'and says so'
rc=0; mv_page Bystander/Renamed.md '../' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a destination outside the wiki is refused'
rc=0; mv_page "$W/Bystander/Renamed.md" X >/dev/null 2>&1 || rc=$?
want "$rc" 2 'an absolute page path is refused'
rc=0; (cd "$W/Bystander" && sh "$bin/move-page.sh" "$W" Renamed.md X) >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a page path is read from the wiki root, never from the working directory'
want "$(there "$W/Bystander/Renamed.md")" yes 'and nothing moved'
rc=0; sh "$bin/move-page.sh" Bystander/Renamed.md X >/dev/null 2>&1 || rc=$?
want "$rc" 2 'no wiki root is a usage error'
rc=0; sh "$bin/move-page.sh" "$tmp/nowhere" Bystander/Renamed.md X >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a wiki root that is no directory is refused'
rc=0; mv_page Bystander/Renamed.md 'import/' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a destination folder with no .subject.md is refused'
rc=0; err=$(mv_page Bystander/Renamed.md './' 2>&1) || rc=$?
want "$rc" 2 'and so is the wiki root'
want "$(printf '%s\n' "$err" | grep -c 'not in a subject')" 1 'and says so'
want "$(there "$W/Bystander/Renamed.md")" yes 'and nothing moved'
rc=0; mv_page import/Loose.md 'Sub/' >/dev/null 2>&1 || rc=$?
want "$rc" 0 'a page from outside any subject moves into one'
want "$(there "$W/Sub/Loose.md")" yes 'and lands there'

# A sidecar whose target is taken is refused before anything moves, the page included.
printf -- '---\ntype: concept\npitch: a clash\n---\n\n# Clash\n\n[s](clash--a.html)\n' > "$W/Sub/Clash.md"
printf 'mine\n' > "$W/Sub/clash--a.html"
printf 'squatter\n' > "$W/Sub/Cluster/clash--a.html"
git -C "$W" add -A && git -C "$W" commit -qm clash
rc=0; mv_page Sub/Clash.md 'Sub/Cluster/' >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a sidecar whose target is taken is refused'
want "$(there "$W/Sub/Clash.md")" yes 'and the page did not move'
want "$(there "$W/Sub/clash--a.html")" yes 'nor its sidecar'

# --- a page written this session and not yet committed --------------------------------
printf -- '---\ntype: concept\npitch: not committed\n---\n\n# Fresh\n\n[s](fresh--a.html)\n' > "$W/Sub/Fresh.md"
printf 'fresh\n' > "$W/Sub/fresh--a.html"
printf 'see [[Fresh]]\n' >> "$L"
rc=0; mv_page Sub/Fresh.md 'Bystander/Newer' >/dev/null 2>&1 || rc=$?
want "$rc" 0 'an untracked page moves'
want "$(there "$W/Bystander/Newer.md")" yes 'and lands there'
want "$(there "$W/Bystander/newer--a.html")" yes 'with its untracked sidecar'
want "$(has "$W/Bystander/Newer.md" '[s](newer--a.html)')" yes 'its link following the sidecar'
want "$(has "$L" 'see [[Newer]]')" yes 'and its inbound links rewritten'

# --- a merge: links repointed at the kept page, nothing moved -------------------------
printf -- '---\ntype: concept\npitch: merged away\n---\n\n# Gone\n' > "$W/Sub/Gone.md"
printf -- '---\ntype: concept\npitch: kept\n---\n\n# Kept\n' > "$W/Bystander/Kept.md"
M="$W/Sub/Merge links.md"
printf 'bare [[Gone]]\nescaped [[Gone\\|shown]]\nqualified [[Sub/Gone#Part]]\ndecoy [[Gone away]]\n' > "$M"
out=$(mv_page --merge Sub/Gone.md Bystander/Kept.md)
want "$(has "$M" 'bare [[Kept]]')"                     yes 'a merge repoints a bare link at the kept page'
want "$(has "$M" 'escaped [[Kept\|shown]]')"           yes 'and keeps an escaped alias'
want "$(has "$M" 'qualified [[Bystander/Kept#Part]]')" yes "a qualified link takes the kept page's folder"
want "$(has "$M" 'decoy [[Gone away]]')"               yes 'a longer name is untouched'
want "$(there "$W/Sub/Gone.md")" yes 'a merge moves and deletes nothing'
want "$(printf '%s\n' "$out" | grep -cxF 'Sub/Merge links.md')" 1 'the rewritten page is reported'
rc=0; mv_page --merge Sub/Gone.md Bystander/Absent.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a merge into a page that does not exist is refused'
rc=0; mv_page --merge Sub/Gone.md Sub/Gone.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a merge into itself is refused'
rc=0; mv_page --merge Sub/Gone.md Sub/Twin.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 "a merge into a page whose name another shares is refused"
rc=0; mv_page --merge Sub/Twin.md Bystander/Kept.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 'and so is merging away a page whose name another shares'
rc=0; mv_page --merge Sub/Gone.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 'a merge with one path is a usage error'

# --- --links: what a deletion would leave behind, nothing changed ---------------------
printf -- '---\ntype: concept\npitch: leaving\n---\n\n# Leaving\n\nself [[Leaving]]\n' > "$W/Sub/Leaving.md"
printf '<p>a chart</p>\n' > "$W/Sub/leaving--chart.html"
printf 'bare [[leaving#Part]]\n' > "$W/Sub/Links bare.md"
printf 'qualified [[Sub/Leaving\\|shown]]\n' > "$W/Bystander/Links qualified.md"
printf 'decoy [[Leaving soon]] and Leaving as a word\n' > "$W/Bystander/Links decoy.md"
before=$(cat "$W/Sub/Links bare.md" "$W/Bystander/Links qualified.md")
out=$(mv_page --links Sub/Leaving.md)
want "$(printf '%s\n' "$out" | sort)" "$(printf '%s\n' 'Bystander/Links qualified.md' 'Sub/Links bare.md' | sed 's/^/link: /'; echo 'sidecar: Sub/leaving--chart.html')" \
	'--links lists each linking page in any form and the sidecar, not the page itself or a decoy'
want "$(cat "$W/Sub/Links bare.md" "$W/Bystander/Links qualified.md") $(there "$W/Sub/Leaving.md")" "$before yes" 'and changes nothing'
want "$(mv_page --links Sub/Twin.md | grep -c '^twin: Bystander/Twin.md$')" 1 'a page sharing the name is listed as a twin'
rc=0; mv_page --links Sub/Absent.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 '--links on a page that does not exist is refused'
rc=0; mv_page --links .sources/chats/record.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 '--links on a file in a dotfolder is refused: a source is no page'

# --- a regenerator that lost its exec bit (`F22.1`) -------------------------------------
# On copies of both scripts, never on the program's own files.
mkdir "$tmp/bin"
cp "$bin/move-page.sh" "$bin/regen-views.sh" "$tmp/bin/"
chmod -x "$tmp/bin/regen-views.sh"
rc=0; sh "$tmp/bin/move-page.sh" "$W" Sub/D.md 'Bystander/' >/dev/null 2>&1 || rc=$?
want "$rc" 0 'a move still regenerates when the regenerator has no exec bit'
want "$(has "$W/Bystander/Index.md" '| [[D]] | A.B+C |')" yes 'and the destination index lists the page'

# An accented name's sidecar takes the contract's slug under a language locale too (F19.4);
# where en_US.UTF-8 isn't installed sed falls back to C and this passes regardless.
printf -- '---\ntype: concept\npitch: accented\n---\n\n# Brûlée\n' > "$W/Sub/Brûlée.md"
printf 'anim\n' > "$W/Sub/br-l-e--anim.html"
LC_ALL=en_US.UTF-8 mv_page Sub/Brûlée.md Custard >/dev/null 2>&1
want "$(there "$W/Sub/custard--anim.html")" yes "an accented page's sidecar follows a rename"

# The shared awkward wiki (fixture-awkward-wiki.sh): a rename of each awkward name
# rewrites the hub's link to it, a CRLF page keeps its line endings, and a move between
# subjects carries a page with no trailing newline.
A=$tmp/awkward
mkdir -p "$A"
sh "$bin/fixture-awkward-wiki.sh" "$A" >/dev/null
git -C "$A" init -q
hub="$A/Cooking/Kitchen hub.md"
inside() { if grep -qF -- "$2" "$1"; then echo yes; else echo no; fi; }
# An accented name is left out of the loop below.
for pair in 'Cooking/-Mise en place.md|Mise en place' "Cooking/Chef's knife.md|Chef's blade" \
	'Cooking/Salt + pepper.md|Salt and pepper' "Chess/Queen's gambit (declined).md|Queen's gambit" \
	'Cooking/Sauce base.md|Roux'; do
	from=${pair%%|*} to=${pair#*|}
	rc=0; sh "$bin/move-page.sh" "$A" "$from" "$to" >/dev/null 2>&1 || rc=$?
	old=${from#*/}; old=${old%.md}
	want "$rc $(inside "$hub" "[[$to]]") $(inside "$hub" "[[$old]]")" '0 yes no' "renaming $old rewrites the hub's link"
done
cr=$(printf '\r')
want "$(grep -c "$cr\$" "$A/Cooking/Roux.md")" "$(grep -c '' "$A/Cooking/Roux.md")" 'a renamed CRLF page keeps every CRLF'
rc=0; sh "$bin/move-page.sh" "$A" 'Cooking/Knife skills.md' 'Chess/' >/dev/null 2>&1 || rc=$?
want "$rc $(tail -n 1 "$A/Chess/Knife skills.md")" '0 Body.' 'a page with no trailing newline moves whole'
want "$(inside "$hub" '[[Knife skills|knives]]')" yes 'and its aliased link still resolves bare'
want "$(inside "$hub" '[[salt + pepper]]') $(inside "$hub" "[[Chef's blade.md]]")" 'no yes' \
	'a case-variant link and a .md link follow a rename'
rc=0; sh "$bin/move-page.sh" "$A" Cooking/Opening.md Wine >/dev/null 2>&1 || rc=$?
want "$rc $(there "$A/Cooking/Opening.md")" '2 yes' 'renaming one of a case-only twin is refused'
rc=0; sh "$bin/move-page.sh" "$A" Cooking/Opening.md Chess/ >/dev/null 2>&1 || rc=$?
want "$rc" 2 'and so is moving it'
rc=0; sh "$bin/move-page.sh" "$A" --merge Pâtisserie/Choux.md Cooking/Opening.md >/dev/null 2>&1 || rc=$?
want "$rc" 2 'and so is merging into it'

# A failure after the first move is not a refusal. A held index lock fails the tracked
# sidecar's git mv after the untracked page has moved by plain mv.
L=$tmp/locked
mkdir -p "$L/Sub"
git -C "$L" init -q
printf -- '---\nrole: instruction\npitch: a subject\n---\n' > "$L/Sub/.subject.md"
printf -- '---\ntype: concept\npitch: a sauce\n---\n\n# Roux\n' > "$L/Sub/Roux.md"
printf '<p>a chart</p>\n' > "$L/Sub/roux--chart.html"
git -C "$L" add Sub/roux--chart.html
: > "$L/.git/index.lock"
rc=0; out=$(sh "$bin/move-page.sh" "$L" Sub/Roux.md Sauce 2>&1) || rc=$?
want "$rc $(there "$L/Sub/Sauce.md")" '1 yes' 'a failure after the page moved exits 1, since something changed'
want "$(printf '%s\n' "$out" | grep -c 'failed partway')" 1 'and says the printed lines are what changed'

exit $fail
