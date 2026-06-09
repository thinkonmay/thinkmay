# 11 — Payment & Wallet

## Overview

Wallet and payments via **NextJS RPC** (encrypted). Deposit/history UI is mostly **mock**.

> **Policy 2026-06-07:** Thinkmay **no longer offers refund service**. Refund flow on mobile is UI prototype — task = **remove from app** (see [TASK.md](../../TASK.md) #6), do not integrate refund API.

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md)

| Component | Status | Backend |
|-----------|--------|---------|
| **Payment tab UI** | 🟡 | `init()` mock; RPC methods exist in cubit |
| `fetchWallet` | ✅ RPC `get_pocket_balance` | **Not** called from `payment_screen.init` |
| `createPocketDeposit`, verify, cancel | ✅ RPC | Called from cubit (some params TODO hardcoded) |
| **Deposit** | 🔴 | UI mock |
| **Bank transfer** | 🔴 | UI mock |
| **History / detail** | 🔴 | Mock |
| **Refund flow** | ⚪ → remove | Refund policy discontinued — remove UI (`confirm_refund/*`, routes, transaction detail button) |

Wallet on **Profile/Dashboard** may use `GlobalState.walletBalance` (preload RPC) — different from Payment tab mock.

---

## Mobile — PaymentCubit

**File:** `payment_cubit.dart`, `payment_service.dart`

`init()` emits hardcoded `PaymentViewModel` (`balance: 7350000`, fake `suggestSubs` list).

**Real** methods (RPC via `NextjsRpcClient`):

| Method | RPC |
|--------|-----|
| `fetchWallet` | `get_pocket_balance` |
| `createPocketDeposit` | `create_pocket_deposit_v4` |
| `verifyAllDeposits` | `verify_all_deposits` |
| `verifyTransaction` | `get_transaction_status` |
| `cancelTransaction` | `cancel_transaction` |
| `createPaymentPocket` | `create_or_replace_payment` |
| `verifyAllPayment` | `verify_all_payment_v2` |

`payment_screen.dart` only calls `_cubit.init()` in `initState`.

---

## Deposit / history screens

| Screen | Cubit | API |
|--------|-------|-----|
| `deposit_cubit` | Mock balance/methods; injects `FetchStoreUseCase` unused |
| `deposit_bank_transfer_cubit` | Hardcoded bank fields |
| `history_transaction_cubit` | Static transaction list |

## Refund (deprecated — remove)

All of `lib/presentation/screen/confirm_refund/` + routes `/confirm-refund`, `/refund-processing`, `/refund-complete` + refund button on transaction detail. **Do not wire API.**

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| Payment mock init | `PaymentPageContent` + wallet thunks |
| Stripe/payOS routes | Not on mobile yet |

---

## Links

- [18-backend-integration](../18-backend-integration.md)
- [10-subscriptions](../subscription/10-subscriptions-plans.md)
