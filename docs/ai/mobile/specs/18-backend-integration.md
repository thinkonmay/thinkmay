# 18 — Backend Integration

## Overview

Mobile uses **4 channels** in parallel (not "Supabase = auth"):

> **Canonical doc:** [technical_doc.md](../../../product/architecture/technical_doc.md) — PocketBase schema, worker cluster, RPC endpoints

| Channel | Primary role |
|---------|--------------|
| **PocketBase** | Auth, worker VM (`/info`, `/new`, …), collections (`volumes`, `setting`, `buckets`, …) |
| **NextJS RPC** | Billing, subscription, banner, gamification, domains (AES body + PB token header) |
| **Supabase** | Read tables `stores`, `discounts`, `resources` (PostgREST) |
| **Direct HTTP** | Plans (`GET thinkmay.net/api/plans`), leaderboard (`GET {baseUrl}/api/leaderboard`) |

Constants: `lib/utils/api/endpoint.dart`

DI: `lib/dependency_injection/injection.dart`

---

## PocketBase

**Default base URL:** `https://saigon2.thinkmay.net` (`Endpoint.baseUrl`)

**Runtime:** `BaseUrlProvider` — Login allows cluster/domain selection; Splash **overwrites** to `Endpoint.baseUrl` on restore.

### Auth (`authentication_service.dart`)

| API | Method |
|-----|--------|
| Login | `collection('users').authWithPassword` |
| Sign up | `collection('users').create` |
| Google | `collection('users').authWithOAuth2('google')` |
| Restore | `authStore.save(token, record)` |

### Worker (`worker_service.dart`)

Custom routes (require `authStore.token`):

| Route | Constant |
|-------|----------|
| GET `/info` | `Endpoint.workerInfo` |
| POST `/new` | `Endpoint.workerNew` |
| GET `/new/sse` | SSE deploy |
| POST `/restart` | `Endpoint.workerRestart` |
| DELETE `/close` | `Endpoint.workerClose` |
| DELETE `/resource` | `Endpoint.workerResource` |
| POST `/reallocate` | `Endpoint.workerReallocate` |

### Collections (examples)

| Collection | Service |
|------------|---------|
| `volumes` | `SettingService.fetchConfiguration` |
| `setting` | `loadSetting`, create, update |
| `buckets` | `StoreService.fetchBuckets` |
| `app_access` | `SettingService.fetchAppAccess` |
| `users` | auth, `UserService.fetchUser`, update |

---

## NextJS RPC

**File:** `lib/data/network/nextjs/nextjs_rpc_client.dart`

- POST `https://thinkmay.net/api/global_rpc/`
- Body: AES encrypt (`crypto_utils.dart`)
- Header `Authorization`: **PocketBase** `authStore.token`
- `issuer`: `_pb.baseURL`

| RPC name (Endpoint constant) | Service |
|------------------------------|---------|
| `get_subscription_v3` | Subscription |
| `get_domains_availability_v5` | Domains (login + preload) |
| `get_pocket_balance` | Wallet (preload + payment) |
| `get_banner_v1` | Banner |
| `create_pocket_deposit_v4`, `verify_all_deposits`, … | Payment |
| `get_user_missions_v2`, `get_star_balance`, `get_user_heatmap` | Gamification |
| `list_addon_charges_v2` | Billing |

---

## Supabase

**URL:** `https://saigon2.thinkmay.net:445` + anon key (`Endpoint.supabaseKey`)

| Table / endpoint | Service |
|------------------|---------|
| `stores` | `StoreService.fetchStore`, `fetchStoreByCode` |
| `discounts` | `SubscriptionService.fetchDiscounts` |
| `resources` | `SettingService.fetchResources` |

**Not used** for login/signup.

---

## Other HTTP

| URL | Service |
|-----|---------|
| `GET https://thinkmay.net/api/plans?type=full` | `SubscriptionService.fetchPlans` (Dio) |
| `GET {baseUrl}/api/leaderboard?limit=20` | `GamificationService.fetchLeaderboard` |
| `GET {baseUrl}/api/currency_rates` | `BillingService.fetchExchangeRates` |

---

## Preload — use case → backend map

| Use case | Backend |
|----------|---------|
| `FetchSubscriptionUseCase` | RPC |
| `FetchConfigurationUseCase` | PB `volumes` |
| `FetchDomainsUseCase` | RPC |
| `FetchWorkerInfoUseCase` | PB GET `/info` |
| `FetchWalletBalanceUseCase` | RPC |
| `FetchStoreUseCase` | Supabase `stores` |
| `LoadSettingUseCase` | PB `setting` |
| Phase 2 (quests, heatmap, stars, mails, recommendations) | RPC / HTTP — **not** in `GlobalCubit` |

`FetchUserUseCase` is injected into `PreloadUseCaseImpl` but **not called** in `call()`.

---

## Dependency injection

- `get_it` + `injectable` → `injection.config.dart`
- `registerCurrentUser(User)` after login
- `SupabaseClient`, `PocketBase`, `Dio`, `NextjsRpcClient` singleton

---

## Website — comparison

| Layer | Website | Mobile |
|-------|---------|--------|
| API | `core/api`, `utils/rpc` | `data/network/*_service.dart` |
| State | Redux | Cubits + `GlobalCubit` |
| SSR preload | `backend/ssr` | Client `PreloadUseCase` |

---

## Links

All screen specs reference this file for the **correct backend** per API.
