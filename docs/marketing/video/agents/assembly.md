# Assembly Agent

**Input:** Edited composition, per-scene audio, `sync-timing.json`  
**Output:** `final_<lang>.mp4` at project root

## Render

```bash
cd editing
npm run check          # primary language
npm run render         # → final_en.mp4 at project root via finalize-output.mjs
npm run check:vi       # if using compositions/index-vi.html
npm run render:vi      # → final_vi.mp4
```

```bash
npx hyperframes render --quality high --output renders/final_en.mp4
node ../scripts/finalize-output.mjs final_en.mp4
```

## Pre-render checklist

- [ ] Raw MP4 gate passed (landing + dashboard ending frames) — [recording agent](./recording.md#post-recording)
- [ ] `sync-timing.json` built with script→video calibration — [sync-timing.md](../sync-timing.md)
- [ ] Required scenes gate passed (keyframes at caption starts)
- [ ] All narration `data-duration` values from `ffprobe`; no overlapping clips on same track
- [ ] Intro and outro transition frames audited (no white flash / black gap)

## Post-render

1. Copy to project root: `final_en.mp4`, `final_vi.mp4`
2. Mirror to `assembly/artifacts/output/` (optional)
3. Hand off to [QA agent](./qa.md) for **final video audit** on rendered MP4 — not just composition lint

## Sync QA (minimum)

At 4+ checkpoints (download, settings, toggle, connect), confirm frame content, caption text, and spoken topic align within ~2s.
