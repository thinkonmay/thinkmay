# Editor Agent

**Input:** Raw recording, `recording_metadata.md`, `video_skeleton_<lang>.md`, brand assets  
**Output:** HyperFrames composition, `sync-timing.json`, `editing_metadata.md`

**Skills:** `hyperframes`, `hyperframes-cli`

## Workflow

1. Copy raw recording + metadata into `editing/`
2. Re-encode WebM → MP4 with `-fflags +genpts`; verify duration — [recording agent](./recording.md#post-recording)
3. **Raw footage gate** — landing + ending frames visible in MP4 before sync
4. Build sync timing (automated):
   ```bash
   node scripts/build-sync-timing.mjs en
   node scripts/apply-sync-to-html.mjs en
   ```
   See [sync-timing.md](../sync-timing.md#automated-sync-workflow)
5. Compose or patch `index.html`: intro, A-roll, captions, per-scene audio, outro
6. Set narration `data-duration` from `ffprobe` (or from `sync-timing.json` if build script embeds it)
7. Run HyperFrames check (`npm run check`) — `duplicate_audio_track` warnings for multi-lang are expected
8. Required scenes gate on **raw MP4** and **final MP4** → render

## Playback & duration

- Default `playbackRate`: **1.08×** for 60s walkthroughs
- Never exceed **1.2×** unless every required-scene keyframe passes
- Extend `data-duration` on root composition rather than dropping steps

## Caption & narration wiring

- `GROUPS` in HTML must match `sync-timing.json` exactly
- **No overlapping caption windows** for adjacent steps
- When scene N narration starts, scene N−1 caption must have exited
- Hero toggle caption: longest window (4–6s)

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

Walkthroughs must not remain statically scaled at 100%. At key instruction beats, zoom and pan the `#video-wrap` container inside the GSAP timeline to focus the viewer's attention on mouse clicks and sidebar changes.

*   **Zoom in**: Scale to `1.3x - 1.6x` and shift `x` and `y` coordinates to center the focused element (e.g. `x: -250, y: 120` to show settings panel clicks).
*   **Transition duration**: Use `0.6s - 0.8s` with `power2.out` or `power3.out` eases.
*   **Reset**: Zoom back out to `scale: 1.0, x: 0, y: 0` using `power2.inOut` when actions are complete or the narrator introduces the ending/Connect dashboard.

## Title cards: grid & glow atmospheres + kinetic type

Intros and outros must feel alive:
1.  **Backgrounds**: Layer a CSS digital grid (`.scene-grid-bg`) and slow-moving breathing glowing blobs (`.scene-glow-orb`) behind the content.
2.  **Kinetic Type**: Split headings into `<span class="line">` tags. Animate lines sequentially using `gsap.from` with an overshoot ease like `back.out(1.4)` and a stagger delay.

## Interactive captions: karaoke & marker sweeps

Avoid static caption updates. Animate them interactively:
1.  **Word-by-word Karaoke**: Programmatically split subtitle sentences into `<span class="word">` elements. Stagger active states (`tl.set(word, { className: "word active" })`) sequentially over the group duration.
2.  **Brand Highlighter Sweeps**: Style brand terms (`.brand`) with an absolute pseudo-element background (`.brand::after`) scaled to `scaleX(0)`. Enable automatically sweeping the highlight in when any word inside becomes active using the CSS `:has()` pseudo-selector:
    ```css
    .caption-pill .brand::after {
      content: '';
      position: absolute;
      inset: 4px -6px 0 -6px;
      background: rgba(0, 232, 168, 0.22);
      border-radius: 6px;
      transform: scaleX(0);
      transform-origin: left center;
      transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      z-index: -1;
    }
    .caption-pill .brand:has(.active)::after {
      transform: scaleX(1);
    }
    ```

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
