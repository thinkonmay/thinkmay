# 03 — Navigation & Home Shell

## Tổng quan

Điều hướng toàn app bằng **GoRouter**. Shell chính sau login: **HomeScreen** — 4 tab (Dashboard, Explore, Payment, Profile).

Website: `WebAppLayout` + routes `(app)/*` — desktop sidebar / mobile bottom nav.

---

## Mobile

### Router

**File:** `lib/presentation/router/app_router.dart`, `route_paths.dart`

- `initialLocation: /splash`
- **Redirect guard:** nếu `!AppRouter.isAppInitialized` → force `/splash`
- Params: `state.extra` cast explicit (`RemoteScreenParam`, `DepositParam`, …)

### HomeScreen

**File:** `lib/presentation/screen/home_screen.dart`

| Index | Tab | Widget | Route riêng |
|-------|-----|--------|-------------|
| 0 | Cloud PC | `DashboardScreen` | `/dashboard` (cũng có route độc lập) |
| 1 | Khám phá | `ExploreScreen` | `/explore` |
| 2 | Thanh toán | `PaymentScreen` | `/payment` |
| Tab 3 Cá nhân | `ProfileScreen` | `/profile` | PWA nav **`/profile`** (gamification) — [gamification.md](../../docs/product/features/gamification.md) |

- `IndexedStack` giữ state tab khi chuyển.
- Không có Cubit ở shell — mỗi tab tự inject cubit qua `getIt`.

> **Doc gốc:** [client_user_flow_contract.md](../../docs/product/architecture/client_user_flow_contract.md), [thinkmay_mobile_design.md](../../docs/product/design/thinkmay_mobile_design.md)

### Remote & fullscreen routes

Nằm **ngoài** tab shell:
- `/remote-screen` — landscape fullscreen
- Deposit, subscription flows, settings — push stack

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| `HomeScreen` 4 tabs | `(app)/layout.tsx` + `WebAppLayout.tsx` |
| Tab 0 Dashboard | `/play` — `play/page.tsx` + `GetStarted` |
| Tab 1 Explore | `/store` |
| Tab 2 Payment | `/payment` |
| Tab 3 Profile | `/profile` (gamification) | Tab `/profile` — target [gamification.md](../../docs/product/features/gamification.md) |
| Account edit | `/setting/profile` | `/update-profile` (từ `/setting`) — **không** trùng tab Profile |

**Lưu ý:** Web bottom nav "Profile" → `/profile` (Stars, quests, leaderboard). Mobile hiện chưa parity — xem [09-profile-account.md](../profile/09-profile-account.md), [TASK.md](../../TASK.md).

### State

- Website: URL-driven (Next.js App Router) + Redux.
- Mobile: `GoRouter` + deep link hạn chế; `extra` objects không serialize URL.

### Render

- Website: `DesktopNavBar` / `MobileNavBar` responsive.
- Mobile: `BottomNavigationBar` + `flutter_screenutil` (375×812 design).

---

## Route map đầy đủ

Xem `specs/README.md` bảng 18 specs + `route_paths.dart` (54 constants).

Routes khai báo nhưng **chưa register** trong `app_router.dart`:
- `secondScreen`, `backButtonOverlay`

---

## Liên kết

- [04-dashboard](../dashboard/04-dashboard-cloud-pc.md)
- [05-remote-streaming](../remote/05-remote-streaming-webrtc.md)
