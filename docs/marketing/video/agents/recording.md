# Recorder Agent

**Input:** `video_skeleton_<lang>.md`, codebase, target URL  
**Output:** `recording/artifacts/output/<lang>/raw_recording.webm`, `recording_metadata.md`

**Skills:** `playwright`, `playwright-video`, `ghost-cursor` (optional — prefer custom Bezier; see [lessons-learned.md](../lessons-learned.md))

## Setup

- Viewport 1920×1080, `deviceScaleFactor: 2`
- `recordVideo` size matches viewport
- Locale per language (`en-US` / `vi-VN`, `/en` / `/vi` paths)
- Custom pointer injection (inline SVG or PNG) — re-inject after every navigation
- Hide Next.js dev overlay via init script

## Account pre-flight

Before recording authenticated segments:

1. Log in with credentials from `marketing/video/.env`
2. Navigate to `/play` and confirm **healthy dashboard** — at least one VM card with Connect/Power on, **not** error-only "System Issue Detected" cards dominating the view
3. If dashboard is unhealthy → fix account/backend or use a different demo account; **do not** record error states for marketing tutorials

Prefer a dedicated **marketing demo account** with:

- Generic display name (e.g. "Thinkmay Demo")
- No real personal email visible in sidebar (mask if needed — see below)

## PII masking (public marketing)

Masking password fields alone is **insufficient**. The following must not appear readable in the final video:

| Element | Mitigation |
|---------|------------|
| Sidebar email | CSS mask on profile block, or demo account |
| Account display name | Generic name on demo account, or CSS `text-indent` / overlay |
| Profile avatar | Acceptable if not identifying |
| Server hostname in badge | Usually OK (`saigon2.thinkmay.net`) |

**Recording script requirements:**

```js
// Extend init script beyond password fields
const PII_MASK = `
  [data-testid="user-email"], .user-email, aside [href*="mailto"] {
    filter: blur(6px) !important;
  }
  /* Or replace text via evaluate after login */
`;
```

Add a **post-login QA mark** in metadata: `PII check — sidebar email masked` and verify in recording gate keyframe.

Reference: `marketing/video/windows-desktop-pwa-60s_v1` audit — `thinkmay@dev.net` and "Thinkmay developer - Hoang" were visible (**hard fail** for public).

## Execution rules

- 2s start/end padding
- Human-like Bezier cursor (≥25 steps); hover download buttons — **do not click** (triggers real download)
- Per-action timestamps in `recording_metadata.md`
- Stable selectors: `#desktop-setting`, `#advance`, exact toggle label text per locale

## Login verification gate

After login, assert dashboard/post-login UI is visible. On failure:

1. Log timestamp and page state to metadata
2. **Halt immediately** — do not navigate to authenticated pages as if login succeeded

```js
await page.waitForURL("**/play**", { timeout: 20000 });
await page.waitForSelector("#desktop-setting, nav, .volume-card", {
  timeout: 10000,
  state: "visible",
});
mark("Login verified — dashboard visible");
```

## Post-recording

1. Re-encode WebM before editing (Playwright WebM often has no duration metadata):
   ```bash
   ffmpeg -y -fflags +genpts -i raw_recording.webm \
     -c:v libx264 -preset fast -r 30 -g 30 -keyint_min 30 -pix_fmt yuv420p \
     -movflags +faststart raw_recording.mp4
   ffprobe -v error -show_entries format=duration -of csv=p=0 raw_recording.mp4
   ```
   Compare MP4 duration to the last metadata timestamp ("End padding"). Gap >2s → investigate before sync.

2. **Raw footage gate** — metadata alone is not sufficient:
   ```bash
   # Intro: landing visible (not white)
   ffmpeg -y -ss 3.5 -i raw_recording.mp4 -vframes 1 -q:v 2 /tmp/check-landing.png

   # Ending: dashboard with Connect/Power on (not Settings)
   DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 raw_recording.mp4)
   ffmpeg -y -ss $(echo "$DUR - 3" | bc) -i raw_recording.mp4 -vframes 1 -q:v 2 /tmp/check-end.png
   ```
   Fail the recording gate if ending frame is still Advanced Settings or login.

3. QA gate: extract keyframes at **video-calibrated** times → audit vs descriptions

## Ending scene (dashboard Connect)

After Save, return to `/play` with **hard navigation** — SPA sidebar clicks may not repaint in capture:

```js
await page.goto(`${TARGET_URL}${config.pathPrefix}/play`, {
  waitUntil: "domcontentloaded",
});
await page.waitForLoadState("networkidle");
await page.waitForTimeout(3000);
await maskPii(page);
// verify Connect or Power on visible before mark("Connect button highlighted")
```

Hold 3s on Connect hover before end padding so the frame appears in the WebM.

## Canonical references

- `marketing/video/windows-desktop-pwa-60s_v1/recording/scripts/record_shared.mjs`
- `marketing/video/records/demo/record.spec.js` (if present)
