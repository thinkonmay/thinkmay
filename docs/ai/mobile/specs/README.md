# Thinkmay Mobile — Feature Specifications

**Flutter implementation** documentation — code status, file paths, API coverage. **Does not** replace product specs.

## Document sources

| Layer | Location | Role |
|-------|----------|------|
| **Product & parity (canonical)** | [`../../../product/`](../../../product/) | Gamification, user flows, mobile sync checklist, protocol |
| **Mobile work** | [`TASK.md`](../TASK.md) | Active tasks, done log, implementation checklist |
| **Per-screen specs** | `docs/ai/mobile/specs/` (this folder) | Cubit/API status + links to `mobile/lib/` code |
| **Dev/AI** | [`CLAUDE.md`](../CLAUDE.md), [`.CURSOR.md`](../../.CURSOR.md) | Build commands, TASK update rules |

Full layering: **[00-docs-hierarchy.md](./00-docs-hierarchy.md)**

**When writing/editing specs:** read canonical docs in `thinkmay/docs` first → compare with `lib/` → update [API-COVERAGE.md](./API-COVERAGE.md) + [TASK.md](../TASK.md).

## Folder structure

```
specs/
├── 00-docs-hierarchy.md
├── README.md
├── API-COVERAGE.md
├── 01-app-bootstrap-global-state.md
├── 07-worker-api-session.md
├── 18-backend-integration.md
├── 20-app-release-publishing.md
├── auth/ … profile/ … remote/ …
```

## API status

**[API-COVERAGE.md](./API-COVERAGE.md)** — Cubit ↔ API.

**[mobile_sync_checklist.md](../../../product/architecture/mobile_sync_checklist.md)** — PWA ↔ mobile parity (77 items, thinkmay/docs).

| Symbol | Meaning |
|--------|---------|
| ✅ | UI/Cubit calls API on the correct user flow |
| 🟡 | Partial |
| 🔴 | Mock / stub |
| ⚪ | No API needed |

## Spec catalog

### Cross-cutting

| # | File | Canonical doc |
|---|------|---------------|
| 00 | [00-docs-hierarchy.md](./00-docs-hierarchy.md) | Index |
| 01 | [01-app-bootstrap-global-state.md](./01-app-bootstrap-global-state.md) | [client_user_flow_contract](../../../product/architecture/client_user_flow_contract.md) |
| 07 | [07-worker-api-session.md](./07-worker-api-session.md) | [client_protocol_contract](../../../product/architecture/client_protocol_contract.md) |
| 18 | [18-backend-integration.md](./18-backend-integration.md) | [technical_doc](../../../product/architecture/technical_doc.md) |
| 20 | [20-app-release-publishing.md](./20-app-release-publishing.md) | — |

### Per screen

| API | Folder | File |
|-----|--------|------|
| ✅ | [auth](./auth/) | [02-authentication.md](./auth/02-authentication.md) |
| ✅ | [auth](./auth/) | [03-authentication-test-cases.md](./auth/03-authentication-test-cases.md) |
| ⚪ | [home](./home/) | [03-navigation-home-shell.md](./home/03-navigation-home-shell.md) |
| 🟡 | [dashboard](./dashboard/) | [04-dashboard-cloud-pc.md](./dashboard/04-dashboard-cloud-pc.md) |
| ✅ | [remote](./remote/) | [05-remote-streaming-webrtc.md](./remote/05-remote-streaming-webrtc.md) |
| ✅ | [remote](./remote/) | [06-virtual-controls-sidepane.md](./remote/06-virtual-controls-sidepane.md) |
| 🟡 | [remote](./remote/) | [19-remote-streaming-optimization.md](./remote/19-remote-streaming-optimization.md) |
| 🟡 | [explore](./explore/) | [12-explore-games-store.md](./explore/12-explore-games-store.md) |
| 🔴🟡 | [payment](./payment/) | [11-payment-wallet.md](./payment/11-payment-wallet.md) |
| 🟡 | [subscription](./subscription/) | [10-subscriptions-plans.md](./subscription/10-subscriptions-plans.md) |
| 🟡 | [profile](./profile/) | [09-profile-account.md](./profile/09-profile-account.md) |
| 🟡 | [setting](./setting/) | [08-settings-configuration.md](./setting/08-settings-configuration.md) |
| 🔴 | [setting](./setting/) | [15-localization.md](./setting/15-localization.md) |
| 🟡 | [setting](./setting/) | [16-network-domain-diagnostics.md](./setting/16-network-domain-diagnostics.md) |
| ✅ | [banner](./banner/) | [13-banners-marketing.md](./banner/13-banners-marketing.md) |
| ⚪ | [welcome](./welcome/) | [14-onboarding-welcome.md](./welcome/14-onboarding-welcome.md) |
| 🔴 | [error](./error/) | [17-error-handling-support.md](./error/17-error-handling-support.md) |

## How to work

0. [`00-docs-hierarchy.md`](./00-docs-hierarchy.md) + canonical docs in `thinkmay/docs`
1. [`TASK.md`](../TASK.md)
2. Screen spec + `API-COVERAGE.md`
3. Parity → [`mobile_sync_checklist.md`](../../../product/architecture/mobile_sync_checklist.md)

[CONTRIBUTING.md](./CONTRIBUTING.md)

## Parity (summary)

Per [mobile_sync_checklist.md](../../../product/architecture/mobile_sync_checklist.md): storage, snapshots, AI store, gamification UI, community/support, onboarding tours — not done.

**Profile tab** = PWA `/profile` ([gamification.md](../../../product/features/gamification.md)).

*Updated: 2026-06-07*
