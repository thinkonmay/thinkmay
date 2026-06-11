# Error Recovery

| Failure | Recovery |
|---------|----------|
| Recording fails mid-script | Retry from last checkpoint; scripts should be idempotent |
| Login fails | **Halt.** Check `.env`, site access, re-record. Never continue to authenticated pages |
| Dashboard shows errors | Use healthy demo account or fix backend; re-record `/play` segments |
| Metadata says Connect but MP4 shows Settings | SPA nav not captured — use `page.goto(/play)` + raw ending frame check; re-record |
| MP4 duration << metadata end time | Re-encode with `-fflags +genpts`; if still short, recording ended early — re-record |
| Script vs video timing drift | Rebuild sync with landing+end calibration — [sync-timing.md](./sync-timing.md#script-clock-to-video-time-calibration) |
| PII visible in final audit | Add CSS masking in record script; re-record authenticated segments |
| White flash at intro handoff | Raise `mediaStart` to first visible landing frame in MP4; keep `#video-wrap` opacity 1 — [editing agent](./agents/editing.md#intro-to-a-roll-transition) |
| Connect caption over Settings UI | Anchor Connect caption to "Dashboard loaded" event; verify raw MP4 ending |
| Black gap before outro | Set `outroStart ≈ aRollEnd - 0.5`; overlap A-roll fade-out with outro fade-in |
| QA rejects recording | Adjust Playwright script → re-record; verify raw MP4 keyframes |
| QA rejects editing | Fix composition / sync-timing → re-render |
| Voice/caption drift | Rebuild `sync-timing.json` from metadata + calibration; fix caption overlap; regenerate audio |
| HyperFrames `overlapping_clips_same_track` | Stagger narration starts (scene-02 after scene-01 ends) in build script |
| Settings flashed too briefly | Lower `playbackRate` (≤1.2×), extend duration |
| Voice clipped | Set `data-duration` from `ffprobe`; separate `data-track-index` |
| Overlapping captions | Normalize in `build-sync-timing.mjs`; rule: `prior.end <= next.start` |
| HyperFrames `multiple_root_compositions` | Move secondary HTML to `editing/compositions/` |
| HyperFrames lint `duplicate_audio_track` | Expected warning if VI in `compositions/`; render uses one composition |
| HyperFrames validate 404 | Add `caption-overrides.json` (`{}`) |
| WebM seek freeze in render | Re-encode to MP4 with `-g 30 -fflags +genpts` |
| Kokoro fails on Python 3.9 | Use Python ≥3.10 or edge-tts |
| TTS poor quality | Switch voice or use ElevenLabs/OpenAI |

See [lessons-learned.md](./lessons-learned.md) for root-cause narratives.
