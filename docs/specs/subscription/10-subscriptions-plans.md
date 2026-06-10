# 10 — Subscriptions & Plans

## Tổng quan

Gói subscription: data chủ yếu từ **preload (RPC)**; màn `/subscription` hiện là **dev harness**; upgrade-addons mock.

---

## Trạng thái API

> [API-COVERAGE.md](../API-COVERAGE.md)

| Thành phần | Trạng thái | Backend |
|------------|------------|---------|
| Data trên Dashboard/Profile | ✅ | `GlobalCubit.subscriptions` ← RPC `get_subscription_v3` |
| `SubscriptionScreen` | 🟡 Dev only | Nút Fetch thủ công — **không** production UI |
| `fetchSubscription` | ✅ | RPC |
| `fetchDiscounts` | ✅ | Supabase `discounts` |
| `fetchDomains` | ✅ | RPC |
| `fetchPlans` | ✅ | Supabase `plans` — `policy->v4_policy` RAM/CPU/GPU/DISK (parity website `FetchPlans`) |
| `/upgrade-and-services` | 🔴 | `upgrade_and_services_cubit` mock |

---

## Mobile — SubscriptionCubit

**File:** `subscription_cubit.dart`, `subscription_service.dart`

| Method | Implementation |
|--------|----------------|
| `fetchSubscription` | RPC `get_subscription_v3` |
| `fetchDiscounts` | Supabase select `discounts` |
| `fetchDomains` | RPC `get_domains_availability_v5` |
| `fetchPlans` | Supabase `plans` select + filter `metadata->v4_hide IS NULL`, `active=true` |

**`subscription_screen.dart`:** Scaffold + ElevatedButton gọi từng method — màn test API, không phải flow user.

Production UI dùng subscription từ `GlobalCubit` (dashboard, profile card, payment widgets).

---

## Upgrade / downgrade routes

Widget screens dưới `payment/widgets/` — cần rà từng file khi implement; chưa document chi tiết RPC tại đây.

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| Global preload | Redux `fetch_subscription` |
| Plans | SSR `FetchPlans` + API |
| Addon configurator | `upgrade_and_services` mock |

---

## Liên kết

- [11-payment-wallet](../payment/11-payment-wallet.md)
- [04-dashboard](../dashboard/04-dashboard-cloud-pc.md)
- [18-backend-integration](../18-backend-integration.md)
