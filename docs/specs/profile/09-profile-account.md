# 09 — Profile & Account

## Tổng quan

Tab **Cá nhân** (`/profile`, Home tab 4) — mục tiêu **parity với website `/profile`** (gamification hub), không phải web `/setting/profile` (account edit).

| Route | Website | Mobile (target) |
|-------|---------|-------------------|
| Profile tab (nav) | `/profile` — Rank, quests, leaderboard, heatmap | `/profile` — cùng nội dung |
| Account edit | `/setting/profile` — avatar, name, email marketing | `/update-profile` (từ `/setting`) |
| Change password | `/setting/password` | `/change-password` (từ `/setting`) |

**Implementation checklist:** [`TASK.md`](../../TASK.md) mục **Profile tab — parity website `/profile`**

---

## Docs monorepo (`thinkmay/docs`) — đối chiếu

| Doc | Vai trò |
|-----|---------|
| [`gamification.md`](../../../docs/product/features/gamification.md) | **Product spec chính** — Stars, ranks, missions v2, RPC, Discord, telemetry |
| [`user_doc.md`](../../../docs/product/guides/user_doc.md) | End-user: Profile = hours played, allowance, expiration, disk metrics |
| [`thinkmay_mobile_design.md`](../../../docs/product/design/thinkmay_mobile_design.md) | UI intent: account/diagnostics trong **Settings**; Figma = source of truth |
| [`mobile_sync_checklist.md`](../../../docs/product/architecture/mobile_sync_checklist.md) | §G Profile tab `[~]`; account edit tách; §K remove refund UI |
| [`client_user_flow_contract.md`](../../../docs/product/architecture/client_user_flow_contract.md) | Profile tab vs account edit — hai route riêng |
| [`reward_mission.md`](../../../docs/product/features/reward_mission.md) | Legacy v1 — **không** implement; dùng v2 trong `gamification.md` |
| [`thinkmay_analytics_research.md`](../../../docs/marketing/analytics/thinkmay_analytics_research.md) | Profile UI metrics = cùng API customer-facing (usage, heatmap, subscription) |

---

## Trạng thái API (hiện tại → target)

> [API-COVERAGE.md](../API-COVERAGE.md)

| Thành phần | Hiện tại | Target |
|------------|----------|--------|
| User avatar/name | ✅ storage | ✅ + refresh PB khi cần |
| Usage / expiration | 🔴 hardcode | ✅ `subscription.total_usage`, limit, end date (`user_doc`) |
| Join date | 🔴 hardcode | ✅ `User.created` |
| Domain picker on profile | ✅ đã gỡ (C1) | ⚪ Chọn server ở `/network-check` / Settings (`mobile_design`) |
| Subscription card mock | 🔴 static | ⚪ Payment tab; profile chỉ plan badge trong RankBanner |
| Quests / stars / heatmap / leaderboard | 🔴 preload không emit UI | ✅ `GlobalCubit` + widgets |
| `claim_mission_v2` | ❌ | ✅ |
| Leaderboard | 🟡 `/api/leaderboard` legacy | ✅ `get_star_leaderboard` |
| Mission telemetry | ❌ | ✅ `session_device`, `ai_search_used` (`gamification.md` §4.5) |
| Update profile / change password | ✅ API, route orphan | ✅ link từ `/setting` (phase D TASK.md) |

---

## Website `/profile` — layout (reference)

```
RankBanner — stars, rank, avatar, plan, hours/allowance, expiration, addon charges, heatmap
RoadmapCard — 7 rank tiers + perks (coming soon)
LeaderboardCard — lifetime stars (get_star_leaderboard)
QuestsCard — missions v2 + claim + Discord + referral
```

Web: `website/app/[locale]/(app)/profile/page.tsx`, `website/components/profile/*`

---

## Mobile hiện tại (cần thay)

`profile_screen.dart`: account card (mock stats) → subscription card (API).

**Không khớp** `gamification.md` §7 nor `user_doc.md` Profile section.

---

## Liên kết

- [TASK.md](../../TASK.md) — checklist phase A–F
- [02-authentication](../auth/02-authentication.md)
- [10-subscriptions](../subscription/10-subscriptions-plans.md)
- [08-settings-configuration](../setting/08-settings-configuration.md)

*Cập nhật: 2026-06-07 — đối chiếu `thinkmay/docs`, sửa mâu thuẫn flow contract vs gamification.*
