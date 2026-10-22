#!/bin/sh
# PreToolUse hook: refuse a tool call that reaches into the Obsidian vault outside the
# wiki folder (`D3.2`). The wiki may be one folder of a larger vault beside folders
# Yggdrasil never touches, and neither the project boundary nor auto mode keeps a
# session out of them (`F12.2`); a plugin hook's refusal stops the call (`F11.1`, `F11.2`)
# and holds inside dispatches too (`F11.3`), so this one hook fences Odin and every agent.
#
# The vault is the nearest folder holding `.obsidian/`, walking up from the wiki root.
# None, or the wiki root itself, makes this a no-op: no config, nothing to go stale.
# The program's own folder is never refused, should it sit inside the vault.
#
# What is checked, every path normalised against the payload's `cwd`:
#   file tools  file_path, notebook_path, path, and Glob's pattern;
#   Bash        every word of the command that holds a `/`, is `..` or starts `~`,
#               after `~`, `$HOME` and `${HOME}` are expanded.
# A call missing the key it must carry (Read, Write, Edit or NotebookEdit with no path,
# Glob with no pattern, Bash with no command, or no tool_name) is refused, not passed: a
# payload drift would otherwise open the fence silently. Grep's path is optional, so it isn't.
# Limit: a vault whose config folder was renamed and holds no .obsidian/ is not found, so it
# is unfenced (`F13.2`, `D3.2`).
# Limit: lexical only. Symlinks aren't followed, and a Bash path built at run time
# (another variable, a `cd` into a subfolder before a relative climb) isn't seen. It
# fences honest mistakes, not a determined command; tighten if one ever slips through.
#
# The payload is read with a flat string scan, no JSON parser: the keys arrive as plain
# strings inside tool_input (`F11.4`; a Write's path, `F11.6`). POSIX sh + awk, inside macOS awk's floor (`F18.2`).
#
# Usage: wiki-boundary.sh WIKI_ROOT < payload
# Prints a PreToolUse deny decision, or nothing to let the call through. Exits 0.
#
# Cost: not timed — a walk up the wiki root's ancestors and one awk over one payload per
# tool call, nothing that grows with the wiki.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=${1:-}
[ -n "$root" ] || exit 0

vault=$root
while [ ! -d "$vault/.obsidian" ]; do
  [ "$vault" = / ] && exit 0
  vault=$(dirname -- "$vault")
done
[ "$vault" = "$root" ] && exit 0

awk -v root="$root" -v vault="$vault" -v prog="$HERE/../.." -v home="${HOME:-}" '
function norm(p,   n, a, i, k, out) {
  n = split(p, a, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (a[i] == "" || a[i] == ".") continue
    if (a[i] == "..") { if (k > 0) k--; continue }
    seg[++k] = a[i]
  }
  out = ""
  for (i = 1; i <= k; i++) out = out "/" seg[i]
  return out == "" ? "/" : out
}
function abs(p, base) {
  if (p == "~" || substr(p, 1, 2) == "~/") p = home substr(p, 2)
  if (substr(p, 1, 1) != "/") p = base "/" p
  return norm(p)
}
function within(p, d) { return d == "/" || p == d || substr(p, 1, length(d) + 1) == d "/" }
function repl(s, from, to,   i, out) {
  out = ""
  while ((i = index(s, from)) > 0) { out = out substr(s, 1, i - 1) to; s = substr(s, i + length(from)) }
  return out s
}
# The first string value of "key", JSON escapes undone (\n and \t become spaces).
function jstr(key,   s, i, j, c, out) {
  s = J
  while ((i = index(s, "\"" key "\"")) > 0) {
    s = substr(s, i + length(key) + 2)
    j = 1
    while ((c = substr(s, j, 1)) == " " || c == "\t") j++
    if (c != ":") continue
    j++
    while ((c = substr(s, j, 1)) == " " || c == "\t") j++
    if (c != "\"") continue
    out = ""
    for (j++; j <= length(s); j++) {
      c = substr(s, j, 1)
      if (c == "\"") return out
      if (c == "\\") {
        c = substr(s, ++j, 1)
        if (c == "n" || c == "t") c = " "
        else if (c == "u") { c = "?"; j += 4 }
      }
      out = out c
    }
    return out
  }
  return ""
}
function check(p) {
  if (p == "" || found != "") return
  if (within(p, vault) && !within(p, root) && !within(p, prog)) found = p
}
function esc(s) { s = repl(s, "\\", "\\\\"); return repl(s, "\"", "\\\"") }
{ J = J $0 " " }
END {
  root = norm(root); vault = norm(vault); prog = norm(prog)
  cwd = jstr("cwd"); if (cwd == "") cwd = root
  tool = jstr("tool_name")
  if (tool == "") shape = 1
  if (tool == "Bash") {
    if ((cmd = jstr("command")) == "") shape = 1
    cmd = repl(repl(cmd, "${HOME}", home), "$HOME", home)
    gsub(/["\047`()|;&<>=]/, " ", cmd)
    n = split(cmd, w, /[ \t]+/)
    for (i = 1; i <= n; i++)
      if (index(w[i], "/") || w[i] == ".." || substr(w[i], 1, 1) == "~") check(abs(w[i], cwd))
  } else {
    f = jstr("file_path"); nb = jstr("notebook_path")
    if (f != "") check(abs(f, cwd))
    if (nb != "") check(abs(nb, cwd))
    if (f nb == "" && tool ~ /^(Read|Write|Edit|NotebookEdit)$/) shape = 1
    base = cwd
    if ((p = jstr("path")) != "") { base = abs(p, cwd); check(base) }
    if (tool == "Glob") { if ((p = jstr("pattern")) != "") check(abs(p, base)); else shape = 1 }
  }
  if (found == "" && shape) {
    printf "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"This %s call carries no path the wiki fence can read, so it is refused rather than let through unchecked: the tool payload likely changed in a Claude Code update. Tell the user; run /yggdrasil:harness-review in the Yggdrasil program folder, naming this refusal as the feature, so its compare reads it against the payload facts.\"}}\n", esc(tool == "" ? "tool" : tool)
    exit
  }
  if (found == "") exit
  printf "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"%s is in the Obsidian vault but outside this wiki folder (%s). Yggdrasil reads and writes only inside the wiki folder; whatever else the vault holds is the user'"'"'s, so leave it alone rather than reaching it another way.\"}}\n", esc(found), esc(root)
}'
