# 01 — App Bootstrap & Global State

## Tổng quan

**Splash** → restore PocketBase session từ SharedPreferences → **preload** → `AppRouter.isAppInitialized = true` → `/home` hoặc welcome/login.

`GlobalCubit` giữ state dùng chung: subscription, worker, games, wallet, domains, settings metadata.

> **Doc gốc:** [client_user_flow_contract.md](../../docs/product/architecture/client_user_flow_contract.md) (boot/auth routes), [user_doc.md](../../docs/product/guides/user_doc.md)

---

## Trạng thái API

> [API-COVERAGE.md](./API-COVERAGE.md)

| Thành phần | Trạng thái |
|------------|------------|
| Splash restore | ✅ PB `authStore.save` + `FetchUserUseCase` |
| Preload phase 1 | ✅ RPC + PB + Supabase (xem bảng dưới) |
| Preload phase 2 | 🟡 Gọi API, **không** emit `GlobalCubit` |
| Login → Home (không qua splash) | 🟡 **Không** gọi preload (xem [02-authentication](./auth/02-authentication.md)) |

---

## Mobile — files

| Thành phần | Path |
|------------|------|
| Entry | `lib/main.dart` |
| Splash | `presentation/screen/splash/` |
| Global | `presentation/screen/global/cubit/global_cubit.dart` |
| Preload | `data/use_case/preload/preload_use_case_impl.dart` |
| Router guard | `presentation/router/app_router.dart` — `isAppInitialized` |

### GlobalState fields

`user`, `subscriptions`, `workerInfo`, `configuration`, `games`, `domains`, `walletBalance`, `settingDomain`, `quests`, `leaderboard`, `starBalance`, `fetched`, `isLoading`, `error`

**Lưu ý:** `quests`, `leaderboard`, `starBalance` có field nhưng **preload không gán** — luôn default rỗng/0.

---

## Splash flow (code)

1. `GetUserStorageUseCase` + `GetSessionTokenUseCase`
2. Nếu có user:
   - `BaseUrlProvider.updateBaseUrl(Endpoint.baseUrl)` — **luôn saigon2**, bỏ server URL cũ
   - `UpdatePocketBaseAuthStoreUseCase`
   - `FetchUserUseCase` → PB `users.getList(page:1)` — nếu `items` rỗng → coi như logged out
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

Kết quả → `PreloadResult` → `GlobalCubit.emit(fetched: true, …)`.

Lỗi từng call: `fold` → list rỗng hoặc null, **không** fail cả preload (trừ exception ngoài).

## Preload phase 2 (fire-and-forget)

`_preloadNonCritical(email)`:

- `FetchRecommendationsUseCase`
- `FetchMailsUseCase`
- `FetchQuestsUseCase` (RPC)
- `FetchHeatmapUseCase` (RPC)
- `FetchStarBalanceUseCase` (RPC)

**Không** await, **không** cập nhật `GlobalState`.

---

## GlobalCubit actions

- `preload()` — như trên
- `refreshWorker()` — `FetchWorkerInfoUseCase` sau power on/off/restart

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| `GlobalCubit` | Redux `user`, `worker`, … |
| Splash | Web layout guard + preload action |
| No SSR | Web có SSR fetch trên `/play` |

---

## Liên kết

- [02-authentication](./auth/02-authentication.md)
- [04-dashboard](./dashboard/04-dashboard-cloud-pc.md)
- [18-backend-integration](./18-backend-integration.md)
