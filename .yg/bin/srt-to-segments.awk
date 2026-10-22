# SRT in, segments.tsv out: one cue a line, start <tab> end <tab> speaker <tab> text, times in
# seconds. The speaker field is always empty: SRT has nowhere to carry one.
#
# Every SRT producer uses it -- a caption track fetched natively, and any adapter whose engine
# answers in SRT -- so the transcription contract's one output format is reached from SRT in
# one place. A cue's lines join with a space, and a tab inside the text becomes one, since a
# tab is the field separator. A cue with no text contributes no line, and input that is not an SRT produces
# nothing at rc=0, which is why a caller tests the output's size rather than the status.
#
# POSIX awk: macOS's awk is the floor (`F18.2`).

/-->/ {
    flush()
    split($0, tf, " ")
    start = seconds(tf[1])
    end = seconds(tf[3])
    text = ""
    intext = 1
    next
}

/^[ \t\r]*$/ {
    flush()
    next
}

intext {
    line = $0
    sub(/\r$/, "", line)
    gsub(/\t/, " ", line)
    text = (text == "" ? line : text " " line)
}

END { flush() }

function flush(   t) {
    if (intext) {
        t = text
        gsub(/^[ ]+|[ ]+$/, "", t)
        if (t != "") printf "%s\t%s\t\t%s\n", start, end, t
    }
    intext = 0
    text = ""
}

# HH:MM:SS,mmm or HH:MM:SS.mmm -> seconds, milliseconds kept.
function seconds(t,   p, ms) {
    ms = 0
    if (match(t, /[,.][0-9]+$/)) { ms = substr(t, RSTART + 1) + 0; t = substr(t, 1, RSTART - 1) }
    split(t, p, ":")
    return sprintf("%.3f", p[1] * 3600 + p[2] * 60 + p[3] + ms / 1000)
}
