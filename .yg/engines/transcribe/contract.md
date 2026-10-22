---
role: instruction
pitch: What a transcription adapter must do — contract 1 — for anyone making an engine conform to /yggdrasil:transcribe.
---

# Transcription adapter contract — version 1

An adapter makes one transcription engine usable by `/yggdrasil:transcribe` without editing the flow. It is one POSIX `sh` script, run through `sh`, named `<name>.sh` — `<name>` lowercase letters, digits, `-` and `_` only, since the flow refuses any other (21). `whisper.sh` beside this file is the reference implementation. Why a seam, and why this shape, is `D20.1` and `D20.1.1`.

**Where it lives.** A personal adapter goes in the user layer, the folder `echo "${XDG_CONFIG_HOME:-$HOME/.config}/yggdrasil/engines/transcribe"` prints, and is found before the shipped ones in `<program>/.yg/engines/transcribe/`; `sh <program>/.yg/bin/find-engine.sh transcribe <name>` prints which file a name resolves to. It is selected by name only, never by path, with `transcribe.engine: <name>` in the user layer's config, since which engine runs is a fact about the machine, not the wiki (`D20.1.2.1`). A personal adapter under a shipped name replaces it, at the cost of no longer following the program's changes to that one, and the lookup says so each time. The user-layer directory is unversioned unless you keep it in your own dotfiles. A fork versions its adapter by adding it to its copy of the program, in `.yg/engines/transcribe/`.

`sh <program>/.yg/engines/transcribe/test-engine-contract.sh <wiki> <name> [<speech clip>]` checks the half of this that a script can, resolving the adapter as the flow does; `--adapter <path>` in place of the name tests a draft before it is installed. The rest is below, and holding to it is the adapter's.

## What the flow gives it

- **The program and wiki roots**, as the two arguments after the subcommand. Settings are the adapter's own keys, `transcribe.<name>.*`, read from `<wiki>/.yg/resolved/config.conf`, a flat `key: value` file, with no fallback when a key is missing — except a credential reference, which is keyed by the service it authenticates to and shared with anything else using that service (`D22.1.2`). Programs an adapter may run by path, such as `srt-to-segments.awk`, are in `<program>/.yg/bin/`.
- **Audio** as 16 kHz mono 16-bit WAV. An engine that wants something else, or has a size limit, re-encodes or chunks from it — and returns times measured from the start of the whole recording.
- **`hints.conf`** in the output directory, if present, in the same `key: value` form. Hints are optional: use what the engine can, ignore the rest, and never fail on a key you do not know. Version 1 defines `language`, the source's language code where its metadata gave one, as it gave it, region and all (`en-US`). An absent `language` means the language is unknown: have the engine detect it where it can.
- **`--consent <tokens>`**, comma-separated, when the user has granted what the adapter asked for.

## What it must do

**`<name>.sh check <program> <wiki> [--consent <tokens>]`** confirms the engine is ready — its binary, model, endpoint, or whatever it depends on — without transcribing anything. On success it prints, on stdout:

```
contract: 1
timestamps: yes|no
speakers: yes|no
silence_safe: yes|no
```

- `timestamps` — segments carry start times. Without them the transcript has no seek handles, and the flow cannot report a stretch the engine dropped or a transcript that stops before the recording does.
- `speakers` — segments can carry a speaker.
- `silence_safe` — **a recording with no speech produces no segments**, rather than invented text. Declare `yes` only where the engine holds to it; `no` makes the flow warn on every run. It is the one guarantee the flow cannot check for itself.

**`<name>.sh run <program> <wiki> [--consent <tokens>] <in.wav> <out-dir>`** transcribes, writing two files into `<out-dir>`:

- **`segments.tsv`** — one segment a line, four tab-separated fields: `start`, `end`, `speaker`, `text`. Times are seconds, decimals allowed. A field the engine does not produce is left empty; the text never is. Tabs and newlines are removed from the text. **No speech is an empty file and success**, never an invented line and never a failure.
- **`meta.conf`** — `model_requested: <what was asked for>`, and `model_reported: <what ran>` where the engine or service says. The flow records the reported one where they differ, with the request beside it. Any other `key: value` line is the adapter's to add, and the flow ignores one it does not read.

**Consent.** Anything the user should agree to first — a download, spending a credential, sending audio off the machine — is asked, never done: print `consent: <token> <what, and how much>` on stdout and exit 20. The flow shows the line, and the re-run carries `--consent <token>` beside every token granted before it. Ask for everything a run will need in one line where you can — whisper's one `download` covers both its models — so the user is asked once. `check` and `run` ask on the same terms.

**An error from a service is reported by its status and a characterisation, never its body**, whether or not a credential was sent: a body can echo a key back (`D22.1.4`, `D22.2.2`), and it is a third party's text reaching the session.

**A credential never reaches stdout or stderr.** Its reference is expanded inside the command that spends it (`D22.1`), a service's error is reported as above, and no verbose or trace flag is used. The consent line names the service and what will be spent, never the value — stderr is passed to the user verbatim.

**Stdout carries only the lines above.** The engine's own output is captured or discarded, its diagnostics alone reaching stderr, and **the transcript is never printed** — whatever reaches stdout or stderr can reach the session's context, and no engine or script reads a transcript.

**Exit statuses** — only these:

| Status | Meaning | May exit it |
| --- | --- | --- |
| 0 | done | `check`, `run` |
| 10 | usage — only a wrong call from the flow causes it, and the flow reports it as its own defect | `check`, `run` |
| 14 | the engine could not decode the input | `run` |
| 20 | consent needed — the `consent:` line says for what | `check`, `run` |
| 21 | a dependency is missing or too old, or a setting the adapter needs is absent from resolved config — say which on stderr | `check`, `run` |
| 31 | a download that was consented to failed | `check`, `run` |
| 40 | the engine failed — its status on stderr, and a local engine's own diagnostics; a service's, its status alone | `check`, `run` |

The flow reads any other status, and success with no `segments.tsv`, as the adapter breaking its contract. An engine's own exit number is never passed through: it would land on one of these and mean something else (`F20.5`).

## What it need not do

Fetching the media, trying a caption track first, normalising the audio, checking what came back, rendering paragraphs and speaker labels, the provenance string, the frontmatter, asking the user and placing the transcript are all the flow's.

## Versions

`contract: 1` is what this file describes. A change that adds, changes or removes a requirement on either side, something new asked of an adapter or something the flow stops giving it, raises the number, and the flow refuses an adapter declaring another, naming it — so a program commit that raises it is one a personal or fork's adapter has to be brought up to, rather than one that applies on its own. A key either side may ignore, a hint, an adapter's own setting or a `meta.conf` line, is added without raising it.
