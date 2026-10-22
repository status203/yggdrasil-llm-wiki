---
type: progression/tutorial
pitch: A four-step tutorial on the Lucena position, the rook-and-pawn-against-rook endgame the side with the pawn wins by building a bridge.
volatility: low
checkpoint: 2026-10-03
---

# Lucena position tutorial

Four steps on the Lucena position: recognising it, why its cut-off king matters, building the bridge that wins it, and where the method applies and where it stops. Each step ends with a position to try.

## Step 1 — Recognising the Lucena position

This step covers what the Lucena position is and how to tell when you have one in front of you. It places it in the endgame it belongs to, shows the standard position, and breaks that position into five features you can check on any board. Then you sort three positions that look close, and finish with one to try on your own. Nothing here is about how to win it yet; that is step 3. Recognition comes first, because the winning method is only worth knowing if you can spot the moment to use it.

### The endgame

The Lucena position comes from one of the most common endgames in practice: rook and pawn against rook. White has a king, a rook and one pawn; Black has a king and a rook. Whether that extra pawn is enough to win depends almost entirely on where the pieces stand, and the Lucena is the classic arrangement in which it is: the side with the pawn has a known, reliable way through. It is named after Luis Ramírez de Lucena, a Spanish chess writer of the late fifteenth century.

One thing changes from the opening. The [[Opening principles]] have you castle early, to tuck the king away while the board is full of pieces that could attack it. With most of those pieces gone, the king stops being something to hide and becomes a piece that fights. In the Lucena, White's king stands right in front of its own pawn, and the whole position turns on getting it out of the way.

A reminder on notation, since later steps use it: `+` after a move means it gives check, and a move number followed by three dots, such as `1...Rc1`, is a move by Black. The diagrams have White at the bottom, so White's pawn moves up the board.

### The standard position

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 1: White king d8, pawn d7, rook f1; Black king g7, rook c2; the f-file shaded">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="220" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 1 — the standard Lucena position, White to move. The shaded file is the f-file, which White's rook on f1 controls.*
FEN: `3K4/3P2k1/8/8/8/8/2r5/5R2 w - - 0 1`

This is the position the rest of the tutorial works from. White's pawn is on d7, one square from promoting. White's king is on d8, the very square the pawn needs. Black's king is on g7, on the far side of the f-file, and Black's rook is on c2. White's rook is on f1.

The pawn cannot move while its own king stands on d8, so the king has to step aside. That is the whole problem, and the five features below are what make it solvable.

The line under each diagram is its FEN, the one-line text record of a chess position. Paste it into any analysis board you already use, or read it to set the position up on a real board.

### The five features

A position is a Lucena when all five of these hold. Check each against Diagram 1 as you read.

1. **The pawn is on its seventh rank, and not on an edge file.** For White, the seventh rank is the one just short of promotion: here, d7. A pawn on the a- or h-file is ruled out, because the king in front of it has only one side to step out on.

2. **The attacking king stands on the square in front of its pawn**, the promotion square: here, d8. It protects the pawn and holds the square the pawn is heading for, but it is also standing in the pawn's way.

3. **The defending king is cut off from the pawn by the attacking rook along a file.** A rook controls every square on its file, and a king can never move onto an attacked square, so a rook's file is a wall the king cannot cross. Here, White's rook holds the f-file and Black's king is on the far side of it. The file has to lie *between* the defending king and the pawn: a rook on the f-file cuts nothing off if the black king is already on the pawn's side of it. Step 2 is about why this feature matters so much.

4. **The defending rook stops the king leaving on the other side.** White's king has two ways off d8: towards the c-file or towards the e-file. Black's rook on c2 controls the whole c-file, c7 and c8 included, so that way is shut. That leaves the e-file side, which the black king cannot reach because of feature 3. But the moment White's king steps out, Black's rook can swing round behind it and give check: from c2 to e2 would check a king on e7. Dealing with those checks is what building the bridge is for.

5. **The attacking rook is free to move.** It is not guarding anything else and nothing is attacking it, so it can travel up and down its file without letting the black king through. In step 3 that freedom is the technique: the rook moves to a square from which it can later block Black's checks.

That is the whole checklist. Notice what it is about: where the pieces stand relative to each other, not which squares they stand on. Black's king could be on h8 instead of g7, Black's rook on c6 instead of c2, and it would still be a Lucena, because all five relations would still hold.

### Sorting near-misses

Each of the next three positions is close to Diagram 1. Run the checklist on each and decide: Lucena, or not yet, meaning at least one of the five features is missing. Then open the answer.

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 2: White king d8, pawn d7, rook g2; Black king h6, rook c1">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="280" cy="260" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="280" y="266" fill="#222222">R</text>
<circle cx="320" cy="100" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="320" y="106" fill="#ffffff">K</text>
<circle cx="120" cy="300" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="306" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 2 — White to move.*
FEN: `3K4/3P4/7k/8/8/8/6R1/2r5 w - - 0 1`

> [!question]- Diagram 2: Lucena or not yet?
> **Lucena.** Three pieces have moved from Diagram 1, but every relation has held. The pawn is on d7 with the king in front of it; Black's rook, now on c1, still holds the c-file; White's rook is free. The cut-off now runs along the g-file instead of the f-file, with Black's king shut on the h-file, further from the pawn than before. A rook holding any file between the defending king and the pawn meets feature 3.

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 3: White king a8, pawn a7, rook f1; Black king g7, rook b2">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="40" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="40" y="26" fill="#222222">K</text>
<circle cx="40" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="40" y="66" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="80" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="80" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 3 — White to move.*
FEN: `K7/P5k1/8/8/8/8/1r6/5R2 w - - 0 1`

> [!question]- Diagram 3: Lucena or not yet?
> **Not yet.** Feature 1 fails: the pawn is on the a-file, the edge of the board. Everything else looks right, but from a8 White's king has only two squares to step out to, b8 and b7, and both are on the b-file that Black's rook controls. There is no second side to leave by. Unlike the other near-misses, this one is not a small adjustment away from a Lucena: the edge file is the problem itself, and step 4 comes back to it.

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 4: White king d8, pawn d7, rook f1; Black king e6, rook c2">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="200" cy="100" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="200" y="106" fill="#ffffff">K</text>
<circle cx="120" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 4 — White to move.*
FEN: `3K4/3P4/4k3/8/8/8/2r5/5R2 w - - 0 1`

> [!question]- Diagram 4: Lucena or not yet?
> **Not yet.** Feature 3 fails. White's rook is on the f-file, exactly as in Diagram 1, but Black's king is on e6, on the pawn's side of that file, so the rook cuts nothing off. The black king already covers e7, one of the squares White's king would step out to, and it is attacking the pawn too; only White's king on d8 is holding it. A rook on the right file is not enough: the defending king has to be on the far side of it. Step 2 looks at what a nearby defending king does.

### Try one

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 5: White king d7, pawn d6, rook f1; Black king g7, rook c2">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">K</text>
<circle cx="160" cy="100" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="106" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 5 — White to move. Lucena or not yet? Decide before you open the answer.*
FEN: `8/3K2k1/3P4/8/8/8/2r5/5R2 w - - 0 1`

> [!question]- Diagram 5: answer
> **Not yet.** Feature 1 fails, by one rank: the pawn is on d6, its sixth rank, not its seventh. Everything else holds. White's king is on the square in front of the pawn, Black's king is cut off behind the f-file, Black's rook holds the c-file, and White's rook is free, which is what makes it tempting. Move the pawn up to d7 and the king up to d8 and you have Diagram 1 exactly. If you called it a Lucena, go back to feature 1: the seventh rank is part of the definition, not a detail.

## Step 2 — Why the cut-off matters

This step covers why the cut-off is the feature the whole Lucena turns on. It shows why White's king is stuck in front of its own pawn, which squares it needs to get out, and what the defending king does to those squares when it stands close enough. You'll see the standard position beside a version with Black's king one file nearer, and finish with one position to try. There are still no winning moves here; those are step 3. This step is why they work.

### A king in its own pawn's way

A pawn moves only straight forward. White's pawn on d7 has one square to go to, d8, and White's own king is standing on it. Until the king moves, the pawn can't.

So the king has to step off d8, and it has very few places to go. A king in the middle of the board touches eight squares, but d8 is on the edge, so it touches only five: c8, c7, d7, e7 and e8. The pawn is on d7. Every way out is sideways, onto the c-file or the e-file.

Sideways is also the right direction. From c7, c8, e7 or e8 the king still stands next to both the pawn and d8, so it keeps protecting the pawn and guarding the square it promotes on. Stepping out costs White nothing, as long as there is a square to step to.

Black's rook settles half of that. Standing on the c-file, it attacks c7 and c8, and a king can never move onto an attacked square. That leaves two squares, e7 and e8, and the whole position depends on them.

### Two positions side by side

<svg xmlns="http://www.w3.org/2000/svg" width="620" height="319" viewBox="0 0 710 365" role="img" aria-label="Diagrams 6 and 7 side by side. Diagram 6: White king d8, pawn d7, rook f1; Black king g7, rook c2; the f-file shaded; e7 and e8 marked open, c7 and c8 marked shut. Diagram 7: White king d8, pawn d7, rook e1; Black king f7, rook c2; the e-file shaded; c7, c8, e7 and e8 all marked shut">
<g font-family="sans-serif" font-size="14" font-weight="bold" fill="#333333" text-anchor="middle"><text x="180" y="16">Diagram 6</text><text x="550" y="16">Diagram 7</text></g>
<g transform="translate(0,25)">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="220" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<rect x="183" y="3" width="34" height="34" fill="none" stroke="#1e8449" stroke-width="4"/>
<rect x="183" y="43" width="34" height="34" fill="none" stroke="#1e8449" stroke-width="4"/>
<rect x="103" y="3" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M109 9L131 31M131 9L109 31" stroke="#c0392b" stroke-width="4"/>
<rect x="103" y="43" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M109 49L131 71M131 49L109 71" stroke="#c0392b" stroke-width="4"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="266" fill="#ffffff">R</text>
</g>
</g>
<g transform="translate(370,25)">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="180" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<rect x="103" y="3" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M109 9L131 31M131 9L109 31" stroke="#c0392b" stroke-width="4"/>
<rect x="103" y="43" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M109 49L131 71M131 49L109 71" stroke="#c0392b" stroke-width="4"/>
<rect x="183" y="3" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M189 9L211 31M211 9L189 31" stroke="#c0392b" stroke-width="4"/>
<rect x="183" y="43" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M189 49L211 71M211 49L189 71" stroke="#c0392b" stroke-width="4"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="200" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="306" fill="#222222">R</text>
<circle cx="240" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="240" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="266" fill="#ffffff">R</text>
</g>
</g>
</svg>

*Diagram 6 (left) — the standard position, White to move. Diagram 7 (right) — Black's king one file nearer, with White's rook holding the e-file. The shaded file is the one White's rook holds. A green outline marks a square White's king can step to; a red outline with a cross marks one it can't.*
FEN, Diagram 6: `3K4/3P2k1/8/8/8/8/2r5/5R2 w - - 0 1`
FEN, Diagram 7: `3K4/3P1k2/8/8/8/8/2r5/4R3 w - - 0 1`

Diagram 6 is Diagram 1 from step 1 with the exits marked. Black's rook shuts c7 and c8. Nothing Black has reaches e7 or e8: the rook is on the c-file and the second rank, and Black's king on g7 is two files away. White's king can step out to either.

Diagram 7 moves Black's king one file nearer, to f7. It can't stand on the f-file with White's rook still on f1, because that would be check, so the rook moves over to e1 and the wall runs along the e-file instead. Run step 1's checklist on it and every feature still holds: the pawn on d7, the king in front of it, the defending king cut off by a rook's file, Black's rook holding the c-file, White's rook free. By the checklist, this is a Lucena too.

Now look at White's king. Black's rook still shuts c7 and c8. But e7 and e8 both touch Black's king on f7, and two kings can never stand on neighbouring squares, so every square around a king is closed to the other one. White's king has no legal move at all, and its pawn can't move either. Only the rook can.

### What the wall does and doesn't do

The difference between the two diagrams is the lesson of this step. A rook's file stops the defending king *crossing* it. It doesn't stop the king *reaching over* it: a king standing right beside the wall still covers the squares on the far side.

In Diagram 6 the wall is the f-file, so Black's king can only ever stand on the g- or h-file. From there the nearest squares it can touch are on the f-file, and the e-file is beyond its reach however it moves. e7 and e8 stay open for as long as the rook holds the f-file, not just for this move.

In Diagram 7 the wall is the e-file itself, the very file White's king needs to step onto. The f-file beside it is open to Black's king, and from f7 it covers e6, e7 and e8 without ever crossing.

So the cut-off that matters isn't just "a rook's file between the king and the pawn". It has to keep the defending king away from the squares beside the pawn, the ones the attacking king steps out to. Step 1's checklist says the defending king must be cut off; this step says how far. With the pawn on d7 and Black's king on the kingside, a wall on the f-file does it, as does one further out, like the g-file wall in step 1's Diagram 2.

Step 1's Diagram 4 was the far end of the same scale: no wall between the king and the pawn at all, and Black's king on e6 not only covering e7 but attacking the pawn.

What White does in Diagram 7 is a longer story. Its first job is to drive Black's king at least a file further off, usually with a check from the rook, and Black has more than one way to answer; following those lines is beyond this tutorial. Step 3 starts from Diagram 6, where e7 and e8 are already open, so the winning method can begin on the first move.

### Try one

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 8: White king d8, pawn d7, rook e1; Black king g7, rook c2">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="200" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 8 — White to move. Can White's king step out of d8 this move, and if so, to which squares? Is there any reason to do it now rather than later? Decide before you open the answer.*
FEN: `3K4/3P2k1/8/8/8/8/2r5/4R3 w - - 0 1`

> [!question]- Diagram 8: answer
> **Yes, to e7 or e8.** Black's rook still shuts c7 and c8, but Black's king on g7 touches f6, f7 and f8 and nothing on the e-file. The wall is on the e-file, as in Diagram 7; what has changed is where the king behind it stands. The wall alone doesn't decide it: the king's distance does.
>
> **And there is a reason not to wait.** With the wall on the e-file, nothing stops Black's king walking to the f-file. If it reaches f7 while White's king is still on d8, White's king is shut in exactly as in Diagram 7. Stepping out now uses the squares while they are open. In Diagram 6 the question never comes up, because a wall on the f-file keeps Black's king off f7 altogether.
>
> If you answered "no", look again at the squares around g7: a king reaches one square in every direction, and from g7 that stops at the f-file.

## Step 3 — Building the bridge

This step covers the winning method: how White, from the standard position, builds the bridge in six moves and frees its pawn to promote. The line comes in four stages, and the step gives you four ways to hold it in mind, each where it fits: a stage list to say, a reason for every move, Black's side of it, and a picture. A short paragraph gathers them at the end, and the try-one asks you to say the stages from memory before you work out the moves.

The whole line, to come back to: `1.Rf4 Rc1 2.Ke7 Re1+ 3.Kd6 Rd1+ 4.Ke6 Re1+ 5.Kd5 Rd1+ 6.Rd4`. To step through it one move at a time, open [the bridge, move by move](lucena-position-tutorial--bridge.html); it opens in your web browser rather than in Obsidian. The diagrams below carry the same line without it.

### Four stages

The line splits into four stages, each with a two-word name: **rook up, king out, king down, rook across**. Say them once now. The walkthrough takes them one at a time, and the names are what you'll say to yourself at the board.

<svg xmlns="http://www.w3.org/2000/svg" width="620" height="319" viewBox="0 0 710 365" role="img" aria-label="Diagrams 9 and 10 side by side. Diagram 9: White king d8, pawn d7, rook f1; Black king g7, rook c2; the f-file shaded; an arrow from f1 to f4. Diagram 10: White king d8, pawn d7, rook f4; Black king g7, rook c1; the f-file shaded; e7 and e8 marked open, c7 and c8 marked shut">
<g font-family="sans-serif" font-size="14" font-weight="bold" fill="#333333" text-anchor="middle"><text x="180" y="16">Diagram 9</text><text x="550" y="16">Diagram 10</text></g>
<g transform="translate(0,25)">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="220" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<line x1="240" y1="292" x2="240" y2="197" stroke="#2c3e50" stroke-width="5" stroke-opacity="0.85"/><polygon points="240,184 248,197 232,197" fill="#2c3e50" fill-opacity="0.85"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="266" fill="#ffffff">R</text>
</g>
</g>
<g transform="translate(370,25)">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="220" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<rect x="183" y="3" width="34" height="34" fill="none" stroke="#1e8449" stroke-width="4"/>
<rect x="183" y="43" width="34" height="34" fill="none" stroke="#1e8449" stroke-width="4"/>
<rect x="103" y="3" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M109 9L131 31M131 9L109 31" stroke="#c0392b" stroke-width="4"/>
<rect x="103" y="43" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M109 49L131 71M131 49L109 71" stroke="#c0392b" stroke-width="4"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="240" cy="180" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="186" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="300" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="306" fill="#ffffff">R</text>
</g>
</g>
</svg>

*Diagram 9 (left) — the standard position, White to move; the arrow is White's first move. Diagram 10 (right) — after 1.Rf4 Rc1. The key is step 2's: the shaded file is the one White's rook holds, a green outline marks a square White's king can step to, and a red outline with a cross marks one it can't.*
FEN, Diagram 9: `3K4/3P2k1/8/8/8/8/2r5/5R2 w - - 0 1`
FEN, Diagram 10: `3K4/3P2k1/8/8/5R2/8/8/2r5 w - - 0 1`

### Rook up

**1.Rf4.** The rook climbs its own file to the fourth rank. It is still on the f-file, so the wall from step 2 still stands and Black's king still can't reach e7 or e8. What the move gains is a square from which the rook can later slide along the fourth rank to d4, where the bridge will go.

Why the fourth rank? The rook will end the checks by stepping in front of White's king, and it can only do that safely on a square the king protects, so the king will walk down to stand just above it. That walk is why the rook shouldn't go lower: the lower the rook, the further the king has to walk. It shouldn't go higher either, because higher is nearer Black's king. On f6 the rook would stand next to g7 and simply be taken. On f5, one king step, to g6, attacks it, and White must spend a move saving it or lose it. From g7, Black's king can't attack f4 in one move: it would need g6 and then g5. The fourth rank is as near as the rook can stand while out of that reach.

In the main line Black waits: **1...Rc1**, keeping its rook on the c-file, so c7 and c8 stay shut (Diagram 10).

### King out

**2.Ke7.** The king steps out onto the square the cut-off kept open, which is what step 2 was about. From e7 it still touches both d7 and d8, so the pawn is protected and its square is free. White threatens 3.d8=Q.

**2...Re1+.** Step 1 warned that this was coming: once the king leaves d8, Black's rook swings round behind it. Seen from Black's side, White is threatening to promote, and each check makes White answer it instead. The rook checks from far down the board because that is where it is safe: a rook that checks from the square next to White's king is simply taken.

### King down

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 11: White king d6, pawn d7, rook f4; Black king g7, rook e1; the f-file shaded">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="220" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="100" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="106" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="240" cy="180" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="186" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="200" cy="300" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="200" y="306" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 11 — after 3.Kd6, Black to move. White's king has stepped off the e-file and still stands beside its pawn; the next check comes up the d-file.*
FEN: `8/3P2k1/3K4/8/5R2/8/8/4r3 b - - 0 1`

**3.Kd6 Rd1+ 4.Ke6 Re1+ 5.Kd5.** Each check comes up a file, and each time the king steps off that file, and down towards its rook when it can. The king can't stop the checks itself, so it walks towards the one piece that can.

The zigzag has a reason too. On move 4, Black's rook is on d1, on the pawn's own file and behind it, so the king stays beside the pawn on e6 rather than going on down to the fifth rank and leaving the pawn to the rook. On move 5 the rook is on e1, off the pawn's file, so the king can leave the pawn and go to d5, right above d4.

From Black's side, the checks have switched between the d- and e-files, all from the first rank. White's rook has been waiting on the fourth rank, across both of those files.

### Rook across

**5...Rd1+ 6.Rd4.** The rook slides across the fourth rank and stands between Black's rook and the king, and the king on d5 protects it. That is the bridge.

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 12: White king d5, pawn d7, rook d4; Black king g7, rook d1; the rook's route drawn from f1 up to f4 and across to d4; the king's route drawn from d8 by e7, d6 and e6 to d5">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<polyline points="240,300 240,180 190,180" fill="none" stroke="#2c3e50" stroke-width="5" stroke-opacity="0.85" stroke-linejoin="round" stroke-linecap="round"/><polygon points="177,180 190,172 190,188" fill="#2c3e50" fill-opacity="0.85"/><circle cx="240" cy="180" r="6" fill="#2c3e50" fill-opacity="0.85"/>
<polyline points="160,20 200,60 160,100 200,100 181.2,118.8" fill="none" stroke="#2c3e50" stroke-width="5" stroke-opacity="0.85" stroke-linejoin="round" stroke-linecap="round"/><polygon points="172,128 175.6,113.1 186.9,124.4" fill="#2c3e50" fill-opacity="0.85"/><circle cx="200" cy="60" r="6" fill="#2c3e50" fill-opacity="0.85"/><circle cx="160" cy="100" r="6" fill="#2c3e50" fill-opacity="0.85"/><circle cx="200" cy="100" r="6" fill="#2c3e50" fill-opacity="0.85"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="140" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="146" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="160" cy="180" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="186" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="160" cy="300" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="160" y="306" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 12 — the finished bridge after 6.Rd4, Black to move, with the whole route drawn in: the rook up from f1 to f4 and across to d4, and the king from d8 by e7, d6 and e6 to d5. Each dot is a square a piece stopped on.*
FEN: `8/3P2k1/8/3K4/3R4/8/8/3r4 b - - 0 1`

From Black's side, the rook now has no open line left to check along. The d-file is blocked at d4, and the e-file is open but the king isn't on it. Its one remaining check is to take the bridge, and that is the try you are most likely to meet: **6...Rxd4+ 7.Kxd4.** White's rook was also the wall, so Black's king can now cross the f-file. It is too late, and step 2 is why: from g7, Black's king needs two moves to reach a square beside d8, and the pawn needs one. After 7...Kf7 8.d8=Q, White has a queen against a lone king. Anything else on move 6 is met by 7.d8=Q at once.

Diagram 12 is also the step's picture, and the name gives it to you. The rook is a bridge laid across the board, and White's king walks down onto it; the checks come up from below and strike the bridge instead of the king. If you keep one image of this step, keep this one: the two routes are the whole line.

### Holding it in mind

The four ways, together. **Say the stages:** rook up, king out, king down, rook across. **If the list slips, rebuild it from the reasons:** the king steps out onto the square the cut-off keeps open; the checks come from behind, the one safe place for Black's rook; the king walks towards the piece that can stop them, keeping beside its pawn while Black's rook is on the pawn's file; and the rook waits on the fourth rank, the highest one Black's king can't reach in a move, to block on a square its king protects. **From Black's side,** the checks end when the rook has no open line left. **And the picture** is Diagram 12: a bridge across the fourth rank, with the king standing on it.

### Try one

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 13: White king d8, pawn d7, rook f1; Black king h7, rook c3">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="160" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="26" fill="#222222">K</text>
<circle cx="160" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="160" y="66" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="320" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="320" y="66" fill="#ffffff">K</text>
<circle cx="120" cy="220" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="120" y="226" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 13 — White to move. Before you work out a single move, say the four stages from memory. Then write down White's moves, taking Black's first reply as 1...Kg7 and having Black check from a distance whenever it can after that. Decide before you open the answer.*
FEN: `3K4/3P3k/8/8/8/2r5/8/5R2 w - - 0 1`

> [!question]- Diagram 13: answer
> **The stages:** rook up, king out, king down, rook across.
>
> **The moves:** 1.Rf4 Kg7 2.Ke7 Re3+ 3.Kd6 Rd3+ 4.Ke6 Re3+ 5.Kd5 Rd3+ 6.Rd4.
>
> Black's rook starts on c3 instead of c2 and its king on h7 instead of g7, but step 1's checklist still holds, and White's moves are exactly the main line's. Only Black's checks change, coming from the third rank instead of the first. If Black takes the bridge, 6...Rxd4+ 7.Kxd4, the pawn still promotes, as in the main line. That is why the stages are worth learning rather than the squares: they don't depend on where Black's pieces start.
>
> If the stages came but the moves didn't, go back to the reasons under "Holding it in mind". If the moves came but the stages didn't, say them again now, before step 4 asks for them.

## Step 4 — Where it applies and where it doesn't

This step covers how far the bridge reaches. You'll run step 3's four stages on the mirrored board and on another file, see why a pawn on the edge file breaks the method, and meet the defences that take over when the defending king isn't cut off, named here but not taught. There is nothing new to memorise: the step tests the stages and the picture you already have, in places you haven't seen them. It ends on when to aim for a Lucena and when not to.

### The mirrored board

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 14: White king e8, pawn e7, rook c1; Black king b7, rook f2; the c-file shaded">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="100" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="200" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="26" fill="#222222">K</text>
<circle cx="200" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="66" fill="#222222">P</text>
<circle cx="120" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="120" y="306" fill="#222222">R</text>
<circle cx="80" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="80" y="66" fill="#ffffff">K</text>
<circle cx="240" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="240" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 14 — the standard position in a mirror, White to move. The key is step 2's: the shaded file is the one White's rook holds, here the c-file.*
FEN: `4K3/1k2P3/8/8/8/8/5r2/2R5 w - - 0 1`

Diagram 14 is Diagram 1 with left and right swapped. The pawn is on e7 with its king on e8, Black's king is on b7 behind a wall on the c-file, and Black's rook holds the f-file. Run step 1's checklist and all five features hold. It is a Lucena on a new file and on the other side of the board at once.

Before you read on, say the four stages. Then picture Diagram 12's bridge on this board: which square does White's rook block on, and where does White's king stand above it?

> [!question]- Diagram 14: the bridge
> **Rook up:** 1.Rc4, up its own file to the fourth rank. **King out:** Black's rook shuts f7 and f8, so the open side is the d-file: 2.Kd7. **King down:** the same zigzag, between the d- and e-files, ending on e5. **Rook across:** the rook slides right along the fourth rank to e4, and the king on e5 protects it.
>
> The whole line: 1.Rc4 Rf1 2.Kd7 Rd1+ 3.Ke6 Re1+ 4.Kd6 Rd1+ 5.Ke5 Re1+ 6.Re4.

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 15: White king e5, pawn e7, rook e4; Black king b7, rook e1; the rook route drawn from c1 up to c4 and across to e4; the king route drawn from e8 by d7, e6 and d6 to e5">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<polyline points="120,300 120,180 170,180" fill="none" stroke="#2c3e50" stroke-width="5" stroke-opacity="0.85" stroke-linejoin="round" stroke-linecap="round"/><polygon points="183,180 170,172 170,188" fill="#2c3e50" fill-opacity="0.85"/><circle cx="120" cy="180" r="6" fill="#2c3e50" fill-opacity="0.85"/>
<polyline points="200,20 160,60 200,100 160,100 178.8,118.8" fill="none" stroke="#2c3e50" stroke-width="5" stroke-opacity="0.85" stroke-linejoin="round" stroke-linecap="round"/><polygon points="188,128 184.4,113.1 173.1,124.4" fill="#2c3e50" fill-opacity="0.85"/><circle cx="160" cy="60" r="6" fill="#2c3e50" fill-opacity="0.85"/><circle cx="200" cy="100" r="6" fill="#2c3e50" fill-opacity="0.85"/><circle cx="160" cy="100" r="6" fill="#2c3e50" fill-opacity="0.85"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="200" cy="140" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="146" fill="#222222">K</text>
<circle cx="200" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="66" fill="#222222">P</text>
<circle cx="200" cy="180" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="186" fill="#222222">R</text>
<circle cx="80" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="80" y="66" fill="#ffffff">K</text>
<circle cx="200" cy="300" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="200" y="306" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 15 — the finished bridge on the mirrored board, after 6.Re4, Black to move: Diagram 12 in a mirror. The rook went up from c1 to c4 and across to e4; the king went from e8 by d7, e6 and d6 to e5.*
FEN: `8/1k2P3/8/4K3/4R3/8/8/4r3 b - - 0 1`

What flipped is left and right: the king steps out to the left, and the rook slides to the right. What didn't flip is up and down. The rook still stops on the fourth rank, the king still stands one rank above it, and the bridge still goes on the pawn's own file. Step 3's reasons all carry over, because each is about where the pieces stand relative to each other: the king steps onto the side the cut-off keeps open, the checks come from behind, and the rook blocks on a square its king protects.

One thing does turn over if you have the pawn as Black: the board, since your pawn runs down it. Count ranks from your own side. Your pawn's seventh rank is the board's second, and your rook's fourth is the board's fifth.

### Other files

A pawn on the b-, c-, f- or g-file is won the same way. The rook climbs its own file to the fourth rank and later slides across to the pawn's file; the king steps out on the side away from Black's rook and zigzags down to stand above it. Whether you have a Lucena at all is step 1's checklist, with step 2's reading of feature 3: the wall has to keep the defending king off the squares beside the pawn, not just somewhere across a file. For a pawn on c7, with Black's king on the kingside, those squares are on the d-file, so the wall has to be on the e-file or further out. The try-one below is that position.

### The edge file

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 16: White king a8, pawn a7, rook f1; Black king g7, rook b2; the f-file shaded; b8 and b7 marked shut">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="220" y="0" width="40" height="320" fill="#3a7bd5" fill-opacity="0.3"/>
<rect x="63" y="3" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M69 9L91 31M91 9L69 31" stroke="#c0392b" stroke-width="4"/>
<rect x="63" y="43" width="34" height="34" fill="none" stroke="#c0392b" stroke-width="4"/><path d="M69 49L91 71M91 49L69 71" stroke="#c0392b" stroke-width="4"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="40" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="40" y="26" fill="#222222">K</text>
<circle cx="40" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="40" y="66" fill="#222222">P</text>
<circle cx="240" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="240" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="80" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="80" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 16 — step 1's Diagram 3 again, White to move, marked with step 2's key: the shaded file is the one White's rook holds, and a red outline with a cross marks a square White's king can't step to.*
FEN: `K7/P5k1/8/8/8/8/1r6/5R2 w - - 0 1`

Step 1 sorted this position as "not yet" and said it would come back to it. Now you can say why the bridge can't help.

The bridge answers the checks that come once the king is out. Here the king never gets out. In the standard position White's king had two sides to step out on: Black's rook shut one, and White's rook kept the other open. From a8 there is only one side, because the a-file is the edge of the board. Black's rook shuts it, b7 and b8 both, and that leaves White's rook nothing to keep open. It still holds the f-file and Black's king is still cut off, but the cut-off was only ever worth having because it guarded the open side.

So none of the four stages starts: there is no king out for the rook up to prepare. How boxed in is White's king? Try 1.Rb1, offering a trade of rooks. Black has no reason to decline: the rook on b2 is attacked, and 1...Rxb1 draws on the spot, because White is stalemated.

Stalemate is when the side to move has no legal move but isn't in check, and it ends the game as a draw. Check each part against the position after 1...Rxb1. The pawn on a7 can't move, because White's own king is standing on a8, its promotion square. The king is in the corner, so it touches only three squares: a7, b7 and b8. Its own pawn is on a7, and Black's rook on b1 controls the whole b-file, b7 and b8 included. And the king isn't in check, because the rook is on the b-file and the king is on the a-file. White is to move, has no legal move, and isn't in check.

That is the edge file's doing. A king on d8 in front of a d7 pawn has squares on both the c-file and the e-file, and one rook can shut only one side. In the corner, the edge of the board has already removed one side, so a single rook on the b-file removes everything else.

With a pawn on the edge file, whether White can win at all depends on a different plan, and mostly on how far away the defending king is. Often it can't. This tutorial doesn't go there.

### When the defending king isn't cut off

Step 1's Diagram 4 and step 2's Diagram 7 showed the other way it fails: Black's king close enough to cover the squares White's king needs. That isn't a Lucena, and the bridge doesn't apply. The defender has methods of its own, and two have names worth knowing.

The **Philidor position**, named after François-André Danican Philidor, the eighteenth-century French player and composer, is the standard draw when the defending king reaches the square in front of the pawn. The **defence by checks from the side** has the defending rook go a long way off and check White's king along the ranks rather than from behind, and it can hold some positions where Black's king is near the pawn but not in front of it. Each is a topic of its own, and this tutorial doesn't teach either. What matters here is the signal: once the defending king gets to the pawn first, you are no longer playing for a Lucena.

### Try one

<svg xmlns="http://www.w3.org/2000/svg" width="340" height="340" viewBox="0 0 340 340" role="img" aria-label="Diagram 17: White king c8, pawn c7, rook e1; Black king g7, rook b2">
<rect x="20" y="0" width="320" height="320" fill="#f0d9b5"/>
<path fill="#b58863" d="M60 0h40v40h-40z M140 0h40v40h-40z M220 0h40v40h-40z M300 0h40v40h-40z M20 40h40v40h-40z M100 40h40v40h-40z M180 40h40v40h-40z M260 40h40v40h-40z M60 80h40v40h-40z M140 80h40v40h-40z M220 80h40v40h-40z M300 80h40v40h-40z M20 120h40v40h-40z M100 120h40v40h-40z M180 120h40v40h-40z M260 120h40v40h-40z M60 160h40v40h-40z M140 160h40v40h-40z M220 160h40v40h-40z M300 160h40v40h-40z M20 200h40v40h-40z M100 200h40v40h-40z M180 200h40v40h-40z M260 200h40v40h-40z M60 240h40v40h-40z M140 240h40v40h-40z M220 240h40v40h-40z M300 240h40v40h-40z M20 280h40v40h-40z M100 280h40v40h-40z M180 280h40v40h-40z M260 280h40v40h-40z"/>
<rect x="20" y="0" width="320" height="320" fill="none" stroke="#333333" stroke-width="1"/>
<g font-family="sans-serif" font-size="12" fill="#333333" text-anchor="middle">
<text x="10" y="24">8</text><text x="10" y="64">7</text><text x="10" y="104">6</text><text x="10" y="144">5</text><text x="10" y="184">4</text><text x="10" y="224">3</text><text x="10" y="264">2</text><text x="10" y="304">1</text>
<text x="40" y="335">a</text><text x="80" y="335">b</text><text x="120" y="335">c</text><text x="160" y="335">d</text><text x="200" y="335">e</text><text x="240" y="335">f</text><text x="280" y="335">g</text><text x="320" y="335">h</text>
</g>
<g font-family="sans-serif" font-size="16" font-weight="bold" text-anchor="middle">
<circle cx="120" cy="20" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="120" y="26" fill="#222222">K</text>
<circle cx="120" cy="60" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="120" y="66" fill="#222222">P</text>
<circle cx="200" cy="300" r="15" fill="#ffffff" stroke="#222222" stroke-width="2"/><text x="200" y="306" fill="#222222">R</text>
<circle cx="280" cy="60" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="280" y="66" fill="#ffffff">K</text>
<circle cx="80" cy="260" r="15" fill="#222222" stroke="#222222" stroke-width="2"/><text x="80" y="266" fill="#ffffff">R</text>
</g>
</svg>

*Diagram 17 — White to move. Before you work out a single move, say the four stages from memory and picture the finished bridge: which square the rook blocks on, and where the king stands above it. Then write down White's moves, taking Black's first reply as 1...Rb1 and having Black check from a distance whenever it can after that. Decide before you open the answer.*
FEN: `2K5/2P3k1/8/8/8/8/1r6/4R3 w - - 0 1`

> [!question]- Diagram 17: answer
> **The stages:** rook up, king out, king down, rook across. **The bridge:** the rook blocks on c4, the pawn's file, with the king on c5 above it.
>
> **The moves:** 1.Re4 Rb1 2.Kd7 Rd1+ 3.Kc6 Rc1+ 4.Kd6 Rd1+ 5.Kc5 Rc1+ 6.Rc4.
>
> This is the standard position moved one file to the left, except that Black's king stayed on g7, further from the pawn, which changes nothing. The rook climbs its own file, now the e-file, and slides across from e4. If Black takes the bridge, 6...Rxc4+ 7.Kxc4, its king is three moves from the squares beside c8 and the pawn promotes next move.
>
> If you put the bridge on d4 out of habit, that is the one thing to fix: the bridge stands on the pawn's own file, wherever the pawn is.

### When to aim for it

In a rook-and-pawn-against-rook ending, aim for the Lucena when your pawn is off the edge file and you can keep the defending king cut off. Get your king in front of the pawn and the pawn to its seventh rank, with your rook on a file that keeps the defending king off the squares beside the pawn. Once all five features hold, the win is a set procedure, not something to work out at the board: rook up, king out, king down, rook across.

Don't aim for it with a pawn on the a- or h-file, where the procedure has nowhere to start. And don't count on it when the defending king is already in front of the pawn or right beside it: the cut-off has to come first, and where it can't be had, the defender's drawing methods take over.

From the other side the lesson turns round. If you are the one defending, avoid having your king cut off from the pawn, because a Lucena on the board is lost against anyone who knows the bridge.

The stages hold best once you've played them against a defender who tries everything. Set up Diagram 1 on a board, or in an analysis program you already use, and play White against someone or something that defends as well as it can.
