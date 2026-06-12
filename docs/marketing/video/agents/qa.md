# QA Agent

**Input:** Pipeline artifacts or rendered `final_<lang>.mp4`  
**Output:** Pass/fail report with retry instructions

QA runs at three levels: **recording (raw MP4)**, **editing (pre-render)**, and **final video audit (post-render)**. The final audit on the MP4 is mandatory before public distribution.

**Lint passing ≠ shippable.** HyperFrames can render successfully while sync drift, PII, or missing dashboard footage remain.

## Recording QA (raw MP4, before sync)

After re-encode, before `build-sync-timing.mjs`:

```bash
# Landing visible
ffmpeg -y -ss 3.5 -i editing/raw_recording.mp4 -vframes 1 -q:v 2 /tmp/qa-landing.png

# Dashboard ending (must NOT be Settings)
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 editing/raw_recording.mp4)
ffmpeg -y -ss $(echo "$DUR - 3" | bc) -i editing/raw_recording.mp4 -vframes 1 -q:v 2 /tmp/qa-end.png
```

Fail → re-record. Do not trust metadata if ending frame is wrong.

## Final video audit procedure

Target: `<project>/final_<lang>.mp4`

### 1. Technical probe

```bash
ffprobe -v error -show_entries format=duration -show_entries stream=width,height,codec_name \
  -of json final_en.mp4
```

Expect: ~target duration, 1920×1080, H.264 + AAC.

### 2. Extract keyframes

From `editing/sync-timing.json`, extract at:

- Every caption `start` time
- Every narration `start` time
- Transition boundaries: `videoDataStart + 0.1`, `outroStart ± 0.3`
- Required scenes gate checkpoints (see [sync-timing.md](../sync-timing.md))

```bash
QA=editing/temp/audit-en
mkdir -p "$QA"
# Use times from sync-timing.json — example only:
for ts in 4.1 8.4 19.6 31.2 37.2 44.2 47.5; do
  ffmpeg -y -ss "$ts" -i final_en.mp4 -vframes 1 -q:v 2 "$QA/t${ts//./_}.png"
done
```

### 3. Audit each frame

Compare keyframe to expected content (VLM or human):

| Time | Expected | Pass example | Fail example |
|------|----------|--------------|--------------|
| 4.1s | Landing page visible | thinkmay.net hero | White/blank frame |
| 13.5s | Download page | Windows card section | Login form |
| 38s | Advanced + toggle | Toggle label on screen | Personal info only |
| 50s | Dashboard Connect | Connect button highlighted | Settings page (metadata passed but capture missed nav) |
| 50s | Game install dashboard | Witcher on VM card + Power on | Confirm dialog or store page (false-positive metadata) |
| 33s | Dashboard before Settings | Sidebar + dashboard | OK if caption is lead-in |

### 4. Hard fail criteria (public marketing)

| ID | Check |
|----|-------|
| PII | Readable email, real name, or account label in authenticated UI |
| INTRO_FLASH | Blank/white frame at A-roll handoff |
| SCENE_DRIFT | Required checkpoint shows wrong UI |
| AUDIO_CLIP | Audible mid-sentence cut (verify against ffprobe durations) |
| CAPTION_DRIFT | Caption text describes action not on screen (>1s) |
| CAPTION_STYLE | Caption text unreadable: black/unstyled font, contrast failure against pill (`disk-upgrade-60s_v1` — className-tween karaoke broke in seek render) |

### 5. Warning criteria

| ID | Check |
|----|-------|
| CAPTION_OVERLAP | Two caption pills visible at once |
| DASHBOARD_ERROR | "System Issue Detected" or similar during walkthrough |
| OUTRO_GAP | >0.5s black between A-roll and outro |
| CAPTION_LAG | Narration topic changed; old caption still showing |
| OUTRO_OVERRUN | Static outro >8s — compare frame at `outroStart + 5` vs final frame; identical = overrun |
| ZOOM_FRAMING | UI text cut mid-glyph at frame edge during a zoom hold, or zoom target outside center third |
| DEAD_AIR | ≥5s of A-roll with no caption, narration, or camera motion |

### 6. Verdict

| Verdict | Action |
|---------|--------|
| **Pass — public** | No hard fails; warnings resolved or waived |
| **Conditional — internal** | Instructional flow OK; PII or polish issues remain |
| **Fail** | Re-record (PII, dashboard health), re-edit (sync, transitions), or re-render |

Document results in `taskchecklist.md` and optionally `editing/temp/audit-<lang>/report.md`.

## Example audit summary format

```markdown
# Final Audit: final_en.mp4

## Verdict: Conditional pass (internal only)

### Hard fails
- PII: thinkmay@dev.net visible 33s–51s → re-record with masked sidebar

### Warnings
- 44s: overlapping captions "Turn on…" + "Save changes"
- 4.1s: minor white flash at intro handoff

### Required scenes gate
- Download ✅  Settings ✅  Advanced ✅  Toggle ✅  Save ✅  Connect ✅
```

Reference audits: `windows-desktop-pwa-60s_v1`, `game-install-witcher3-60s_v1` (2026-06-11).

## Recording & editing QA (summary)

- **Recording:** raw MP4 landing + ending frames; duration vs metadata
- **Pre-render:** required scenes gate + HyperFrames lint/validate/inspect
- **Post-render:** this document — **never skip for shipped marketing videos**

**Pipeline principle:** verify **pixels in the raw MP4**, then calibrate sync, then audit the final MP4. Metadata timestamps are hints, not ground truth for video time.

See [quality-gates.md](../quality-gates.md).
