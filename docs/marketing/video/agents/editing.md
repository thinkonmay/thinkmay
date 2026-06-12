# Editor Agent

**Input:** Raw recording, `recording_metadata.md` **including its `## Frame review` section** ([agents/review.md](./review.md)), `video_skeleton_<lang>.md`, brand assets  
**Output:** HyperFrames composition, `sync-timing.json`, `editing_metadata.md`

**Skills:** `hyperframes`, `hyperframes-cli`

## Workflow

1. Copy raw recording + metadata into `editing/`
2. Re-encode WebM → MP4 with `-fflags +genpts`; verify duration — [recording agent](./recording.md#post-recording)
3. **Raw footage gate** — landing + ending frames visible in MP4 before sync
4. **Read the `## Frame review` section** of `recording_metadata.md`. It is the pixel-verified ground truth:
   - `mediaStart` = "first clean landing frame" from the review — never the metadata mark
   - Caption/narration anchors = **corrected (observed) times**, not raw script marks
   - Zoom targets = recorded `(tx, ty)` + bbox per event
   - `DEAD_AIR` spans = bridge with a zoom-to-target or a playback-rate bump on that span
   - If the section is missing, run the frame review first — do not sync blind
5. Build sync timing (automated):
   ```bash
   node scripts/build-sync-timing.mjs en
   node scripts/apply-sync-to-html.mjs en
   ```
   See [sync-timing.md](../sync-timing.md#automated-sync-workflow)
6. Compose or patch `index.html`: intro, A-roll, captions, per-scene audio, outro
7. Set narration `data-duration` from `ffprobe` (or from `sync-timing.json` if build script embeds it)
8. Run HyperFrames check (`npm run check`) — `duplicate_audio_track` warnings for multi-lang are expected
9. Required scenes gate on **raw MP4** and **final MP4** → render

## Playback & duration

- Default `playbackRate`: **1.08×** for 60s walkthroughs
- Never exceed **1.2×** unless every required-scene keyframe passes
- Extend `data-duration` on root composition rather than dropping steps
- **Intro 3.0–4.5s, outro 5–7s (hard max 8s)** — see [brand-design.md](../brand-design.md#intro--outro-scene-standards-60s-tutorials). Set `data-duration ≈ outroStart + outro budget`; never let leftover padding stretch a static outro (`disk-upgrade-60s_v1`: 18.8s frozen outro)

## Caption & narration wiring

- `GROUPS` in HTML must match `sync-timing.json` exactly
- **No overlapping caption windows** for adjacent steps
- When scene N narration starts, scene N−1 caption must have exited
- Hero toggle caption: longest window (4–6s)
- **Caption must describe pixels on screen, not the script mark.** Anchor each caption `start` to the *observed* time in the frame review — a "Dashboard is ready" caption over a login form is a CAPTION_DRIFT hard fail (`disk-upgrade-60s_v1` at 19s)
- **Caption pill must not occlude interactive targets.** When the caption references an option list or button group, verify no sibling option sits under the pill at zoomed framing (see safe area in [camera-zoom.md](../camera-zoom.md))

## Premium transitions (no jump cuts or flat slides)

Always use **Depth Scale Transitions** at scene boundaries (e.g. Intro → A-roll, A-roll → Outro) to create parallax camera weight.

```javascript
// Depth Transition: Intro -> A-Roll (at 4.0s)
tl.to("#scene-intro", { scale: 0.85, opacity: 0, duration: 0.6, ease: "power3.in" }, 3.8);
tl.fromTo("#video-wrap", 
  { scale: 1.15, opacity: 0 }, 
  { scale: 1.0, opacity: 1, duration: 0.6, ease: "power3.out" }, 
  4.0
);

// Depth Transition: A-Roll -> Outro
tl.to("#video-wrap", { scale: 0.85, opacity: 0, duration: 0.6, ease: "power3.in" }, outroStart - 0.23);
tl.set("#video-wrap", { opacity: 0 }, outroStart + 0.55);
tl.to("#caption-contrast", { opacity: 0, duration: 0.3, ease: "power2.in" }, outroStart - 0.23);
tl.set("#caption-contrast", { opacity: 0 }, outroStart);

tl.fromTo("#scene-outro", 
  { scale: 1.15, opacity: 0 }, 
  { scale: 1.0, opacity: 1, duration: 0.6, ease: "power3.out" }, 
  outroStart
);
```

## A-roll camera zooms & panning

Walkthroughs must not remain statically scaled at 100%. At key instruction beats, zoom and pan the `#video-wrap` container to focus on the action target.

**Zoom coordinates are computed, never eyeballed** — follow [camera-zoom.md](../camera-zoom.md) for the centering/clamp math, target-selection rules (no text cut mid-glyph, target in center third, caption safe area), and the mandatory measure → compute → verify loop. Targets come from the `## Frame review` bounding boxes.

Summary: scale `1.15–1.6×`, transitions `0.6–0.8s` with `power2.out`/`power3.out`, hold ≥2s, reset to `scale: 1.0, x: 0, y: 0` (`power2.inOut`) before scene changes, `overwrite: "auto"` on all `#video-wrap` tweens.

## Title cards: grid & glow atmospheres + kinetic type

Intros and outros must feel alive:
1.  **Backgrounds**: Layer a CSS digital grid (`.scene-grid-bg`) and slow-moving breathing glowing blobs (`.scene-glow-orb`) behind the content.
2.  **Kinetic Type**: Split headings into `<span class="line">` tags. Animate lines sequentially using `gsap.from` with an overshoot ease like `back.out(1.4)` and a stagger delay.

## Caption styling: render-safe patterns only

**Do not use GSAP `className` tweens or CSS `transition`-driven word karaoke.** In HyperFrames' seek-based renderer, `tl.set(word, { className: "+=active" })` state and `transition` interpolation are not reliably applied at arbitrary seek times — `disk-upgrade-60s_v1` shipped black (unstyled) caption text because word colors depended on the `.active` class being applied (2026-06-12).

Render-safe rules:

1. **Base styles carry all critical properties.** `color: #fff` (and shadow/weight) live directly on `.caption-pill`, never only on dynamically-toggled child classes.
2. **Insert caption text as plain `innerHTML`** with pre-styled `<span class="brand">` accents. Brand highlight `::after` backgrounds are statically visible (`transform: scaleX(1)`) — no `:has(.active)` gating, no `transition`.
3. **Animate only the pill container** with GSAP property tweens (`y`, `opacity`, `scale`) — these seek deterministically.
4. If word-level emphasis is required, drive it with **per-word GSAP property tweens** (e.g. `tl.fromTo(word, { opacity: 0.55 }, { opacity: 1 })`) on the timeline — never class toggles or CSS transitions.

## Multi-language compositions

HyperFrames lint fails with `multiple_root_compositions` when two `index*.html` files with `data-composition-id` sit at `editing/` root.

**Layout:**

```
editing/
├── index.html              # Primary language (e.g. EN) — only root composition
├── compositions/
│   └── index-vi.html       # Secondary languages
├── raw_recording.mp4
├── raw_recording_vi.mp4
└── assets/                 # Shared; VI uses ../ paths from compositions/
```

**Asset paths in `compositions/index-vi.html`:**

- Video: `../raw_recording_vi.mp4`
- Audio: `../assets/narration-scenes/vi/scene-NN.mp3`
- Logo: `../assets/logo_white.webp`

**package.json scripts:**

```json
{
  "check": "npx hyperframes lint && npx hyperframes validate --no-contrast && npx hyperframes inspect",
  "check:vi": "cd compositions && npx hyperframes lint && npx hyperframes validate --no-contrast && npx hyperframes inspect",
  "render": "npx hyperframes render --quality high --output renders/final_en.mp4 && node ../scripts/finalize-output.mjs final_en.mp4",
  "render:vi": "npx hyperframes render --quality high --composition compositions/index-vi.html --output renders/final_vi.mp4 && node ../scripts/finalize-output.mjs final_vi.mp4"
}
```

Render discovers all HTML under the project tree for lint warnings (`duplicate_audio_track`) but compiles the specified composition — keep secondary files in `compositions/` to avoid `multiple_root_compositions` **errors**.

## HyperFrames constraints

- `<video data-start>` must be direct child of root composition div — not nested in another timed div
- Use `data-track-index` to separate intro, A-roll, audio, outro
- Add `caption-overrides.json` (`{}`) before validate
- Use `--no-contrast` during iteration (caption pills start at opacity 0)

## Video nesting

See [lessons-learned.md](../lessons-learned.md) §9 — nested video clips freeze in render.
