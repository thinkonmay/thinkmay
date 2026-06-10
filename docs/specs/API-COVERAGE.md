# Trạng thái gắn API (API Coverage)

Theo dõi **Cubit ↔ API** trên Flutter app — bổ sung cho parity checklist monorepo.

> **Product / protocol (gốc):** [`../../docs/product/`](../../docs/product/) — đặc biệt [mobile_sync_checklist.md](../../docs/product/architecture/mobile_sync_checklist.md), [gamification.md](../../docs/product/features/gamification.md).  
> **Implementation (code):** `lib/` — không dựa `CLAUDE.md`.  
> **Công việc:** [`../TASK.md`](../TASK.md).  
> **Phân tầng doc:** [00-docs-hierarchy.md](./00-docs-hierarchy.md)

## Chú giải

| Ký hiệu | Ý nghĩa |
|---------|---------|
| ✅ | UI/Cubit gọi API đúng luồng user |
| 🟡 | Một phần: mock init, field cứng, API có nhưng chưa wire, hoặc chỉ dev screen |
| 🔴 | Mock / stub cubit hoặc service trả rỗng |
| ⚪ | Không cần API |

---

## Auth & bootstrap

| Màn / flow | Trạng thái | Ghi chú |
|------------|------------|---------|
| Login / Google OAuth | ✅ | PocketBase `users` auth + `preload()` sau login |
| Sign up | ✅ | PB `create` → `authWithPassword` → `requestVerification` → `preload` → Home; form có name + phone (tuỳ chọn), validation gần website |
| Splash restore | ✅ | PB token + `authRefresh` + lưu token/user + saved server URL + preload |
| Login → Home | ✅ | `GlobalCubit.preload()` trước navigate |
| Bảo vệ route (guest) | ✅ | Sau splash: route private + không có `User` trong GetIt → `/login` |
| Đăng xuất | ✅ | Xóa key auth trong prefs + PB `authStore.clear` + `unregisterCurrentUser` + `GlobalCubit.clearSession` (giữ `serverUrlKey`) |
| Forgot password | ✅ | PB `requestPasswordReset` |
| Confirm reset password | ✅ | PB `confirmPasswordReset` + deep link `thinkmay://confirm-reset-password?token=` |
| Login OTP | ✅ | PB `requestOTP` + `authWithOTP` + preload; route `/login-otp` + link từ màn Login |
| Email verification (link trong email) | ✅ | `requestVerification` / resend + `confirmVerification`; deep link `thinkmay://confirm-verification?token=` + route `/confirm-verification?token=` |
| Email verification màn hướng dẫn (manual) | 🟡 | Không còn UI OTP 6 số; chỉ text + resend + Continue |
| Test cases auth | ✅ | [specs/auth/03-authentication-test-cases.md](./auth/03-authentication-test-cases.md) — unit: `test/auth/` |

---

## 🔴 UI mock (chưa gọi API trên màn)

| Màn hình | Cubit | Ghi chú |
|----------|-------|---------|
| Advanced settings | `advanced_settings_cubit` | `init()` rỗng |
| Language settings | `language_settings_cubit` | List cứng; không persist locale |

> Các màn **deposit**, **deposit_bank_transfer**, **history_transaction**, **transaction_detail**, **confirm_refund**, **upgrade_and_services** đã **xóa** (2026-06-08) — payment → web redirect, refund policy ngừng.

---

## 🟡 Một phần

| Màn hình | Đã có | Thiếu |
|----------|-------|-------|
| Payment tab | ⚪ → web | Redirect `thinkmay.net/{locale}/payment/`; không dùng payment API trong app |
| Explore tab | `FetchStoreUseCase` + `SearchStoresUseCase` | AI search wired (#7) |
| Explore search | ✅ | Supabase RPC `get_all_app_genres_v1` + `stores.genres`; search name/code_name/genres; chip filter |
| Game detail | Catalog + `StartSessionUseCase` khi có param | **#23:** `performance_section` FPS hardcode; wire plan/game benchmarks |
| Dashboard | Worker/session qua GlobalCubit | share/resize disk TODO (#10–#11) |
| Profile | User + domains từ storage/RPC | Gamification UI 🔴 — xem [gamification.md](../../docs/product/features/gamification.md), [TASK.md](../TASK.md) Profile parity |
| Network check | `FetchDomains` RPC | Speed test fake |
| Subscription screen | API methods trong cubit | Màn **dev** — nút Fetch thủ công, không production UI |
| Error list | `FetchErrorMessageUseCase` wired | `ErrorService` **return `[]`** |
| Setting (create/update) | Fetch/load thật | create/update setting & app access dùng `exampleParam` |

---

## ✅ Đã gắn API (production path)

| Khu vực | Backend |
|---------|---------|
| Splash restore + preload | PB + RPC + Supabase (bảng trong [01-app-bootstrap](./01-app-bootstrap-global-state.md)) |
| Dashboard VM ops | PB `/info`, `/new`, SSE, `/close`, `/restart` |
| Dashboard hero carousel | Supabase `banner` via `FetchPlayBannersUseCase` + preload `stores` (spotlight ×2) |
| Explore catalog load | Supabase `stores` via `FetchStoreUseCase` |
| Remote | PB session + WebRTC |
| Store (`/store`) | Supabase `stores` + PB `buckets` |
| Banner | RPC |
| Setting (main) | PB volumes/setting + Supabase resources |
| Change password / update profile | PB `users` — update profile gửi `name`, `disableEM`, avatar multipart |
| Profile logout | PB clear auth |

---

## API gọi nhưng không có UI state

| Dữ liệu | Gọi từ | Ghi chú |
|---------|--------|---------|
| Quests, heatmap, stars | Preload phase 2 | Không emit `GlobalCubit` |
| Recommendations, mails | Preload phase 2 | Không UI |

---

## Backend nhanh (tránh nhầm)

| Việc | Backend |
|------|---------|
| Login | **PocketBase** |
| Game catalog (preload/store/explore) | **Supabase** `stores` |
| Subscription, wallet, domains | **NextJS RPC** |
| Worker VM | **PocketBase** custom routes |

Chi tiết: [18-backend-integration.md](./18-backend-integration.md).

---

## Việc cần làm (ưu tiên)

Theo [`../TASK.md`](../TASK.md) — checklist P0→P2. Tóm tắt:

1. **P1:** Profile tab parity ← [gamification.md](../../docs/product/features/gamification.md); dashboard plan specs (#9–#11)
2. **P2:** `ErrorService.fetchErrorMessage`; language settings; gamification UI; xóa `explore_cubit_fixed.dart`

*Cập nhật: 2026-06-08 — Explore search #8 wired (genres RPC + multi-field filter).*
