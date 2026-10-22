#!/bin/sh
# Black-box test for .yg/hooks/wiki-boundary.sh. POSIX sh — no framework.
# Each case feeds the hook a PreToolUse payload of the shape `F11.6` and `F11.3` record and
# checks whether it denies. The fixtures hard-code that shape, so a payload drift leaves
# this green; the hook refuses a call missing its key (cases 39-43), the facts carry the rest.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PASS=0
FAIL=0

# A vault V holding .obsidian/, the wiki W and a sibling folder S; the program P outside
# it. V is dot-named only so the ~ cases' paths sit in the technical well.
T=$(mktemp -d "${TMPDIR:-/tmp}/yg-wb.XXXXXX")
trap 'rm -rf "$T"' EXIT
V="$T/.vault"; W="$V/wiki"; S="$V/other"; P="$T/program"
mkdir -p "$V/.obsidian" "$W/Openings" "$S" "$P/.yg/hooks"
cp "$HERE/wiki-boundary.sh" "$P/.yg/hooks/"

ok()  { PASS=$((PASS + 1)); echo "ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
# hook ROOT PAYLOAD [SCRIPT] — the hook's output for one payload.
hook() { printf '%s' "$2" | HOME="$T" sh "${3:-$P/.yg/hooks/wiki-boundary.sh}" "$1"; }
deny()  { case $(hook "$@") in *'"permissionDecision":"deny"'*) return 0 ;; esac; return 1; }
denies() { name=$1; shift; if deny "$@"; then ok "$name"; else bad "$name"; fi; }
allows() { name=$1; shift; if deny "$@"; then bad "$name"; else ok "$name"; fi; }
file()  { printf '{"cwd":"%s","tool_name":"%s","tool_input":{"%s":"%s"}}' "$1" "$2" "$3" "$4"; }
bash_() { printf '{"cwd":"%s","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" "$2"; }

# --- file tools ---
allows '1 Read inside the wiki'               "$W" "$(file "$W" Read file_path "$W/Openings/Italian Game.md")"
denies '2 Read in a sibling folder'           "$W" "$(file "$W" Read file_path "$S/notes.md")"
denies '3 Write in a sibling folder'          "$W" "$(file "$W" Write file_path "$S/new.md")"
denies '4 Edit reached through ..'            "$W" "$(file "$W" Edit file_path "$W/../other/notes.md")"
denies '5 Read of the vault root itself'      "$W" "$(file "$W" Read file_path "$V/Index.md")"
denies '6 a file in .obsidian/'               "$W" "$(file "$W" Read file_path "$V/.obsidian/app.json")"
allows '7 Read outside the vault'             "$W" "$(file "$W" Read file_path "$T/elsewhere.md")"
allows '8 a climb that comes back into the wiki' "$W" "$(file "$W" Read file_path "$W/x/../../wiki/a.md")"
mkdir -p "$V/wiki-old"
denies '9 a folder named like the wiki plus a suffix' "$W" "$(file "$W" Read file_path "$V/wiki-old/a.md")"
denies '10 Grep path in a sibling'            "$W" "$(file "$W" Grep path "$S")"
denies '11 Glob with an absolute pattern'     "$W" "$(file "$W" Glob pattern "$S/*.md")"
denies '12 Glob climbing out of the wiki'     "$W" "$(file "$W" Glob pattern "../other/**/*.md")"
allows '13 Glob with a relative pattern'      "$W" "$(file "$W" Glob pattern "**/*.md")"
denies '14 NotebookEdit in a sibling'         "$W" "$(file "$W" NotebookEdit notebook_path "$S/a.ipynb")"
allows '15 a tool with no path'               "$W" '{"cwd":"'"$W"'","tool_name":"WebSearch","tool_input":{"query":"italian game"}}'
allows '16 relative file_path inside, from a subfolder' "$W" "$(file "$W/Openings" Read file_path "../Index.md")"

# --- Bash ---
denies '17 cat ../other'                      "$W" "$(bash_ "$W" 'cat ../other/notes.md')"
denies '18 quoted path, JSON-escaped'         "$W" "$(bash_ "$W" 'cat \"../other/a b.md\"')"
denies '19 absolute path'                     "$W" "$(bash_ "$W" "ls $S")"
denies '20 ~ path'                            "$W" "$(bash_ "$W" 'cat ~/.vault/other/notes.md')"
denies '21 $HOME path'                        "$W" "$(bash_ "$W" 'cat $HOME/.vault/other/notes.md')"
denies '22 ${HOME} path'                      "$W" "$(bash_ "$W" 'cat ${HOME}/.vault/other/notes.md')"
denies '23 redirect into a sibling'           "$W" "$(bash_ "$W" 'echo x >../other/a.md')"
denies '24 --opt=path'                        "$W" "$(bash_ "$W" 'grep -r --exclude-dir=x --include=*.md x --file=../other/p')"
denies '25 cd .. from the wiki root'          "$W" "$(bash_ "$W" 'cd .. && ls')"
allows '26 cd .. from a subfolder'            "$W" "$(bash_ "$W/Openings" 'cd .. && ls')"
allows '27 ordinary command in the wiki'      "$W" "$(bash_ "$W" 'grep -rl castle . | head -n 5')"
allows '28 /dev/null and a URL'               "$W" "$(bash_ "$W" 'curl -s https://example.com/a 2>/dev/null')"
allows '29 git -C the wiki root'              "$W" "$(bash_ "$W" "git -C $W status")"

# --- where the hook stands down ---
allows '30 the wiki is the vault'             "$V" "$(file "$V" Read file_path "$S/notes.md")"
N="$T/novault"; mkdir -p "$N/wiki" "$N/other"
allows '31 no .obsidian above the wiki'       "$N/wiki" "$(file "$N/wiki" Read file_path "$N/other/a.md")"
allows '32 no wiki root given'                "" "$(file "$W" Read file_path "$S/notes.md")"
mkdir -p "$V/program/.yg/hooks"; cp "$HERE/wiki-boundary.sh" "$V/program/.yg/hooks/"
allows '33 the program inside the vault'      "$W" "$(file "$W" Read file_path "$V/program/.yg/page-contract.md")" "$V/program/.yg/hooks/wiki-boundary.sh"
denies '34 ...but not the rest of the vault'  "$W" "$(file "$W" Read file_path "$S/notes.md")" "$V/program/.yg/hooks/wiki-boundary.sh"
M="$T/nested"; mkdir -p "$M/.obsidian" "$M/notes/wiki" "$M/notes/other"
denies '35 nested wiki: a sibling at its level' "$M/notes/wiki" "$(file "$M/notes/wiki" Read file_path "$M/notes/other/a.md")"
allows '36 trailing slash on the wiki root'   "$W/" "$(file "$W" Read file_path "$W/a.md")"

# --- the decision itself ---
out=$(hook "$W" '{"cwd":"'"$W"'","tool_name":"Read","tool_input":{"file_path":"'"$S"'/a \"q\".md"}}')
case $out in
  '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'"$S"'/a \"q\".md is in the Obsidian vault'*) ok '37 deny JSON names the path, quotes escaped' ;;
  *) bad "37 deny JSON names the path, quotes escaped: $out" ;;
esac
out=$(hook "$W" "$(file "$W" Read file_path "$W/a.md")"); rc=$?
if [ -z "$out" ] && [ $rc -eq 0 ]; then ok '38 allow is silent and exits 0'; else bad '38 allow is silent and exits 0'; fi

# --- a payload shape the hook doesn't know ---
denies '39 Read with its path under a renamed key' "$W" "$(file "$W" Read filePath "$W/a.md")"
denies '40 Edit with no path at all'          "$W" '{"cwd":"'"$W"'","tool_name":"Edit","tool_input":{}}'
denies '41 Bash with no command'              "$W" '{"cwd":"'"$W"'","tool_name":"Bash","tool_input":{"cmd":"ls"}}'
denies '42 Glob with no pattern'              "$W" '{"cwd":"'"$W"'","tool_name":"Glob","tool_input":{}}'
denies '43 no tool_name'                      "$W" '{"cwd":"'"$W"'","tool":"Read","tool_input":{"file_path":"'"$W"'/a.md"}}'
allows '44 Grep with no path'                 "$W" '{"cwd":"'"$W"'","tool_name":"Grep","tool_input":{"pattern":"castle"}}'
allows '45 a renamed key, no vault around'    "$N/wiki" "$(file "$N/wiki" Read filePath "$N/wiki/a.md")"

echo "passed $PASS, failed $FAIL"
[ "$FAIL" -eq 0 ]
