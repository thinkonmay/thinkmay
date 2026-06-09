# Working with Specs

## Layers — thinkmay/docs is canonical

| Content type | Edit here |
|--------------|-----------|
| Product (Stars, missions, user flows, design intent) | [`../../../product/`](../../../product/) |
| WebRTC/HID protocol, PWA parity | [`../../../product/architecture/`](../../../product/architecture/) |
| Cubit status, mock API, `lib/` file paths | `docs/ai/mobile/specs/` + [`API-COVERAGE.md`](./API-COVERAGE.md) |
| Active work | [`../TASK.md`](../TASK.md) |

Read first: **[00-docs-hierarchy.md](./00-docs-hierarchy.md)**

## What are mobile specs?

They supplement **implementation** — they do not replace the PRD. Every mobile spec must link to canonical docs in `thinkmay/docs`.

**When writing/editing:** canonical doc → `lib/` — **do not** rely on `CLAUDE.md` alone.

## When to update?

- **thinkmay/docs** — product, policy, or protocol changes (edit canonical first)
- **mobile specs + TASK + API-COVERAGE** — wire API, fix Cubit, change app behavior

## PR review

1. Product change → `thinkmay/docs`?
2. Mobile change → `specs/` + `API-COVERAGE.md` + `TASK.md`?
3. Parity item → tick [`mobile_sync_checklist.md`](../../../product/architecture/mobile_sync_checklist.md)?

## Read before coding

1. [`00-docs-hierarchy.md`](./00-docs-hierarchy.md)
2. [`TASK.md`](../TASK.md)
3. Screen spec + [`client_protocol_contract.md`](../../../product/architecture/client_protocol_contract.md) if streaming
