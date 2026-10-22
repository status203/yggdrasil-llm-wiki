#!/bin/sh
# Refuse a value outside the technical well: an absolute or ~/ path, an email address, a
# URL host or an IP address that no entry in .yg/technical-well.txt admits. The check
# looks only for shapes, so it holds for any machine and needs no list of what to hide.
#
# The root LICENSE is skipped: it is the licence's text verbatim, which names its
# publisher's hosts, and the program never writes it.
#
# A named URL host in a folder the well lists under docs: is let through, since forge-wiki
# pages cite the web by link. --staged lists each URL it lets through, so a private
# repository or service among them is seen at commit. An IP host there is still refused,
# and so is every other shape.
#
# It guards literal values only. A private name in prose, or a motivating case from the
# conversation behind a change, has no shape to find; CLAUDE.md's privacy rules and the
# system review cover those.
#
# Usage: check-leaks.sh [--staged] ROOT
#   ROOT          a git checkout; every tracked text file but LICENSE is scanned.
#   --staged ROOT only the lines staged for commit (the pre-commit hook).
#
# Output: one "path:line: value" per refused value, on stdout; --staged also prints one
# "notice: path:line: URL ..." per URL let through, which doesn't change the exit.
# Exit: 0 clean; 1 refused values found; 2 unknown, never clean (no well, no repository,
# git or awk failed), so a check that couldn't run never passes as one that found nothing.
#
# Needs a repository for its own work, so it asks git rather than finding the root from
# where it sits; the technical well is found beside it.
#
# Cost: not timed. The pre-commit run reads only the staged lines; the tree run reads
# every tracked text file, but only in a review, which the user starts knowing it takes
# a while.
set -u

unknown() { echo "check-leaks: $1; unknown, never clean." >&2; exit 2; }

mode=tree
if [ "${1-}" = --staged ]; then mode=staged; shift; fi
if [ $# -ne 1 ] || [ -z "$1" ]; then
  echo "usage: check-leaks.sh [--staged] ROOT" >&2
  exit 2
fi

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WELL="$HERE/../technical-well.txt"
[ -f "$WELL" ] || unknown "no technical well at $WELL"
[ -f "$HERE/check-leaks.awk" ] || unknown "no scanner beside the script"
git -C "$1" rev-parse --git-dir >/dev/null 2>&1 || unknown "$1 is not a git checkout"

TMP=$(mktemp "${TMPDIR:-/tmp}/yg-leaks.XXXXXX") || unknown "no temp file"
trap 'rm -f "$TMP"' EXIT

SKIP=':(top,exclude)LICENSE'
if [ $mode = staged ]; then
  # --no-renames: a renamed file's lines arrive as added, so each is checked.
  git -C "$1" -c core.quotePath=false diff --cached -U0 --no-color --no-ext-diff \
    --no-renames -- "$SKIP" >"$TMP" || unknown "git diff failed"
else
  # Only lines that could hold a shape; git grep exits 1 when none do, which is clean.
  git -C "$1" -c core.quotePath=false grep -I -n -E '[/@~\\]|[0-9][.][0-9]' -- "$SKIP" >"$TMP"
  [ $? -le 1 ] || unknown "git grep failed"
fi

awk -v mode=$mode -v wellfile="$WELL" -f "$HERE/check-leaks.awk" "$WELL" "$TMP"
rc=$?
[ $rc -le 1 ] || unknown "the scanner failed"
exit $rc
