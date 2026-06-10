# Thinkmay Mobile — Feature Specifications

Tài liệu **implementation Flutter** — trạng thái code, file path, API coverage. **Không** thay product spec.

## Nguồn gốc tài liệu

| Layer | Vị trí | Vai trò |
|-------|--------|---------|
| **Product & parity (gốc)** | [`../docs/product/`](../docs/product/) | Gamification, user flows, mobile sync checklist, protocol |
| **Công việc mobile** | [`TASK.md`](../TASK.md) | Active tasks, done log, checklist implement |
| **Spec theo màn** | `specs/` (folder này) | Cubit/API status + link code `lib/` |
| **Dev/AI** | [`CLAUDE.md`](../CLAUDE.md), [`.CURSOR.md`](../.CURSOR.md) | Lệnh build, quy tắc cập nhật TASK |

Phân tầng đầy đủ: **[00-docs-hierarchy.md](./00-docs-hierarchy.md)**

**Khi viết/sửa spec:** đọc doc gốc trong `thinkmay/docs` trước → đối chiếu `lib/` → cập nhật [API-COVERAGE.md](./API-COVERAGE.md) + [TASK.md](../TASK.md).

## Cấu trúc thư mục

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

## Trạng thái API

**[API-COVERAGE.md](./API-COVERAGE.md)** — Cubit ↔ API.

**[mobile_sync_checklist.md](../docs/product/architecture/mobile_sync_checklist.md)** — parity PWA ↔ mobile (77 mục, thinkmay/docs).

| Ký hiệu | Ý nghĩa |
|---------|---------|
| ✅ | UI/Cubit gọi API đúng luồng |
| 🟡 | Một phần |
| 🔴 | Mock / stub |
| ⚪ | Không cần API |

## Danh mục specs

### Cross-cutting

| # | File | Doc gốc |
|---|------|---------|
| 00 | [00-docs-hierarchy.md](./00-docs-hierarchy.md) | Index |
| 01 | [01-app-bootstrap-global-state.md](./01-app-bootstrap-global-state.md) | [client_user_flow_contract](../docs/product/architecture/client_user_flow_contract.md) |
| 07 | [07-worker-api-session.md](./07-worker-api-session.md) | [client_protocol_contract](../docs/product/architecture/client_protocol_contract.md) |
| 18 | [18-backend-integration.md](./18-backend-integration.md) | [technical_doc](../docs/product/architecture/technical_doc.md) |
| 20 | [20-app-release-publishing.md](./20-app-release-publishing.md) | — |

### Theo màn hình

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

## Cách làm việc

0. [`00-docs-hierarchy.md`](./00-docs-hierarchy.md) + doc gốc `thinkmay/docs`
1. [`TASK.md`](../TASK.md)
2. Spec màn + `API-COVERAGE.md`
3. Parity → [`mobile_sync_checklist.md`](../docs/product/architecture/mobile_sync_checklist.md)

[CONTRIBUTING.md](./CONTRIBUTING.md)

## Parity (tóm tắt)

Theo [mobile_sync_checklist.md](../docs/product/architecture/mobile_sync_checklist.md): storage, snapshots, AI store, gamification UI, community/support, onboarding tours — chưa xong.

**Profile tab** = PWA `/profile` ([gamification.md](../docs/product/features/gamification.md)).

*Cập nhật: 2026-06-07*
