# Scanner for check-leaks.sh, which states the contract.
# Arguments: the technical well, then the lines to scan. mode=tree reads git grep's
# "path:line:content"; mode=staged reads a -U0 unified diff and scans its added lines.
#
# Portability: no POSIX character classes, which the floor, macOS's awk, predates (`F18.2`).
# It also avoids {n,m} intervals and a ] inside a bracket expression, a margin no fact
# records: every awk in reach accepts both, and the floor is not probeable here.

FILENAME == wellfile {
  if ($0 ~ /^docs:/) { d = $0; sub(/^docs:[ \t]*/, "", d); docs[++nd] = d }
  else if ($0 !~ /^[ \t]*#/ && $0 !~ /^[ \t]*$/) well[++nw] = $0
  next
}

mode == "tree" {
  i = index($0, ":"); file = substr($0, 1, i - 1); rest = substr($0, i + 1)
  i = index(rest, ":"); line = substr(rest, 1, i - 1)
  scan(substr(rest, i + 1))
  next
}

# Staged: a header runs from "diff --git" to the first hunk, so an added content line
# that itself begins "++" is never mistaken for a "+++" file line.
/^diff --git / { inhdr = 1; file = ""; next }
inhdr && /^\+\+\+ / { file = substr($0, 5); sub(/^b\//, "", file); next }
/^@@ / {
  inhdr = 0
  match($0, /\+[0-9]+/); line = substr($0, RSTART + 1, RLENGTH - 1) + 0
  next
}
!inhdr && file != "" && /^\+/ { scan(substr($0, 2)); line++ }

END {
  if (nw == 0) { print "check-leaks: the technical well has no entries." > "/dev/stderr"; exit 2 }
  exit (hits > 0)
}

function indocs(f,   i) { for (i = 1; i <= nd; i++) if (f ~ docs[i]) return 1; return 0 }
function allowed(v,   i) { for (i = 1; i <= nw; i++) if (v ~ well[i]) return 1; return 0 }
function report(v) { if (!allowed(v)) { print file ":" line ": " v; hits++ } }

# Cut the first match of re out of s, so a later shape doesn't see it again, leaving the
# matched text in tok. scan() pads s with a space at each end, so every shape's boundary
# class is satisfiable at the start and end of a line.
function take(re) {
  if (!match(s, re)) return 0
  tok = substr(s, RSTART, RLENGTH)
  s = substr(s, 1, RSTART - 1) " " substr(s, RSTART + RLENGTH)
  return 1
}
function trimend(v) { sub(/[.,;:]+$/, "", v); return v }

function scan(text,   host) {
  s = " " text " "
  gsub(/\$\{HOME\}|\$HOME/, "~", s)
  gsub(/\$\{[^}]*\}/, "VAR", s)
  gsub(/\$[A-Za-z_][A-Za-z0-9_]*/, "VAR", s)
  gsub(/<[A-Za-z0-9_.-]+>/, "PH", s)

  # URL: the host is the value. A URL with no host (file:///...) goes back on the line
  # as a bare path, for the path rule below.
  while (take("[A-Za-z][A-Za-z0-9+.-]*://[^ \t\"'`<>)]*")) {
    host = substr(tok, index(tok, "://") + 3)
    if (substr(host, 1, 1) == "/") { s = s " " host " "; continue }
    sub(/[\/?#].*$/, "", host); sub(/^.*@/, "", host); sub(/:[0-9]*$/, "", host)
    # In a docs: folder a named host is let through; an IP host is not.
    if (indocs(file) && host ~ /[A-Za-z]/ && host !~ /^\[/) {
      if (mode == "staged") print "notice: " file ":" line ": " tok " let through, in a docs: folder"
      continue
    }
    report(host)
  }
  while (take("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z][A-Za-z]+")) report(tok)
  # A path runs while its characters are path characters, so a value inside an ERE or
  # a format string ends where the pattern syntax begins.
  while (take("[A-Za-z]:\\\\[A-Za-z0-9._@+\\\\-]+")) report(trimend(tok))
  while (take("~[A-Za-z0-9._-]*/[A-Za-z0-9._@+-][A-Za-z0-9._@+/-]*")) report(trimend(tok))
  # An absolute path starts a word: after a space, quote, (, [, =, :, ,, >, ; or |. It
  # has two segments at least, so a slash command (/yggdrasil:wrap) is not a path.
  while (take("[ \t\"'`(=:,[>;|]/[A-Za-z0-9._@+-]+/[A-Za-z0-9._@+-][A-Za-z0-9._@+/-]*"))
    report(trimend(substr(tok, 2)))
  # A letter before it makes a record id, D1.1.1.1, not an address (`facts.md` § *The four fields*).
  while (take("[^0-9.A-Za-z][0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+[^0-9.]"))
    report(substr(tok, 2, length(tok) - 2))
}
