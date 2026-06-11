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

0. **New projects** — scaffold from `marketing/video/_template-60s_v1` via `node marketing/video/scripts/scaffold-project.mjs <slug> --flow game-install|pwa-desktop`. Customize `record_shared.mjs` and `build-sync-timing.mjs`; do not start from scratch.
1. **Sync ground truth** — caption and narration times come from `recording_metadata.md` **calibrated to the re-encoded MP4**, not script timestamps directly, uniform blocks, or prior projects. Use `build-sync-timing.mjs`. See [sync-timing.md](./sync-timing.md).
2. **Verify raw footage** — before sync, confirm landing and dashboard ending frames in `raw_recording.mp4`. Metadata can lie (SPA nav). See [agents/recording.md](./agents/recording.md#post-recording).
3. **Required scenes** — verify the UI matches the tutorial type at each caption time. Desktop/PWA install: Download → Settings → Advanced → toggle → Save → Connect. Game install: landing → login → Store → game page → confirm → `/play` with game on VM card. See [quality-gates.md](./quality-gates.md#required-scenes-gate).
4. **PII** — no emails, real names, or account labels in public renders. See [agents/recording.md](./agents/recording.md#pii-masking-public-marketing).
5. **Final audit** — extract keyframes from rendered `final_<lang>.mp4` before shipping. Lint passing ≠ shippable. See [agents/qa.md](./agents/qa.md).
6. **Multi-language** — one native pipeline per language; non-primary compositions live under `editing/compositions/`. See [agents/editing.md](./agents/editing.md#multi-language-compositions).
