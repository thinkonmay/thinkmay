# Lessons Learned

Update this file after each completed video. Reference by project name and date.

## Recording

1. **Ghost-cursor is version-fragile.** Prefer custom Bezier over `page.mouse.move()` with ≥25 steps, 8–15ms/step, control-point jitter.

2. **Inject a realistic cursor** (48×48 PNG or inline SVG). Re-inject after every navigation. Do not use a CSS circle.

3. **Re-encode WebM before HyperFrames import** — Playwright WebM often reports `Duration: N/A`. Always verify output length matches metadata:
   ```bash
   ffmpeg -y -fflags +genpts -i raw_recording.webm \
     -c:v libx264 -preset medium -crf 14 -r 60 -g 60 -keyint_min 60 -pix_fmt yuv420p \
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

14. **Metadata can pass while footage fails** (`game-install-witcher3-60s_v1`, 2026-06-11). Playwright logged "Witcher visible on dashboard" while the MP4 still showed the store page or `change_template/pending` spinner — because `getByText(/Witcher/i)` matched the **game detail page**, not the VM card on `/play`. **Fix:** require `page.url()` includes `/play`, dashboard title visible ("Cloud PC Dashboard"), and game name on `h3` VM card. Always verify ending frame in raw MP4.

15. **Script events after video end are useless for sync** (`game-install-witcher3-60s_v1`). Wall clock ran ~63s while WebM/MP4 was ~49s — dashboard metadata at script 53s was off-video. Compare `ffprobe` duration to last metadata timestamp; hold 3–5s on `/play` before end padding so ending pixels are captured.

16. **Headless Chromium triggers Browser Incompatible modal** (`game-install-witcher3-60s_v1`). Set Chrome user-agent, seed `localStorage.browser_warning_last_seen`, dismiss Confirm on load — or overlay blocks the tutorial.

17. **Store search is fragile for automation** (`game-install-witcher3-60s_v1`). Search → click result often loads before `#subscribe-button` hydrates. Prefer direct `page.goto(…/store/<appId>/…)` + `waitFor({ state: "attached" })` on install CTA + `scrollIntoViewIfNeeded()`.

18. **Shut down VM before game template install** (`game-install-witcher3-60s_v1`). Backend rejects install when volume is in use. After login, visit `/play`; if Shut down is visible, click it and wait before opening Store.

19. **Install polling: reload sparingly** (`game-install-witcher3-60s_v1`). `page.goto(/play)` every 5s can leave blank SPA frames in capture. Reload at most every ~20s; wait for `networkidle` and `#desktop-store` before checking game card.

20. **Finish MP4 encode before sync** (`game-install-witcher3-60s_v1`). Running `build-sync-timing.mjs` while ffmpeg is still writing produced `moov atom not found` and wrong calibration.

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

26. **Kokoro requires Python ≥3.10** and `kokoro-onnx` + `soundfile`; onnxruntime conflicts can block install on some environments (`game-install-witcher3-60s_v1`).

27. **edge-tts on macOS:** use `python3 -m edge_tts`.

28. **macOS `say` + ffmpeg** is an acceptable fallback when Kokoro/edge-tts unavailable — verify each MP3 with `ffprobe` (first scene often fails silently if `say` output is empty).

29. **Walkthrough sync ground truth is `recording_metadata.md`**, calibrated to MP4 — not skeleton or uniform 4s blocks (`pwa-desktop-60s`, `windows-desktop-pwa-30s_v1`).

30. **ElevenLabs `eleven_multilingual_v2` is broken for Vietnamese** (`disk-upgrade-60s_v1`, 2026-06-12). Use `eleven_v3` via `ELEVEN_LABS_MODEL_VI` in `generate-narration.mjs`. English can stay on `eleven_multilingual_v2`.

## Editing — captions & framing (`disk-upgrade-60s_v1`, 2026-06-12)

43. **GSAP `className` tweens break in seek-based render.** Word-karaoke via `tl.set(word, { className: "+=active" })` left caption text **black/unstyled** in the rendered MP4 (worked in live preview). Fix: critical styles (`color: #fff`) on the pill base class; animate only GSAP properties (`y`, `opacity`, `scale`); no CSS `transition`/`:has(.active)` gating. See [agents/editing.md](./agents/editing.md#caption-styling-render-safe-patterns-only).

44. **Eyeballed zoom coordinates miss the target.** First zoom pass landed "nowhere" (user-visible defect at 0:21); corrected pass still clipped the VM card's text mid-glyph at the left edge. Zooms must be **computed** from measured target coords with clamp math + verification frames — [camera-zoom.md](./camera-zoom.md).

45. **Caption anchored to a script mark ≠ pixels.** "Your Cloud PC Dashboard is ready" displayed ~1.5s over the login form because the metadata mark fired before the dashboard painted. Anchor captions to **frame-review observed times** ([agents/review.md](./agents/review.md)).

46. **Unbudgeted outro absorbs the timeline.** Composition `data-duration` left the outro running 18.8s static (34% of runtime). Budget: intro 3.0–4.5s, outro 3.0–4.5s, `data-duration = outroStart + outro budget` — [brand-design.md](./brand-design.md#intro--outro-scene-standards-60s-tutorials).

47. **Typing segments create dead air.** ~6s of email/password typing had no caption, narration, or motion. Frame review flags `DEAD_AIR` spans; editor bridges with zoom-to-form or per-span playback-rate bump.

48. **Capture `boundingBox()` at `mark()` time.** Post-hoc frame measurement for zoom targets is slow and error-prone; viewport CSS px = raw-video px at 1920×1080, so recorded boxes feed the zoom math directly — [agents/recording.md](./agents/recording.md#capture-target-bounding-boxes-at-mark-time).

49. **Fixed-duration floors create black tails** (`disk-upgrade-60s_v1` VI, 2026-06-12). `DURATION = Math.max(60, …)` plus a 55s sync produced ~9s of black after the outro, and an outro CTA voice anchored at `DURATION − 5` played 9s into a silent card. Derive `DURATION = outroStart + outro budget (≤4.5s)` from the A-roll end; anchor the CTA at `outroStart + 0.7`.

50. **Zoom presence ≠ zoom coverage** (`disk-upgrade-60s_v1`, user review). Two zooms in a 60s video still left 0:04–0:40 at full-browser 1.0× — unreadable text, split-screen distraction. Coverage rule: ≤6s consecutive at 1.0× during instruction, ≥50% of A-roll at ≥1.2× — [camera-zoom.md](./camera-zoom.md#coverage-rule-when-to-zoom).

51. **Char-by-char typing is dead air at the source.** `keyboard.type(text, { delay: 80 })` burned ~10s on login. Fix in the recorder, not the editor: click the field, then `locator.fill()` instantly — template `humanType` updated.

52. **Voice-only mixes read as amateur.** Every shipped video needs a low-volume music bed (track 5, vol ≤0.15), click SFX at every `Clicked:` mark (track 6), and popup whooshes (track 7). `Clicked: … | center=x,y` marks also drive yellow click-ripple overlays. Automated via `clicks`/`popups` in `sync-timing.json`.

## General pipeline

30. **QA keyframe extraction** — `ffmpeg -ss T -i final.mp4 -vframes 1 -q:v 2 frame.png`; PNG size hints at scene complexity.

31. **Separate `data-track-index`** for intro, A-roll, audio tracks, outro.

32. **Halt on failed login** — never teleport to authenticated UI.

33. **Per-project folders** under `marketing/video/<name>_v<N>/`.

34. **Final MP4 at project root** via `finalize-output.mjs`.

35. **Login/typing runs longer than skeleton** — extend caption/voice windows to metadata span.

36. **Never copy composition times across playback rates** (`windows-desktop-pwa-30s_v1`: 1.65× + copied 60s timings → settings invisible during voice).

37. **Target duration is output, not cap** — extend to 48–60s rather than `playbackRate` >1.2×.

38. **Never truncate `data-duration` below MP3 length.**

39. **Login jump-cut optional** for install tutorials — remap sync after splice.

40. **Required scenes gate mandatory** before render — checklist varies by tutorial type (PWA vs game install).

41. **Final video audit on rendered MP4** — lint passing ≠ shippable; audit PII, intro flash, caption overlap (`windows-desktop-pwa-60s_v1`, `game-install-witcher3-60s_v1`, 2026-06-11).

42. **Docs split** — spec lives in `docs/marketing/video/`; see [README.md](./README.md).

## Project reference table

| Project | Lesson |
|---------|--------|
| `pwa-desktop-60s` | Uniform caption blocks → sync drift |
| `windows-desktop-pwa-30s_v1` | 1.65× playback + copied timings → dropped settings |
| `windows-desktop-pwa-60s_v1` | Sync tooling + 1.08× baseline; script≠video clock; verify raw MP4 ending; intro flash fixed via `mediaStart`; Connect ending still capture-sensitive |
| `game-install-witcher3-60s_v1` | Strict `/play` dashboard detection (URL + h3 card); direct store URL vs search; Browser Incompatible modal; false-positive "installed" on store page; encode-before-sync; 5s end hold on dashboard |
| `desktop_install_v3` | Solid 60s composition baseline |
| `disk-upgrade-60s_v1` | className-tween karaoke → black captions in seek render; eyeballed zooms miss/clip targets; caption ahead of pixels (login vs dashboard); 18.8s static outro; dead air during typing → motivated frame-review round + camera-zoom.md + intro/outro budgets |
