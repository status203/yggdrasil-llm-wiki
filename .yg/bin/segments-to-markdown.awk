# Render segments.tsv into timestamped paragraphs. Driven by segments-to-markdown.sh.
#
# Input is the transcription contract's one output format: start <tab> end <tab> speaker <tab>
# text a line, any field but the text possibly empty. A paragraph closes at the first sentence
# end at or past BUDGET bytes, cutting inside a segment where its boundary offers none. The
# word stream is preserved exactly: every word of every segment is emitted once, in order. Each
# paragraph opens with the [HH:MM:SS] start time of the segment its first word came from, which
# works as a seek handle back into the recording; a segment with no start time gives its
# paragraph no handle rather than an invented one.
#
# A change of speaker closes a paragraph whatever its length, and a paragraph with a speaker is
# labelled after its handle -- [HH:MM:SS] **SPEAKER:** -- since one paragraph holding two people's
# words would attribute half of them wrongly. Where no segment carries a speaker, nothing here
# changes and the paragraphs are the length-budget ones alone.
#
# The rule reads the word stream and the sentence ends and nothing else, so paragraph text is
# identical however the source cut its segments -- measured byte-identical across six structures
# over one word stream, from three words a cue to thirty, tiled, gapped and overlapping. That
# matters because the two producing paths cut differently: Whisper tiles the timeline, Whisper
# with VAD leaves real gaps, and a native YouTube track overlaps so every gap is negative. The
# rule this replaced broke after four segments, which made paragraph shape a direct function
# of the source's cue cadence, and it lost words.
#
# BUDGET is 600, set by the caller. Finer granularity is worth something because of the seek
# handle and coarser is worth nothing, which is the tiebreak that took 600 over 700.
#
# HARD is the fallback for a track carrying no sentence-final punctuation at all -- some ASR
# output has none, and without it the whole transcript becomes one paragraph and the seek
# handle goes with it. It breaks at a word boundary, never inside a word. Twice the budget,
# so that a long sentence spanning the budget is still closed at its end rather than cut: the
# widest overshoot measured on punctuated text is 110 characters, measured before the count became bytes, on a human-authored YouTube
# caption track, which leaves the hard cut at 1200 well clear of what punctuated prose reaches.
#
# POSIX awk: no gensub, no length(array), no ENDFILE (`F18.1.1`). macOS's awk is the floor (`F18.2`) -- checked
# identical under mawk, nawk, busybox awk and gawk --posix. The caller runs it under LC_ALL=C, since gawk
# otherwise counts characters where the others count bytes (`F19.2`).

BEGIN {
    budget = BUDGET + 0
    if (budget <= 0) budget = 600
    hard = budget * 2
    nw = 0
    first = 1
    FS = "\t"
}

NF >= 4 {
    n = split($4, wv, /[ ]+/)
    for (i = 1; i <= n; i++) {
        if (wv[i] == "") continue
        nw++
        word[nw] = wv[i]
        wtime[nw] = ($1 == "" ? "" : int($1 + 0))
        wspk[nw] = $3
    }
}

END {
    para = ""
    ptime = 0
    for (i = 1; i <= nw; i++) {
        if (para != "" && wspk[i] != pspk) emit()
        if (para == "") { para = word[i]; ptime = wtime[i]; pspk = wspk[i] }
        else para = para " " word[i]
        len = length(para)
        if (len >= budget && closes(word[i])) emit()
        else if (len >= hard) emit()
    }
    if (para != "") emit()
}

# A word ends a sentence if it ends in . ! or ? behind any closing quotes or brackets. ] leads
# the bracket expression because that is how POSIX spells a literal one.
function closes(w) {
    return w ~ /[.!?][]'")]*$/
}

# The blank line goes before each paragraph rather than after, so the output carries no
# trailing blank line.
function emit(   hh, mm, ss) {
    if (first) first = 0
    else printf "\n"
    if (ptime != "") {
        hh = int(ptime / 3600)
        mm = int((ptime % 3600) / 60)
        ss = ptime % 60
        printf "[%02d:%02d:%02d] ", hh, mm, ss
    }
    if (pspk != "") printf "**%s:** ", pspk
    printf "%s\n", para
    para = ""
}
