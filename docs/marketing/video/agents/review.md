# Frame Review Agent (VLM round)

**Position in pipeline:** after Recording (re-encode + raw footage gate), **before** Editing/sync.
**Input:** `editing/raw_recording.mp4`, `recording_metadata.md`
**Output:** `## Frame review` section **appended to `recording_metadata.md`** — consumed by the editor agent.

## Why this round exists

Script marks lie. Playwright logs "Dashboard loaded" when an assertion passes, not when pixels paint. Every sync/zoom decision made from uncalibrated script marks produced drift in past projects (`windows-desktop-pwa-60s_v1`, `game-install-witcher3-60s_v1`, `disk-upgrade-60s_v1` — caption "Dashboard is ready" over a login form). This round converts script marks into **pixel-verified video timestamps + target coordinates** so the editor never guesses.

## Procedure

### 1. Calibrate and extract

Calibrate the script clock → video time (same anchor method as [sync-timing.md](../sync-timing.md)). Then extract one keyframe per metadata event, plus a uniform 2s grid to catch dead air between events:

```bash
REVIEW=editing/temp/frame-review
mkdir -p "$REVIEW"
# Per metadata event (video-calibrated time T):
ffmpeg -y -ss "$T" -i editing/raw_recording.mp4 -frames:v 1 -update 1 "$REVIEW/event-<n>-t${T}.png"
# Uniform grid:
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 editing/raw_recording.mp4)
for ((t=1; t<${DUR%.*}; t+=2)); do
  ffmpeg -y -ss "$t" -i editing/raw_recording.mp4 -frames:v 1 -update 1 "$REVIEW/grid-t${t}.png"
done
```

### 2. Evaluate every keyframe (VLM)

Read each frame as an image and answer, per frame:

1. **What UI state is actually visible?** (landing / login form / dashboard / popup / loading spinner / blank)
2. **Does it match the metadata event description?** verified ✅ / early ⏪ (pixels not there yet) / late ⏩ / wrong ❌
3. **Where is the action target?** Center `(tx, ty)` and bounding box of the element the next caption/zoom will reference — measured from the frame if the recording script didn't capture a `boundingBox()`.
4. **Anomalies:** PII readable, error cards, dev overlays, stuck spinners, mid-paint frames.
5. **Grid frames only — pacing:** is anything happening? Mark spans of ≥4s with no visible change as `DEAD_AIR`.

### 3. Append `## Frame review` to recording_metadata.md

```markdown
## Frame review

- **Reviewed:** <ISO timestamp>  ·  **MP4:** raw_recording.mp4 (49.2s)
- **Calibration:** script −7.4s ≈ video time (anchors: landing 7.6s→0.4s, end pad 56.5s→49.0s)

### Event verification

| Video time | Metadata event | Observed | Verdict | Target (tx,ty) + bbox |
|------------|----------------|----------|---------|----------------------|
| 0.8s  | Landing page loaded | Hero fully painted | ✅ | — |
| 12.3s | Login submitted | Login form, button pressed | ✅ | — |
| 13.1s | Dashboard loaded | **Still login form; dashboard paints at 14.6s** | ⏩ use 14.6s | — |
| 16.2s | Disk button visible | Dashboard, VM card right side | ✅ | (1406, 786) bbox 1372,770→1440,802 |
| 19.0s | Disk popup opened | Popup fully painted, pricing row visible | ✅ | pricing row (511, 320) |

### Corrections for editor

- `mediaStart`: first clean landing frame = **0.8s** (not metadata 0.0s)
- "Dashboard ready" caption/narration anchor: **14.6s**, not 13.1s
- DEAD_AIR: 5.2s–11.8s (email/password typing, no visual change) → editor should bridge with zoom-to-form or playback-rate bump on this span

### Anomalies

- None / e.g. "sidebar email readable at 14.6s → PII hard fail, re-record"
```

Rules for the section:

- **Every event row gets a verdict.** An unverified event must not be used as a sync anchor downstream.
- **Corrected times are authoritative.** When observed ≠ metadata, the editor uses the observed time; the original mark is kept for traceability only.
- **Target coordinates are mandatory** for every event the skeleton marks as a zoom beat — the editor computes zoom transforms from them ([camera-zoom.md](../camera-zoom.md)).
- Any PII / error-card / wrong-flow finding at this stage → **stop, re-record**. This is the cheapest point to fail.

## Editor contract

The editor agent **must** read `## Frame review` before building `sync-timing.json` and the composition:

| Editor decision | Source in frame review |
|-----------------|------------------------|
| `mediaStart` | "first clean landing frame" |
| Caption/narration `start` per beat | corrected (observed) video times |
| Zoom `scale/x/y` | target `(tx, ty)` + bbox via [camera-zoom.md](../camera-zoom.md) |
| Playback-rate bumps / bridging zooms | `DEAD_AIR` spans |
| Abort-and-re-record | Anomalies |

`build-sync-timing.mjs` should prefer corrected times from the frame review over raw metadata needles when both exist.

## Cost control

~25–35 frames per 60s video. Batch-read frames (4–6 per evaluation pass). Skip grid frames that fall within ±0.5s of an event frame.
