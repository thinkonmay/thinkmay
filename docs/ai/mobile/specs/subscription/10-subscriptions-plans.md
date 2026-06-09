# 10 — Subscriptions & Plans

## Overview

Subscription plans: data mainly from **preload (RPC)**; `/subscription` screen is currently a **dev harness**; upgrade-addons mock.

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md)

| Component | Status | Backend |
|-----------|--------|---------|
| Data on Dashboard/Profile | ✅ | `GlobalCubit.subscriptions` ← RPC `get_subscription_v3` |
| `SubscriptionScreen` | 🟡 Dev only | Manual Fetch buttons — **not** production UI |
| `fetchSubscription` | ✅ | RPC |
| `fetchDiscounts` | ✅ | Supabase `discounts` |
| `fetchDomains` | ✅ | RPC |
| `fetchPlans` | ✅ | `GET https://thinkmay.net/api/plans?type=full` |
| `/upgrade-and-services` | 🔴 | `upgrade_and_services_cubit` mock |

---

## Mobile — SubscriptionCubit

**File:** `subscription_cubit.dart`, `subscription_service.dart`

| Method | Implementation |
|--------|----------------|
| `fetchSubscription` | RPC `get_subscription_v3` |
| `fetchDiscounts` | Supabase select `discounts` |
| `fetchDomains` | RPC `get_domains_availability_v5` |
| `fetchPlans` | Dio GET `thinkmay.net/api/plans` |

**`subscription_screen.dart`:** Scaffold + ElevatedButton calling each method — API test screen, not user flow.

Production UI uses subscription from `GlobalCubit` (dashboard, profile card, payment widgets).

---

## Upgrade / downgrade routes

Widget screens under `payment/widgets/` — review each file when implementing; RPC details not documented here yet.

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| Global preload | Redux `fetch_subscription` |
| Plans | SSR `FetchPlans` + API |
| Addon configurator | `upgrade_and_services` mock |

---

## Links

- [11-payment-wallet](../payment/11-payment-wallet.md)
- [04-dashboard](../dashboard/04-dashboard-cloud-pc.md)
- [18-backend-integration](../18-backend-integration.md)
