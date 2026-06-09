# 01 — App Bootstrap & Global State

## Overview

**Splash** → restore PocketBase session from SharedPreferences → **preload** → `AppRouter.isAppInitialized = true` → `/home` or welcome/login.

`GlobalCubit` holds shared state: subscription, worker, games, wallet, domains, settings metadata.

> **Canonical doc:** [client_user_flow_contract.md](../../../product/architecture/client_user_flow_contract.md) (boot/auth routes), [user_doc.md](../../../product/guides/user_doc.md)

---

## API status

> [API-COVERAGE.md](./API-COVERAGE.md)

| Component | Status |
|-----------|--------|
| Splash restore | ✅ PB `authStore.save` + `FetchUserUseCase` |
| Preload phase 1 | ✅ RPC + PB + Supabase (see table below) |
| Preload phase 2 | 🟡 Calls API, **does not** emit `GlobalCubit` |
| Login → Home (without splash) | 🟡 **Does not** call preload (see [02-authentication](./auth/02-authentication.md)) |

---

## Mobile — files

| Component | Path |
|-----------|------|
| Entry | `lib/main.dart` |
| Splash | `presentation/screen/splash/` |
| Global | `presentation/screen/global/cubit/global_cubit.dart` |
| Preload | `data/use_case/preload/preload_use_case_impl.dart` |
| Router guard | `presentation/router/app_router.dart` — `isAppInitialized` |

### GlobalState fields

`user`, `subscriptions`, `workerInfo`, `configuration`, `games`, `domains`, `walletBalance`, `settingDomain`, `quests`, `leaderboard`, `starBalance`, `fetched`, `isLoading`, `error`

**Note:** `quests`, `leaderboard`, `starBalance` have fields but **preload does not assign** — always default empty/0.

---

## Splash flow (code)

1. `GetUserStorageUseCase` + `GetSessionTokenUseCase`
2. If user exists:
   - `BaseUrlProvider.updateBaseUrl(Endpoint.baseUrl)` — **always saigon2**, discard old server URL
   - `UpdatePocketBaseAuthStoreUseCase`
   - `FetchUserUseCase` → PB `users.getList(page:1)` — if `items` empty → treat as logged out
   - `registerCurrentUser` + `GlobalCubit.preload()`
3. `AppRouter.isAppInitialized = true`

---

## Preload phase 1 (`Future.wait`)

| # | Use case | Backend |
|---|----------|---------|
| 0 | `FetchSubscriptionUseCase` | RPC `get_subscription_v3` |
| 1 | `FetchConfigurationUseCase` | PB collection `volumes` |
| 2 | `FetchDomainsUseCase` | RPC `get_domains_availability_v5` |
| 3 | `FetchWorkerInfoUseCase` | PB GET `/info` |
| 4 | `FetchWalletBalanceUseCase` | RPC `get_pocket_balance` |
| 5 | `FetchStoreUseCase` | Supabase table `stores` |
| 6 | `LoadSettingUseCase` | PB collection `setting` |

Result → `PreloadResult` → `GlobalCubit.emit(fetched: true, …)`.

Per-call errors: `fold` → empty list or null, **does not** fail entire preload (except external exception).

## Preload phase 2 (fire-and-forget)

`_preloadNonCritical(email)`:

- `FetchRecommendationsUseCase`
- `FetchMailsUseCase`
- `FetchQuestsUseCase` (RPC)
- `FetchHeatmapUseCase` (RPC)
- `FetchStarBalanceUseCase` (RPC)

**Not** awaited, **does not** update `GlobalState`.

---

## GlobalCubit actions

- `preload()` — as above
- `refreshWorker()` — `FetchWorkerInfoUseCase` after power on/off/restart

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| `GlobalCubit` | Redux `user`, `worker`, … |
| Splash | Web layout guard + preload action |
| No SSR | Web has SSR fetch on `/play` |

---

## Links

- [02-authentication](./auth/02-authentication.md)
- [04-dashboard](./dashboard/04-dashboard-cloud-pc.md)
- [18-backend-integration](./18-backend-integration.md)
