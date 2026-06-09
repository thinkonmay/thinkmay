# Documentation hierarchy — mobile

## Layers

| Layer | Location | Role |
|-------|----------|------|
| **Product (canonical)** | [`../../../product/`](../../../product/) | Gamification, user flows, protocol, design intent |
| **AI / implementation** | [`../`](..) + `specs/` (this folder) | Claude guide, TASK log, Cubit/API specs |
| **Application code** | [`../../../../mobile/lib/`](../../../../mobile/lib/) | Flutter source (`mobile/` submodule) |

## Which file to edit?

| Content | Edit here |
|---------|-----------|
| Product behavior, parity policy, WebRTC protocol | `docs/product/` |
| Cubit wiring, mock status, file paths | `docs/ai/docs/ai/mobile/specs/` + [API-COVERAGE.md](./API-COVERAGE.md) |
| Active tasks | [../TASK.md](../TASK.md) |
| Build commands, architecture overview | [../CLAUDE.md](../CLAUDE.md) |

## Workflow

1. Read product doc in `docs/product/`
2. Check [../TASK.md](../TASK.md) and relevant spec in this folder
3. Implement in `mobile/lib/`
4. Update [API-COVERAGE.md](./API-COVERAGE.md) and parity checklists in `docs/product/architecture/`
