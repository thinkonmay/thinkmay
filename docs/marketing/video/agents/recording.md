# Recorder Agent

**Input:** `video_skeleton_<lang>.md`, codebase, target URL  
**Output:** `recording/artifacts/output/<lang>/raw_recording.webm`, `recording_metadata.md`

**Skills:** `playwright`, `playwright-video`, `ghost-cursor` (optional — prefer custom Bezier; see [lessons-learned.md](../lessons-learned.md))

## Setup

- **Resolution & Frame Rate**: Viewport FullHD 1920×1080, `deviceScaleFactor: 2`. Always record Playwright browser walkthroughs at **lossless visual quality at 90fps** to guarantee perfectly crisp UI details and ultra-smooth cursor movement.
- `recordVideo` size matches viewport (1920×1080)
- Locale per language (`en-US` / `vi-VN`, `/en` / `/vi` paths)
- **Chrome user-agent** for headless capture (avoids Browser Incompatible modal)
- Init script: `localStorage.setItem('browser_warning_last_seen', …)` before first navigation
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

### Capture target bounding boxes at mark time

Every `mark()` for an element the editor will zoom to or caption against **must include the element's bounding box**. Viewport CSS px equal raw-video px (1920×1080 viewport), so these coordinates feed directly into the zoom math in [camera-zoom.md](../camera-zoom.md) without frame measurement:

```js
async function markTarget(label, locator) {
  const box = await locator.boundingBox();   // { x, y, width, height }
  mark(box
    ? `${label} | bbox=${Math.round(box.x)},${Math.round(box.y)},${Math.round(box.width)},${Math.round(box.height)} center=${Math.round(box.x + box.width / 2)},${Math.round(box.y + box.height / 2)}`
    : `${label} | bbox=unavailable`);
}
// usage:
await markTarget("Disk button visible", page.getByRole("button", { name: /Disk/i }));
```

If a bbox is unavailable (element detached), the frame-review agent measures it from the extracted keyframe instead — but recorded boxes are preferred.

## Frame review handoff

After the raw footage gate passes, the **frame review round** ([agents/review.md](./review.md)) runs on the re-encoded MP4 and appends a `## Frame review` section to `recording_metadata.md` — pixel-verified event times, target coordinates, dead-air spans, anomalies. Recording is not complete until that section exists; the editor agent refuses to sync without it.

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
   Compare MP4 duration to the last metadata timestamp ("End padding"). Gap >2s → investigate before sync. **Do not run `build-sync-timing.mjs` until ffmpeg has finished** (incomplete MP4 → `moov atom not found`).

2. **Raw footage gate** — metadata alone is not sufficient:
   ```bash
   # Intro: landing visible (not white)
   ffmpeg -y -ss 3.5 -i raw_recording.mp4 -vframes 1 -q:v 2 /tmp/check-landing.png

   # Ending: dashboard with Connect/Power on (not Settings)
   DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 raw_recording.mp4)
   ffmpeg -y -ss $(echo "$DUR - 3" | bc) -i raw_recording.mp4 -vframes 1 -q:v 2 /tmp/check-end.png
   ```
   Fail the recording gate if ending frame is still Advanced Settings, login, store confirm dialog, or install spinner — **must show `/play` dashboard with game/template on VM card** for game-install tutorials.

3. QA gate: extract keyframes at **video-calibrated** times → audit vs descriptions

## Ending scene (dashboard)

Return to `/play` with **hard navigation** — SPA sidebar clicks may not repaint in capture:

```js
await page.goto(`${TARGET_URL}${config.pathPrefix}/play`, {
  waitUntil: "domcontentloaded",
});
await page.waitForLoadState("networkidle");
await dismissBrowserWarning(page);
await page.waitForTimeout(3000);
await maskPii(page);
// verify Connect or Power on visible before mark("Connect button highlighted")
```

Hold **3–5s** on dashboard (Connect/Power on hover) before end padding so the frame appears in the WebM.

**PWA/desktop install:** after Save on Advanced Settings, use the same hard `/play` navigation (do not rely on sidebar Home).

### Dashboard detection (game install tutorials)

Do **not** use `getByText(/Game Name/i)` alone — it matches the store detail page and causes false "installed" marks while the MP4 still shows the store or `change_template/pending`.

```js
const onPlay = page.url().includes("/play");
const onDashboard = await page.getByText(/Cloud PC Dashboard/i).isVisible();
const gameOnCard = await page
  .locator("h3")
  .filter({ hasText: /Witcher 3/i })
  .first()
  .isVisible();
// all three must be true before mark("Game installed — … on dashboard")
```

## Game install tutorials

Additional rules for store → template install flows (reference: `game-install-witcher3-60s_v1`):

| Step | Rule |
|------|------|
| Pre-install | After login, visit `/play`; if **Shut down** visible, shut down VM and wait ~8s |
| Store navigation | Open Explore sidebar, then **direct `page.goto` to game URL** — search is fragile |
| Install CTA | Wait for `#subscribe-button` or `#set-template-button` **attached**; scroll into view |
| Confirm | Click Confirm in modal; wait for install (poll `/play` every ~20s, not every 5s) |
| Ending | `/play` with game name on VM card + Connect or Power on; 5s end padding |

Account must have an **installable volume** for the template. If install button missing → fix account/subscription before recording.

## Browser Incompatible modal

Headless Chromium may show a full-screen "Browser Incompatible" dialog. Dismiss before continuing:

```js
async function dismissBrowserWarning(page) {
  if (await page.getByText(/Browser Incompatible/i).isVisible().catch(() => false)) {
    await page.getByRole("button", { name: /Confirm/i }).first().click();
  }
}
```

Call after landing, login, and each `/play` navigation.

## Canonical references

- `marketing/video/windows-desktop-pwa-60s_v1/recording/scripts/record_shared.mjs` — PWA/desktop install
- `marketing/video/game-install-witcher3-60s_v1/recording/scripts/record_shared.mjs` — game template install
- `marketing/video/records/demo/record.spec.js` (if present)
