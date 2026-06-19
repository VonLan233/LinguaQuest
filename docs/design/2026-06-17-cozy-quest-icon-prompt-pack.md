# Cozy Quest — Icon Prompt Pack (ChatGPT Image)

A ready-to-paste set of prompts to generate LinguaQuest's custom icon set with **ChatGPT image generation**. House style: **friendly blue-cat mascot DNA**, **unified azure monochrome**, flat app-grade pictograms on transparent background.

> **How to use this file:** (1) Paste the **Master Style Block** once at the top of a ChatGPT image chat (or save it as a Custom GPT instruction). (2) Optionally upload the mascot `icon.png` as a style reference. (3) Generate the **Reference Sheet** first to lock the look. (4) Then send each per-icon **Subject** line — ChatGPT keeps the style in-context within one chat, so you don't repeat the style block. Always ask for "transparent background, PNG, one centered icon."

---

## Palette (single hue family — azure)

| Role | Hex | Use |
|---|---|---|
| Azure ink (primary) | `#2C7BE0` | The single icon color — all strokes/fills |
| Pale azure (optional soft fill) | `#EAF2FC` | Light same-hue fill for depth (keeps it monochrome) |
| Deep navy (accent only) | `#233A66` | Tiny details (cat eyes/outline) where azure needs contrast |
| Background | transparent | Always transparent PNG (porcelain `#FAF8F5` only if a bg is forced) |

Strictly **monochrome azure** — do not introduce green/orange/red. Semantic meaning comes from the *shape*, not color.

---

## Master Style Block (paste once)

```
You are generating a cohesive ICON SET for a friendly language-learning app called LinguaQuest. Keep EVERY icon in the exact same house style:

STYLE
- Flat vector pictogram, app-icon quality, modern and minimal — like a premium iOS/Material rounded icon.
- MONOCHROME AZURE only: a single ink color #2C7BE0. Optional light fill #EAF2FC (same blue hue) for gentle depth. Tiny navy #233A66 details allowed only for the cat's eyes/nose. NO other colors. No gradients, no photorealism, no drop shadows.
- Geometry: rounded, soft, friendly. Generous corner radius, even ~3–4px optical stroke weight, balanced negative space. Smooth curves over sharp corners.
- Mascot DNA: the brand mascot is a cute NAVY/AZURE CAT — round head, two triangular ears, small dot eyes, tiny whiskers, soft rounded body. Carry this friendly, rounded character throughout. HERO icons may feature the cat or its head; UTILITY icons stay clean but echo the same rounded softness, occasionally with a subtle cat-ear or paw accent where it feels natural (never forced).
- Composition: ONE icon, centered, filling ~76% of a square canvas with even padding (safe margin all around). Consistent visual weight across the whole set so they sit together in a grid.
- Background: fully TRANSPARENT. Output PNG. Square 1024×1024.
- NO text, NO letters, NO numbers inside the icon (unless the subject explicitly is a letter/symbol). No borders or frames around the canvas.

Render the following subject in this exact style:
```

> Append the per-icon **Subject** line after that block (or just send the Subject once the style is established in the chat).

---

## ChatGPT image — consistency tips

- **Lock the style first:** generate the **Reference Sheet** (below) before individual icons. Then for each new icon say: *"Same exact style, line weight, azure color and mascot character as the set — now make: …"*.
- **Upload the mascot** `lib/assets/image/icon.png` as a reference image so the cat stays on-model.
- **One icon per generation** for clean transparent cutouts. Ask explicitly for *"transparent background."*
- If a result drifts (wrong color, added shading, off-style), reply *"keep it flat monochrome azure #2C7BE0, no shadows, transparent bg"* and regenerate.
- For outline vs filled nav states: generate the **filled/active** version, then ask *"now the outline (stroke-only) version of the same icon, same size and alignment."*
- Avoid letters — image models garble text. For "translate"-type icons use abstract glyph shapes, not real characters.

### Optional one-shot Reference Sheet prompt

```
[Master Style Block]
Subject: a 3×3 contact sheet (transparent background) of nine icons in identical house style, evenly spaced on a grid: 1) cozy house with subtle cat-ear roof bumps, 2) game controller with rounded cat-paw button, 3) cat head with a small idea-sparkle, 4) compass with a cat-ear north point, 5) round blue-cat face avatar, 6) lightning bolt, 7) flame, 8) open book with a curling cat-tail bookmark, 9) rounded checkmark in a circle. All monochrome azure #2C7BE0, flat, friendly, consistent weight.
```

---

## Per-icon prompts

Each entry is a **Subject** line to send after the style is set. Grouped by role. Hero/brand icons lead with the cat; utility icons stay clean.

### 1 · Bottom navigation (hero — feature the mascot)
Generate each as **active (filled)**; then request the **outline** twin.

1. **Home** — `a cozy rounded house; the roof has two subtle triangular cat-ear bumps; warm and welcoming; monochrome azure.`
2. **Training (games)** — `a friendly game controller with rounded edges; one button shaped like a small cat paw print; playful; monochrome azure.`
3. **AI Learning** — `a cute cat head in profile with a small glowing spark / idea node above it, suggesting smart AI tutoring; monochrome azure.`
4. **Discover** — `a round explorer's compass; the north point styled as a small cat ear; sense of adventure; monochrome azure.`
5. **Profile** — `a round blue-cat face avatar: round head, two triangular ears, dot eyes, tiny whiskers; centered; monochrome azure.`

### 2 · Question types (learning glyphs — light mascot accent)
6. **Meaning / translate** — `two overlapping rounded speech bubbles, one with an abstract glyph swap motif (no real letters), implying translation; monochrome azure.`
7. **Chinese ↔ English choice** — `two curved swap arrows forming a circle around a small abstract character block; language-switch feel; monochrome azure.`
8. **Context / sentence** — `a pair of large rounded quotation marks above a short underline, implying a sentence in context; monochrome azure.`
9. **Image choice** — `a rounded picture frame containing a simple mountain-and-sun shape with a tiny sparkle; monochrome azure.`
10. **Listening** — `a single rounded cat ear emitting two soft concentric sound waves; audio/listening; monochrome azure.`
11. **Spelling / input** — `a rounded pencil writing on a short dotted baseline, with a small blinking cursor tick; monochrome azure.`

### 3 · Training modes
12. **Word Rush (speed)** — `a rounded stopwatch with two small motion streaks beside it, conveying fast pace; monochrome azure.`
13. **Survival** — `three ascending rounded steps with a small heart on top, conveying a climbing survival challenge; monochrome azure.`
14. **Spelling game** — `a rounded pencil above a dotted word line with three empty letter slots (no letters); monochrome azure.`

### 4 · Gamification & stats
15. **XP / points** — `a bold rounded lightning bolt; energetic; monochrome azure.`
16. **Streak** — `a soft rounded flame whose tip curls like a cat tail; monochrome azure.`
17. **Trophy / achievement** — `a rounded trophy cup; its two handles styled as subtle cat ears; monochrome azure.`
18. **Correct / check** — `a thick rounded checkmark inside a soft circle; positive; monochrome azure.`
19. **Wrong / retry** — `a rounded X inside a soft circle (friendly, not harsh); monochrome azure.`
20. **Goal / flag** — `a rounded pennant flag on a short pole, marking a milestone; monochrome azure.`
21. **Leaderboard** — `three rounded podium bars of different heights with a tiny star over the tallest; monochrome azure.`

### 5 · Wordbook / vocabulary
22. **Wordbook** — `an open book; a bookmark ribbon curls out like a cat tail; monochrome azure.`
23. **Add word card** — `a rounded flashcard with a plus sign in the corner; monochrome azure.`
24. **Tag / label** — `a rounded price-tag shape with a small hole, soft corners; monochrome azure.`
25. **Word family / relations** — `three small rounded nodes connected by soft curved lines, like a mini word web; monochrome azure.`

### 6 · Empty states & feedback (showcase the cat)
26. **Empty state** — `a sweet sleeping blue cat curled into a circle, tail wrapped around; calm, minimal; monochrome azure.`
27. **Success / celebration** — `a happy blue-cat head with both small paws raised and two tiny confetti sparkles; joyful; monochrome azure.`
28. **Hint / tip** — `a rounded lightbulb with two tiny whisker lines on the sides; clever idea; monochrome azure.`
29. **Warning** — `a rounded triangle with an alert mark; two tiny cat ears perk up from its top corners; gentle caution; monochrome azure.`

### 7 · Profile, rewards & lottery
30. **Gift / reward** — `a rounded gift box; the bow loops styled as soft cat ears; monochrome azure.`
31. **Lottery / draw** — `a rounded gachapon capsule machine with a small paw on the dial; playful; monochrome azure.`
32. **Wallet / coins** — `a small stack of rounded coins with a soft sparkle; monochrome azure.`
33. **Badge / medal** — `a rounded medal on a short ribbon; the medal center is a tiny cat face; monochrome azure.`

### 8 · AI & teaching
34. **AI tutor bot** — `a friendly robot-cat head: rounded screen-face with two antenna styled as cat ears; helpful; monochrome azure.`
35. **Chat / dialogue** — `a rounded speech bubble with two tiny cat ears on top; conversational; monochrome azure.`

### 9 · Actions & chrome (clean utility — minimal mascot)
Keep these crisp and functional; same rounded softness, no cat unless noted.
36. **Back** — `a rounded left-pointing arrow; monochrome azure.`
37. **Next / forward** — `a rounded right-pointing arrow; monochrome azure.`
38. **Search** — `a rounded magnifying glass; monochrome azure.`
39. **Add** — `a rounded plus sign inside a soft circle; monochrome azure.`
40. **Settings** — `a rounded gear with soft teeth; monochrome azure.`
41. **Refresh / replay** — `a rounded circular arrow (refresh loop); monochrome azure.`
42. **Close** — `a rounded X (stroke only); monochrome azure.`
43. **Notifications** — `a rounded bell with a tiny soft clapper; monochrome azure.`
44. **Check-in / calendar** — `a rounded calendar page with a small checkmark in the center; monochrome azure.`
45. **Edit** — `a rounded pencil at a slight angle; monochrome azure.`
46. **Filter** — `three rounded horizontal slider lines with small knobs; monochrome azure.`
47. **Lock** — `a rounded padlock, soft and friendly; monochrome azure.`

---

## Reusable template for the long tail (~100 remaining icons)

For any icon not listed above, drop the subject into this one-liner after the style is set:

```
Same exact house style (flat monochrome azure #2C7BE0, rounded & friendly, transparent bg, one centered icon, no text): make a <SUBJECT — what it represents>. Echo the soft mascot feel; add a subtle cat ear/paw only if it feels natural.
```

Long-tail subjects (map the app's remaining Material icons to a plain description):

| Need | Subject to use |
|---|---|
| Streak (alt) | a soft flame |
| Mastery / brain | a rounded brain / cat-head with a gentle glow |
| Insights / analytics | a rounded line-chart trending up |
| Verified | a rounded shield with a checkmark |
| Library | a small shelf of three rounded books |
| Compare | two rounded arrows pointing opposite ways |
| Schedule / spaced repetition | a rounded clock with a small arrow loop |
| Volume / sound | a rounded speaker with one sound wave |
| Language | a rounded globe with soft meridians |
| Dark/light mode | a rounded moon / a rounded sun |
| Groups / class | three overlapping rounded cat-head silhouettes |
| Forum / discussion | two rounded chat bubbles |
| Shuffle | two crossing rounded arrows |
| Delete | a rounded trash can |
| Save | a rounded floppy/save shape |
| Key / login | a rounded key |
| Quest / assignment | a rounded clipboard with a checkmark |
| Route / path | a rounded winding road with two pins |
| Wallet/balance | rounded scales / coin stack |
| Avatar add | a rounded cat-head with a small plus |
| Premium / unlock | a rounded ribbon rosette |
| Pause / play | a rounded pause bar pair / a rounded play triangle |
| Help / info | a rounded circle with an info dot |
| Sentiment / encourage | a smiling rounded cat face |

---

## Delivery checklist (for whoever generates the assets)

- [ ] Generate the **Reference Sheet** first; confirm the azure-monochrome + cat-DNA look.
- [ ] Produce the **5 nav icons** in both active (filled) and outline states first — they're the most visible.
- [ ] Then the **6 question-type** + **3 training** + **gamification** icons.
- [ ] Export each as **transparent PNG, 1024×1024**, trimmed with even padding; also provide @1x/@2x/@3x (or SVG if the tool can vectorize) for Flutter.
- [ ] Eyeball the full set together at 24px (nav size) and 48px (badge size) for consistent weight and legibility on porcelain `#FAF8F5`.
- [ ] Keep the mascot `icon.png` itself as-is (it's the master character reference, not part of the icon grid).

> Integration note (for the app side, later): custom PNG/SVG icons replace `Icons.*` usages screen-by-screen via a small `AppIcon` widget or `ImageIcon`/`SvgPicture`. That's an app task for after the assets exist — not part of this prompt pack.
