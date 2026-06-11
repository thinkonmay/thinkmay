# Quality Gates

Every stage passes validation before the next. Final rendered MP4s require a **separate final audit** — lint passing alone is not enough.

## Recording gate

### Cursor & motion

- [ ] Realistic pointer (48×48px PNG or inline SVG), not a CSS circle
- [ ] Bezier movement: ≥25 steps, 8–15ms/step, jitter on control points
- [ ] 100–300ms pause before clicks; no cursor teleporting

### Visual & automation

- [ ] 1920×1080, `deviceScaleFactor: 2`
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
