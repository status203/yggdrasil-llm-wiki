#!/bin/sh
# Check the program's mechanism for the drift the system review's passes should not have
# to find by reading. Reports; changes nothing. Exit 1 on any finding, 2 when it could not
# check.
#
#   check-system.sh              run every check
#   check-system.sh files SET…   list the files in the named corpus sets
#   check-system.sh worklist facts|decisions
#                                list what a review pass is handed, one item per line
#   check-system.sh added BASE   print only the rows the work since BASE added: BASE's own
#                                copy run in a throwaway worktree, line numbers dropped
#                                at both ends. Exit 1 when it added any, 2 when either
#                                end could not check, since one failure at both ends
#                                would otherwise cancel out to "added nothing".
#   check-system.sh briefs DIR   write each system review pass's brief into DIR, one
#                                brief-<short name>.md per pass, and print their paths.
#
# The mechanical half of the system review (D1.1, home 4; D16.1): what is decidable by
# enumerating the whole corpus is here, so a pass returns a judgment rather than a sample
# of these. check-vault.sh is the other side of the same line, one wiki page at a time,
# and check-leaks.sh holds the values outside the technical well.
#
# It takes no root argument and checks the checkout it sits in: the integration review
# runs a base commit's copy from a worktree, and that copy has to check the base. The full
# run asks git what it ignores, so it needs the checkout to be a repository; `files` reads
# no file and needs none.
#
# Cost: measured 2026-10-04 on this program (67 files, 77 facts) and on copies with both
# doubled, quadrupled and octupled: 1.1s, 1.6s, 2.5s, 4.5s, linear. Only reviews run it,
# the integration review twice (at its base and now), and the user starts a review knowing
# it takes a while; `files` reads no file.
# Linux, warm cache: the times are this machine's, the ratios are not.
#
# Exit 2 is unknown, never clean: a missing input stops the run rather than reporting
# nothing, since the review briefs its passes from this output and a partial enumeration
# produces a confidently incomplete review.

set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd -P)
AWKPROG=$(dirname "$0")/check-system.awk

# Corpus sets. A pass names the sets it reads and nothing else, so an exception is only
# ever a different composition, never a file added or removed by hand (D16.2). Tests are a
# set of their own rather than part of code: their fixtures are deliberate defects. The
# templates README is instruction among the templates, so forge takes it and config skips it
# by name.
globs() {
	case $1 in
	instruction) echo '.claude/CLAUDE.md .yg/wiki.md .yg/output-styles/*.md' ;;
	forge) echo '.yg/forge-mode.md .yg/forge-catalog.md .yg/facts.md .yg/*-contract.md .yg/engines/*/contract.md .yg/templates/README.md' ;;
	agents) echo '.yg/agents/*.md' ;;
	flows) echo '.yg/skills/*/SKILL.md .yg/skills/*/references/*.md' ;;
	code) echo '.yg/bin/*.sh .yg/bin/*.awk .yg/engines/*/*.sh .yg/hooks/* .yg/githooks/* .claude-plugin/*.json' ;;
	tests) echo '.yg/bin/test-*.sh .yg/engines/*/test-*.sh .yg/hooks/test-*.sh .yg/githooks/test-*.sh' ;;
	config) echo '.yg/default/config.conf .yg/config.conf .yg/templates/* .yg/technical-well.txt .gitignore .gitattributes .claude/settings.json' ;;
	docs) echo 'Docs/*.md' ;;
	prose) echo 'instruction forge agents flows' ;;
	program) echo 'instruction forge agents flows code config' ;;
	mechanism) echo 'program tests' ;;
	*) return 1 ;;
	esac
}

files() {
	for s; do
		case $s in
		prose | program | mechanism) files $(globs "$s") ;;
		*) (cd "$ROOT" && for f in $(globs "$s"); do
			[ -f "$f" ] || continue
			case $s:$f in code:*/test-* | config:.yg/templates/README.md) continue ;; esac
			echo "$f"
		done) ;;
		esac
	done
}

if [ "${1:-}" = files ]; then
	shift
	[ $# -gt 0 ] || { echo 'check-system: files needs a set name' >&2; exit 2; }
	for s; do globs "$s" >/dev/null || { echo "check-system: unknown set: $s" >&2; exit 2; }; done
	files "$@" | LC_ALL=C sort -u
	exit 0
fi

if [ "${1:-}" = added ]; then
	[ $# -eq 2 ] || { echo 'check-system: added needs a base commit' >&2; exit 2; }
	t=$(mktemp -d)
	trap 'git -C "$ROOT" worktree remove --force "$t/base" >/dev/null 2>&1 || :; rm -rf "$t"' EXIT
	git -C "$ROOT" worktree add -q --detach "$t/base" "$2" >/dev/null 2>&1 ||
		{ echo "check-system: cannot check, no worktree at $2" >&2; exit 2; }
	[ -f "$t/base/.yg/bin/check-system.sh" ] ||
		{ echo "check-system: cannot check, $2 has no check-system.sh" >&2; exit 2; }
	set +e
	sh "$t/base/.yg/bin/check-system.sh" >"$t/b" 2>&1; rb=$?
	sh "$ROOT/.yg/bin/check-system.sh" >"$t/n" 2>&1; rn=$?
	set -e
	[ "$rb" -le 1 ] || { grep 'check-system: cannot' "$t/b" >&2; echo "check-system: cannot check $2" >&2; exit 2; }
	[ "$rn" -le 1 ] || { grep 'check-system: cannot' "$t/n" >&2; exit 2; }
	sed 's/:[0-9][0-9]*:/:/' "$t/b" | LC_ALL=C sort -u >"$t/bs"
	sed 's/:[0-9][0-9]*:/:/' "$t/n" | LC_ALL=C sort -u | LC_ALL=C comm -13 "$t/bs" - >"$t/a"
	cat "$t/a"
	[ -s "$t/a" ] && exit 1
	exit 0
fi

# A brief is a pure function of passes.md, the worklists, the sets and both scripts' rows,
# so it is built here: the conduct block, the pass's section, its worklist, the files it
# reads and the rows, every program path absolute. A pass passes.md names with no recipe
# below stops it, as does an empty or failed list, since a pass briefed with nothing walks
# nothing and the review would record it as none found (D16.1.1). The newcomer read gets only the rows naming a docs file (D16.2).
if [ "${1:-}" = briefs ]; then
	{ [ $# -eq 2 ] && [ -d "$2" ]; } || { echo 'check-system: briefs needs an existing folder' >&2; exit 2; }
	dir=$2
	P=$ROOT/.yg/skills/system-review/references/passes.md
	[ -f "$P" ] || { echo "check-system: cannot brief, missing ${P#"$ROOT"/}" >&2; exit 2; }
	self=$ROOT/.yg/bin/check-system.sh
	fail() { echo "check-system: cannot brief, $1" >&2; exit 2; }
	sets() {
		l=$(files "$@" | LC_ALL=C sort -u)
		[ -n "$l" ] || fail "set $* lists no file"
		printf '%s\n' "$l" | R=$ROOT awk '{ print ENVIRON["R"] "/" $0 }'
	}
	# Program paths the sections name relative to the root, made absolute for the dispatch.
	absolute() {
		R=$ROOT awk 'function rep(s, a, b,   o, i) {
			o = ""; while ((i = index(s, a)) > 0) { o = o substr(s, 1, i - 1) b; s = substr(s, i + length(a)) }
			return o s
		}
		{ r = ENVIRON["R"]
		  $0 = rep($0, "git log -p -- .yg/forge-catalog.md", "git -C " r " log -p -- " r "/.yg/forge-catalog.md")
		  $0 = rep($0, "`.yg/", "`" r "/.yg/")
		  print rep($0, "`.claude/CLAUDE.md`", "`" r "/.claude/CLAUDE.md`") }'
	}
	section() { H=$1 awk '$0 == "## " ENVIRON["H"] { p = 1; print; next } p && /^## / { exit } p' "$P" | absolute; }

	set +e
	cs=$(sh "$self" 2>&1); rc=$?
	[ "$rc" -le 1 ] || fail "check-system.sh exited $rc: $cs"
	cl=$(sh "$ROOT/.yg/bin/check-leaks.sh" "$ROOT" 2>&1); rc=$?
	[ "$rc" -le 1 ] || fail "check-leaks.sh exited $rc: $cl"
	wf=$(sh "$self" worklist facts); rc=$?
	[ "$rc" = 0 ] && [ -n "$wf" ] || fail 'worklist facts is empty or failed'
	wd=$(sh "$self" worklist decisions); rc=$?
	[ "$rc" = 0 ] && [ -n "$wd" ] || fail 'worklist decisions is empty or failed'
	set -e
	rows="${cs:-(check-system.sh: no rows)}
${cl:-(check-leaks.sh: no rows)}"
	docs=$(files docs)
	docrows=$(printf '%s\n' "$rows" | D=$docs awk 'BEGIN { n = split(ENVIRON["D"], a, "\n"); for (i = 1; i <= n; i++) d[a[i]] }
		{ r = $0; sub(/^(question|notice): /, "", r); sub(/:.*/, "", r); if (r in d) print }')
	facts_wl=$(printf '%s\n' "$wf" | R=$ROOT awk -F '\t' '{ n = split($3, a, ", "); o = ""
		for (i = 1; i <= n; i++) o = o (i > 1 ? ", " : "") ENVIRON["R"] "/" a[i]
		print $1 " (facts.md line " $2 "): " o }')
	dec_wl=$(printf '%s\n' "$wd" | awk -F '\t' '{ print $1 " (forge-catalog.md line " $2 ")" }')
	conduct=$(section 'Conduct — the head of every brief')
	[ -n "$conduct" ] || fail 'passes.md has no conduct block'

	# Every section but the conduct block is a pass; one with no short name prints a blank.
	passes=$(awk 'function out() { if (h != "" && h != "Conduct — the head of every brief") print n "\t" h }
		/^## / { out(); h = substr($0, 4); n = "" }
		/^\*\*Short name:\*\* `/ { n = $0; sub(/^\*\*Short name:\*\* `/, "", n); sub(/`.*/, "", n) }
		END { out() }' "$P")
	[ -n "$passes" ] || fail 'passes.md names no pass'
	build='Build it yourself, as your section says.'
	printf '%s\n' "$passes" | while IFS='	' read -r name heading; do
		r=$rows
		case $name in
		decisions) wl=$dec_wl; rd=$(sets program) ;;
		facts-to-files) wl=$facts_wl; rd="$ROOT/.yg/facts.md and the citing files named in the worklist" ;;
		files-to-facts) wl=$(sets instruction forge agents flows code); rd="$ROOT/.yg/facts.md
$wl" ;;
		structure) wl="$(printf '%s\n' "$wf" | awk -F '\t' '{ print $1 " (facts.md line " $2 ")" }')
$dec_wl"; rd="$ROOT/.yg/facts.md
$ROOT/.yg/forge-catalog.md" ;;
		rule-homes | prose-bar) wl=$(sets instruction forge agents flows); rd=$wl ;;
		edge-cases) wl="$(sets flows agents)
Header comment only of each of:
$(sets code)"; rd="$(sets flows agents code) (code: header comments only)" ;;
		consistency | duplication) wl=$build; rd=$(sets program) ;;
		forkability) wl=$(sets mechanism); rd=$wl ;;
		docs-currency) wl=$(sets docs); rd=$(sets docs program) ;;
		newcomer-read) wl=$(sets docs); rd=$wl; r=${docrows:-(no script row names a docs file)} ;;
		residue) wl='None — read for contradictions, at most five.'; rd=$(sets program) ;;
		'') fail "passes.md's section $heading names no short name" ;;
		*) fail "no brief recipe for the pass $name" ;;
		esac
		f=$dir/brief-$name.md
		{ printf '%s\n\n' "$conduct"; section "$heading"; printf '\n## Your worklist\n\n%s\n' "$wl"
		  printf '\n## Files you read\n\n%s\n' "$rd"
		  printf "\n## The scripts' rows (already reported; do not re-file)\n\n%s\n" "$r"; } >"$f"
		printf '%s\n' "$f"
	done
	exit 0
fi

for f in "$ROOT/.yg/facts.md" "$ROOT/.yg/forge-catalog.md" "$ROOT/.yg/default/config.conf" "$AWKPROG"; do
	[ -f "$f" ] || { echo "check-system: cannot check, missing ${f#"$ROOT"/}" >&2; exit 2; }
done

scanned=$(files program | LC_ALL=C sort -u)
tests=$(files tests | LC_ALL=C sort -u | tr '\n' ' ')

if [ "${1:-}" = worklist ]; then
	case ${2:-} in facts | decisions) ;; *) echo "check-system: unknown worklist: ${2:-}" >&2; exit 2 ;; esac
	list=$(cd "$ROOT" && awk -v tests="$tests" -v worklist="$2" -f "$AWKPROG" $scanned) ||
		{ echo 'check-system: cannot list, the awk pass failed' >&2; exit 2; }
	# The pass still prints what it finds while reading; only the items are the worklist.
	printf '%s\n' "$list" | grep "^[FD][0-9][0-9.a-z]*$(printf '\t')" || true
	exit 0
fi

git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 ||
	{ echo "check-system: cannot check, $ROOT is not a git checkout" >&2; exit 2; }

US=$(printf '\037')

# Not a pipeline: a failing awk would hand the loop nothing, and nothing reads as clean.
# The usage docs are read for their citations too, though no composition holds them (D16.2);
# their glob is expanded here, where a page name with a space stays one word.
raw=$(cd "$ROOT" && set -- $(globs docs) && { [ -f "$1" ] || set --; } &&
	awk -v tests="$tests" -f "$AWKPROG" $scanned "$@") ||
	{ echo 'check-system: cannot check, the awk pass failed' >&2; exit 2; }

# Whether git ignores a path, as a file or as a folder: what it ignores is generated or
# kept per machine, never mechanism, and a fresh checkout lacks it.
ignored() { git -C "$ROOT" check-ignore -q -- "$1" || git -C "$ROOT" check-ignore -q -- "${1%/}/"; }

# Paths are the one citation awk cannot resolve alone, so it hands them back to be stat'ed.
report=$(printf '%s\n' "$raw" | while IFS= read -r line; do
	case $line in
	'P '*)
		rest=${line#P }
		loc=${rest%%"	"*}
		target=${rest#*"	"}
		[ -e "$ROOT/$target" ] && continue
		ignored "$target" || printf '%s: path does not resolve: %s\n' "$loc" "$target"
		;;
	"C$US"*) ;;
	*) printf '%s\n' "$line" ;;
	esac
done)

# A file in the program's folders that no set matches is outside every review, and nothing
# else would say so. What git ignores is outside on purpose, asked of git rather than kept
# in a list here, which would drift from the ignore rules it restates (D16.2). Git still
# lists a tracked file deleted from the working tree, and a nested repository as a folder.
all=$(cd "$ROOT" && git -c core.quotePath=false ls-files -co --exclude-standard -- .yg .claude .claude-plugin) ||
	{ echo 'check-system: cannot check coverage, git could not list the tree' >&2; exit 2; }
all=$(printf '%s\n' "$all" | while IFS= read -r f; do [ -f "$ROOT/$f" ] && printf '%s\n' "$f"; done | LC_ALL=C sort -u)
known=$(printf '%s\n%s\n' "$scanned" "$(printf '%s' "$tests" | tr ' ' '\n')" | LC_ALL=C sort -u)
uncovered=$(printf '%s\n' "$all" | while IFS= read -r f; do
	[ -n "$f" ] || continue
	printf '%s\n' "$known" | grep -qxF -- "$f" || printf '%s: in no corpus set\n' "$f"
done)
report=$(printf '%s\n%s\n' "$report" "$uncovered")

# Version drift, per fact and per tool it was checked with. The installed version is either
# in the fact's checkpoint set, which is silent, or it has moved. A moved fact whose probe
# judges itself is re-run and reported only if it stops holding; any other is a question
# for the user, asked by the review rather than here, and so is a version that cannot be
# read. A moved tool is one notice per run whatever its facts did, since nothing else says
# a dependency moved (the harness review is on demand, and this is the demand).
#
# Claude Code is the exception, since the harness review reads its release notes and names
# every fact a change touches (D17.3). Its manual facts are re-tested only where a change
# relates: at the harness review's checkpoint they are silent, and past it the one question
# is to run the review first. Its command probes still re-run, which costs nothing.
#
# Nothing is written: a probe that holds is silent without its set being expanded, which is
# an edit to facts.md and the fixer's. A probe runs in a scratch directory with no input,
# and it is a command taken from facts.md, so a pulled facts.md can run code here.
installed() {
	case $1 in
	'Claude Code') claude --version ;;
	mawk) mawk -W version ;;
	'busybox awk') busybox | grep -i busybox ;;
	'GNU findutils') find --version | grep 'GNU findutils' ;;
	# Where uutils is the default, a distribution may keep GNU beside it under a gnu prefix.
	'GNU coreutils') { sort --version; gnusort --version; } | grep 'GNU coreutils' ;;
	# The in-session bfs is the claude binary run under that name, which plain sh
	# cannot do: exec -a is bash's.
	bfs) bash -c 'exec -a bfs "$(command -v claude)" --version' ;;
	# whisper-cli prints no version; the build is its checkout's git describe.
	# Guarded, since with no whisper-cli git would describe whatever checkout it stood in.
	# readlink -f is not POSIX: where it is missing the version is unread, a question. Only
	# whisper.cpp's own checkout is described, since git would read any repository enclosing it.
	whisper.cpp) w=$(command -v whisper-cli) &&
		t=$(git -C "$(dirname "$(readlink -f "$w")")" rev-parse --show-toplevel) &&
		[ -f "$t/include/whisper.h" ] && git -C "$t" describe --tags ;;
	'uutils coreutils') sort --version | grep 'uutils coreutils' ;;
	PyYAML) python3 -c 'import yaml; print(yaml.__version__)' ;;
	Ubuntu) (. /etc/os-release && [ "$NAME" = Ubuntu ] && echo "$VERSION_ID") ;;
	# Obsidian is a desktop app, read through the Linux package manager that installed it.
	# Elsewhere, an AppImage or macOS, it cannot be read: a question, which does not fail.
	Obsidian) { snap list obsidian | awk 'NR == 2 { print $2 }'
		flatpak info md.obsidian.Obsidian | awk '$1 == "Version:" { print $2 }'
		dpkg-query -W -f '${Version}\n' obsidian; } 2>/dev/null | grep . ;;
	*' '*) ;;
	*) command -v "$1" >/dev/null && "$1" --version ;;
	esac 2>/dev/null </dev/null | head -n 1
}

# Whether any recorded version stands whole in the line a tool printed.
in_set() {
	l=" $1 "; shift
	for v; do case $l in *[!0-9.]"$v"[!0-9.]*) return 0 ;; esac; done
	return 1
}

cps=$(printf '%s\n' "$raw" | grep "^C$US" || true)
versions=$(printf '%s\n' "$cps" | cut -d "$US" -f 4 | LC_ALL=C sort -u | while IFS= read -r tool; do
	if [ -n "$tool" ]; then printf '%s\t%s\n' "$tool" "$(installed "$tool")"; fi
done)
lookup() { printf '%s\n' "$versions" | awk -F '\t' -v t="$1" '$1 == t { print $2; exit }'; }
shown() { printf '%s\n' "$1" | sed -n 's/^[^0-9]*\([0-9][0-9.]*[0-9]\).*/\1/p'; }

drift=$(printf '%s\n' "$cps" | while IFS=$US read -r _ line id tool vers cmd citers; do
	[ -n "$id" ] || continue
	now=$(lookup "$tool")
	by=${citers:+, cited by $citers}
	at=$(printf '%s' "$vers" | sed 's/|/, /g')
	if [ -z "$now" ]; then
		printf "question: .yg/facts.md:%s: %s — %s's version cannot be read here, checked at %s%s\n" \
			"$line" "$id" "$tool" "$at" "$by"
		continue
	fi
	(IFS='|'; in_set "$now" $vers) && continue
	if [ -n "$cmd" ]; then
		d=$(mktemp -d)
		(cd "$d" && sh -c "$cmd") >/dev/null 2>&1 </dev/null ||
			printf '.yg/facts.md:%s: probe no longer holds at %s %s: %s%s\n' "$line" "$tool" "$(shown "$now")" "$id" "$by"
		rm -rf "$d"
	elif [ "$tool" = 'Claude Code' ]; then
		continue
	else
		printf 'question: .yg/facts.md:%s: %s — %s is at %s, checked at %s%s\n' \
			"$line" "$id" "$tool" "$(shown "$now")" "$at" "$by"
	fi
done)

# The harness review's checkpoint: line and version, from facts.md's frontmatter.
hc=$(awk 'NR == 1 && !/^---$/ { exit } NR > 1 && /^---$/ { exit }
	/^checkpoint: Claude Code @ / { print NR "\t" $5; exit }' "$ROOT/.yg/facts.md")
moved=$(printf '%s\n' "$versions" | while IFS='	' read -r tool now; do
	[ -n "$now" ] || continue
	if [ "$tool" = 'Claude Code' ]; then
		v=$(shown "$now")
		if [ -z "$hc" ]; then
			printf 'question: .yg/facts.md:1: Claude Code is at %s, and facts.md records no harness review checkpoint: run the harness review\n' "$v"
		elif [ "$v" != "${hc#*	}" ]; then
			printf "question: .yg/facts.md:%s: Claude Code is at %s, not the harness review's checkpoint %s: run the harness review, which names the manual facts a change touches\n" "${hc%%	*}" "$v" "${hc#*	}"
		fi
		continue
	fi
	all=$(printf '%s\n' "$cps" | awk -F "$US" -v t="$tool" '$4 == t { printf "%s|", $5 }')
	(IFS='|'; in_set "$now" $all) || printf "notice: %s is at %s, in no fact's checkpoints\n" "$tool" "$(shown "$now")"
done)

# A ledger at its default place sits inside this checkout, which is published: unless git
# ignores it, a review's findings and dispositions reach a public commit (D18.3).
ledgers=$(grep -n '^review\.[a-z]*\.ledger_location:' "$ROOT/.yg/default/config.conf" | while IFS= read -r l; do
	n=${l%%:*}; rest=${l#*:}; key=${rest%%:*}
	loc=$(printf '%s' "${rest#*:}" | sed 's/^[[:blank:]]*//; s/[[:blank:]]*$//')
	case $loc in '' | none | /* | '~/'*) continue ;; esac
	ignored "$loc/x.md" || printf '.yg/default/config.conf:%s: %s is not gitignored: %s\n' "$n" "$key" "$loc"
done)

# A docs: entry in the technical well admits named URL hosts in the folder it matches.
# One that matches no tracked file is left over from a folder renamed or retired, and
# would admit a new folder of that name unseen.
tracked=$(git -C "$ROOT" -c core.quotePath=false ls-files) ||
	{ echo 'check-system: cannot check docs: entries, git could not list the tree' >&2; exit 2; }
stale=$(grep -n '^docs:' "$ROOT/.yg/technical-well.txt" 2>/dev/null | while IFS= read -r l; do
	re=$(printf '%s' "${l#*:docs:}" | sed 's/^[[:blank:]]*//')
	printf '%s\n' "$tracked" | grep -qE -- "$re" ||
		printf '.yg/technical-well.txt:%s: docs: entry matches no tracked file: %s\n' "${l%%:*}" "$re"
done)

# An agent loads only where plugin.json lists it by file (`F8.4`): an unlisted one never
# loads and nothing says so, and a listed one with no file behind it is a line a retirement
# left. Matched on the literal path string, since the scripts run on sh and awk alone.
# With no plugin.json, every agent is reported unlisted, since none of them loads.
plugin=$ROOT/.claude-plugin/plugin.json
agents=$(for a in "$ROOT"/.yg/agents/*.md; do
	[ -f "$a" ] || continue
	r=${a#"$ROOT"/}
	grep -qF "\"./$r\"" "$plugin" 2>/dev/null || printf '%s: agent is not listed in plugin.json, so it never loads\n' "$r"
done
[ ! -f "$plugin" ] || tr ',[]{}' '\n\n\n\n\n' <"$plugin" | sed -n 's/.*"\.\/\(\.yg\/agents\/[^"]*\)".*/\1/p' | while IFS= read -r r; do
	[ -f "$ROOT/$r" ] || printf '.claude-plugin/plugin.json: lists an agent with no file: %s\n' "$r"
done)

report=$(printf '%s\n%s\n%s\n%s\n%s\n%s\n' "$report" "$drift" "$moved" "$ledgers" "$stale" "$agents")

# By file, then by line as a number. Not sort -u: with keys it dedupes on the keys alone
# and would drop two different rows about one line.
bylines() { LC_ALL=C sort -t: -k"$1,$1" -k"$(($1 + 1)),$(($1 + 1))n" -k"$(($1 + 2))" | uniq; }
findings=$(printf '%s\n' "$report" | grep -v -e '^notice: ' -e '^question: ' -e '^$' | bylines 1 || true)
questions=$(printf '%s\n' "$report" | grep '^question: ' | bylines 2 || true)
notices=$(printf '%s\n' "$report" | grep '^notice: ' | bylines 2 || true)

# Findings first, then what the user is asked, then notices; only findings fail the run.
[ -n "$findings" ] && printf '%s\n' "$findings"
[ -n "$questions" ] && printf '%s\n' "$questions"
[ -n "$notices" ] && printf '%s\n' "$notices"
[ -z "$findings" ]
