#!/bin/sh
# PostToolUse (Write|Edit) companion to resolve-config.sh: re-resolve after a mid-session
# write to a config layer.
# POSIX sh + sed only — inside resolve-config.sh's dependency floor (sh + awk), but not
# under its awk-specific rule: `F18.2` constrains awk, and `field()`'s `[[:space:]]` is
# fine in sed. Checked by test-resolve-config.sh's on-write cases.
#
# Which wiki to re-resolve depends on the layer written:
#   wiki layer, a <root>/.yg/config.conf recording wiki.format, or the session's own
#     -> <root>, taken from the edited path, NOT the
#     session root: $CLAUDE_PROJECT_DIR stays on the launch folder after a mid-session
#     worktree switch (`F7.2`), so it would resolve the main checkout while a worktree
#     session edits the worktree's config, silently.
#   default or user layer -> the session root, the one argument. Both are shared by
#     every wiki and their path names none; another wiki picks the change up at its
#     next session start.
# Limit: a user layer edited through a symlink's target path rather than the
# ${XDG_CONFIG_HOME:-~/.config} path is not seen; the next session start resolves it.
# Nor is a layer changed other than by Write or Edit — a hand edit, a Bash edit — so
# what reads the resolved file holds the old value until that session start, where going
# public names any session record already committed (`D2.2`).
#
# Every Write and Edit reaches here — the hook's matcher is the tool name only (`F11.5`) —
# so the case below and the format check after it are the whole filter, and a path either
# turns away exits 0 silently.
#
# The payload shape the `field()` sed relies on — `file_path` nested in tool_input,
# `cwd` top-level, both unescaped strings reachable without a JSON parser — is `F11.6`,
# probed end-to-end. The test cannot check it: its fixtures hard-code that shape, so a
# payload drift leaves them green while this hook silently stops firing.
#
# Usage: resolve-config-on-write.sh SESSION_ROOT < payload
#
# Cost: not timed — one sed over one hook payload per Write or Edit, nothing that grows.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
session=${1:-}

in=$(cat)
field() { printf '%s' "$in" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n 1; }

f=$(field file_path)
[ -n "$f" ] || exit 0

# file_path arrives absolute (`F11.6`). The relative branch is kept anyway, as cheap
# insurance against harness drift: anchor a relative one on the session's cwd rather
# than letting the case below fall through, which would fail silently.
case "$f" in
  /*) ;;
  *) cwd=$(field cwd); [ -n "$cwd" ] || exit 0; f="$cwd/$f" ;;
esac

case "$f" in
  */.yg/config.conf) root=${f%/.yg/config.conf} ;;
  */.yg/default/config.conf|"${XDG_CONFIG_HOME:-$HOME/.config}/yggdrasil/config.conf") root=$session ;;
  *) exit 0 ;;
esac

# An empty root would be the resolver's usage error, which the harness reports as a
# hook failure on a write that succeeded.
[ -n "$root" ] || exit 0

# A wiki layer counts only where it records a format, which init.sh writes into every
# wired wiki, so a worktree's own layer counts though it is not the session root (`F7.2`):
# any other tree's .yg/config.conf is not a wiki, and resolving it would write outside the
# session's wiki. A wiki whose format line was deleted is resolved at the next session
# start, which warns about it.
[ "$root" = "$session" ] || [ "$f" != "$root/.yg/config.conf" ] || grep -q '^wiki\.format:' "$f" 2>/dev/null || exit 0

exec sh "$HERE/resolve-config.sh" "$root"
