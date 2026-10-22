#!/bin/sh
# Black-box test for check-leaks.sh and the pre-commit hook that runs it. POSIX sh, no
# framework. Builds temp repositories, runs the check, asserts on exit code and output.
#
# Every refused value is assembled with printf from pieces, so this file carries none of
# them and passes the check itself.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CL="$HERE/check-leaks.sh"
PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
code() { if [ "$rc" = "$1" ]; then ok "$2"; else bad "$2 (exit $rc)"; fi; }
says() { case "$out" in *"$1"*) ok "$2" ;; *) bad "$2" ;; esac; }
quiet(){ case "$out" in *"$1"*) bad "$2" ;; *) ok "$2" ;; esac; }
rootless() { if printf '%s\n' "$out" | grep -q '^LICENSE:'; then bad "$1"; else ok "$1"; fi; }

g() { git -C "$T" -c core.hooksPath=/dev/null -c user.name=t -c user.email=t@example.com "$@"; }
newrepo() { T=$(mktemp -d "${TMPDIR:-/tmp}/yg-cl.XXXXXX"); g init -q; }
put() { f=$1; shift; printf '%s\n' "$@" > "$T/$f"; }
tree()   { out=$(sh "$CL" "$T" 2>&1); rc=$?; }
staged() { out=$(sh "$CL" --staged "$T" 2>&1); rc=$?; }

H=$(printf '/%s/%s' home alice)
MAC=$(printf '/%s/%s' Users alice)
EM=$(printf '%s@%s.%s' cook kitchen com)
REMOTE=$(printf '%s@%s.%s:%s' git githost com chef/recipes.git)
URL=$(printf '%s%s%s' https :// kitchen-intranet.com/menu)
IP=$(printf '%s.%s.%s.%s' 10 1 2 3)
WIN=$(printf '%s%s%s' 'C:' '\Users' '\alice')
SCRATCH=$(printf '/%s/%s' tmp claude-1000)

# --- tree: what the well admits ---

newrepo
put clean.md \
  'Config lives at ~/.config/yggdrasil/config.conf, or $HOME/.config, or ${XDG_CONFIG_HOME}/x.' \
  'The wiki layer is <wiki>/.yg/config.conf; a vault at ~/<vault>/wiki.' \
  'Mail user@example.com, see https://docs.example.org/a/b, host 192.0.2.7.' \
  'cmd >/dev/null 2>&1; #!/bin/sh; /usr/bin/env sh; ${TMPDIR:-/tmp}/yg.XXXXXX' \
  'Run /yggdrasil:wrap at Claude Code 2.1.286. Paths like $W/.yg/x and */.yg/y are relative.' \
  'An example home is /home/<you>/notes, or C:\Users\<you>\notes.' \
  '/.yg/resolved/' \
  'Records D1.1.1.1 and F17.1.1.1 are ids, not addresses.'
g add -A
tree
code 0 'tree: placeholders, reserved names and well values pass'

# --- tree: each shape outside the well is refused ---

newrepo
TP=$(printf '~/%s/x' private-stuff)
TU=$(printf '~%s/x' alice)
put a.md "Notes in $H/notes." "Or $MAC/x." "$TP and $TU" \
  "Mail $EM; push to $REMOTE" "See $URL" "Server $IP" "Or $WIN\\x" "Scratch $SCRATCH/x" \
  "log 2>$H/log" "# a comment: $H/c" "two on a line: $H/one $MAC/two"
g add -A
tree
code 1 'tree: leaks found exit 1'
says "a.md:1: $H/notes"                'tree: home path, with file and line'
says "a.md:2: $MAC/x"                  'tree: macOS home path'
says "a.md:3: $TP"                     'tree: ~/ path not under a dot folder'
says "a.md:3: $TU"                     'tree: another user'"'"'s ~ path'
says "a.md:4: $EM"                     'tree: email address'
says "a.md:4: $(printf '%s@%s.%s' git githost com)" 'tree: scp-style remote'
says "a.md:5: kitchen-intranet.com"    'tree: URL host'
says "a.md:6: $IP"                     'tree: IP address'
says "a.md:7: $WIN"                    'tree: Windows home path'
says "a.md:8: $SCRATCH/x"              'tree: /tmp path that is no placeholder'
says "a.md:9: $H/log"                  'tree: path after a redirect'
says "a.md:10: $H/c"                   'tree: comment lines are not exempt'
says "a.md:11: $MAC/two"               'tree: a second value on the same line'
quiet 'notes.' 'tree: trailing punctuation is not part of the value'

# --- tree: only tracked files ---

newrepo
put tracked.md 'nothing here'
g add -A
put untracked.md "$H/x"
tree
code 0 'tree: an untracked file is not scanned'

# --- staged ---

newrepo
put a.md "old $H/x" 'line two'
g add -A; g commit -q -m one
put a.md "old $H/x" 'line two' 'a clean third line'
g add -A
staged
code 0 'staged: a committed leak is not re-reported; only staged lines count'

put a.md "old $H/x" 'line two' 'a clean third line' "new $MAC/y"
g add -A
staged
code 1 'staged: a staged leak exits 1'
says "a.md:4: $MAC/y" 'staged: reported at its line in the new file'
quiet "$H" 'staged: unchanged lines are not reported'

newrepo
put a.md 'first'
g add -A; g commit -q -m one
printf '%s\n' 'first' "++ $H/z" > "$T/a.md"
g add -A
staged
code 1 'staged: an added line beginning ++ is content, not a file header'

newrepo
put a.md "gone $H/x" 'kept'
g add -A; g commit -q -m one
put a.md 'kept'
g add -A
staged
code 0 'staged: a removed leak is not refused'

newrepo
put a.md "first commit $H/x"
g add -A
staged
code 1 'staged: works before the first commit'

# --- the root LICENSE is skipped, verbatim text the program doesn't write ---

newrepo
mkdir -p "$T/sub"
put LICENSE "See $URL"
put sub/LICENSE "See $URL"
put LICENSE.md "See $URL"
g add -A
tree
code 1 'license: other files still refused'
rootless 'license: tree skips the root LICENSE'
says "sub/LICENSE:1: kitchen-intranet.com" 'license: tree checks a LICENSE below the root'
says "LICENSE.md:1: kitchen-intranet.com"  'license: tree checks LICENSE.md'
staged
rootless 'license: staged skips the root LICENSE'
says "sub/LICENSE:1: kitchen-intranet.com" 'license: staged checks a LICENSE below the root'

newrepo
put LICENSE "See $URL"
g add -A
tree
code 0 'license: tree with only the root LICENSE is clean'
staged
code 0 'license: staged with only the root LICENSE is clean'

# --- a named URL host in a docs: folder is let through ---

S=$(printf '%s%s%s' https :// cookbook-site.com/stew)
SIP=$(printf '%s%s%s' http :// "$IP"/x)
D=$(mktemp -d "${TMPDIR:-/tmp}/yg-cl.XXXXXX")
mkdir -p "$D/.yg/bin"
cp "$HERE/check-leaks.sh" "$HERE/check-leaks.awk" "$D/.yg/bin/"
{ cat "$HERE/../technical-well.txt"; echo 'docs: ^Cooking/'; } >"$D/.yg/technical-well.txt"
dtree()   { out=$(sh "$D/.yg/bin/check-leaks.sh" "$T" 2>&1); rc=$?; }
dstaged() { out=$(sh "$D/.yg/bin/check-leaks.sh" --staged "$T" 2>&1); rc=$?; }

newrepo
mkdir -p "$T/Cooking/.sources" "$T/Chess" "$T/.yg" "$T/MyCooking"
put 'Cooking/Stew.md' "Body $S" "- $SIP" "- $H/x" "- $EM"
put 'Cooking/.subject.md' "See $S"
put 'Cooking/.sources/a.txt' "From $S"
put 'Chess/Opening.md' "See $S"
put 'Index.md' "See $S"
put '.yg/rules.md' "See $S"
put 'MyCooking/a.md' "See $S"
g add -A
dtree
code 1 'docs: other values still refused'
quiet 'Cooking/Stew.md:1:'                  'docs: a named host passes in a listed folder'
quiet 'Cooking/.subject.md'                 'docs: a dot file in a listed folder passes'
quiet 'Cooking/.sources/a.txt'              'docs: any file under a listed folder passes'
says "Cooking/Stew.md:2: $IP"               'docs: an IP host is still refused'
says "Cooking/Stew.md:3: $H/x"              'docs: a path is still refused'
says "Cooking/Stew.md:4: $EM"               'docs: an email address is still refused'
says 'Chess/Opening.md:1: cookbook-site.com' 'docs: an unlisted folder is refused'
says 'Index.md:1: cookbook-site.com'        'docs: a root file is refused'
says '.yg/rules.md:1: cookbook-site.com'    'docs: a program file is refused'
says 'MyCooking/a.md:1: cookbook-site.com'  'docs: the entry is anchored'
quiet 'notice:' 'docs: tree prints no notice'
tree
says 'Cooking/Stew.md:1: cookbook-site.com' 'docs: the real well lists no folder this test uses'

newrepo
mkdir -p "$T/Cooking"
put 'Cooking/Stew.md' "- $S"
g add -A
dstaged
code 0 'docs staged: a named host commits'
says "notice: Cooking/Stew.md:1: $S" 'docs staged: notice names the whole URL'

# --- unknown, never clean ---

U=$(mktemp -d "${TMPDIR:-/tmp}/yg-cl.XXXXXX")
mkdir -p "$U/.yg/bin"
cp "$HERE/check-leaks.sh" "$HERE/check-leaks.awk" "$U/.yg/bin/"
newrepo
out=$(sh "$U/.yg/bin/check-leaks.sh" "$T" 2>&1); rc=$?
code 2 'unknown: no technical well exits 2'
says 'never clean' 'unknown: says so'

printf '# only a comment\n\n' > "$U/.yg/technical-well.txt"
put a.md "$H/x"
g add -A
out=$(sh "$U/.yg/bin/check-leaks.sh" "$T" 2>&1); rc=$?
code 2 'unknown: a well with no entries exits 2'

N=$(mktemp -d "${TMPDIR:-/tmp}/yg-cl.XXXXXX")
out=$(sh "$CL" "$N" 2>&1); rc=$?
code 2 'unknown: not a git checkout exits 2'

out=$(sh "$CL" 2>&1); rc=$?
code 2 'usage: no root exits 2'

# --- the pre-commit hook ---

newrepo
mkdir -p "$T/.yg/bin" "$T/.yg/githooks"
cp "$HERE/check-leaks.sh" "$HERE/check-leaks.awk" "$T/.yg/bin/"
cp "$HERE/../technical-well.txt" "$T/.yg/"
cp "$HERE/../githooks/pre-commit" "$T/.yg/githooks/"
chmod +x "$T/.yg/githooks/pre-commit"
hc() { git -C "$T" -c core.hooksPath=.yg/githooks -c user.name=t -c user.email=t@example.com commit -q -m x 2>&1; }
g add -A
out=$(hc); rc=$?
code 0 'hook: a clean commit goes through'
put b.md "see $H/x"
g add -A
out=$(hc); rc=$?
code 1 'hook: a leaking commit is refused'
says 'Refused' 'hook: says why'
says "b.md:1: $H/x" 'hook: names the value'
put b.md "- $S"
g add -A
out=$(hc); rc=$?
code 1 'hook: a host outside any docs: folder is refused'
says 'Rows starting notice: were let through' 'hook: the refusal says what notice rows are'
says 'under docs:' 'hook: the refusal names where a docs folder is listed'
echo 'docs: ^Cooking/' >>"$T/.yg/technical-well.txt"
mkdir -p "$T/Cooking"
put b.md 'clean'
put Cooking/c.md "- $S"
g add -A
out=$(hc); rc=$?
code 0 'hook: a host in a docs: folder commits'
says "notice: Cooking/c.md:1: $S" 'hook: and lists it'

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
