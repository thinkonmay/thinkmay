# 01 — App Bootstrap & Global State

## Overview

**Splash** → restore PocketBase session from SharedPreferences → **preload** → `AppRouter.isAppInitialized = true` → `/home` or welcome/login.

`GlobalCubit` holds shared state: subscription, worker, games, wallet, domains, settings metadata, gamification.
**Authed cold start**: splash stays visible until **all shell APIs** complete (parallel batch); then navigate with data ready for Dashboard, Profile, and Explore tabs.

> **Canonical doc:** [client_user_flow_contract.md](../../../product/architecture/client_user_flow_contract.md) (boot/auth routes), [user_doc.md](../../../product/guides/user_doc.md)

---

## API status

> [API-COVERAGE.md](./API-COVERAGE.md)

| Component | Status |
|-----------|--------|
| Splash restore | ✅ PB `authStore.save` + `FetchUserUseCase` |
| Preload (authed) | ✅ `PreloadUseCase.loadAll()` — 13 parallel API calls on splash |
| Preload (guest) | ✅ Domains only |
| Gamification | ✅ Included in `loadAll()` — not fetched on Profile tab open |
| Store catalog | ✅ Included in `loadAll()` — Explore reads `GlobalState.games` |
| Login → Home bootstrap gate | ✅ `bootstrap()` + `isBootstrapReady` before navigate |
| Non-critical background | 🟡 Recommendations + mails — fire-and-forget 5 s after preload |

---

## Mobile — files

| Component | Path |
|-----------|------|
| Entry | `lib/main.dart` |
| Splash | `presentation/screen/splash/` |
| Global | `presentation/screen/global/cubit/global_cubit.dart` |
| Preload | `data/use_case/preload/preload_use_case_impl.dart` — `loadAll()` |
| Router guard | `presentation/router/app_router.dart` — `isAppInitialized` |

### GlobalState fields

`user`, `subscriptions`, `workerInfo`, `configuration`, `games`, `domains`, `walletBalance`, `settingDomain`, `quests`, `leaderboard`, `heatmap`, `starBalance`, `rankRewards`, `addonCharges`, `deferredPreloadComplete`, `bootstrapProgress`, `fetched`, `isLoading`, `error`

**Bootstrap ready**: `isBootstrapReady` = `fetched && !isLoading && deferredPreloadComplete`

---

## Splash flow (code)

1. `GetUserStorageUseCase` + `GetSessionTokenUseCase`
2. If cached user exists: restore PocketBase auth + `FetchUserUseCase` (empty → logged out)
3. **Always** `GlobalCubit.bootstrap()`:
   - **Guest**: `loadDomains()` only → `isBootstrapReady`
   - **Authed**: `PreloadUseCase.loadAll(email, onProgress: …)` — single parallel batch → emit full `GlobalState` → `isBootstrapReady`
4. Splash progress bar maps `bootstrapProgress` (0→1 as each of 13 calls completes)
5. `AppRouter.isAppInitialized = true` → `/home` or `/welcome`

---

## Preload — parallel batch (`loadAll`)

All calls run concurrently via one `Future.wait` (phase label `parallel` in `[perf]` logs):

| # | Use case | Backend |
|---|----------|---------|
| 0 | `FetchWorkerInfoUseCase` | PB GET `/info` |
| 1 | `FetchConfigurationUseCase` | PB collection `volumes` |
| 2 | `FetchSubscriptionUseCase` | RPC `get_subscription_v3` |
| 3 | `FetchWalletBalanceUseCase` | RPC `get_pocket_balance` |
| 4 | `FetchDomainsUseCase` | RPC `get_domains_availability_v5` |
| 5 | `LoadSettingUseCase` | PB collection `setting` |
| 6 | `FetchQuestsUseCase` | RPC missions v2 |
| 7 | `FetchHeatmapUseCase` | RPC heatmap |
| 8 | `FetchStarBalanceUseCase` | RPC star balance |
| 9 | `FetchLeaderboardUseCase` | RPC leaderboard |
| 10 | `FetchRankRewardsUseCase` | RPC rank rewards |
| 11 | `FetchAddonChargesUseCase` | RPC addon charges |
| 12 | `FetchStoreUseCase` | Supabase `stores` |

Result → `FullPreloadResult` → single `GlobalCubit.emit`.

Per-call errors: `fold` → empty list or null, **does not** fail entire preload (except outer exception).

---

## Background (non-blocking)

`_scheduleDeferredNonCritical(email)` after `loadAll` completes:

- `FetchRecommendationsUseCase`
- `FetchMailsUseCase`

**Not** awaited; **does not** update `GlobalState` or block splash exit.

---

## Tab consumers (no fetch on first open)

| Tab | Cubit | Data source |
|-----|-------|-------------|
| Dashboard | `DashboardCubit` | `GlobalCubit` worker, subscription, configuration |
| Explore | `ExploreCubit` | `GlobalState.games` |
| Profile | `ProfileCubit` | `GlobalState` gamification + subscription |

Refresh paths: Profile pull-to-refresh → `refreshGamification()`; Explore AI search → `SearchStoresUseCase`.

---

## GlobalCubit actions

- `bootstrap()` / `preload()` — authed `loadAll()` or guest domains
- `refreshGamification()` — manual refresh (pull-to-refresh, claim mission)
- `refreshWorker()` — `FetchWorkerInfoUseCase` after power on/off/restart
- `ensureDomainsLoaded()` — lazy domains if empty outside splash

---

## Known obstacles (L-1)

- Splash duration ≈ slowest parallel API (store catalog, subscription RPC).
- JSON decode for ~4k store rows still on **main isolate** after fetch returns.
- Dashboard first frame may still jank (volume cards, hero carousel) despite preloaded data.

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| `GlobalCubit` + `loadAll()` | Redux + `preloadSilent()` await gate |
| Splash blocks until data ready | Web shell + await before interactive |
| No SSR | Web has SSR fetch on `/play` |

---

## Links

- [02-authentication](./auth/02-authentication.md)
- [04-dashboard](./dashboard/04-dashboard-cloud-pc.md)
- [12-explore-games-store](./explore/12-explore-games-store.md)
- [09-profile-account](./profile/09-profile-account.md)
- [18-backend-integration](./18-backend-integration.md)

*Updated: 2026-06-09 — full parallel splash preload; profile + store on splash.*
