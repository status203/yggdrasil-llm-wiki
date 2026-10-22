#!/bin/sh
# segments.tsv in, timestamped paragraphs out, on stdout.
#
# Every producing path reaches segments.tsv -- a caption track through srt-to-segments.awk, an
# engine adapter directly -- so this is the one renderer, and the only place the paragraph rule
# lives. What it does and why the constant is 600 is in segments-to-markdown.awk.
#
# It exits 0 having written nothing when the input holds no segment, which is why its caller
# renders to a file and tests the file's size rather than reading the exit status: a bare
# append would leave a transcript holding frontmatter and no body.
#
# Nothing here reads the rendered body. A transcript passed through a model's context can be silently
# paraphrased, truncated or dropped, against a source nobody re-reads, and a long recording
# then sits in that context for the rest of the session. A size test is not a read.
#
# Usage: segments-to-markdown.sh <segments.tsv>
#
# Cost: not timed — one transcript per run, nothing that grows, and transcription is the wait.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

[ $# -eq 1 ] || { echo "usage: segments-to-markdown.sh <segments.tsv>" >&2; exit 2; }
[ -f "$1" ] || { echo "segments-to-markdown.sh: no such file: $1" >&2; exit 2; }

exec env LC_ALL=C awk -v BUDGET=600 -f "$here/segments-to-markdown.awk" -- "$1"
