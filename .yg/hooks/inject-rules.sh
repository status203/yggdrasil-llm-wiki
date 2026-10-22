#!/bin/sh
# Hand the wiki rules, the program's .yg/wiki.md, to a session or a dispatch as hook context.
# Runs at SessionStart, every source, and at SubagentStart, every agent: a dispatch fires
# only the second (`F10.4`), and both carry `additionalContext` into the model's context
# (`F4.5`, `F10.1`). Only in a wired wiki, one whose own layer carries `wiki.format`, so a
# folder that merely enables the plugin gets nothing.
#
# The context opens with a `Yggdrasil:` line, which is what a wiki's sign-post CLAUDE.md
# tests for, and a dispatch sees no session-start line of its own (`F4.1.2`). It names no path:
# a dispatch that sends queries off the machine gets it too, and a home path names the user.
#
# Usage: inject-rules.sh WIKI_ROOT EVENT     EVENT: SessionStart or SubagentStart
#
# Cost: not timed — one file of the program's, which grows with the rules and not with a wiki.
set -eu

[ $# -eq 2 ] || { echo "usage: inject-rules.sh WIKI_ROOT EVENT" >&2; exit 2; }
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROG=$(CDPATH= cd -P -- "$HERE/../.." && pwd)

grep -q '^wiki\.format:' "$1/.yg/config.conf" 2>/dev/null || exit 0

{ printf 'Yggdrasil: the wiki rules follow.\n\n'; cat "$PROG/.yg/wiki.md"; } | awk -v ev="$2" '
  # Character by character: a backslash in a gsub replacement differs between awks (`F18.1.2`).
  function esc(l,   o, i, c) {
    o = ""
    for (i = 1; i <= length(l); i++) {
      c = substr(l, i, 1)
      if (c == "\\") c = "\\\\"; else if (c == "\"") c = "\\\""
      else if (c == "\t") c = "\\t"; else if (c == "\r") c = "\\r"
      o = o c
    }
    return o
  }
  { s = s (NR > 1 ? "\\n" : "") esc($0) }
  END { printf "{\"hookSpecificOutput\":{\"hookEventName\":\"%s\",\"additionalContext\":\"%s\"}}\n", ev, s }'
