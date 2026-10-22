#!/bin/sh
# Resolve a wiki's config into <wiki>/.yg/resolved/config.conf, and decide the session kind.
# Runs at SessionStart. POSIX sh + awk only — no Python, no extra dependencies
# (sh and awk are base-system utilities on Linux, macOS, and WSL).
#
# Portability (`F18.2`): no POSIX character classes in awk — use the explicit
# `[ \t]` set. The awk that constrains this program is the one-true-awk macOS
# ships, which predates them; "does mawk have it?" is not the test.
#
# Three source layers, per-key merged, each overriding the one before (`D13.1`):
#   default  .yg/default/config.conf in the program this script belongs to
#   user     ${XDG_CONFIG_HOME:-~/.config}/yggdrasil/config.conf, outside every repo
#   wiki     <wiki>/.yg/config.conf
# A missing user or wiki layer counts as no overrides.
#
# The session kind is derived, never read from a layer: `forge` when the wiki root is
# the program root this script lives in, `wiki` otherwise; a directory-marketplace install
# runs hooks from that folder, not a cache copy, so this holds (`F8.7`). The wiki root is
# CLAUDE_PROJECT_DIR, which under `claude -w` names the new worktree, so a forge worktree
# started that way reads as `wiki`; one entered mid-session keeps the launch folder (`F7.2`).
# It is written as the resolved file's last key, `session.kind`, and printed on stdout first, which a
# SessionStart hook's stdout puts into the main session's context (`F4.1.2`). The same line
# gives the program root, which instructions read at runtime name paths against:
# `${CLAUDE_PLUGIN_ROOT}` expands only in skill and agent definitions (`F7.4`, `F7.4.1`).
#
# Writes are atomic and last-good-retaining: config resolves into a same-filesystem
# temp file and is renamed onto the canonical path only on awk success AND non-empty
# output. On any failure the previous resolved output is kept and one warning line is
# printed to stdout. Readers trust the resolved file as an invariant — they do NOT fall
# back to the default layer.
#
# Config is flat 'key: value' lines. A line whose first non-blank character is '#' is a
# comment; comments and blank lines are NOT carried into the resolved output (it is a
# build artifact). Every other line is a 'key: value' pair with the VALUE TAKEN
# LITERALLY — it may contain '#', spaces, and colons after the first; there are no
# inline comments and no escaping. Per-key meaning is in the comment above a key in the
# default layer where it has one.
#
# Usage: resolve-config.sh WIKI_ROOT
#
# Cost: not timed — merges three config files at session start, none of which grows with use,
# and lists one folder of forge ledgers, which holds a handful.
set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
  echo "usage: resolve-config.sh WIKI_ROOT" >&2
  exit 2
fi

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROG=$(CDPATH= cd -P -- "$HERE/../.." && pwd)
if ! WIKI=$(CDPATH= cd -P -- "$1" 2>/dev/null && pwd); then
  echo "Yggdrasil: resolve-config found no wiki at $1 — nothing resolved."
  exit 0
fi

if [ "$WIKI" = "$PROG" ]; then kind=forge; else kind=wiki; fi
echo "Yggdrasil: $kind session; program root $PROG."

# A forge checkout commits past the leak check unless core.hooksPath names the program's
# hooks and the hook keeps its exec bit, which a checkout can lose (`F22.1`, `F22.2`). Said, not
# fixed: setting git config unasked is a silent write.
if [ "$kind" = forge ]; then
  case $(git -C "$PROG" config core.hooksPath 2>/dev/null || :) in
    .yg/githooks | .yg/githooks/ | "$PROG/.yg/githooks" | "$PROG/.yg/githooks/") hp=1 ;;
    *) hp= ;;
  esac
  [ -n "$hp" ] && [ -x "$PROG/.yg/githooks/pre-commit" ] ||
    echo "Yggdrasil: this checkout's pre-commit is not wired, so commits skip the leak check. Run \`git config core.hooksPath .yg/githooks\` and \`chmod +x .yg/githooks/pre-commit\`."
fi

DEF="$PROG/.yg/default/config.conf"
USR="${XDG_CONFIG_HOME:-$HOME/.config}/yggdrasil/config.conf"
WCF="$WIKI/.yg/config.conf"
OUT="$WIKI/.yg/resolved"

if [ ! -f "$DEF" ]; then
  echo "Yggdrasil: resolve-config found no default layer at $DEF — nothing resolved; the program checkout is incomplete."
  exit 0
fi

# A default layer carrying no key at all is broken, not empty-by-choice: it is tracked
# mechanism, never hand-edited (`D13.1`). Guard the INPUT, because the output-side non-empty
# test below cannot see this — the awk END block still emits override-only keys, so the
# temp is non-empty and the promote silently drops every default key.
if ! awk '
  $0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/ { next }   # comment or blank, as the merge below
  index($0, ":")                     { found = 1; exit }
  END                                { exit !found }
' "$DEF"; then
  echo "Yggdrasil: resolve-config found no keys in $DEF — the default layer looks truncated or blanked; restore it from git. Resolved config left unchanged."
  exit 0
fi

# The wiki's format against the one this program reads, each read from its own layer
# rather than from resolved config, where the default layer would fill in a wiki that
# records none.
want=$(sed -n 's/^program\.wiki_format:[[:space:]]*//p' "$DEF" | head -n 1)
have=$(sed -n 's/^wiki\.format:[[:space:]]*//p' "$WCF" 2>/dev/null | head -n 1)
case $have in
  '') echo "Yggdrasil: this wiki records no format; set it up with: sh $PROG/.yg/bin/init.sh $WIKI" ;;
  *[!0-9]*) echo "Yggdrasil: this wiki's wiki.format, '$have', is not a number; the program reads format $want." ;;
  *) if [ -z "$want" ]; then
       echo "Yggdrasil: the default layer carries no program.wiki_format; restore it from git."
     elif [ "$have" -gt "$want" ]; then
       echo "Yggdrasil: this wiki is format $have, newer than the program's $want; update the program with git pull in $PROG."
     elif [ "$have" -lt "$want" ]; then
       # Limit: no migration exists until a second format does.
       echo "Yggdrasil: this wiki is format $have and the program reads format $want; nothing migrates it yet."
     fi ;;
esac

# Keys that record this wiki's own state, and mean nothing set for every wiki. In the default
# or user layer each is dropped from that layer and named, and the resolve goes on, since
# failing it would freeze every other key at last-good. Hand-listed: membership is gated
# (`D13.1.1`).
WIKI_ONLY='wiki.format wiki.public_answered'
for f in "$DEF" "$USR"; do
  [ -f "$f" ] || continue
  for k in $WIKI_ONLY; do
    re=$(printf '%s' "$k" | sed 's/\./\\./g')
    grep -q "^[[:space:]]*$re[[:space:]]*:" "$f" &&
      echo "Yggdrasil: $k belongs only in a wiki's own .yg/config.conf, so it is ignored in $f; remove it there."
  done
done

mkdir -p "$OUT"

# Whether a prior resolved config exists governs the failure message (last-good vs cold).
had_config=0
if [ -f "$OUT/config.conf" ]; then had_config=1; fi

[ -f "$USR" ] || USR=/dev/null
[ -f "$WCF" ] || WCF=/dev/null

# Resolve into a same-filesystem temp, promote only on awk success + non-empty output.
tmp=$(mktemp "$OUT/.config.conf.XXXXXX")
if awk -v deffile="$DEF" -v wcf="$WCF" -v wikionly="$WIKI_ONLY" -v kind="$kind" '
  function trim(s)  { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  BEGIN { nw = split(wikionly, w, " "); for (i = 1; i <= nw; i++) wo[w[i]] = 1 }
  # Sets k and v from the current line; false for a comment, a blank, a line with no
  # colon, or session.kind, which is derived below and never read from a layer.
  function parse(   ci) {
    if ($0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/) return 0
    ci = index($0, ":"); if (ci == 0) return 0
    k = trim(substr($0, 1, ci - 1)); v = trim(substr($0, ci + 1))
    return k != "session.kind"
  }

  # The override layers come first, user then wiki, so a later one wins. FILENAME
  # dispatch (not NR==FNR, which misfires when a file is empty, e.g. /dev/null).
  FILENAME != deffile {
    if (parse() && (FILENAME == wcf || !(k in wo))) { if (!(k in ov)) order[++n] = k; ov[k] = v }
    next
  }

  # The default layer comes last; walk it in file order.
  parse() && !(k in wo) {
    if (k in ov) { print k ": " ov[k]; used[k] = 1 }
    else         { print k ": " v }
  }

  END {
    # override-only keys (absent from the default layer) append in the order they
    # were first seen — as plain key:value, same as everything else.
    for (i = 1; i <= n; i++) {
      k = order[i]
      if (k in used) continue
      print k ": " ov[k]
    }
    print "session.kind: " kind
  }
' "$USR" "$WCF" "$DEF" > "$tmp" && [ -s "$tmp" ]; then
  mv "$tmp" "$OUT/config.conf"
else
  rm -f "$tmp"
  if [ "$had_config" = 0 ]; then
    echo "Yggdrasil: resolve-config failed and no resolved config exists — fix .yg/hooks/resolve-config.sh before continuing."
  else
    echo "Yggdrasil: resolve-config failed; using the last-good resolved config — fix .yg/hooks/resolve-config.sh."
  fi
fi

# Going public changes what the program does with examples, ledgers and session records; the
# wiki's own wiki.public_answered marks the question answered and lists what the answer wrote
# (`D12.2`). Said every session until answered, since a wiki can go public by a hand edit (`D12.2.1`).
if [ -f "$OUT/config.conf" ]; then
  vis=$(sed -n 's/^wiki\.visibility:[[:space:]]*//p' "$OUT/config.conf" | head -n 1)
  ans=$(sed -n 's/^wiki\.public_answered:[[:space:]]*//p' "$OUT/config.conf" | head -n 1)
  if [ "$vis" = public ] && [ -z "$ans" ]; then
    echo "Yggdrasil: this wiki is public and hasn't answered what going public means for it; put the question in /yggdrasil:init § Visibility to the user."
  elif [ "$vis" != public ] && [ -n "$ans" ]; then
    echo "Yggdrasil: this wiki is private but carries what going public wrote ($ans); offer to undo it, per /yggdrasil:init § Visibility."
  fi
fi

# A forge session is told where the forge ledgers are, read from resolved config so a user
# layer can point them at a private store. Each `*.md` at the top of the folder is one;
# subfolders, such as review ledgers kept beside them, are not.
[ "$kind" = forge ] && [ -f "$OUT/config.conf" ] || exit 0
loc=$(sed -n 's/^forge\.ledger_location:[[:space:]]*//p' "$OUT/config.conf" | head -n 1)
case $loc in
  ''|none) exit 0 ;;
  '~/'*) loc="$HOME/${loc#\~/}" ;;
  /*) ;;
  *) loc="$WIKI/$loc" ;;
esac
list=
for f in "$loc"/*.md; do
  [ -f "$f" ] && list="${list:+$list, }$f"
done
if [ -n "$list" ]; then
  echo "Yggdrasil: forge ledgers, read before changing the program: $list."
else
  echo "Yggdrasil: no forge ledgers yet; they go in $loc."
fi
