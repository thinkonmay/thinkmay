# 09 — Profile & Account

## Overview

**Profile** tab (`/profile`, Home tab 4) — target **parity with website `/profile`** (gamification hub), not web `/setting/profile` (account edit).

| Route | Website | Mobile (target) |
|-------|---------|-----------------|
| Profile tab (nav) | `/profile` — Rank, quests, leaderboard, heatmap | `/profile` — same content |
| Account edit | `/setting/profile` — avatar, name, email marketing | `/update-profile` (from `/setting`) |
| Change password | `/setting/password` | `/change-password` (from `/setting`) |

**Implementation checklist:** [`TASK.md`](../../TASK.md) section **Profile tab — parity website `/profile`**

---

## Monorepo docs (`thinkmay/docs`) — comparison

| Doc | Role |
|-----|------|
| [`gamification.md`](../../../../product/features/gamification.md) | **Primary product spec** — Stars, ranks, missions v2, RPC, Discord, telemetry |
| [`user_doc.md`](../../../../product/guides/user_doc.md) | End-user: Profile = hours played, allowance, expiration, disk metrics |
| [`thinkmay_mobile_design.md`](../../../../product/design/thinkmay_mobile_design.md) | UI intent: account/diagnostics in **Settings**; Figma = source of truth |
| [`mobile_sync_checklist.md`](../../../../product/architecture/mobile_sync_checklist.md) | §G Profile tab `[~]`; account edit separate; §K remove refund UI |
| [`client_user_flow_contract.md`](../../../../product/architecture/client_user_flow_contract.md) | Profile tab vs account edit — two separate routes |
| [`reward_mission.md`](../../../../product/features/reward_mission.md) | Legacy v1 — **do not** implement; use v2 in `gamification.md` |
| [`thinkmay_analytics_research.md`](../../../docs/marketing/analytics/thinkmay_analytics_research.md) | Profile UI metrics = same customer-facing APIs (usage, heatmap, subscription) |

---

## API status (current → target)

> [API-COVERAGE.md](../API-COVERAGE.md)

| Component | Current | Target |
|-----------|---------|--------|
| User avatar/name | ✅ RankBanner + `UserAvatarImage` | ✅ |
| Usage / allowance | ✅ `subscription.total_usage` / `usage_limit` in RankBanner | ✅ |
| Join date | ⚪ not on gamification hub | ⚪ account edit only |
| Domain picker on profile | ✅ removed (C1) | ✅ `/network-check` / Settings |
| Subscription card on profile | ✅ removed; Payment tab (web) | ✅ |
| Quests / stars / heatmap / leaderboard | ✅ `GlobalCubit` + widgets | ✅ |
| `claim_mission_v2` | ✅ `ClaimMissionUseCase` | ✅ |
| Leaderboard avatars | ✅ PB resolve + DiceBear PNG fallback | ✅ |
| Rank badges | ✅ local `assets/badges/*.png` | ✅ |
| Discord OAuth | 🟡 UI stub | ✅ OAuth wire (B6) |
| Mission telemetry | ❌ | ✅ `session_device`, `ai_search_used` |
| Update profile / change password | ✅ `/setting` routes | ✅ |

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

## Mobile current (2026-06-09)

`profile_screen.dart`: gamification hub — `RankBanner`, `RoadmapCard`, `LeaderboardCard`, `QuestsCard`.

**Remaining**: Discord OAuth, ThemePicker, mission telemetry, exchange-rate addon formatting, pixel audit vs PWA.

---

## Links

- [TASK.md](../../TASK.md) — checklist phase A–F
- [02-authentication](../auth/02-authentication.md)
- [10-subscriptions](../subscription/10-subscriptions-plans.md)
- [08-settings-configuration](../setting/08-settings-configuration.md)

*Updated: 2026-06-09 — L-6 gamification hub shipped; checklist §G/L-6 marked `[~]`.*
