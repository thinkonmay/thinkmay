# Quality Gates

Every stage passes validation before the next. Final rendered MP4s require a **separate final audit** — lint passing alone is not enough.

## Recording gate

### Cursor & motion

- [ ] Realistic pointer (48×48px PNG or inline SVG), not a CSS circle
- [ ] Bezier movement: ≥25 steps, 8–15ms/step, jitter on control points
- [ ] 100–300ms pause before clicks; no cursor teleporting

### Visual & automation

- [ ] FullHD 1920×1080 at 90fps, `deviceScaleFactor: 2`, lossless visual quality
- [ ] No Next.js dev overlay, infobar, or "Chrome is being controlled"
- [ ] 2s padding at start and end of raw recording
- [ ] No stuck spinners or obvious glitches

### PII & account state

- [ ] **No viewer-facing personal data** — see [agents/recording.md](./agents/recording.md#pii-masking-public-marketing)
- [ ] Dashboard shows healthy VM cards — **no** "System Issue Detected" or error-dominated frames during walkthrough
- [ ] Password fields masked during recording (`-webkit-text-security: disc`)

### Metadata

- [ ] `recording_metadata.md` with per-action timestamps
- [ ] Login verification assertion passed (or recording halted)

### Raw footage verification (before editing)

- [ ] Re-encoded MP4 duration within ~2s of last metadata event ("End padding")
- [ ] Frame at ~3–4s in MP4 shows **landing hero** (not solid white)
- [ ] Frame at `duration - 3s` shows **`/play` dashboard** with Connect/Power on — **not** Advanced Settings, confirm dialog, or install spinner
- [ ] **Game install:** ending frame shows **game name on VM card** (e.g. h3 title), not store detail page
- [ ] If ending check fails → re-record; do not build sync from metadata alone

See [agents/recording.md](./agents/recording.md#post-recording).

## Frame review gate (between recording and editing)

See [agents/review.md](./agents/review.md).

- [ ] Keyframe extracted and evaluated for **every** metadata event (video-calibrated) + 2s grid
- [ ] `## Frame review` section appended to `recording_metadata.md` with verdict per event
- [ ] Every zoom/caption beat has target `(tx, ty)` + bbox (recorded or measured)
- [ ] Corrected times noted wherever observed pixels ≠ metadata mark
- [ ] `DEAD_AIR` spans ≥4s flagged for the editor
- [ ] No PII / error cards / wrong-flow frames — else re-record before editing starts

## Editing gate

### Timing & content

- [ ] `sync-timing.json` built via `build-sync-timing.mjs` from **this** recording + calibrated MP4 duration
- [ ] `mediaStart` verified against visible landing frame in MP4
- [ ] `playbackRate` ≤ 1.2× unless all required scenes verified at caption times
- [ ] Caption `GROUPS` match `sync-timing.json` (via `apply-sync-to-html.mjs` or manual); **no overlapping adjacent captions**
- [ ] Narration clips on same track **non-overlapping** (HyperFrames lint error if overlapped)
- [ ] Each narration `data-start` aligns with its caption window (±0.1s)
- [ ] Each narration `data-duration` ≥ `ffprobe` MP3 length
- [ ] `outroStart` derived from A-roll end (crossfade), not a stale fixed timestamp
- [ ] **Intro 3.0–4.5s; outro 3.0–4.5s**; `data-duration = outroStart + outro budget` derived from A-roll end — **no fixed 55/60s floor, zero black frames after the outro fade** ([brand-design.md](./brand-design.md#intro--outro-scene-standards-60s-tutorials))
- [ ] Outro CTA narration starts at `outroStart + ~0.7s` (not `DURATION − 5`)
- [ ] Caption `start` values anchored to **frame-review observed times**, not raw script marks
- [ ] Typing occupies ≤2s of timeline (instant `fill()` at record time, or jump-cut legacy footage)

### Camera zooms ([camera-zoom.md](./camera-zoom.md))

- [ ] **Coverage:** no >6s consecutive span of full-browser 1.0× during instruction; ≥50% of A-roll at ≥1.2×; every "click X" beat zoomed to X + its container; split-screen pages cropped to the relevant column
- [ ] Every zoom's `scale/x/y` computed from a measured target + clamp math, documented in a code comment
- [ ] Verification frame per zoom hold: target in center third, no text cut mid-glyph, no background exposed, caption pill not covering target or sibling options

### Motion polish & soundscape

- [ ] Caption pills animate in/out (slide+fade) — no popping
- [ ] Click ripple at every `clicks[]` timestamp (yellow ring inside `#video-wrap`)
- [ ] Music bed present, `data-volume ≤ 0.15`, spans full composition, fades with outro
- [ ] Click SFX + popup whoosh tags generated between `<!-- sfx:start/end -->` markers

### Transitions (no blank frames)

- [ ] **Intro → A-roll:** no white/blank flash at handoff — audit frame at `videoDataStart + 0.1s`
- [ ] **A-roll → outro:** crossfade overlap; no full-black gap >0.3s before outro visible
- [ ] Intro/outro use entrance animations; no raw jump cuts on title cards

See [agents/editing.md](./agents/editing.md#intro-to-a-roll-transition).

### HyperFrames validation

Run **per composition file** (primary `index.html` only, or each file in `compositions/`):

```bash
cd editing
npx hyperframes lint
npx hyperframes validate --no-contrast
npx hyperframes inspect
```

- [ ] `caption-overrides.json` exists (`{}` minimum)
- [ ] Non-primary language files **not** at editing root (avoids `multiple_root_compositions`)

### Required scenes gate

Extract keyframes at each checkpoint in [sync-timing.md](./sync-timing.md#required-scenes-gate). All must pass before render.

## Audio gate

- [ ] Per-scene MP3 clips for walkthroughs (not one monolithic file)
- [ ] Spoken line matches on-screen action within ~2s at download, settings, toggle, connect
- [ ] Consistent levels; no clipped speech in preview render

## Final video audit

Run on **`final_<lang>.mp4` at project root** after assembly. See [agents/qa.md](./agents/qa.md) for the full procedure.

### Hard fails (block public marketing)

| Check | Method | Fail condition |
|-------|--------|----------------|
| PII visible | Keyframes during authenticated segments | Email, real name, or account label readable |
| Intro flash | Frame at `videoDataStart + 0.1s` | >90% white/blank; landing not visible |
| Required scenes | Keyframe at each caption `start` in sync-timing | Wrong UI at checkpoint |
| Sync drift | Caption text vs frame | Caption describes action not yet on screen (>1s) |
| Clipped audio | Listen or compare duration | Speech cut mid-word |

### Warnings (fix before publish if possible)

| Check | Fail condition |
|-------|----------------|
| Overlapping captions | Two caption pills visible simultaneously |
| Dashboard errors | Error cards visible during instructional segments |
| Outro gap | Black frame >0.5s between A-roll and outro |
| Caption lags narration | Narration topic changed; caption text has not |
| Outro overrun | Outro on screen >5s (check frames at outroStart+4.5 vs end — identical = overrun) |
| Black tail | Any black frame after the outro fade completes (**hard fail**) |
| Zoom framing | UI text cut mid-glyph at frame edge, or target outside center third during hold |
| Zoom coverage | >6s consecutive full-browser 1.0× during instructional beats |
| Dead air | ≥5s span with no caption, narration, or camera motion during A-roll |
| No soundscape | Voice-only mix — missing music bed or SFX layers |
| Typing on camera | Char-by-char credential typing >2s |

### Verdict levels

| Level | Criteria |
|-------|----------|
| **Pass — public** | No hard fails; warnings addressed or accepted by reviewer |
| **Conditional — internal** | Required scenes pass; PII or polish issues remain |
| **Fail** | Any hard fail; re-record, re-edit, or re-render |

## Validation process (keyframes)

```bash
ffmpeg -ss <timestamp> -i final_en.mp4 -vframes 1 -q:v 2 frame.png
```

Compare frame to metadata description (VLM or human). File size heuristic: flat/dark scenes ~60–120KB PNG; complex UI ~500KB–1MB.
