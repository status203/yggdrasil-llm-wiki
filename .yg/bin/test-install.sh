#!/bin/sh
# Black-box test for .yg/bin/install.sh. POSIX sh — no framework.
# Git is isolated from the machine's config, and `claude` is a stub on PATH that answers
# `plugin marketplace list --json` from $STUB_LIST and logs every `marketplace add`.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PASS=0
FAIL=0
ok()   { PASS=$((PASS + 1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
says() { case "$1" in *"$2"*) ok "$3" ;; *) bad "$3: $1" ;; esac; }
is()   { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3: got '$1', want '$2'"; fi; }

TOP=$(mktemp -d "${TMPDIR:-/tmp}/yg-install.XXXXXX")
trap 'rm -rf "$TOP"' EXIT
TOP=$(CDPATH= cd -P -- "$TOP" && pwd)

# A fresh base per case: the program P, a stub bin, and git config.
newbase() {
  T=$(mktemp -d "$TOP/c.XXXXXX"); P="$T/prog"; B="$T/bin"
  mkdir -p "$P/.yg/bin" "$B"
  cp "$HERE/install.sh" "$P/.yg/bin/"
  printf '[user]\n\tname = Cook\n\temail = cook@example.com\n' > "$T/gitconfig"
  cat > "$B/claude" <<EOF
#!/bin/sh
case "\$*" in
  "plugin marketplace list --json") echo "list in \$(pwd -P)" >> "$T/claude.log"; cat "\${STUB_LIST:-/dev/null}" ;;
  "plugin marketplace add "*) echo "add \$4 \$5 \$6" >> "$T/claude.log" ;;
esac
EOF
  chmod +x "$B/claude"; STUB_LIST=/dev/null
}
inst() {
  GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" STUB_LIST="$STUB_LIST" \
    PATH="$B:$PATH" sh "$P/.yg/bin/install.sh" "$@"
}
list() { printf '[\n  {\n    "name": "%s",\n    "source": "directory",\n    "path": "%s",\n    "installLocation": "%s"\n  }\n]\n' "$1" "$2" "$2" > "$T/list.json"; STUB_LIST="$T/list.json"; }

# --- check ---

newbase
is "$(inst check)" "git: present
identity: set
awk: present
marketplace: none" '1 check: nothing registered'
says "$(cat "$T/claude.log")" 'list in /' '1 check: the registry is asked from outside any project'

newbase; list yggdrasil "$P"
says "$(inst check)" 'marketplace: this' '2 check: the registry points at this program'
list yggdrasil "$T/elsewhere"
says "$(inst check)" "marketplace: other $T/elsewhere" '2 check: the registry points elsewhere'
list chess-tools "$P"
says "$(inst check)" 'marketplace: none' '2 check: another marketplace at the same path is not ours'
printf '[\n  {\n    "name": "yggdrasil",\n    "source": {\n      "source": "github",\n      "repo": "example/yggdrasil"\n    },\n    "installLocation": "%s"\n  }\n]\n' "$P" > "$T/list.json"
says "$(inst check)" 'marketplace: this' '2 check: a nested source object before installLocation'

newbase
noclaude=$(printf '%s\n' "$PATH" | tr ':' '\n' | while IFS= read -r d; do [ -x "$d/claude" ] || printf '%s:' "$d"; done)
out=$(GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" PATH="${noclaude%:}" sh "$P/.yg/bin/install.sh" check)
says "$out" 'marketplace: unavailable' '3 check: no claude CLI'
GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" PATH="${noclaude%:}" sh "$P/.yg/bin/install.sh" 2>"$T/err" >/dev/null
is "$?" 2 '3 install: refused with no claude CLI'
says "$(cat "$T/err")" 'install: install Claude Code' '3 install: the refusal says what to install'

# A repository's own identity is not the machine's.
newbase; : > "$T/gitconfig"; mkdir -p "$T/repo"; git -C "$T/repo" init -q
git -C "$T/repo" config user.name Cook; git -C "$T/repo" config user.email cook@example.com
out=$(cd "$T/repo" && inst check)
says "$out" 'identity: unset' '4 check: a repository identity does not count'
(cd "$T/repo" && inst) 2>"$T/err" >/dev/null; is "$?" 2 '4 install: refused with no identity'
says "$(cat "$T/err")" "install: set git's identity first" '4 install: the refusal says how'
if [ -e "$T/claude.log" ] && grep -q '^add' "$T/claude.log"; then bad '4 install: nothing registered'; else ok '4 install: nothing registered'; fi

# --- install ---

newbase; git -C "$P" init -q
out=$(inst); rc=$?
is "$rc" 0 '5 install: exits 0'
is "$(grep '^add' "$T/claude.log")" "add $P --scope user" '5 install: registers this program at user level, the scope named'
says "$out" "claude plugin marketplace add $P" '5 install: says what it registers'
says "$out" "init.sh <folder>" '5 install: names the next step'
says "$out" "alias ygf='cd \"$P\" && claude'" '5 install: suggests a forge alias'
says "$out" "git -C \"$P\" config core.hooksPath .yg/githooks && chmod +x \"$P/.yg/githooks/pre-commit\"" '5 install: suggests wiring the pre-commit, its exec bit included'
is "$(GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" git -C "$P" config core.hooksPath 2>/dev/null)" '' '5 install: wires nothing itself'

newbase; list yggdrasil "$P"
out=$(inst); rc=$?
is "$rc" 0 '6 already registered: exits 0'
says "$out" 'nothing to register' '6 already registered: says so'
if grep -q '^add' "$T/claude.log"; then bad '6 already registered: nothing added'; else ok '6 already registered: nothing added'; fi

newbase; list yggdrasil "$T/elsewhere"
inst 2>"$T/err" >/dev/null; is "$?" 2 '7 another program: refused'
says "$(cat "$T/err")" "at $T/elsewhere, not this program" '7 another program: the refusal names it'
if grep -q '^add' "$T/claude.log"; then bad '7 another program: nothing added'; else ok '7 another program: nothing added'; fi

# A worktree of the registered checkout is not another program, and removing that one's
# registration is not the way in.
newbase; M="$T/main"; git -C "$T" init -q main
GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$T/gitconfig" git -C "$M" commit -q --allow-empty -m start
git -C "$M" worktree add -q "$T/wt" 2>/dev/null; mkdir -p "$T/wt/.yg/bin"; cp "$HERE/install.sh" "$T/wt/.yg/bin/"
P="$T/wt"; list yggdrasil "$M"
inst 2>"$T/err" >/dev/null; is "$?" 2 '7b a worktree of the registered checkout: refused'
says "$(cat "$T/err")" "this is a worktree of $M" '7b a worktree: the refusal says so'
case "$(cat "$T/err")" in *"marketplace remove"*) bad '7b a worktree: no advice to remove the registration' ;; *) ok '7b a worktree: no advice to remove the registration' ;; esac

# --- usage ---

newbase
inst sideways 2>/dev/null; is "$?" 2 '8 usage: an unknown argument'

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
