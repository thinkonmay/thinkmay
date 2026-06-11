# Lessons Learned

Update this file after each completed video. Reference by project name and date.

## Recording

1. **Ghost-cursor is version-fragile.** Prefer custom Bezier over `page.mouse.move()` with ≥25 steps, 8–15ms/step, control-point jitter.

2. **Inject a realistic cursor** (48×48 PNG or inline SVG). Re-inject after every navigation. Do not use a CSS circle.

3. **Re-encode WebM before HyperFrames import** — Playwright WebM often reports `Duration: N/A`. Always verify output length matches metadata:
   ```bash
   ffmpeg -y -fflags +genpts -i raw_recording.webm \
     -c:v libx264 -preset fast -r 30 -g 30 -keyint_min 30 -pix_fmt yuv420p \
     -movflags +faststart raw_recording.mp4
   ffprobe -v error -show_entries format=duration -of csv=p=0 raw_recording.mp4
   ```
   If MP4 duration is shorter than the last metadata timestamp by >2s, the encode truncated or the capture ended early — **do not proceed to sync**.

4. **Script timestamps ≠ video timestamps** (`windows-desktop-pwa-60s_v1`, 2026-06-11). `recording_metadata.md` uses wall clock from script start (includes browser launch). Playwright video starts later. A single fixed offset is insufficient — early events (landing) and late events (Connect) drift differently. **Fix:** calibrate with landing + end-padding anchors vs `ffprobe` duration when building `sync-timing.json` (see [sync-timing.md](./sync-timing.md#script-clock-to-video-time-calibration)).

5. **Verify raw footage, not just metadata.** Playwright can pass `waitForURL(/play/)` and log "Connect highlighted" while the WebM still shows the previous page (SPA client nav may not repaint before capture ends). **Gate before editing:**
   ```bash
   DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 editing/raw_recording.mp4)
   ffmpeg -y -ss $(echo "$DUR - 3" | bc) -i editing/raw_recording.mp4 -vframes 1 -q:v 2 /tmp/end-check.png
   ```
   Ending frame must show `/play` dashboard with Connect/Power on — not Settings. Re-record if not.

6. **Return to dashboard with hard navigation** after Save. Sidebar "Home" / `/play` link clicks may not repaint in capture. Prefer `page.goto('…/play', { waitUntil: 'domcontentloaded' })` + wait for Connect/Power on visible + 3s hold before end padding.

7. **Record at natural speed; compress in composition** via `data-playback-rate` — do not rush actions during capture.

8. **Hover download buttons; do not click** — real downloads stall Playwright.

9. **Inline SVG pointer** survives navigation without separate assets (`record_shared.mjs` pattern).

10. **Copy patterns from `record_shared.mjs`** — dev overlay hiding, login verification, stable selectors.

11. **Production URL (`thinkmay.net`) works** when credentials and UI are stable.

12. **PII masking must cover sidebar email and display name**, not only password fields (`windows-desktop-pwa-60s_v1` audit, 2026-06-11). Password `-webkit-text-security` alone left `thinkmay@dev.net` and "Thinkmay developer - Hoang" readable — **hard fail** for public marketing.

13. **Pre-flight dashboard health.** Abort or switch accounts if `/play` shows "System Issue Detected" cards instead of Connect/Power on VMs (`windows-desktop-pwa-60s_v1` at ~33s).

## Editing (HyperFrames)

11. **Nested `<video data-start>` freezes** — video must be direct child of root composition.

12. **Caption pills at opacity 0 fail contrast validate** — use `--no-contrast` during iteration.

13. **Hero toggle gets longest caption window** (4–6s).

14. **Download page is visually strong** for desktop tutorials — prioritize Windows card + Recommended badge.

15. **`caption-overrides.json` required** — empty `{}` at editing root.

16. **Duplicate logo lint warning** — safe to ignore unless `--strict`.

17. **Intro → A-roll white flash** (`windows-desktop-pwa-60s_v1` at ~4s): caused by fading/hiding `#video-wrap`, **or** `data-media-start` pointing at recording padding/white frames before landing paints. Keep `#video-wrap` at `opacity: 1`; set `mediaStart` to the **first frame where landing is visible in the MP4** (often several seconds into the file — not the metadata "Landing loaded" script time). Audit keyframe at `videoDataStart + 0.1s`.

18. **Automate sync from metadata** — use `editing/scripts/build-sync-timing.mjs` + `apply-sync-to-html.mjs` (`windows-desktop-pwa-60s_v1`). Never hand-edit GROUPS after a re-record. Script must calibrate script clock → video time and normalize non-overlapping captions + narration.

19. **Narration overlap is a lint error** — scene-01 (intro VO) often overlaps scene-02 if both start from landing metadata. After building narration array, enforce `next.start >= prev.start + prev.duration + 0.05` on the same `data-track-index`.

20. **Overlapping caption windows** (`windows-desktop-pwa-60s_v1` at ~44s): two pills visible ("Turn on…" + "Save changes"). Rule: `prior.end <= next.start` (normalize pass in build script).

21. **Caption lags narration** (`windows-desktop-pwa-60s_v1` at ~16s): scene-03 voice started while caption still said "Open the Download page". Align narration and caption `start`; end prior caption before next beat.

22. **Connect caption must start at dashboard loaded**, not at Save or Connect metadata if SPA return lags — anchor to `Dashboard loaded — ending scene` event, not `Connect button highlighted` alone.

23. **Outro black gap** (~54s): A-roll ended while outro started late. Derive `outroStart ≈ (videoDataStart + aRollDuration) - 0.5` and crossfade A-roll out while outro fades in.

24. **`multiple_root_compositions` lint error** when `index.html` and `index-vi.html` both sit at editing root. Move secondary languages to `editing/compositions/` with `../` asset paths.

25. **Lint scans all HTML** — `duplicate_audio_track` warnings if EN and VI audio both discoverable; render still uses specified composition. Expected when both compositions live in one project tree.

## Voice (TTS)

23. **Kokoro requires Python ≥3.10.**

24. **edge-tts on macOS:** use `python3 -m edge_tts`.

25. **Walkthrough sync ground truth is `recording_metadata.md`**, not skeleton or uniform 4s blocks (`pwa-desktop-60s`, `windows-desktop-pwa-30s_v1`).

## General pipeline

26. **QA keyframe extraction** — `ffmpeg -ss T -i final.mp4 -vframes 1 -q:v 2 frame.png`; PNG size hints at scene complexity.

27. **Separate `data-track-index`** for intro, A-roll, audio tracks, outro.

28. **Halt on failed login** — never teleport to authenticated UI.

29. **Per-project folders** under `marketing/video/<name>_v<N>/`.

30. **Final MP4 at project root** via `finalize-output.mjs`.

31. **Login/typing runs longer than skeleton** — extend caption/voice windows to metadata span.

32. **Never copy composition times across playback rates** (`windows-desktop-pwa-30s_v1`: 1.65× + copied 60s timings → settings invisible during voice).

33. **Target duration is output, not cap** — extend to 48–60s rather than `playbackRate` >1.2×.

34. **Never truncate `data-duration` below MP3 length.**

35. **Login jump-cut optional** for install tutorials — remap sync after splice.

36. **Required scenes gate mandatory** before render.

37. **Final video audit on rendered MP4** — lint passing ≠ shippable; audit PII, intro flash, caption overlap (`windows-desktop-pwa-60s_v1`, 2026-06-11).

38. **Docs split** — spec lives in `docs/marketing/video/`; see [README.md](./README.md).

## Project reference table

| Project | Lesson |
|---------|--------|
| `pwa-desktop-60s` | Uniform caption blocks → sync drift |
| `windows-desktop-pwa-30s_v1` | 1.65× playback + copied timings → dropped settings |
| `windows-desktop-pwa-60s_v1` | Sync tooling + 1.08× baseline; script≠video clock; verify raw MP4 ending; intro flash fixed via `mediaStart`; Connect ending still capture-sensitive |
| `desktop_install_v3` | Solid 60s composition baseline |
