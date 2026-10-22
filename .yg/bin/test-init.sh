#!/bin/sh
# Black-box test for .yg/bin/init.sh. POSIX sh — no framework.
# Git is isolated from the machine's config, and `claude` is a stub on PATH that answers
# `plugin marketplace list --json` from $STUB_LIST and logs every `marketplace add`.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PASS=0
FAIL=0
ok()   { PASS=$((PASS + 1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
says() { case "$1" in *"$2"*) ok "$3" ;; *) bad "$3: $1" ;; esac; }
lacks(){ case "$1" in *"$2"*) bad "$3: $1" ;; *) ok "$3" ;; esac; }
is()   { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3: got '$1', want '$2'"; fi; }

TOP=$(mktemp -d "${TMPDIR:-/tmp}/yg-init.XXXXXX")
trap 'rm -rf "$TOP"' EXIT
TOP=$(CDPATH= cd -P -- "$TOP" && pwd)

# A fresh base per case: home H holding the program P, a stub bin, and git config.
newbase() {
  T=$(mktemp -d "$TOP/c.XXXXXX"); H="$T/home"; P="$H/prog"; B="$T/bin"
  mkdir -p "$P/.yg/bin" "$P/.yg/default" "$B"
  cp "$HERE/init.sh" "$HERE/install.sh" "$HERE/regen-views.sh" "$P/.yg/bin/"
  printf 'wiki.visibility: private\nprogram.wiki_format: 1\n' > "$P/.yg/default/config.conf"
  printf '[user]\n\tname = Cook\n\temail = cook@example.com\n[init]\n\tdefaultBranch = main\n' > "$T/gitconfig"
  cat > "$B/claude" <<EOF
#!/bin/sh
case "\$*" in
  "plugin marketplace list --json") cat "\${STUB_LIST:-/dev/null}" ;;
  "plugin marketplace add "*) echo "add \$4 \$5 \$6 in \$(pwd -P)" >> "$T/claude.log" ;;
esac
EOF
  chmod +x "$B/claude"; STUB_LIST=/dev/null
  W="$H/vault/wiki"
}
init() {
  HOME="$H" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" STUB_LIST="$STUB_LIST" \
    PATH="$B:$PATH" sh "$P/.yg/bin/init.sh" "$@"
}
g() { GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" git "$@"; }
list() { printf '[\n  {\n    "name": "%s",\n    "source": "directory",\n    "path": "%s",\n    "installLocation": "%s"\n  }\n]\n' "$1" "$2" "$2" > "$T/list.json"; STUB_LIST="$T/list.json"; }

# --- check ---

newbase
out=$(init check "$W")
is "$out" "git: present
identity: set
repo: none
folder: missing
wired: no
vault: none
marketplace: none" '1 check: a missing folder, nothing registered'

newbase; mkdir -p "$W/Cooking/.templates" "$W/.obsidian"
touch "$W/Cooking/Sourdough.md" "$W/notes.txt" "$W/.obsidian/app.json" "$W/Cooking/.templates/recipe.md"
says "$(init check "$W")" 'folder: populated 2' '2 check: populated counts files outside dot-paths'

newbase; list yggdrasil "$P"
says "$(init check "$W")" 'marketplace: this' '3 check: the registry points at this program'
list yggdrasil "$T/elsewhere"
says "$(init check "$W")" "marketplace: other $T/elsewhere" '3 check: the registry points elsewhere'
list chess-tools "$P"
says "$(init check "$W")" 'marketplace: none' '3 check: another marketplace at the same path is not ours'
printf '[\n  {\n    "name": "yggdrasil",\n    "source": {\n      "source": "github",\n      "repo": "example/yggdrasil"\n    },\n    "installLocation": "%s"\n  }\n]\n' "$P" > "$T/list.json"
says "$(init check "$W")" 'marketplace: this' '3 check: a nested source object before installLocation'

newbase
noclaude=$(printf '%s\n' "$PATH" | tr ':' '\n' | while IFS= read -r d; do [ -x "$d/claude" ] || printf '%s:' "$d"; done)
out=$(HOME="$H" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" PATH="${noclaude%:}" sh "$P/.yg/bin/init.sh" check "$W")
says "$out" 'marketplace: unavailable' '4 check: no claude CLI'

newbase; printf '[init]\n\tdefaultBranch = main\n' > "$T/gitconfig"
says "$(init check "$W")" 'identity: unset' '5 check: no identity'
init wire "$W" 2>"$T/err"; is "$?" 2 '5 wire: refused with no identity'
says "$(cat "$T/err")" 'init: git has no user.name' '5 wire: the refusal says why'
if [ -e "$W/.git" ]; then bad '5 wire: no repository made'; else ok '5 wire: no repository made'; fi

newbase; mkdir -p "$W/Openings" "$H/vault/.obsidian"
says "$(init check "$W")" "vault: $H/vault" '5a check: the vault is the .obsidian/ folder above'
mkdir -p "$W/.obsidian"
says "$(init check "$W")" 'vault: self' '5a check: a wiki that is the whole vault'

# --- wire, from nothing ---

newbase
out=$(init wire "$W"); rc=$?
is "$rc" 0 '6 wire: exits 0 from a missing folder'
says "$out" 'committed the wiki as its first commit' '6 wire: says it committed'
is "$(g -C "$W" rev-parse --show-toplevel)" "$W" '6 wire: the wiki is its own repository'
is "$(g -C "$W" log --format=%s)" 'Init: wiki' '6 wire: one commit, Init: wiki'
is "$(cat "$W/.gitattributes")" '* text=auto eol=lf' '6 wire: .gitattributes'
is "$(cat "$W/.gitignore")" '/.*/
!/.yg/
!/.claude/
!/.sources/
/.yg/resolved/
/import/*
!/import/.gitkeep
/.claude/worktrees/
/.claude/settings.local.json' '6 wire: .gitignore'
says "$(cat "$W/.claude/settings.json")" '"enabledPlugins": { "yggdrasil@yggdrasil": true }' '6 wire: settings enable the plugin, path-free'
says "$(cat "$W/.claude/CLAUDE.md")" 'This folder is an Yggdrasil wiki' '6 wire: the sign-post'
is "$(grep -c . "$W/.claude/CLAUDE.md")" 1 '6 wire: the sign-post alone, no import'
is "$(cat "$W/.yg/config.conf" | grep -v '^#')" 'wiki.format: 1
wiki.visibility: private' '6 wire: config carries the format and private visibility'
says "$(cat "$W/Misc/.subject.md")" 'pitch: Items that don' '6 wire: Misc minted'
tracked=$(g -C "$W" ls-files)
says "$tracked" 'import/.gitkeep' '6 wire: the drop-zone keepfile is tracked'
says "$tracked" 'Index.md' '6 wire: the views are generated and tracked'
says "$tracked" 'Misc/Index.md' '6 wire: Misc has its index'
mkdir -p "$W/.yg/resolved" "$W/.obsidian" "$W/.claude/worktrees/w"
touch "$W/import/notes.md" "$W/.yg/resolved/config.conf" "$W/.obsidian/app.json" "$W/.claude/worktrees/w/a.md" "$W/.claude/settings.local.json"
is "$(g -C "$W" status --porcelain)" '' '6 wire: drop-zone, resolved config, .obsidian, worktrees and local settings are ignored'
mkdir -p "$W/.sources/chats" "$W/.mine"; touch "$W/.sources/chats/r.md" "$W/.mine/x"
is "$(g -C "$W" status --porcelain --untracked-files=all)" '?? .sources/chats/r.md' '6 wire: .sources/ is tracked, a dot folder of the user'"'"'s own is not'
rm -rf "$W/.sources" "$W/.mine"
mkdir -p "$W/.claude/agent-memory/munin"; touch "$W/.claude/agent-memory/munin/m.md"
says "$(g -C "$W" status --porcelain)" '.claude/agent-memory/' '6 wire: an agent memory folder shows as untracked'
rm -rf "$W/.claude/agent-memory"

before=$(cd "$W" && find . -path ./.git -prune -o -type f -print | sort | xargs cat | cksum)
out=$(init wire "$W")
says "$out" 'nothing to change' '7 re-run: nothing to change'
is "$(g -C "$W" rev-list --count HEAD)" 1 '7 re-run: no new commit'
after=$(cd "$W" && find . -path ./.git -prune -o -type f -print | sort | xargs cat | cksum)
is "$after" "$before" '7 re-run: no file changed'

# 8a. a renamed config folder is ignored as .obsidian/ is, being a top-level dot folder (F13.2)
newbase; mkdir -p "$W/.probe-config"; touch "$W/.probe-config/app.json"
init wire "$W" >/dev/null
if g -C "$W" check-ignore -q .probe-config/app.json; then ok '8a wire: a renamed config folder is ignored'; else bad '8a wire: a renamed config folder is ignored'; fi
is "$(g -C "$W" ls-files -- .probe-config)" '' '8a wire: and not committed'

# --- populated folders ---

newbase; mkdir -p "$W/Cooking"; printf 'Fold, rest, fold.\n' > "$W/Cooking/Sourdough.md"
init wire "$W" 2>"$T/err"; is "$?" 2 '9 populated: refused without --populated-ok'
says "$(cat "$T/err")" 'already holds 1 files' '9 populated: the refusal counts'
if [ -e "$W/.git" ]; then bad '9 populated: nothing made'; else ok '9 populated: nothing made'; fi
init wire "$W" --populated-ok >/dev/null; is "$?" 0 '9 populated: --populated-ok wires'
says "$(g -C "$W" show --stat --format= HEAD)" 'Cooking/Sourdough.md' '9 populated: the first commit takes the existing pages'

newbase; mkdir -p "$W"; g -C "$W" init -q
printf 'Castle early.\n' > "$W/Italian Game.md"; printf 'drafts/\n' > "$W/.gitignore"
g -C "$W" add -A; g -C "$W" commit -q -m 'chess notes'
printf 'Castle early, then centre.\n' > "$W/Italian Game.md"
mkdir -p "$W/.claude"; printf '{ "permissions": {} }\n' > "$W/.claude/settings.json"
printf 'Be brief.\n' > "$W/.claude/CLAUDE.md"
mkdir -p "$W/.yg"; printf 'wiki.visibility: public\n' > "$W/.yg/config.conf"
out=$(init wire "$W" --populated-ok)
says "$out" 'committed what init wrote' '10 existing repo: init commits its own paths'
says "$out" 'note: .claude/settings.json exists without the plugin' '10 existing repo: a foreign settings file is named'
says "$(g -C "$W" status --porcelain)" ' M "Italian Game.md"' '10 existing repo: the user'"'"'s edit stays uncommitted'
is "$(head -n 1 "$W/.gitignore")" 'drafts/' '10 existing repo: the user'"'"'s ignore line kept'
says "$(cat "$W/.gitignore")" '/import/*' '10 existing repo: init'"'"'s ignore lines added'
is "$(sed -n 1p "$W/.claude/CLAUDE.md")" 'Be brief.' '10 existing repo: the user'"'"'s CLAUDE.md kept'
is "$(sed -n 2p "$W/.claude/CLAUDE.md")" '' '10 existing repo: the sign-post appended after a blank line'
says "$(sed -n 3p "$W/.claude/CLAUDE.md")" 'This folder is an Yggdrasil wiki' '10 existing repo: the sign-post appended to an existing CLAUDE.md'
is "$(cat "$W/.yg/config.conf")" 'wiki.visibility: public
wiki.format: 1' '10 existing repo: format added, visibility kept'
init wire "$W" >/dev/null
is "$(grep -c '^/import/\*$' "$W/.gitignore")" 1 '10 re-run: no ignore line doubled'
is "$(grep -c 'Yggdrasil wiki' "$W/.claude/CLAUDE.md")" 1 '10 re-run: no sign-post doubled'

# --- inside another repository ---

newbase; mkdir -p "$W"; g -C "$H/vault" init -q
says "$(init check "$W")" "repo: enclosing $H/vault" '11 enclosing: check names the outer root'
init wire "$W" 2>"$T/err"; is "$?" 2 '11 enclosing: refused without --nested'
says "$(cat "$T/err")" 're-run with --nested' '11 enclosing: the refusal names the way on'
if [ -e "$W/.git" ]; then bad '11 enclosing: no repository made'; else ok '11 enclosing: no repository made'; fi
init wire "$W" --nested >/dev/null; is "$?" 0 '11 nested: wires'
is "$(g -C "$W" rev-parse --show-toplevel)" "$W" '11 nested: the wiki has its own repository'
if g -C "$H/vault" rev-parse -q --verify HEAD >/dev/null; then bad '11 nested: the outer repository untouched'; else ok '11 nested: the outer repository untouched'; fi

# --- interactive ---

newbase; list yggdrasil "$P"; mkdir -p "$W"; g -C "$H/vault" init -q
printf '\n' | init "$W" >/dev/null 2>&1
if [ -e "$W/.git" ]; then bad '13 interactive: Enter at the nesting question stops'; else ok '13 interactive: Enter at the nesting question stops'; fi
printf 'n\n' | init "$W" >/dev/null 2>&1
is "$(g -C "$W" rev-parse --show-toplevel 2>/dev/null)" "$W" '13 interactive: n nests'

newbase; list yggdrasil "$P"; mkdir -p "$W"; touch "$W/a.md"
printf '\n' | init "$W" >/dev/null 2>&1
if [ -e "$W/.git" ]; then bad '14 interactive: Enter at the populated question stops'; else ok '14 interactive: Enter at the populated question stops'; fi

newbase; list yggdrasil "$P"
out=$(printf '' | init "$W" 2>&1)
says "$out" '/yggdrasil:init' '15 interactive: names the skill to run next'
says "$out" "alias yg='cd \"$W\" && claude'" '15 interactive: suggests a wiki alias'
if grep -q '^add' "$T/claude.log" 2>/dev/null; then bad '15 interactive: nothing registered'; else ok '15 interactive: nothing registered'; fi

for reg in none "other $T/elsewhere"; do
  newbase; [ "$reg" = none ] || list yggdrasil "$T/elsewhere"
  printf '' | init "$W" >/dev/null 2>"$T/err"; is "$?" 2 "15a not installed ($reg): refused"
  says "$(cat "$T/err")" "run sh $P/.yg/bin/install.sh first" "15a not installed ($reg): the refusal points at install.sh"
  if [ -e "$W" ]; then bad "15a not installed ($reg): nothing made"; else ok "15a not installed ($reg): nothing made"; fi
done

# --- the user's own remote ---

newbase
mkdir -p "$W"; git -C "$W" init -q
init origin "$W" 'https://tok3n@example.com/v.git' >"$T/out" 2>"$T/err"; is "$?" 2 '17 origin: a token in an https URL is refused'
lacks "$(cat "$T/out" "$T/err")" 'tok3n' '17 origin: and the refusal never prints it'
init origin "$W" 'ssh://me:pw9x@example.com/v.git' >"$T/out" 2>"$T/err"; is "$?" 2 '17 origin: a password in any scheme URL is refused'
lacks "$(cat "$T/out" "$T/err")" 'pw9x' '17 origin: and that refusal never prints it either'
init origin "$W" 'https://example.com/v.git?token=qs7k' >"$T/out" 2>"$T/err"; is "$?" 2 '17 origin: a token in a query string is refused'
lacks "$(cat "$T/out" "$T/err")" 'qs7k' '17 origin: and that refusal never prints it'
is "$(git -C "$W" remote)" '' '17 origin: a refused URL adds no remote'
init origin "$W" 'git@example.com:me/v.git' >/dev/null 2>&1; is "$?" 0 '17 origin: an scp-style account is not a credential'
is "$(git -C "$W" remote get-url origin)" 'git@example.com:me/v.git' '17 origin: and is added as given'
init origin "$W" 'ssh://git@example.com/v.git' >/dev/null 2>&1; is "$?" 2 '17 origin: a second origin is refused'
init origin "$T/none" 'git@example.com:me/v.git' >/dev/null 2>&1; is "$?" 2 '17 origin: a folder with no repository is refused'

# --- usage ---

newbase
init 2>/dev/null; is "$?" 2 '16 usage: no arguments'
init wire 2>/dev/null; is "$?" 2 '16 usage: wire with no folder'
init wire "$W" --sideways 2>/dev/null; is "$?" 2 '16 usage: unknown option'

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
