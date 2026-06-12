# Video Creation AI Agent — Instructions

> **This file is the compatibility entry point.** The full specification is split across [README.md](./README.md) and linked docs below. Agents should read the README index first, then the stage-specific guides.

## Quick links

- [Pipeline overview & toolchain](./overview.md)
- [Workspace structure](./workspace.md)
- [Execution protocol (step-by-step)](./execution-protocol.md)
- [Sync timing rules](./sync-timing.md)
- [Quality gates & final audit](./quality-gates.md)
- [Lessons learned](./lessons-learned.md)

## Agent guides

[agents/research.md](./agents/research.md) · [agents/planning.md](./agents/planning.md) · [agents/recording.md](./agents/recording.md) · [agents/editing.md](./agents/editing.md) · [agents/voice.md](./agents/voice.md) · [agents/assembly.md](./agents/assembly.md) · [agents/qa.md](./agents/qa.md)

## Non-negotiable rules (summary)

0. **New projects** — scaffold from `marketing/video/_template-60s_v1` via `node marketing/video/scripts/scaffold-project.mjs <slug> --flow game-install|pwa-desktop|disk-upgrade`. Customize `record_shared.mjs` and `build-sync-timing.mjs`; do not start from scratch. Run `node scripts/run-pipeline.mjs <lang>` **from the project root** — see `_template-60s_v1/PIPELINE-NOTES.md`.
1. **Sync ground truth** — caption and narration times come from `recording_metadata.md` **calibrated to the re-encoded MP4**, not script timestamps directly, uniform blocks, or prior projects. Use `build-sync-timing.mjs`. See [sync-timing.md](./sync-timing.md).
2. **Verify raw footage** — before sync, confirm landing and dashboard ending frames in `raw_recording.mp4`. Metadata can lie (SPA nav). See [agents/recording.md](./agents/recording.md#post-recording).
3. **Required scenes** — verify the UI matches the tutorial type at each caption time. Desktop/PWA install: Download → Settings → Advanced → toggle → Save → Connect. Game install: landing → login → Store → game page → confirm → `/play` with game on VM card. See [quality-gates.md](./quality-gates.md#required-scenes-gate).
4. **PII** — no emails, real names, or account labels in public renders. See [agents/recording.md](./agents/recording.md#pii-masking-public-marketing).
5. **Final audit** — extract keyframes from rendered `final_<lang>.mp4` before shipping. Lint passing ≠ shippable. See [agents/qa.md](./agents/qa.md).
6. **Multi-language** — one native pipeline per language; non-primary compositions live under `editing/compositions/`. See [agents/editing.md](./agents/editing.md#multi-language-compositions).
7. **ElevenLabs Model** — Vietnamese narration **must** use `eleven_v3` (`eleven_multilingual_v2` is broken for Vietnamese). English defaults to `eleven_multilingual_v2`. Configure pronunciation dictionaries for brand consistency. See [agents/voice.md](./agents/voice.md).
8. **Premium Visual Editing** — avoid bland slides/fades; always implement grid/glow backgrounds, kinetic title cards, animated caption entrances, and **click ripples on every recorded click**. See [agents/editing.md](./agents/editing.md).
9. **Lossless Recording & Max-Fidelity Render** — record Playwright walkthroughs at FullHD (1920×1080) 90fps lossless; render finals with `--quality high --fps 60`; `finalize-output.mjs` must **copy** the render, never transcode it. See [agents/recording.md](./agents/recording.md).
10. **Mandatory Zoom Coverage** — never show the full uncropped browser for >6s during instruction; zoom every "click X" beat to the target + its container, computed per [camera-zoom.md](./camera-zoom.md). ≥50% of A-roll at ≥1.2×.
11. **Pacing** — no char-by-char typing on camera (instant `fill()`); intro 3–4.5s; outro 3–4.5s; composition duration derived from A-roll end — **zero black frames after the outro**. See [brand-design.md](./brand-design.md).
12. **Soundscape** — every shipped video has a low-volume music bed (≤0.15), click SFX, and popup whooshes in addition to narration. Voice-only mixes are a shipping blocker. See [brand-design.md](./brand-design.md#soundscape-mandatory-for-shipped-tutorials).
