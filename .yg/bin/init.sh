#!/bin/sh
# Set up a folder as an Yggdrasil wiki. The bootstrap: plain sh, because the plugin that
# carries /yggdrasil:init loads only once a wiki enables it, which is what this sets up,
# on a machine install.sh has registered the program on. The conversation that follows,
# subjects and remote advice, is /yggdrasil:init in the wiki's first session (`D12.1`).
#
# Everything it writes is inside the wiki folder (`D3.2`): a file only where it is missing,
# and to one already there only the lines it lacks, so a re-run, or a run over a folder
# that already holds pages, keeps what is there.
#
# Usage:
#   init.sh FOLDER                   interactive: check, ask, wire, next steps
#   init.sh check FOLDER             "key: value" lines, below
#   init.sh wire FOLDER [--nested] [--populated-ok]   the direct form, which the interactive
#                                    one runs after its checks; it skips the marketplace check,
#                                    since what it writes is right either way and install.sh
#                                    can come after
#   init.sh origin FOLDER URL        add the user's own remote, refusing a URL carrying a credential
#
# check prints, in order (git: missing alone if git is):
#   git: present|missing
#   identity: set|unset           user.name and user.email as the folder sees them
#   repo: none|here|enclosing <root>
#   folder: missing|fresh|populated <n>    n files outside dot-paths
#   wired: yes|no                 the wiki layer carries wiki.format
#   vault: self|none|<path>       the nearest folder holding .obsidian/, as wiki-boundary.sh
#                                 finds it; self when that is the folder itself
#   marketplace: none|this|other <path>|unavailable    as install.sh check reports it
#
# Exit: 0 done; 2 refused or usage, with one "init: <reason>" line on stderr.
#
# Cost: not timed — run once per wiki by hand; the one walk is the populated count.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROG=$(CDPATH= cd -P -- "$HERE/../.." && pwd)
FORMAT=$(sed -n 's/^program\.wiki_format:[[:space:]]*//p' "$PROG/.yg/default/config.conf")

refuse() { echo "init: $1" >&2; exit 2; }

SIGNPOST='This folder is an Yggdrasil wiki: pages a person edits in Obsidian, maintained alongside them by the Yggdrasil program, a Claude Code plugin. When the program is loaded, a line marked `Yggdrasil:` is in context. If it isn'"'"'t, the program is not installed or not enabled on this machine: tell the user before reading or changing any page, and leave it to them whether to go on without it.'

# The folder's canonical path, or the path as given when it doesn't exist yet.
canon() { (CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || printf '%s\n' "$1"; }

# The nearest existing folder at or above $1, for git to look from.
existing() { d=$1; while [ ! -d "$d" ]; do d=$(dirname -- "$d"); done; printf '%s\n' "$d"; }

# Git finds a repository by walking upward (`F22.5`), so a folder inside another
# repository reports that one's root: `enclosing`.
repo_state() {
  top=$(git -C "$(existing "$F")" rev-parse --show-toplevel 2>/dev/null) || { echo none; return; }
  top=$(canon "$top")
  if [ "$top" = "$F" ]; then echo here; else echo "enclosing $top"; fi
}

identity() {
  at=$(existing "$F")
  if [ -n "$(git -C "$at" config user.name 2>/dev/null)" ] && [ -n "$(git -C "$at" config user.email 2>/dev/null)" ]
  then echo set; else echo unset; fi
}

folder_state() {
  [ -d "$F" ] || { echo missing; return; }
  n=$(find "$F/." \( -name '.*' ! -name . \) -prune -o -type f -print | wc -l | tr -d ' ')
  if [ "$n" -eq 0 ]; then echo fresh; else echo "populated $n"; fi
}

wired() {
  if [ -f "$F/.yg/config.conf" ] && grep -q '^wiki\.format:' "$F/.yg/config.conf"; then echo yes; else echo no; fi
}

# The same walk as .yg/hooks/wiki-boundary.sh, which is what fences the session.
vault() {
  d=$F
  while [ ! -d "$d/.obsidian" ]; do [ "$d" = / ] && { echo none; return; }; d=$(dirname -- "$d"); done
  if [ "$d" = "$F" ]; then echo self; else echo "$d"; fi
}

marketplace() { sh "$HERE/install.sh" check | sed -n 's/^marketplace: //p'; }

check() {
  if ! command -v git >/dev/null 2>&1; then echo "git: missing"; return; fi
  echo "git: present"
  echo "identity: $(identity)"
  echo "repo: $(repo_state)"
  echo "folder: $(folder_state)"
  echo "wired: $(wired)"
  echo "vault: $(vault)"
  echo "marketplace: $(marketplace)"
}

# Append each line of stdin to file $1 that it doesn't already hold, whole-line.
ensure_lines() {
  mkdir -p "$(dirname -- "$1")"
  while IFS= read -r line; do
    if [ -f "$1" ] && grep -qxF -- "$line" "$1"; then continue; fi
    printf '%s\n' "$line" >> "$1"
  done
}

# Write stdin to file $1 only if it is missing.
ensure_file() {
  if [ -e "$1" ]; then cat >/dev/null; return 0; fi
  mkdir -p "$(dirname -- "$1")"; cat > "$1"
}

wire() {
  nested=0; populated_ok=0
  for a in "$@"; do
    case $a in --nested) nested=1 ;; --populated-ok) populated_ok=1 ;; *) refuse "unknown option $a" ;; esac
  done
  command -v git >/dev/null 2>&1 || refuse "git is not installed"
  [ "$(identity)" = set ] || refuse "git has no user.name and user.email; set them, then re-run"
  case $(repo_state) in
    enclosing*) [ "$nested" = 1 ] || refuse "$F sits inside the repository at $(repo_state | cut -d' ' -f2-); re-run with --nested to give the wiki its own repository inside it" ;;
  esac
  case $(folder_state) in
    populated*) [ "$populated_ok" = 1 ] || [ "$(wired)" = yes ] || refuse "$F already holds $(folder_state | cut -d' ' -f2) files; re-run with --populated-ok to keep them and wire around them" ;;
  esac

  mkdir -p "$F"
  [ "$(repo_state)" = here ] || git -C "$F" init -q
  cd "$F"

  # Every top-level dot folder but the three the program uses, so Obsidian's config folder is
  # ignored whole whatever it is called: community plugins keep their data, tokens included,
  # inside it, and a vault can rename it (`F13.2`).
  ensure_lines .gitignore <<'EOF'
/.*/
!/.yg/
!/.claude/
!/.sources/
/.yg/resolved/
/import/*
!/import/.gitkeep
/.claude/worktrees/
/.claude/settings.local.json
EOF
  printf '* text=auto eol=lf\n' | ensure_lines .gitattributes

  # Path-free: the machine's marketplace registration names the folder (`F8.1`).
  if [ -f .claude/settings.json ] && ! grep -q '"yggdrasil@yggdrasil"' .claude/settings.json; then
    echo "note: .claude/settings.json exists without the plugin; add \"yggdrasil@yggdrasil\": true under \"enabledPlugins\" by hand"
  fi
  ensure_file .claude/settings.json <<'EOF'
{
  "enabledPlugins": { "yggdrasil@yggdrasil": true }
}
EOF

  # The sign-post, for a machine without the program, where the settings line above is
  # skipped without a word (`F8.2`). The rules themselves come from the plugin's hooks.
  if ! { [ -f .claude/CLAUDE.md ] && grep -qF 'marked `Yggdrasil:`' .claude/CLAUDE.md; }; then
    { [ -s .claude/CLAUDE.md ] && echo; printf '%s\n' "$SIGNPOST"; } >> .claude/CLAUDE.md
  fi

  if [ "$(wired)" = no ]; then
    [ -f .yg/config.conf ] || printf '# This wiki'"'"'s config layer, over the program'"'"'s defaults and the user layer.\n' | ensure_lines .yg/config.conf
    printf 'wiki.format: %s\n' "$FORMAT" | ensure_lines .yg/config.conf
    grep -q '^wiki\.visibility:' .yg/config.conf || printf 'wiki.visibility: private\n' | ensure_lines .yg/config.conf
  fi

  ensure_file Misc/.subject.md <<'EOF'
---
role: instruction
note: Holds whatever this subject does differently from default. User-editable, directly or via Odin; every subject needs one, so don't remove it.
pitch: Items that don't yet belong to a subject of their own.
---

# Misc (subject) context

<!--
Fields or sections that every page of one type here starts with go in a template, `.templates/<type>.md` in this folder, not in this file. This file holds what belongs in the subject, how new material joins its pages, guidance every later edit of a section needs, and any shape that varies from page to page.
-->
EOF
  : | ensure_file import/.gitkeep

  sh "$PROG/.yg/bin/regen-views.sh" "$F" all >/dev/null

  # A first commit takes the whole folder; a later one only the paths init writes, so
  # the user's own uncommitted work stays theirs.
  if ! git rev-parse -q --verify HEAD >/dev/null; then
    git add -A && git commit -q -m "Init: wiki" && echo "committed the wiki as its first commit"
  else
    set -- .gitignore .gitattributes .claude/settings.json .claude/CLAUDE.md .yg/config.conf \
      Misc/.subject.md import/.gitkeep Index.md Progressions.md ':(glob)**/Index.md'
    git add -- "$@"
    if git diff --cached --quiet -- "$@"; then echo "nothing to change"
    else git commit -q -m "Init: wiki" -- "$@" && echo "committed what init wrote"; fi
  fi
  echo wired
}

# origin — the user's own remote. A URL carrying a credential would land in .git/config in
# the clear, so the script refuses it on its own (`D22.1`, `D12.1.9`); a refusal never prints the
# URL, and what is added is printed redacted.
redact() { printf '%s\n' "$1" | sed 's#^\([A-Za-z][A-Za-z0-9+.-]*://\)[^/@]*@#\1***@#'; }

# carries_credential <url> — any URL with a query string, which a remote never needs and a
# token can ride in; an http(s) URL with any userinfo (a token alone is one), or any scheme
# URL with a password. scp-style user@host:path names an account, not a secret.
carries_credential() {
  case $1 in *\?*) return 0 ;; esac
  case $1 in *://*) ;; *) return 1 ;; esac
  auth=${1#*://}
  auth=${auth%%/*}
  case $auth in *@*) ;; *) return 1 ;; esac
  case ${1%%://*} in http | https) return 0 ;; esac
  case ${auth%@*} in *:*) return 0 ;; esac
  return 1
}

origin() {
  [ $# -eq 1 ] && [ -n "$1" ] || refuse "usage: init.sh origin FOLDER URL"
  [ -e "$F/.git" ] || refuse "no repository at $F; run sh $PROG/.yg/bin/init.sh $F first"
  carries_credential "$1" && refuse "that URL carries a credential, so it was not added; use an SSH address or a credential helper"
  git -C "$F" remote get-url origin >/dev/null 2>&1 && refuse "origin already exists"
  git -C "$F" remote add origin "$1"
  echo "added origin: $(redact "$1")"
}

ask() { printf '%s ' "$1" >&2; read -r reply || reply=; printf '%s\n' "$reply"; }

interactive() {
  state=$(check); printf '%s\n\n' "$state"
  val() { printf '%s\n' "$state" | sed -n "s/^$1: //p"; }
  [ "$(val git)" = present ] || refuse "install git, then re-run"
  [ "$(val identity)" = set ] || refuse "set git's identity first: git config --global user.name \"Your Name\" and git config --global user.email you@example.com"
  case $(val marketplace) in
    this) ;;
    *) refuse "the program is not installed on this machine; run sh $PROG/.yg/bin/install.sh first" ;;
  esac
  opts=
  case $(val repo) in
    enclosing*)
      echo "This folder sits inside the git repository at $(val repo | cut -d' ' -f2-)."
      echo "The wiki can stand alone (move the folder outside that repository and re-run), or have"
      echo "its own repository nested inside it. Nested, the outer repository sees the folder as an"
      echo "embedded repository: its own commits stop covering the wiki's files unless you add the"
      echo "folder to its .gitignore, which this never does for you."
      case $(ask "Stop here to move it [s], or nest the wiki's repository [n]? [S/n]") in n|N) opts="$opts --nested" ;; *) exit 0 ;; esac ;;
  esac
  case $(val folder) in
    populated*) [ "$(val wired)" = yes ] || case $(ask "The folder already holds $(val folder | cut -d' ' -f2) files. Keep them all and set the wiki up around them? [y/N]") in
      y|Y) opts="$opts --populated-ok" ;; *) exit 0 ;; esac ;;
  esac
  # shellcheck disable=SC2086
  wire $opts
  echo
  echo "Next: run claude in"
  echo "  $F"
  echo "then /yggdrasil:init to choose the wiki's subjects."
  echo
  echo "A launcher, for bash; Claude can adapt it for another shell:"
  echo "  alias yg='cd \"$F\" && claude'    # named as you like, for your shell's startup file"
}

cmd=${1:-}
case $cmd in
  check|wire|origin) shift ;;
  '') refuse "usage: init.sh FOLDER | check FOLDER | wire FOLDER [--nested] [--populated-ok] | origin FOLDER URL" ;;
  *) cmd=interactive ;;
esac
[ -n "${1:-}" ] || refuse "no folder given"
F=$(canon "$1"); shift
case $F in /*) ;; *) F="$(pwd)/$F" ;; esac

case $cmd in
  check) check ;;
  wire) wire "$@" ;;
  origin) origin "$@" ;;
  interactive) interactive ;;
esac
