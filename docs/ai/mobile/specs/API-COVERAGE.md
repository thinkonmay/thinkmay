# API Coverage Status

Tracks **Cubit ↔ API** on the Flutter app — supplements the monorepo parity checklist.

> **Product / protocol (canonical):** [`../../../product/`](../../../product/) — especially [mobile_sync_checklist.md](../../../product/architecture/mobile_sync_checklist.md), [gamification.md](../../../product/features/gamification.md).  
> **Implementation (code):** `lib/` — do not rely on `CLAUDE.md`.  
> **Work tracking:** [`../TASK.md`](../TASK.md).  
> **Doc layering:** [00-docs-hierarchy.md](./00-docs-hierarchy.md)

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | UI/Cubit calls API on the correct user flow |
| 🟡 | Partial: mock init, hardcoded fields, API exists but not wired, or dev screen only |
| 🔴 | Mock / stub cubit or service returns empty |
| ⚪ | No API needed |

---

## Auth & bootstrap

| Screen / flow | Status | Notes |
|---------------|--------|-------|
| Login / Google OAuth | ✅ | PocketBase `users` auth + `preload()` after login |
| Sign up | ✅ | PB `create` → `authWithPassword` → `requestVerification` → `preload` → Home; form has name + phone (optional), validation close to website |
| Splash restore | ✅ | PB token + `authRefresh` + save token/user + saved server URL + preload |
| Login → Home | ✅ | `GlobalCubit.preload()` before navigate |
| Route guard (guest) | ✅ | After splash: private route + no `User` in GetIt → `/login` |
| Logout | ✅ | Remove auth keys in prefs + PB `authStore.clear` + `unregisterCurrentUser` + `GlobalCubit.clearSession` (keeps `serverUrlKey`) |
| Forgot password | ✅ | PB `requestPasswordReset` |
| Confirm reset password | ✅ | PB `confirmPasswordReset` + deep link `thinkmay://confirm-reset-password?token=` |
| Login OTP | ✅ | PB `requestOTP` + `authWithOTP` + preload; route `/login-otp` + link from Login screen |
| Email verification (link in email) | ✅ | `requestVerification` / resend + `confirmVerification`; deep link `thinkmay://confirm-verification?token=` + route `/confirm-verification?token=` |
| Email verification instruction screen (manual) | 🟡 | No 6-digit OTP UI; text + resend + Continue only |
| Auth test cases | ✅ | [specs/auth/03-authentication-test-cases.md](./auth/03-authentication-test-cases.md) — unit: `test/auth/` |

---

## 🔴 UI mock (no API call on screen)

| Screen | Cubit | Notes |
|--------|-------|-------|
| Deposit | `deposit_cubit` | Hardcoded balance + payment methods |
| Deposit bank transfer | `deposit_bank_transfer_cubit` | Hardcoded VCB info |
| History transaction | `history_transaction_cubit` | 7 fake transactions; `get_job_history` unused |
| Transaction detail | `transaction_detail_cubit` | Fake logic, hardcoded account |
| ~~Confirm refund~~ | `confirm_refund_*` | **Policy 2026-06-07:** refund service discontinued — task = **remove UI** (see [TASK.md](../TASK.md) #6), do not wire API |
| Upgrade & services | `upgrade_and_services_cubit` | Mock CPU/RAM/storage/game-pass |
| Advanced settings | `advanced_settings_cubit` | Empty `init()` |
| Language settings | `language_settings_cubit` | Hardcoded list; locale not persisted |

---

## 🟡 Partial

| Screen | Has | Missing |
|--------|-----|---------|
| Payment tab | RPC use cases in cubit | `init()` mock; does not call `fetchWallet` on open |
| Explore tab | `FetchStoreUseCase` → Supabase `stores` | `performAiSearch` = local filter + fake delay; no `search_stores` RPC yet |
| Explore search | Real store fetch | Hardcoded genre list; client-side search only |
| Game detail | Catalog + `StartSessionUseCase` when param present | FC26 demo fallback when no param |
| Dashboard | Worker/session via GlobalCubit | Hardcoded `_planSpecs` RAM/GPU; share/resize disk TODO |
| Profile | User + domains from storage/RPC | Gamification UI 🔴 — see [gamification.md](../../../product/features/gamification.md), [TASK.md](../TASK.md) Profile parity |
| Network check | `FetchDomains` RPC | Fake speed test |
| Subscription screen | API methods in cubit | **Dev** screen — manual Fetch buttons, not production UI |
| Error list | `FetchErrorMessageUseCase` wired | `ErrorService` **returns `[]`** |
| Setting (create/update) | Real fetch/load | create/update setting & app access use `exampleParam` |

---

## ✅ API wired (production path)

| Area | Backend |
|------|---------|
| Splash restore + preload | PB + RPC + Supabase (table in [01-app-bootstrap](./01-app-bootstrap-global-state.md)) |
| Dashboard VM ops | PB `/info`, `/new`, SSE, `/close`, `/restart` |
| Explore catalog load | Supabase `stores` via `FetchStoreUseCase` |
| Remote | PB session + WebRTC |
| Store (`/store`) | Supabase `stores` + PB `buckets` |
| Banner | RPC |
| Setting (main) | PB volumes/setting + Supabase resources |
| Change password / update profile | PB users |
| Profile logout | PB clear auth |

---

## API called but no UI state

| Data | Called from | Notes |
|------|-------------|-------|
| Quests, heatmap, stars | Preload phase 2 | Not emitted to `GlobalCubit` |
| Recommendations, mails | Preload phase 2 | No UI |

---

## Backend quick reference (avoid confusion)

| Task | Backend |
|------|---------|
| Login | **PocketBase** |
| Game catalog (preload/store/explore) | **Supabase** `stores` |
| Subscription, wallet, domains | **NextJS RPC** |
| Worker VM | **PocketBase** custom routes |

Details: [18-backend-integration.md](./18-backend-integration.md).

---

## TODO (priority)

Per [`../TASK.md`](../TASK.md) — P0→P2 checklist. Summary:

1. **P0:** Payment tab ← `fetchWallet` + plans; deposit/history flows; **remove refund UI** (refund policy discontinued)
2. **P1:** Profile tab parity ← [gamification.md](../../../product/features/gamification.md); Explore AI search; dashboard plan specs
3. **P2:** `ErrorService.fetchErrorMessage`; language settings; gamification UI; delete `explore_cubit_fixed.dart`

*Updated: 2026-06-07 — sync hierarchy thinkmay/docs; profile = gamification parity.*
