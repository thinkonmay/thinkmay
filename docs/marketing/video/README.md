# Marketing Video Pipeline

Autonomous pipeline for product walkthrough and tutorial videos: idea → research → planning → recording → editing → voice → assembly → QA.

**Start here:** read [overview.md](./overview.md) for the pipeline diagram, then follow [execution-protocol.md](./execution-protocol.md) step by step.

## Documentation map

| Doc | Purpose |
|-----|---------|
| [overview.md](./overview.md) | Toolchain, pipeline diagram, secrets |
| [workspace.md](./workspace.md) | Project naming, directory tree, multi-language rules |
| [execution-protocol.md](./execution-protocol.md) | Step-by-step commands for each stage |
| [sync-timing.md](./sync-timing.md) | Caption/narration timing from recording metadata |
| [quality-gates.md](./quality-gates.md) | Recording, editing, audio, and **final video audit** checklists |
| [artifact-formats.md](./artifact-formats.md) | Templates for research brief, skeleton, script, metadata |
| [error-recovery.md](./error-recovery.md) | Failure → fix lookup table |
| [brand-design.md](./brand-design.md) | Brand and motion guidelines |
| [lessons-learned.md](./lessons-learned.md) | Post-mortems from completed projects (update after each video) |

## Agent guides

Each pipeline stage has a dedicated agent guide under [agents/](./agents/):

| Agent | Guide |
|-------|--------|
| Research | [agents/research.md](./agents/research.md) |
| Planning | [agents/planning.md](./agents/planning.md) |
| Recording | [agents/recording.md](./agents/recording.md) |
| Editing | [agents/editing.md](./agents/editing.md) |
| Voice | [agents/voice.md](./agents/voice.md) |
| Assembly | [agents/assembly.md](./agents/assembly.md) |
| QA | [agents/qa.md](./agents/qa.md) |

## Runtime assets

| Path | Purpose |
|------|---------|
| `marketing/video/.env` | Shared secrets (`TM_USERNAME`, API keys) — never commit |
| `marketing/video/<project>_v<N>/` | Versioned video projects and `final_*.mp4` outputs |

## Reference projects

- `marketing/video/windows-desktop-pwa-60s_v1` — 60s desktop/PWA tutorial; **reference for sync tooling** (`build-sync-timing.mjs`, `apply-sync-to-html.mjs`) and script→video calibration
- `marketing/video/desktop_install_v3` — 60s composition reference
- `marketing/video/windows-desktop-pwa-30s_v1` — **anti-pattern:** 1.65× playback, copied timings
