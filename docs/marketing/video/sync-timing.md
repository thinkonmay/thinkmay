# Sync Timing

For screen-recording walkthroughs, **caption and narration times must be derived from `recording_metadata.md`**, not from `video_skeleton.md`, uniform time blocks, or timings copied from another project.

**Critical:** metadata timestamps use **script wall clock** (from `Date.now()` at script start). Playwright video starts later. Always calibrate metadata → video file time before computing composition times — see [Script clock → video time calibration](#script-clock-to-video-time-calibration).

## Composition ↔ recording mapping

When A-roll uses `data-start="V"`, `data-media-start="M"`, and `data-playback-rate="R"`:

```
compositionTime = V + (videoTimestamp - M) / R
```

Where `videoTimestamp` is the event time **in the re-encoded MP4**, not the raw script timestamp from metadata.

Example with `V=4`, `M=6` (landing visible in MP4), `R=1.08`:

| Video (s) | Event | Composition (s) |
|-----------|-------|-------------------|
| 6.0 | Landing visible | 4.0 (handoff) |
| 33.0 | Settings click | ~29.0 |
| 44.0 | Connect on dashboard | ~39.2 |

## Script clock → video time calibration

Metadata event at script time `T_script` must map to video time `T_video`:

```
T_video = videoLandingTs + (T_script - landingScriptTs) × videoScale
```

Where:

- `landingScriptTs` = script time of "Landing page loaded" in metadata
- `videoLandingTs` ≈ time in MP4 when landing hero is **visually** present (verify with `ffmpeg -ss N -vframes 1`)
- `videoScale` = `(mp4Duration - videoLandingTs) / (endPaddingScriptTs - landingScriptTs)`
- `endPaddingScriptTs` = script time of "End padding"

**Do not** assume `T_video = T_script - constantOffset` — drift between early and late events breaks Connect timing.

Reference implementation: `marketing/video/windows-desktop-pwa-60s_v1/editing/scripts/build-sync-timing.mjs`

## Automated sync workflow

After re-encode, per language:

```bash
cd editing
node scripts/build-sync-timing.mjs en    # → sync-timing.json
node scripts/build-sync-timing.mjs vi    # → sync-timing-vi.json
node scripts/apply-sync-to-html.mjs en   # patches index.html
node scripts/apply-sync-to-html.mjs vi   # patches compositions/index-vi.html
```

`build-sync-timing.mjs` should:

1. Parse `recording/artifacts/output/<lang>/recording_metadata.md`
2. Read `ffprobe` duration of `raw_recording.mp4` (or `.webm`)
3. Calibrate script → video times (above)
4. Set `mediaStart` to first **visible landing frame** in MP4 (typically `videoLandingTs - 0.05`)
5. Compute caption windows with lead-in; **normalize** so `captions[i].start >= captions[i-1].end`
6. Build narration starts; **normalize** so clips on track 2 do not overlap (`next.start >= prev.start + prev.duration + 0.05`)
7. Set `aRollDuration = (videoEndPadding - mediaStart) / playbackRate`
8. Set `outroStart ≈ videoDataStart + aRollDuration - 0.5` (crossfade overlap)

## Rules

1. **Never** assign caption `GROUPS` from script scene ranges or equal-width blocks.
2. **Never** copy composition times when `playbackRate`, `mediaStart`, or duration differ — recompute every time.
3. After each recording, write `editing/sync-timing.json` via `build-sync-timing.mjs` — do not hand-copy from another project.
4. **`mediaStart` must match visible pixels** — extract frames from the MP4 until landing hero appears; do not use script "Landing loaded" time directly.
5. Lead-in captions ~0.3–0.5s before the recorded action; hero step (toggle) gets the longest window (4–6s).
6. **Connect / dashboard caption** starts at **"Dashboard loaded — ending scene"** metadata (or later), not while Settings UI is still on screen.
7. **Voice:** one `<audio>` clip per beat; `data-start` from `sync-timing.json`; `data-duration` from `ffprobe` on the MP3 — never truncate; non-overlapping on same track.
8. **Duration is an output.** Extend to 48–60s rather than raising `playbackRate` above ~1.2× or dropping steps.
9. **`outroStart`** derived from A-roll end minus ~0.5s crossfade — not a fixed constant like 54s.

## Caption window rules (avoid overlap)

Adjacent instructional captions **must not overlap**:

```
prior.end <= next.start - 0.2
```

When narration for scene N starts at time `T`, the caption for scene N should also start at `T` (±0.1s). Do not leave the previous scene's caption visible after its narration has ended.

**Failure example (`windows-desktop-pwa-60s_v1`):** at 16s narration says "Click Download on the Windows card" while caption still reads "Open the Download page" until 16.5s. At 44s two captions ("Turn on…" and "Save your changes") stack. **Fix:** end prior caption before next narration/caption starts.

## Required scenes gate

For desktop-app / PWA install tutorials, verify at each caption `start` (extract keyframe):

| Checkpoint | Must show | Fail if |
|------------|-----------|---------|
| Download | `/download`, Windows card | Login form |
| Settings | Settings sidebar or page | Login only |
| Advanced | Advanced settings panel | Dashboard only |
| Toggle | Desktop app toggle label | — |
| Save | Save click or success toast | — |
| Connect | `/play` dashboard, Connect button | Settings page |

If any fail → rebuild `sync-timing.json`, lower `playbackRate`, extend duration, or jump-cut login — do not ship.

## Optional: jump-cut login

When auth is not the teaching goal, omit login from the composition (ffmpeg splice or two A-roll clips). Remove sign-in narration/captions; remap times with splice offset. Recording may still perform login for authenticated pages.

## `sync-timing.json` shape

```json
{
  "mediaOffset": 2,
  "videoDataStart": 4,
  "mediaStart": 5.98,
  "playbackRate": 1.08,
  "duration": 60,
  "aRollDuration": 38.85,
  "outroStart": 42.83,
  "timeOffset": 6.03,
  "videoScale": 0.9,
  "videoDuration": 47.93,
  "lang": "en",
  "captions": [
    {
      "start": 3.37,
      "end": 8.38,
      "text": "Start at thinkmay.net",
      "recordingEvent": "7.96s Landing page loaded"
    }
  ],
  "narration": [
    {
      "start": 4.63,
      "file": "assets/narration-scenes/scene-02.mp3",
      "duration": 4.2,
      "text": "Start at thinkmay.net and open the Download page."
    }
  ]
}
```

Note: `recordingEvent` preserves script timestamps for debugging; composition times use calibrated video times.

## Known failure modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| White flash at intro handoff | `mediaStart` before landing paints in MP4 | Frame-scan MP4; raise `mediaStart` |
| Black / Settings during Connect caption | Script timestamps used without calibration; SPA nav not in capture | Calibrate sync; verify raw MP4 ending; re-record with `page.goto(/play)` |
| HyperFrames `overlapping_clips_same_track` | Narration scene-01 overlaps scene-02 | Normalize narration starts in build script |
| "Open Settings" while login visible | Uniform 4s blocks or copied timings | Rebuild from metadata + calibration |
| Settings flash <1s | `playbackRate` >1.2× or 30–40s cap | Extend to ~48–60s at ~1.08× |
| Voice clipped mid-sentence | `data-duration` < MP3 length | `ffprobe` each clip; use separate tracks |
| Caption lags narration | Caption `end` overlaps next `start` | Stagger windows; align narration `start` with caption |
| Outro black gap | Fixed `outroStart` after A-roll ends | `outroStart = aRollEnd - 0.5` + crossfade |

See [lessons-learned.md](./lessons-learned.md) for project-specific examples.
