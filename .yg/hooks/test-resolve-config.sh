#!/bin/sh
# Black-box test for both config hooks — .yg/hooks/resolve-config.sh and its PostToolUse
# companion resolve-config-on-write.sh. POSIX sh — no framework, no Python.
# Builds temp fixtures, runs the hook, asserts on the resolved output via grep.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PASS=0
FAIL=0

# Every fixture is a program P (both scripts copied in, since the resolver finds the
# default layer beside itself), a separate wiki W, and a user config home X standing
# in for $XDG_CONFIG_HOME.
newbase() {
  T=$(mktemp -d "${TMPDIR:-/tmp}/yg-rc.XXXXXX")
  P="$T/program"; W="$T/wiki"; X="$T/xdg"
  mkdir -p "$P/.yg/hooks" "$P/.yg/default" "$W/.yg" "$X/yggdrasil"
  cp "$HERE/resolve-config.sh" "$HERE/resolve-config-on-write.sh" "$P/.yg/hooks/"
  D="$P/.yg/default/config.conf"; U="$X/yggdrasil/config.conf"; L="$W/.yg/config.conf"
  R="$W/.yg/resolved/config.conf"
}
run()  { XDG_CONFIG_HOME="$X" sh "$P/.yg/hooks/resolve-config.sh" "${1:-$W}"; }
ok()   { PASS=$((PASS + 1)); echo "ok   $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
has()  { if grep -q -- "$2" "$1" 2>/dev/null; then ok "$3"; else bad "$3"; fi; }
hasnt(){ if grep -q -- "$2" "$1" 2>/dev/null; then bad "$3"; else ok "$3"; fi; }
absent() { if [ -e "$1" ]; then bad "$2"; else ok "$2"; fi; }
says() { case "$1" in *"$2"*) ok "$3" ;; *) bad "$3" ;; esac; }
# No key may appear twice. `has` cannot see this — grep -q stops at the first hit — and
# readers trust the resolved file as an invariant, so a duplicated key is consumed as a
# correct value by whichever reader reaches it first.
nodup() {
  dups=$(grep ':' "$1" | sed 's/:.*//' | LC_ALL=C sort | uniq -d)
  if [ -z "$dups" ]; then ok "$2"; else bad "$2 (duplicated: $(echo $dups))"; fi
}

# --- config: per-key merge ---

# 1. no override -> defaults pass through
newbase
printf 'sample-key: north\n' > "$D"
run >/dev/null
has "$R" 'sample-key: north' '1 no override: default present'

# 2. a user override substitutes its value; an untouched key flows through
newbase
printf 'sample-key: north\nwiki-review.lines_threshold: 200\n' > "$D"
printf 'wiki-review.lines_threshold: 300\n'                    > "$U"
run >/dev/null
has   "$R" 'wiki-review.lines_threshold: 300' '2 override: new value present'
has   "$R" 'sample-key: north'                '2 override: untouched key flows through'
nodup "$R"                                    '2 override: the overridden key appears exactly once'

# 3. an override-only key is appended cleanly
newbase
printf 'sample-key: north\n' > "$D"
printf 'new.key: 1\n'        > "$U"
run >/dev/null
has   "$R" 'new.key: 1' '3 override-only: value appended'
nodup "$R"              '3 override-only: appending adds no duplicate'

# 4. value containing '#' is taken literally (no inline-comment stripping)
newbase
printf 'sample-key: north\ncolor: #ff0000\n' > "$D"
run >/dev/null
has "$R" 'color: #ff0000' '4 literal value: # preserved in value'

# 5. full-line '#' comments dropped, including a commented-out key
newbase
printf '# disabled.key: 1\nsample-key: north\n' > "$D"
run >/dev/null
has   "$R" 'sample-key: north' '5 comment: real key present'
hasnt "$R" 'disabled.key'      '5 comment: commented-out key dropped'

# 6. '#' value preserved when set by an override
newbase
printf 'color: #ff0000\n' > "$D"
printf 'color: #336699\n' > "$L"
run >/dev/null
has "$R" 'color: #336699' '6 override: # value preserved'

# 7. indented full-line comment in an override dropped
newbase
printf 'sample-key: north\n'                        > "$D"
printf '   # indented comment\nsample-key: south\n' > "$U"
run >/dev/null
has   "$R" 'sample-key: south' '7 indent-comment: real key parsed'
hasnt "$R" 'indented comment'  '7 indent-comment: comment dropped'

# --- three layers ---

# 8. precedence is default -> user -> wiki, each key once
newbase
printf 'a: default\nb: default\nc: default\n' > "$D"
printf 'b: user\nc: user\n'                   > "$U"
printf 'c: wiki\n'                            > "$L"
run >/dev/null
has   "$R" 'a: default' '8 layers: default where nothing overrides'
has   "$R" 'b: user'    '8 layers: user beats default'
has   "$R" 'c: wiki'    '8 layers: wiki beats user'
nodup "$R"              '8 layers: each key exactly once'

# 9. override-only keys from both layers append, and the wiki's value wins a shared one
newbase
printf 'sample-key: north\n'        > "$D"
printf 'u.only: 1\nshared: user\n'  > "$U"
printf 'w.only: 1\nshared: wiki\n'  > "$L"
run >/dev/null
has   "$R" 'u.only: 1'    '9 override-only: user key appended'
has   "$R" 'w.only: 1'    '9 override-only: wiki key appended'
has   "$R" 'shared: wiki' '9 override-only: wiki wins a key both add'
nodup "$R"                '9 override-only: each key exactly once'

# 10. an absent user layer counts as no overrides
newbase
printf 'sample-key: north\n' > "$D"
printf 'other: wiki\n'       > "$L"
run >/dev/null
has "$R" 'sample-key: north' '10 absent user layer: default passes through'
has "$R" 'other: wiki'       '10 absent user layer: wiki layer still applies'

# 11. with no XDG_CONFIG_HOME the user layer is ~/.config/yggdrasil/config.conf
newbase
printf 'sample-key: north\n' > "$D"
mkdir -p "$T/home/.config/yggdrasil"
printf 'sample-key: south\n' > "$T/home/.config/yggdrasil/config.conf"
(unset XDG_CONFIG_HOME; HOME="$T/home" sh "$P/.yg/hooks/resolve-config.sh" "$W") >/dev/null
has "$R" 'sample-key: south' '11 user layer: falls back to ~/.config'

# --- session kind ---

# 12. the program root as the wiki is a forge session
newbase
printf 'sample-key: north\n' > "$D"
out=$(run "$P")
says "$out" 'forge session' '12 kind: forge announced'
says "$out" "program root $(cd -P "$P" && pwd)." '12 kind: program root announced'
has "$P/.yg/resolved/config.conf" 'session.kind: forge' '12 kind: forge resolved into the program'

# 13. any other folder is a wiki session
newbase
printf 'sample-key: north\n' > "$D"
out=$(run)
says "$out" 'wiki session' '13 kind: wiki announced'
has "$R" 'session.kind: wiki' '13 kind: wiki resolved'

# 14. the program reached through a symlink is still the program
newbase
printf 'sample-key: north\n' > "$D"
ln -s "$P" "$T/link"
out=$(run "$T/link")
says "$out" 'forge session' '14 kind: symlinked program root is forge'

# 15. session.kind set in a layer is ignored, never duplicated
newbase
printf 'sample-key: north\nsession.kind: forge\n' > "$D"
printf 'session.kind: forge\n' > "$L"
run >/dev/null
has   "$R" 'session.kind: wiki' '15 kind: a layer cannot set it'
nodup "$R"                      '15 kind: appears exactly once'

# --- arguments ---

# 16. no argument is a usage error, never a guess at the wiki
newbase
printf 'sample-key: north\n' > "$D"
(cd "$W" && XDG_CONFIG_HOME="$X" sh "$P/.yg/hooks/resolve-config.sh") 2>/dev/null
rc=$?
if [ "$rc" = 2 ]; then ok '16 args: no argument exits 2'; else bad '16 args: no argument exits 2'; fi
absent "$R" '16 args: no argument resolves nothing'

# 17. a wiki root that doesn't exist is reported and exits 0
newbase
printf 'sample-key: north\n' > "$D"
out=$(run "$T/nowhere"); rc=$?
says "$out" 'found no wiki' '17 args: missing wiki reported'
if [ "$rc" = 0 ]; then ok '17 args: missing wiki exits 0'; else bad '17 args: missing wiki exits 0'; fi

# --- atomicity + last-good retention ---
#
# Reaching the promote-failure branch takes an awk failure, NOT a blanked default layer:
# the input guard rejects a keyless one with its own message and exit 0. An unreadable
# override layer makes awk exit non-zero, which is the shape the promote test exists for.
if [ "$(id -u)" = 0 ]; then
  echo "skip 18-19: running as root, chmod cannot make a file unreadable"
else

# 18. a failed re-resolve retains last-good + warns, no temp litter
newbase
printf 'sample-key: north\n' > "$D"
run >/dev/null
has "$R" 'sample-key: north' '18 last-good: first resolve present'
printf 'sample-key: south\n' > "$U"
chmod 000 "$U"
msg=$(run 2>&1)
has "$R" 'sample-key: north' '18 last-good: prior value retained on failed re-resolve'
says "$msg" 'last-good' '18 last-good: warning emitted'
if ls "$W/.yg/resolved/".config.conf.* >/dev/null 2>&1; then bad '18 cleanup: no temp litter'; else ok '18 cleanup: no temp litter'; fi

# 19. first-ever resolve failure (no last-good) -> file absent + cold warning
newbase
printf 'sample-key: north\n' > "$D"
printf 'sample-key: south\n' > "$L"
chmod 000 "$L"
msg=$(run 2>&1)
absent "$R" '19 cold-fail: no resolved file left'
says "$msg" 'no resolved config' '19 cold-fail: absence warning emitted'

fi

# 20. a blanked default layer hits the INPUT guard: its own message, exit 0, and any
#     prior resolved file left exactly as it was.
newbase
printf 'sample-key: north\n' > "$D"
run >/dev/null
printf '# only a comment, no keys\n' > "$D"
msg=$(run 2>&1)
says "$msg" 'truncated or blanked' '20 blanked-defaults: input-guard message'
has "$R" 'sample-key: north' '20 blanked-defaults: prior resolved file untouched'

# 21. the guard fires before any override is read, so an override-only key cannot
#     resurrect a blanked default layer into a resolved config.
newbase
printf '# no keys at all\n'   > "$D"
printf 'override-only: yes\n' > "$U"
msg=$(run 2>&1)
says "$msg" 'truncated or blanked' '21 blanked-defaults: guard precedes the merge'
absent "$R" '21 blanked-defaults: no resolved file written'

# --- resolve-config-on-write.sh (PostToolUse companion) ---
#
# Feed a PostToolUse JSON blob on stdin, with a session root as the argument, and assert
# which tree (if any) got resolved. S is a second wiki standing in for the session root,
# so a case can tell "resolved the edited tree" from "resolved the session's".
fire() { printf '%s' "$1" | XDG_CONFIG_HOME="$X" sh "$P/.yg/hooks/resolve-config-on-write.sh" "${2-$S}"; }
newsess() { newbase; S="$T/session"; mkdir -p "$S/.yg"; SR="$S/.yg/resolved/config.conf"; printf 'sample-key: north\n' > "$D"; }

# 22. a write to a wiki layer resolves THAT wiki, not the session root
newsess
printf 'wiki.format: 1\nsample-key: south\n' > "$L"
fire "{\"cwd\":\"$S\",\"tool_input\":{\"file_path\":\"$L\"}}" >/dev/null
has    "$R" 'sample-key: south' '22 on-write: wiki layer resolves its own wiki'
absent "$SR"                    '22 on-write: wiki layer leaves the session root alone'

# 23. a write to the default layer resolves the session root
newsess
fire "{\"tool_input\":{\"file_path\":\"$D\"}}" >/dev/null
has "$SR" 'sample-key: north' '23 on-write: default layer resolves the session root'

# 24. a write to the user layer resolves the session root
newsess
printf 'sample-key: south\n' > "$U"
fire "{\"tool_input\":{\"file_path\":\"$U\"}}" >/dev/null
has "$SR" 'sample-key: south' '24 on-write: user layer resolves the session root'

# 25. an unrelated path is ignored — no resolved file appears anywhere
newsess
fire "{\"tool_input\":{\"file_path\":\"$W/Cooking/Sourdough.md\"}}" >/dev/null
absent "$R"  '25 on-write: unrelated path ignored'
absent "$SR" '25 on-write: unrelated path resolves no session either'

# 26. a relative file_path is anchored on cwd rather than dropped
newsess
printf 'wiki.format: 1\n' > "$L"
fire "{\"cwd\":\"$W\",\"tool_input\":{\"file_path\":\".yg/config.conf\"}}" >/dev/null
has "$R" 'sample-key: north' '26 on-write: relative path anchored on cwd'

# 27. no file_path at all -> exit 0, nothing written
newsess
fire '{"tool_input":{}}'
rc=$?
if [ "$rc" = 0 ]; then ok '27 on-write: absent file_path exits 0'; else bad '27 on-write: absent file_path exits 0'; fi
absent "$SR" '27 on-write: absent file_path is a no-op'

# 28. a shared-layer write with no session root exits 0 rather than a usage error
newsess
fire "{\"tool_input\":{\"file_path\":\"$D\"}}" '' >/dev/null
rc=$?
if [ "$rc" = 0 ]; then ok '28 on-write: no session root exits 0'; else bad '28 on-write: no session root exits 0'; fi

# 28a. a .yg/config.conf recording no format is another tree, not a wiki: left alone
newsess
printf 'sample-key: south\n' > "$L"
fire "{\"cwd\":\"$S\",\"tool_input\":{\"file_path\":\"$L\"}}" >/dev/null
absent "$W/.yg/resolved" '28a on-write: a layer with no format writes nothing in its tree'
absent "$SR"             '28a on-write: nor resolves the session'

# --- the wiki format check ---
fmt() { newbase; printf 'sample-key: north\nprogram.wiki_format: 2\n' > "$D"; [ -z "$1" ] || printf '%s\n' "$1" > "$L"; run; }

# 29. a wiki at the program's format is silent beyond the kind line
out=$(fmt 'wiki.format: 2')
if [ "$(printf '%s\n' "$out" | wc -l)" -eq 1 ]; then ok '29 format: matching format adds no line'; else bad "29 format: matching format adds no line: $out"; fi

# 30. no wiki.format, though the default layer has one: told to run init
says "$(fmt '')" 'records no format; set it up with: sh' '30 format: a wiki with none is pointed at init'

# 31. older and newer
says "$(fmt 'wiki.format: 1')" 'is format 1 and the program reads format 2' '31 format: older wiki named'
says "$(fmt 'wiki.format: 3')" 'newer than the program'"'"'s 2; update the program' '31 format: newer wiki says update the program'

# 32. not a number: named, and the resolve still happens
O=$(mktemp); fmt 'wiki.format: two' > "$O"; out=$(cat "$O"); rm -f "$O"
says "$out" "'two', is not a number" '32 format: a non-number is named'
has "$R" 'sample-key: north' '32 format: config still resolves'

# 33. the user layer cannot supply the wiki's format
newbase; printf 'program.wiki_format: 2\n' > "$D"; printf 'wiki.format: 2\n' > "$U"
says "$(run)" 'records no format' '33 format: only the wiki layer counts'

# --- wiki-only keys and going public ---

# 33a. a wiki-only key in the user or default layer is named, dropped, and the rest resolves
newbase
printf 'sample-key: north\nwiki.public_answered: none\n' > "$D"
printf 'wiki.public_answered: none\nwiki.format: 1\nother: 1\n' > "$U"
printf 'wiki.format: 1\n' > "$L"
out=$(run)
says "$out" "wiki.public_answered belongs only in a wiki's own .yg/config.conf, so it is ignored in $U" '33a wiki-only: user layer named'
says "$out" "wiki.public_answered belongs only in a wiki's own .yg/config.conf, so it is ignored in $D" '33a wiki-only: default layer named'
says "$out" "wiki.format belongs only in a wiki's own .yg/config.conf, so it is ignored in $U" '33a wiki-only: format named too'
hasnt "$R" 'wiki.public_answered' '33a wiki-only: dropped from resolved'
has   "$R" 'other: 1'             '33a wiki-only: the rest of the layer resolves'
has   "$R" 'wiki.format: 1'       '33a wiki-only: the wiki layer still supplies it'
nodup "$R"                        '33a wiki-only: no duplicate'

# 33b. a commented-out mention, or a key that only starts the same, is not named
newbase
printf 'sample-key: north\n# wiki.format: <n>\nwiki.formatting: x\n' > "$D"
printf 'wiki.format: 1\n' > "$L"
case $(run) in *belongs\ only*) bad '33b wiki-only: comment and look-alike pass' ;; *) ok '33b wiki-only: comment and look-alike pass' ;; esac
has "$R" 'wiki.formatting: x' '33b wiki-only: look-alike resolves'

# 33c. public with no marker asks; with one, says nothing
newbase
printf 'wiki.visibility: private\n' > "$D"
printf 'wiki.format: 1\nwiki.visibility: public\n' > "$L"
says "$(run)" "public and hasn't answered" '33c going public: unanswered asks'
printf 'wiki.format: 1\nwiki.visibility: public\nwiki.public_answered: none\n' > "$L"
case $(run) in *going\ public*) bad '33c going public: answered is silent' ;; *) ok '33c going public: answered is silent' ;; esac

# 33d. public set in the user layer still asks, and a marker there does not answer it
newbase
printf 'wiki.visibility: private\n' > "$D"
printf 'wiki.visibility: public\nwiki.public_answered: none\n' > "$U"
printf 'wiki.format: 1\n' > "$L"
says "$(run)" "public and hasn't answered" '33d going public: a user-layer marker answers nothing'

# 33e. private with a marker offers to undo what it lists
newbase
printf 'wiki.visibility: private\n' > "$D"
printf 'wiki.format: 1\nwiki.public_answered: wiki.well gitignore\n' > "$L"
says "$(run)" 'private but carries what going public wrote (wiki.well gitignore)' '33e going private: marker offered for undo'

# --- forge ledgers ---

# 34. a forge session names each ledger at the top of forge.ledger_location, and no deeper
newbase
mkdir -p "$T/led/sub"; : > "$T/led/a.md"; : > "$T/led/b c.md"; : > "$T/led/sub/x.md"
printf 'forge.ledger_location: .yg/ledgers/forge\n' > "$D"
printf 'forge.ledger_location: %s\n' "$T/led" > "$U"
out=$(run "$P")
says "$out" "read before changing the program: $T/led/a.md, $T/led/b c.md." '34 ledgers: each top-level ledger named'
case $out in *x.md*) bad '34 ledgers: a subfolder is not read' ;; *) ok '34 ledgers: a subfolder is not read' ;; esac

# 35. a relative location resolves against the program root; none there says where they go
newbase
printf 'forge.ledger_location: .yg/ledgers/forge\n' > "$D"
out=$(run "$P")
says "$out" "no forge ledgers yet; they go in $(cd -P "$P" && pwd)/.yg/ledgers/forge." '35 ledgers: empty location named'

# 36. ~/ expands to the home directory
newbase
mkdir -p "$T/home/PH"; : > "$T/home/PH/a.md"
printf 'forge.ledger_location: ~/PH\n' > "$D"
out=$(HOME="$T/home" run "$P")
says "$out" "changing the program: $T/home/PH/a.md." '36 ledgers: ~/ expands'

# 37. none, or a wiki session, prints no ledger line
newbase
printf 'forge.ledger_location: none\n' > "$D"
out=$(run "$P")
case $out in *ledger*) bad '37 ledgers: none prints nothing' ;; *) ok '37 ledgers: none prints nothing' ;; esac
printf 'forge.ledger_location: .yg/ledgers/forge\n' > "$D"
out=$(run)
case $out in *ledger*) bad '37 ledgers: a wiki session prints nothing' ;; *) ok '37 ledgers: a wiki session prints nothing' ;; esac

# --- pre-commit wiring ---

# 38. a forge checkout is told when its pre-commit is unwired or has lost its exec bit
newbase
printf 'sample-key: north\n' > "$D"
mkdir -p "$P/.yg/githooks"; printf '#!/bin/sh\n' > "$P/.yg/githooks/pre-commit"
git init -q "$P"
says "$(run "$P")" 'pre-commit is not wired' '38 wiring: unset hooksPath named'
git -C "$P" config core.hooksPath .yg/githooks
says "$(run "$P")" 'pre-commit is not wired' '38 wiring: missing exec bit named'
chmod +x "$P/.yg/githooks/pre-commit"
case $(run "$P") in *wired*) bad '38 wiring: wired prints nothing' ;; *) ok '38 wiring: wired prints nothing' ;; esac
git -C "$P" config core.hooksPath "$(cd -P "$P" && pwd)/.yg/githooks"
case $(run "$P") in *wired*) bad '38 wiring: absolute path accepted' ;; *) ok '38 wiring: absolute path accepted' ;; esac
git -C "$P" config core.hooksPath elsewhere
says "$(run "$P")" 'pre-commit is not wired' '38 wiring: another hooks folder named'
git -C "$P" config --unset core.hooksPath
case $(run) in *wired*) bad '38 wiring: a wiki session prints nothing' ;; *) ok '38 wiring: a wiki session prints nothing' ;; esac

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
