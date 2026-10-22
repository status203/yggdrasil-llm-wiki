#!/bin/sh
# Install the program on this machine: check what it needs, then register this checkout with
# Claude Code as a plugin marketplace at user level, so any wiki whose settings enable the
# plugin loads it from here (`F8.1`). Once per machine, outside any session; updating is
# `git pull` in this checkout, and a wiki is then set up with init.sh (`D12.1`).
#
# Usage:
#   install.sh          check, register, and print the forge suggestions
#   install.sh check    "key: value" lines, below
#
# check prints, in order (git: missing alone if git is):
#   git: present|missing
#   identity: set|unset           user.name and user.email outside any repository
#   awk: present|missing
#   marketplace: none|this|other <path>|unavailable    at user level; unavailable: no claude CLI
#
# Exit: 0 done; 2 refused or usage, with one "install: <reason>" line on stderr.
#
# Cost: not timed — run once per machine by hand.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROG=$(CDPATH= cd -P -- "$HERE/../.." && pwd)

refuse() { echo "install: $1" >&2; exit 2; }

canon() { (CDPATH= cd -P -- "$1" 2>/dev/null && pwd) || printf '%s\n' "$1"; }

# The repository a checkout belongs to, the same for each of its worktrees.
commondir() { (CDPATH= cd -P -- "$1" 2>/dev/null && d=$(git rev-parse --git-common-dir 2>/dev/null) && CDPATH= cd -P -- "$d" && pwd); }

# From /, so neither a repository's identity nor a project's own registration answers.
identity() {
  if [ -n "$(cd / && git config user.name 2>/dev/null)" ] && [ -n "$(cd / && git config user.email 2>/dev/null)" ]
  then echo set; else echo unset; fi
}

# Where the user-level registry says the `yggdrasil` marketplace lives (`F8.1`).
marketplace() {
  command -v claude >/dev/null 2>&1 || { echo unavailable; return; }
  at=$(cd / && claude plugin marketplace list --json 2>/dev/null | tr ',{}' '\n\n\n' | awk '
    function val(s) { sub(/^[^:]*:[ \t]*"/, "", s); sub(/".*/, "", s); return s }
    /^[ \t]*"name"[ \t]*:/            { cur = val($0) }
    /^[ \t]*"installLocation"[ \t]*:/ { if (cur == "yggdrasil") { print val($0); exit } }')
  if [ -z "$at" ]; then echo none
  elif [ "$(canon "$at")" = "$PROG" ]; then echo this
  else echo "other $at"; fi
}

check() {
  if ! command -v git >/dev/null 2>&1; then echo "git: missing"; return; fi
  echo "git: present"
  echo "identity: $(identity)"
  if command -v awk >/dev/null 2>&1; then echo "awk: present"; else echo "awk: missing"; fi
  echo "marketplace: $(marketplace)"
}

install() {
  state=$(check)
  val() { printf '%s\n' "$state" | sed -n "s/^$1: //p"; }
  [ "$(val git)" = present ] || refuse "install git, then re-run"
  [ "$(val identity)" = set ] || refuse "set git's identity first: git config --global user.name \"Your Name\" and git config --global user.email you@example.com"
  [ "$(val awk)" = present ] || refuse "install awk, then re-run"
  case $(val marketplace) in
    unavailable) refuse "install Claude Code, whose claude CLI loads the program, then re-run" ;;
    other*)
      at=$(val marketplace | cut -d' ' -f2-)
      if [ -n "$(commondir "$PROG")" ] && [ "$(commondir "$at")" = "$(commondir "$PROG")" ]; then
        refuse "this is a worktree of $at, which Claude Code already loads the program from: enter it from a session launched there (F7.2)"
      fi
      refuse "Claude Code already knows a marketplace named yggdrasil at $at, not this program; to use this one, run claude plugin marketplace remove yggdrasil, then re-run" ;;
    this) echo "Claude Code already knows this program at user level: nothing to register." ;;
    none)
      echo "Registering this program with Claude Code as a plugin marketplace, at user level, so any"
      echo "wiki that enables it loads it from this folder:"
      echo "  claude plugin marketplace add $PROG --scope user"
      # The scope is named, since the CLI's default can change between versions (D12.1.3).
      claude plugin marketplace add "$PROG" --scope user >/dev/null || refuse "claude could not register the program" ;;
  esac
  echo
  echo "Next, set up a wiki: sh $PROG/.yg/bin/init.sh <folder>"
  echo
  echo "To mould the system itself, work on it in a forge session, a Claude session launched here."
  echo "Two suggestions, for bash; Claude can adapt them for another shell:"
  echo "  alias ygf='cd \"$PROG\" && claude'    # a launcher, named as you like, for your shell's startup file"
  echo "  git -C \"$PROG\" config core.hooksPath .yg/githooks && chmod +x \"$PROG/.yg/githooks/pre-commit\"    # commits pass the leak check"
}

case ${1:-} in
  '') install ;;
  check) check ;;
  *) refuse "usage: install.sh | install.sh check" ;;
esac
