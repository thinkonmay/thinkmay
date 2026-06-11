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

## Intro → A-roll transition

**Failure (`windows-desktop-pwa-60s_v1`):** at ~4s a white/blank frame appeared during intro slide-off.

Rules:

1. `#video-wrap` stays **`opacity: 1`** during the push-slide — do not fade video wrap to white
2. A-roll `data-media-start` must point at the **first frame where landing is visible in the MP4** — not the script metadata timestamp. White/loading frames often precede landing by 1–3s in the file.
3. GSAP: slide intro off (`x: -1920`) while sliding video wrap in (`x: 300 → 0`) on the **same timeline position**
4. **Audit:** extract frame at `videoDataStart + 0.1s` — fail if >90% white/blank

```js
// Good: simultaneous handoff at intro end
tl.to("#scene-intro", { x: -1920, duration: 0.4, ease: "power3.inOut" }, 4.0);
tl.fromTo("#video-wrap", { x: 300, opacity: 1 }, { x: 0, duration: 0.4, ease: "power3.inOut" }, 4.0);
// Bad: fading video-wrap or leaving A-roll at opacity 0 until after intro exits
```

## A-roll → outro transition

- Derive `outroStart` from A-roll end: `≈ videoDataStart + aRollDuration - 0.5`
- Crossfade A-roll out while fading outro in on overlapping timeline (~0.5–0.6s)
- Avoid: A-roll `opacity: 0` → black gap → outro fade in
- **Audit:** frames at `outroStart - 0.2`, `outroStart`, `outroStart + 0.3`

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
