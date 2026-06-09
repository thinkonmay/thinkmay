# 03 — Navigation & Home Shell

## Overview

App-wide navigation via **GoRouter**. Main shell after login: **HomeScreen** — 4 tabs (Dashboard, Explore, Payment, Profile).

Website: `WebAppLayout` + routes `(app)/*` — desktop sidebar / mobile bottom nav.

---

## Mobile

### Router

**File:** `lib/presentation/router/app_router.dart`, `route_paths.dart`

- `initialLocation: /splash`
- **Redirect guard:** if `!AppRouter.isAppInitialized` → force `/splash`
- Params: `state.extra` cast explicit (`RemoteScreenParam`, `DepositParam`, …)

### HomeScreen

**File:** `lib/presentation/screen/home_screen.dart`

| Index | Tab | Widget | Separate route |
|-------|-----|--------|----------------|
| 0 | Cloud PC | `DashboardScreen` | `/dashboard` (also has standalone route) |
| 1 | Explore | `ExploreScreen` | `/explore` |
| 2 | Payment | `PaymentScreen` | `/payment` |
| Tab 3 Profile | `ProfileScreen` | `/profile` | PWA nav **`/profile`** (gamification) — [gamification.md](../../../product/features/gamification.md) |

- `IndexedStack` preserves tab state when switching.
- No Cubit at shell — each tab injects cubit via `getIt`.

> **Canonical doc:** [client_user_flow_contract.md](../../../product/architecture/client_user_flow_contract.md), [thinkmay_mobile_design.md](../../../product/design/thinkmay_mobile_design.md)

### Remote & fullscreen routes

**Outside** tab shell:
- `/remote-screen` — landscape fullscreen
- Deposit, subscription flows, settings — push stack

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| `HomeScreen` 4 tabs | `(app)/layout.tsx` + `WebAppLayout.tsx` |
| Tab 0 Dashboard | `/play` — `play/page.tsx` + `GetStarted` |
| Tab 1 Explore | `/store` |
| Tab 2 Payment | `/payment` |
| Tab 3 Profile | `/profile` (gamification) | Tab `/profile` — target [gamification.md](../../../product/features/gamification.md) |
| Account edit | `/setting/profile` | `/update-profile` (from `/setting`) — **not** same as Profile tab |

**Note:** Web bottom nav "Profile" → `/profile` (Stars, quests, leaderboard). Mobile not at parity yet — see [09-profile-account.md](../profile/09-profile-account.md), [TASK.md](../../TASK.md).

### State

- Website: URL-driven (Next.js App Router) + Redux.
- Mobile: `GoRouter` + limited deep links; `extra` objects not URL-serialized.

### Render

- Website: `DesktopNavBar` / `MobileNavBar` responsive.
- Mobile: `BottomNavigationBar` + `flutter_screenutil` (375×812 design).

---

## Full route map

See `specs/README.md` table of 18 specs + `route_paths.dart` (54 constants).

Routes declared but **not registered** in `app_router.dart`:
- `secondScreen`, `backButtonOverlay`

---

## Links

- [04-dashboard](../dashboard/04-dashboard-cloud-pc.md)
- [05-remote-streaming](../remote/05-remote-streaming-webrtc.md)
