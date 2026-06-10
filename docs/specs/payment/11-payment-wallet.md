# 11 — Payment & Wallet

## Tổng quan

Ví và thanh toán qua **NextJS RPC** (encrypted). UI deposit/history phần lớn **mock**.

> **Policy 2026-06-07:** Thinkmay **không còn dịch vụ hoàn tiền**. Luồng refund trên mobile là UI prototype — task = **gỡ khỏi app** (xem [TASK.md](../../TASK.md) #6), không tích hợp API refund.
>
> **Policy 2026-06-08: Payment → web.** Tab Payment và mọi luồng deposit/history/subscription trên mobile redirect sang `https://thinkmay.net/{locale}/payment/`. Không wire thêm payment API trong app — các màn `deposit`, `deposit_bank_transfer`, `history_transaction`, `subscription_selector` còn trong router nhưng không được navigate đến từ UI chính.

---

## Trạng thái API

> [API-COVERAGE.md](../API-COVERAGE.md)

| Thành phần | Trạng thái | Backend |
|------------|------------|---------|
| **Payment tab** | ⚪ → web | Tap navbar → `launchUrl thinkmay.net/{locale}/payment/` |
| `fetchWallet` / deposit / history | ⚪ | Không dùng trong app — xử lý trên web |
| `createPocketDeposit`, verify, cancel | ✅ RPC | Gọi từ cubit (một số param TODO cứng) |
| **Deposit** | 🔴 | UI mock |
| **Bank transfer** | 🔴 | UI mock |
| **History / detail** | 🔴 | Mock |
| **Refund flow** | ⚪ → remove | Policy ngừng hoàn tiền — xóa UI (`confirm_refund/*`, routes, nút transaction detail) |

Wallet trên **Profile/Dashboard** dùng `GlobalState.walletBalance` (preload); Payment tab fetch riêng qua `FetchWalletUseCase` khi mở tab.

---

## Mobile — PaymentCubit

**File:** `payment_cubit.dart`, `payment_plan_mapper.dart`, `payment_service.dart`

`init()` — parallel `fetchWallet` + `FetchSubscriptionUseCase` + `FetchPlansUseCase` → `PaymentPlanMapper.build()`.

Methods **thật** (RPC qua `NextjsRpcClient`):

| Method | RPC |
|--------|-----|
| `fetchWallet` | `get_pocket_balance` |
| `createPocketDeposit` | `create_pocket_deposit_v4` |
| `verifyAllDeposits` | `verify_all_deposits` |
| `verifyTransaction` | `get_transaction_status` |
| `cancelTransaction` | `cancel_transaction` |
| `createPaymentPocket` | `create_or_replace_payment` |
| `verifyAllPayment` | `verify_all_payment_v2` |

`payment_screen.dart` chỉ `_cubit.init()` trong `initState`.

---

## Deposit / history screens

| Screen | Cubit | API |
|--------|-------|-----|
| `deposit_cubit` | Mock balance/methods; inject `FetchStoreUseCase` unused |
| `deposit_bank_transfer_cubit` | Hardcoded bank fields |
| `history_transaction_cubit` | Static transaction list |

## Refund (deprecated — remove)

Toàn bộ `lib/presentation/screen/confirm_refund/` + routes `/confirm-refund`, `/refund-processing`, `/refund-complete` + nút hoàn tiền trên transaction detail. **Không wire API.**

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| Payment mock init | `PaymentPageContent` + wallet thunks |
| Stripe/payOS routes | Chưa có trên mobile |

---

## Liên kết

- [18-backend-integration](../18-backend-integration.md)
- [10-subscriptions](../subscription/10-subscriptions-plans.md)
