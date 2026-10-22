#!/bin/sh
# Build a small wiki of awkward page shapes, for the tests of every script that reads pages.
# A shape was previously observed found in one page reader at a time — a CRLF page in one,
# an accented name in another — and tested only where it was found; built here once, each
# shape reaches every reader's test, and a shape found later is added here.
#
# Covered by test-check-vault.sh, test-move-page.sh, test-regen-views.sh and
# test-staleness.sh, which build their awkward wiki with it.
#
# Usage: fixture-awkward-wiki.sh DIR
#   Writes two subjects into DIR, an existing folder, and prints each page it wrote,
#   wiki-relative, one per line. Writes no config and runs no git: each test adds what its
#   script needs.
# Exit: 0 written; 2 usage, or DIR not a folder.
#
# Every page is valid frontmatter with `type: concept`, `volatility: low` and a checkpoint,
# so a row about one is the shape's doing, not the fixture's. The shapes:
#   Cooking/Crème brûlée.md       letters outside ASCII
#   Cooking/Knife skills.md       a space, and no trailing newline
#   Cooking/Sauce base.md         CRLF line endings
#   Cooking/-Mise en place.md     a leading dash, which a command reads as a flag
#   Cooking/Chef's knife.md       an apostrophe, which a quoted shell string ends on
#   Cooking/Salt + pepper.md      a regex operator
#   Cooking/Opening.md            a case-only twin of Chess/opening.md
#   Cooking/.templates/Recipe.md  a template in a dotfolder inside a subject, no page
#   Chess/Queen's gambit (declined).md   regex groups and an apostrophe
#   Chess/opening.md              the twin
#   Pâtisserie/Choux.md           a subject folder whose name is outside ASCII
#   Cooking/Kitchen hub.md        links every page above, in each form a link takes
#
# Cost: not timed; a test fixture, run by no wiki.

set -eu

{ [ $# -eq 1 ] && [ -d "$1" ]; } || { echo 'fixture-awkward-wiki: usage: fixture-awkward-wiki.sh DIR' >&2; exit 2; }
W=$1

subject() { mkdir -p "$W/$1"; printf -- '---\nrole: instruction\npitch: The %s subject.\n---\n' "$1" >"$W/$1/.subject.md"; }
# page <path> <pitch> [body]: frontmatter every page reader accepts, then the body.
page() {
	mkdir -p "$(dirname "$W/$1")"
	printf -- '---\ntype: concept\npitch: %s\nvolatility: low\ncheckpoint: 2026-01-01\n---\n\n%s\n' "$2" "${3:-Body.}" >"$W/$1"
	printf '%s\n' "$1"
}

subject Cooking
subject Chess
subject Pâtisserie

page 'Cooking/Crème brûlée.md' 'A custard with a burnt sugar top.'
page 'Cooking/Knife skills.md' 'How to hold and use a knife.' >/dev/null
printf -- '---\ntype: concept\npitch: How to hold and use a knife.\nvolatility: low\ncheckpoint: 2026-01-01\n---\n\nBody.' >"$W/Cooking/Knife skills.md"
printf '%s\n' 'Cooking/Knife skills.md'
page 'Cooking/Sauce base.md' 'A roux and what it thickens.' >/dev/null
awk '{ printf "%s\r\n", $0 }' "$W/Cooking/Sauce base.md" >"$W/crlf.tmp" && mv "$W/crlf.tmp" "$W/Cooking/Sauce base.md"
printf '%s\n' 'Cooking/Sauce base.md'
page 'Cooking/-Mise en place.md' 'Everything in its place before the heat.'
page "Cooking/Chef's knife.md" 'The one knife that does most of the work.'
page 'Cooking/Salt + pepper.md' 'Seasoning, and when to add it.'
page 'Cooking/Opening.md' 'Opening a bottle of wine.'
page "Chess/Queen's gambit (declined).md" 'Black declines the pawn.'
page 'Chess/opening.md' 'The first moves of a game.'
page 'Pâtisserie/Choux.md' 'A paste that puffs hollow.'
page 'Cooking/Kitchen hub.md' 'Where the kitchen pages meet.' "Bare: [[Crème brûlée]], [[Sauce base]], [[-Mise en place]], [[Chef's knife]], [[Salt + pepper]], [[Queen's gambit (declined)]], [[Choux]].

Aliased: [[Knife skills|knives]].

Another letter case, and the extension: [[salt + pepper]], [[Chef's knife.md]].

Qualified, since the name has a case-only twin: [[Cooking/Opening]] and [[Chess/opening]]."
mkdir -p "$W/Cooking/.templates"
printf -- '---\ntype: concept\npitch: \nvolatility: low\n---\n\nSee [[Kitchen hub]].\n' >"$W/Cooking/.templates/Recipe.md"
