# AI agent configuration (monorepo)

Canonical Claude Code and Cursor guidance lives here — **not** in git submodules.

## Layout

| Path | Purpose |
|------|---------|
| [`.CURSOR.md`](./.CURSOR.md) | Cursor rules shared across components |
| [`mobile/CLAUDE.md`](./mobile/CLAUDE.md) | Flutter mobile app (`mobile/` submodule) |
| [`mobile/specs/`](./mobile/specs/) | Mobile implementation specs (Cubit ↔ API) |
| [`mobile/TASK.md`](./mobile/TASK.md) | Active mobile work log |

## Product docs (source of truth)

Agent config references product architecture under [`../product/`](../product/).  
Do not duplicate product/protocol content in `docs/ai/` — link to `docs/product/` instead.

## Submodule stubs

The `mobile/` submodule keeps thin pointer files only (`CLAUDE.md`, `specs/README.md`)  
that link back to this folder when the app is checked out inside the monorepo.
