---
name: transcribe
description: Transcribe an audio or video file, a local path or a URL, into a markdown transcript in the import/ drop-zone. Use when the user passes a path or a URL and asks for a transcript, or invokes /yggdrasil:transcribe.
---

# Transcribe

`sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/transcribe.sh" "$(git rev-parse --show-toplevel)" <input>` does the whole mechanical half — classifying the input, choosing a caption track or transcribing with the configured engine, and writing the transcript. **Run it; do not reproduce what it does** — it has a dozen ways to fail quietly.

What is left is the decision the script cannot make: what the transcript is *for*.

## Running it

**Run it in the background, or at the longest timeout available.** A local transcription takes minutes to tens of minutes without a GPU, and the default shell timeout is two minutes. The main session moves a call that outlasts it to the background (`F9.2`); nothing establishes that for a dispatch or a headless run, where a call cut off part-way loses the whole spend with nothing written. The caption path returns in seconds, but which path it takes is not known until it runs.

`--consent <tokens>` goes **after the wiki root and before the input**; after the input, the script reads it as a second input and refuses.

On success it prints the transcript's path from the wiki root (`import/<date>-<slug>.md`), then `transcription_source: ` and `pitch: ` lines carrying those values. Everything else it says goes to stderr as it happens.

**Pass its messages on rather than summarising them**, and keep one distinction exactly: *a track was listed and did not come back as SRT* is a failed fetch or a track the script can't read, not an absence. Never report it as the video having no captions.

**Write nothing into the transcript or from it unasked**: it stays the engine's output, as checked, for whoever goes back to it. Everything needed to say what it is is in what the script prints on success.

### What a failure means

Read the stderr line too — it names the input and the cause.

The statuses are grouped by what to do, so an unlisted one reads by its tens — except one above 128, a run killed by a signal the script could not catch, which reads as **51**: cut off part-way.

- **1x — the input, and nothing is wrong with the flow.** 10 usage; 11 neither a local file nor anything yt-dlp accepts; 12 no audio stream (a bare image, a silent screen recording); 13 no speech found, the honest outcome rather than a fault; 14 the input could not be decoded.
- **20 — the engine needs consent.** Its `consent: <token> <what>` line says for what: a download and its size, a credential spent, audio sent off the machine. **Put that to the user** in its own words, and say the re-run redoes the whole job, including re-fetching a remote input. On a yes, re-run with `--consent <token>`, comma-separated after every token already granted for this input — `--consent download,<token>` — since an engine can ask for a second thing once the first is granted, and a re-run carrying only the newest asks for the first again. On a no, nothing further is owed.
- **21 — a dependency is missing or too old**: a tool, `transcribe.engine` absent from the resolved config, or a name with no adapter. It says which.
- **3x — fetching.** 30 the media or its metadata; 31 a download the engine was permitted. The network or the URL, not the recording.
- **4x — the engine.** 40 it failed, and stderr says how — a local engine's own diagnostics, or a server's HTTP status, never its response body; pass that on verbatim and do not characterise it; 41 the adapter broke its contract; 42 the adapter keeps a different contract version. 41 and 42 are the adapter's to fix, not the user's recording's.
- **50 — a defect in the script.** Pass the stderr line on; it names the raw status or the wrong call.
- **51 — interrupted part-way** by a signal. Re-run it in the background; a `.md.part` it left in `import/` is a cut-off transcript, to delete.

Where a run says the engine does not promise silence produces nothing, or gives no timings, repeat it: that is what the configured engine can do, not a fault in this run.

Where the run reports a low words-per-second figure, repeat it. The file is fine and stands; it is the recording that may not carry speech. Where it reports a stretch with nothing transcribed, a transcript ending before the recording, or the same text repeating, repeat that too, with its times where it gives them: the file stands, and that stretch is the one to distrust.

## Disposing of it

The transcript sits in the `import/` drop-zone, which is gitignored — it is not committed from there. Completing the request means disposing of it; don't stop at the path or defer to `/yggdrasil:wrap`. For a one-shot invocation the purpose is usually in the conversation already, so act on it rather than running a triage.

**A page it supports.** Write the page from what the **conversation** holds, citing the transcript as backing. Where the user is really asking for the transcript's *contents* — summarise this talk, what did they say about X — that is a request to read it, which this flow does not do silently: say what it costs, that the transcript will sit in the session's context for the rest of the session and that what you report is a paraphrase of a source nobody will re-read, and let them decide.

**Worth keeping, but there is no full page in it.** Instantiate a `type: placeholder` page at `<Subject>/<Title>.md` from the placeholder template the lookup chain gives — `<Subject>/.templates/placeholder.md` where the subject has one, else `${CLAUDE_PLUGIN_ROOT}/.yg/templates/placeholder.md` (`${CLAUDE_PLUGIN_ROOT}/.yg/templates/README.md`), its meta-text removed as the page is made — pointing at the transcript. Do this in the flow rather than dispatching Bragi (`D7.1.1`). **The pointer is the citation and does not go under a `## Sources` heading.**

**Nothing worth keeping.** Leave it in `import/` and say so. Delete it only if the user asks: it may represent tens of minutes of CPU, and leaving it costs nothing.

**No purpose stated, and nothing in the conversation says what it is for.** Leave it where it is. `/yggdrasil:wrap` names whatever is in `import/`, and that is its pending state.

## The order, on the two keep routes

**The session moves the transcript into `.sources/recordings/` first, and it is cited after** (`D7.2`): `sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/transcribe.sh" "$(git rev-parse --show-toplevel)" --keep import/<file>`, citing the path it prints, which may carry a bumped name. Then, by route:

| Route | The page | Before the commit |
|---|---|---|
| Page | Bragi, briefed with the kept path to cite without opening it; its after-writing steps are its own | its return settled as wrap settles it; one left unsettled cites nothing, so the user chooses the placeholder route or the transcript moved back into `import/`, where wrap's drop-zone check names it as pending |
| Placeholder | the session, from the template | `sh "${CLAUDE_PLUGIN_ROOT}/.yg/bin/regen-views.sh" "$(git rev-parse --show-toplevel)" stale --check`; a row on the placeholder is fixed first, and one on any other page predates the flow and is not its to fix |

**Commit** the flow's work now, once, in the wiki's repo, staging the whole tree:

```sh
git add -A && git diff --cached --stat
```

Check what staged against the flow's own work: the kept transcript, the page or placeholder, and the regenerated views. Anything else — a hand edit, another session's work — name it to the user and leave it for a commit of its own — a hand edit is wrap's to commit, as the session's — with `git restore --staged <path>`.

Commit only if anything staged. Report what the commit contained.
