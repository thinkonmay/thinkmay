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
| User avatar/name | ✅ storage | ✅ + refresh PB when needed |
| Usage / expiration | 🔴 hardcode | ✅ `subscription.total_usage`, limit, end date (`user_doc`) |
| Join date | 🔴 hardcode | ✅ `User.created` |
| Domain picker on profile | 🟡 RPC, not persisted | ⚪ Move to `/network-check` / Settings (`mobile_design`) |
| Subscription card mock | 🔴 static | ⚪ Payment tab; profile only plan badge in RankBanner |
| Quests / stars / heatmap / leaderboard | 🔴 preload does not emit UI | ✅ `GlobalCubit` + widgets |
| `claim_mission_v2` | ❌ | ✅ |
| Leaderboard | 🟡 `/api/leaderboard` legacy | ✅ `get_star_leaderboard` |
| Mission telemetry | ❌ | ✅ `session_device`, `ai_search_used` (`gamification.md` §4.5) |
| Update profile / change password | ✅ API, orphan route | ✅ link from `/setting` (phase D TASK.md) |

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

## Mobile current (needs replacement)

`profile_screen.dart`: account card (mock stats) → server picker → subscription mock.

**Does not match** `gamification.md` §7 nor `user_doc.md` Profile section.

---

## Links

- [TASK.md](../../TASK.md) — checklist phase A–F
- [02-authentication](../auth/02-authentication.md)
- [10-subscriptions](../subscription/10-subscriptions-plans.md)
- [08-settings-configuration](../setting/08-settings-configuration.md)

*Updated: 2026-06-07 — compared with `thinkmay/docs`, fixed flow contract vs gamification conflict.*
