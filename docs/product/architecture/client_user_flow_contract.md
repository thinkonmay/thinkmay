# Client User Flow Contract

This document maps all user-facing flows in the Thinkmay platform, establishing the **browser PWA as the reference** and tracking mobile app parity. The mobile app is in development and must implement each flow to match PWA behavior unless a platform-specific divergence is documented.

**Last synced:** 2026-06-12 · `mobile/develop` — see [Mobile sync checklist](./mobile_sync_checklist.md) for item-level status.

## Flow Parity Overview

| Flow Category | PWA Route | Mobile Route | Parity |
|---------------|-----------|-------------|--------|
| Splash / boot | N/A (SSR) | `/splash` | Done |
| Welcome / onboarding | N/A (landing) | `/welcome` | Partial |
| Login | `/(auth)/login` | `/login` | Done |
| Login OTP | `/(auth)/login-otp` | `/login-otp` | Done |
| Register | `/(auth)/register` | `/sign-up` | Done |
| Email verification | `/(auth)/confirm-verification` | `/confirm-verification` | Done |
| Forgot password | `/(auth)/reset-password` | `/forgot-password` | Done |
| Reset password confirm | `/(auth)/confirm-reset-password` | `/confirm-reset-password` → `/enter-new-password` | Done |
| Dashboard / Play | `/(app)/play` | `/dashboard` | Partial |
| Connect / Turn on VM | (within dashboard) | (within dashboard) | Done |
| Deploy watch | (overlay within dashboard) | (overlay within dashboard) | Done |
| Remote / Streaming | `/remote` | `/remote-screen` | Partial |
| Store / Browse games | `/(app)/store` | `/explore` (prod); `/store` (debug) | Partial |
| Game detail / Install | `/(app)/store/[slug]` | `/game-detail-screen` | Partial |
| Storage / Add-ons | `/(app)/storage` | Missing | Missing |
| Settings | `/(app)/setting` | `/setting` | Partial |
| Advanced settings | `/(app)/setting/(other)/advance` | `/advanced-settings` | Done |
| Profile tab (gamification) | `/(app)/profile` | `/profile` | Done |
| Account profile edit | `/(app)/setting/(account)/profile` | `/update-profile` | Done |
| Change password | `/(app)/setting/(account)/password` | `/change-password` | Done |
| Keyboard test | `/(app)/setting/(diagnostic)/keyboard` | `/check-keyboard` | Done |
| Gamepad test | `/(app)/setting/(diagnostic)/gamepad` | `/gamepad-test` | Done |
| Network test | `/(app)/setting/(diagnostic)/network` | `/network-check` | Done |
| Language | `/(app)/setting/(application)/language` | `/language-settings` | Partial |
| Snapshots | `/(app)/setting/(other)/snapshots` | Missing | Missing |
| Payment / Subscribe | `/(app)/payment` | web redirect (`/payment` deep link) | Done |
| Subscription detail | `/(app)/payment/[id]` | `/subscription` (debug) / web | Partial |
| Deposit | (within payment) | web only | N/A |
| Bank transfer deposit | (within payment) | web only | N/A |
| Transaction history | (within payment) | web only | N/A |
| Transaction detail | (within payment) | web only | N/A |
| Explore | `/(e-commerce)/discovery` | `/explore` | Partial |
| Terms / Legal | `/(e-commerce)/legal` | `/terms` | Done |

---

## 1. VM Turn On and Connect

This is the core flow: user starts a Cloud PC session and connects to it.

### 1.1 PWA Reference Flow

**Route**: `/{locale}/play` (Dashboard page)

**Components**: `GetStarted` (dashboard/index.tsx), `ControlPannel` (dashboard/VmState.tsx), `Watch` (dashboard/deployWatch.tsx)

**Sequence**:

1. User lands on `/play` dashboard. Page fetches banners, apps, plans server-side.
2. Dashboard renders volume cards from `state.worker.metadata` (PocketBase volume metadata).
3. Each volume card shows availability state from `state.worker.data[address].volume_status`:
   - **No subscription** → `NoSubscriptionState` with CTA to subscribe
   - **Server down** → `ServerDownState` with refresh button
   - **Wrong server** → `WrongDomainState` with redirect to correct cluster
   - **Waiting shutdown** → `NeedRefreshState` with refresh button
   - **Started/Headless** → `ControlPannel` with Connect/Close/Restart/Share/Debug actions
   - **Other states** → `ControlPannel` with Connect action only
4. User clicks **Connect** on a volume card:
   - `connect(volume_id)` is called
   - `wait_and_claim_volume({ volume_id })` dispatched — claims volume on worker node
   - If no session exists, `StartThinkmay()` runs:
     - POST `/new` → SSE on `/new/sse?id=<id>` with deployment progress
     - Deploy watch overlay appears (`Watch` component) showing progress steps
     - Final SSE event returns `WorkerInfor` with listener tokens
   - `ParseRequest()` builds WebSocket URLs from listener tokens
   - `save_reference(result)` stores credentials in Redux
5. If `desktop_custom_url_launch` is enabled:
   - `BuildDesktopLaunchURL()` constructs `thinkmay:` URL
   - `window.location.href = launchUrl` opens desktop client
6. Otherwise, `router.push('/remote')` opens streaming page in browser

**API calls**:
- `GET /info` — fetch worker state (volumes, sessions, GPU)
- `POST /new` — start VM deployment
- `GET /new/sse?id=<id>` — watch deployment progress (SSE)
- `ParseRequest()` — build WebSocket URLs from listener tokens

**Redux actions**: `worker_refresh`, `wait_and_claim_volume`, `save_reference`, `remote_connect`, `set_watch_mode`, `deploy_unwatch`

### 1.2 Mobile Flow

**Route**: `/dashboard`

**Components**: `DashboardScreen`, `DashboardCubit`, `DeployWatchOverlay`

**Sequence**:

1. User lands on `/dashboard`. `DashboardCubit.init()` fetches worker info.
2. Dashboard renders volume cards based on `DashboardViewModel`:
   - Server down → error state
   - No subscription → banner with CTA
   - Available → volume card with Connect action
3. User clicks Connect:
   - `DashboardCubit` claims volume, starts VM via worker service
   - Deploy watch overlay shows progress (same SSE-based progress)
4. On success, navigates to `/remote-screen` with `RemoteScreenParam`

**Parity gaps**:
- PWA has **Share** (copy session URL) and **Debug** (open VNC window) — mobile lacks these
- PWA has **desktop_custom_url_launch** toggle — not applicable on mobile
- PWA volume card shows port forwards — mobile does not
- PWA has `restart_volume` and `unclaim_volume` on the volume card — mobile has these in the card menu

---

## 2. Install App from Template

Users can browse a store of pre-configured game/software templates and install them as new Cloud PC volumes.

### 2.1 PWA Reference Flow

**Route**: `/{locale}/store` (Store page), `/{locale}/store/[slug]` (Game detail)

**Components**: `AISearchBar`, `AIRecommendations`, `StoreAllGames`, `AppCard`

**Sequence**:

1. User navigates to `/store` from sidebar navigation.
2. Store page renders:
   - **AI Search** bar — natural language search for games
   - **AI Recommendations** — personalized suggestions
   - **All Games** grid — browseable catalog with lazy loading
3. User clicks a game card → navigates to `/store/[slug]` game detail page.
4. Game detail page shows:
   - Game info, screenshots, system requirements
   - **Install** button (creates a new volume from template)
   - **Subscribe** button (if subscription required)
5. On install:
   - API creates a new volume with the selected template configuration
   - User is redirected back to `/play` dashboard
   - New volume appears with deployment progress

**API calls**:
- `FetchApps()` — list store apps (SSR)
- `FetchBanners()` — promotional banners
- Game detail API — fetch game info
- Volume creation API — create volume from template

### 2.2 Mobile Flow

**Route**: `/store`, `/game-detail-screen`

**Components**: `StoreScreen`, `GameDetailScreen`

**Parity gaps** (updated 2026-06-12):
- **Explore tab** — production store UI: AI search, persona recommendation carousels (`StoreAiRecommendationsSection`), all-games carousel. Dev route `/store` remains debug harness.
- **Game detail** — install/preorder/subscribe CTAs wired (`ReallocateVolumeUseCase`, volume pick, config refresh after install). **Remaining:** Thinkmay performance FPS hardcoded (`#23`).
- **Install from template** — core `change_template` parity on existing volumes shipped; verify edge cases (in-use volume, no sub, preorder-only games).

**Shipped (2026-06)**:
- `feature/install-template` — Khởi tạo flow, preorder, preinstalled badge, subscribe-without-sub CTA, post-install `refreshConfiguration()`
- `feature/store-persona-recommendations` — persona `recommendations` → Explore carousels (PWA `AIRecommendations.tsx`)

---

## 3. Settings and Advanced Settings

### 3.1 Settings Page

#### PWA Reference

**Route**: `/{locale}/setting`

**Sections**:
- **Account**: Profile, Change Password
- **Diagnostic Tools**: Keyboard Test, Gamepad Test, Network Test
- **Other Settings**: Advanced Settings, Snapshots, Button Mapping (mobile only)
- **Application**: Language
- **Support**: Discord, Terms, Privacy
- **Community**: Facebook, Discord (mobile layout only)
- **Logout** button (mobile layout only)

On desktop viewport, settings auto-redirects to `/setting/profile`.

#### Mobile

**Route**: `/setting`

**Sections**:
- **Account**: Profile, Change Password
- **Diagnostics**: Keyboard Test, Gamepad Test, Network Test
- **Other**: Advanced Settings, Language, Logout

**Parity gaps**:
- PWA has **Snapshots** page — mobile missing
- PWA has **Button Mapping** link (opens `/remote?mobile=true&dev=true`) — mobile has separate gamepad test screen but no in-remote button mapping
- PWA has **Community** links (Facebook, Discord) — mobile missing
- PWA has **Support** links (Discord, Terms, Privacy) — mobile has Terms screen but no Discord/Privacy links in settings

### 3.2 Advanced Settings

#### PWA Reference

**Route**: `/{locale}/setting/(other)/advance`

**Quality Settings**:
| Setting | Type | Options | Description |
|---------|------|---------|-------------|
| Streaming quality | Radio | HQ / Stability | HQ = 15ms playout, 120fps; Stability = 70ms playout, 60fps |
| Bitrate range | Dual slider | 1–60 mbps min & max | GCC adaptive range; collapses to single slider when GCC disabled |
| Max FPS | Slider | 40/60/90/120/144/240 | Frame rate target |
| Disable GCC | Toggle | — | Switch to fixed bitrate mode |
| Use H.265 | Toggle | — | Prefer HEVC codec |
| Enable microphone | Toggle | — | Pass-through mic audio |
| VSync | Toggle | — | Jitter buffer smoothing (stability mode) |

**Compatibility Settings**:
| Setting | Type | Description |
|---------|------|-------------|
| Keyboard compatibility (scancode) | Toggle | Use hardware scancodes instead of JS keycodes |
| Keyboard lock | Toggle | Capture all keyboard input in remote session |
| Gamepad touch | Toggle | Show virtual gamepad overlay on touch devices |
| Client cursor | Toggle | Show client-side rendered cursor overlay |
| Fill screen | Toggle | Stretch video to fill (vs letterbox) |
| Auto relative mouse | Toggle | Auto-switch to relative mouse in fullscreen |
| Always 1080p | Toggle | Force 1080p resolution regardless of screen size |

**Desktop App Settings**:
| Setting | Type | Description |
|---------|------|-------------|
| Desktop custom URL launch | Toggle | Open sessions in desktop client instead of browser |

**Actions**: Save Changes (caches settings), Reset Default

#### Mobile

**Route**: `/advanced-settings`

**Quality Settings**:
| Setting | Type | Parity |
|---------|------|--------|
| HQ / Stability preset | Radio | Done |
| Dual min/max bitrate range (GCC on) | Range slider | Done (`_DualBitrateSlider`) |
| Fixed bitrate slider (GCC off) | Toggle + Slider | Done (`_FixedBitrateSlider`) |
| Max FPS slider (40–240 steps) | Slider | Done (`_FpsSlider`; 144+ warning) |
| Disable GCC | Toggle | Done |
| Use H.265 | Toggle | Done (gated by `deviceSupportsH265Decode()`) |
| Enable microphone | Toggle | Done (4th WebRTC lane when session has `microphone` listener) |
| VSync | Toggle | Done (`kMobileVideoVsyncEnabled`) |

**Compatibility Settings**:
| Setting | Type | Parity |
|---------|------|--------|
| Keyboard compatibility (scancode) | Toggle | Done |
| Keyboard lock | Toggle | Partial — persisted; no native Keyboard API equivalent |
| Touch while gamepad | Toggle | Done |
| Client cursor | Toggle | Partial — gaming mode only; touch mode uses native PNG at finger |
| Stretch video (fill) | Toggle | Done |
| Auto relative mouse | Toggle | Partial — persisted; runtime blocked until log WebSocket (L-3) |
| Always force 1080p | Toggle | Done (live `ChangeResolution` on connect/resize) |

**Footer / navigation**:
| Behavior | Parity |
|----------|--------|
| Save → persist + feedback | Done (`applyCurrentToClient()` + snackbar) |
| Save from remote (`?remote=true`) → return to remote | Done |
| Reset → defaults + feedback | Done (`reset()` + snackbar; `TmSwitch` sync fix L-8) |

**Intentional mobile omissions**:
- Desktop custom URL launch (desktop-only)

---

## 4. Remote / Streaming Session

### 4.1 PWA Reference Flow

**Route**: `/{locale}/remote`

**Layout**: Full-screen streaming view with overlay controls.

**Layers (bottom to top)**:
1. `<video>` element — WebRTC video stream
2. Loading/error overlay — connection progress, errors
3. Virtual keyboard — toggleable on-screen keyboard for touch devices
4. Virtual gamepad — toggleable gamepad overlay for touch devices
5. Taskbar — minimize, settings, side panel toggles
6. Side panel — collapsible panel with:
   - Streaming quality metrics (FPS, bitrate, latency, decode time)
   - Quick settings (HQ toggle, scancode toggle, etc.)
   - Bot detection / captcha integration

**Key behaviors**:
- Pointer lock on click (gaming mode) — all mouse events captured
- Fullscreen toggle
- Insertable streams watchdog (300ms frame timeout)
- Auto-HID toggle based on `mobile` URL parameter
- Desktop client launch integration via `desktop_custom_url_launch` setting
- Keyboard shortcut: double-Esc to exit fullscreen
- Share session URL via side panel
- Snapshot button (canvas capture to PNG blob)

### 4.2 Mobile Flow

**Route**: `/remote-screen`

**Layout**: Landscape-only full-screen streaming view.

**Layers (bottom to top)**:
1. `RTCVideoView` — flutter_webrtc native video surface
2. Loading/error overlay — connection progress
3. Virtual keyboard — toggleable on-screen keyboard
4. Virtual gamepad — toggleable gamepad overlay
5. Taskbar — back, keyboard toggle, gamepad toggle, settings, side panel

**Key behaviors**:
- **Inactivity timer**: 8 minutes without interaction → close session
- **Orientation lock**: Forces landscape on enter, restores portrait on exit
- **Touch input**: Direct touch-to-HID mapping (trackpad or native touch mode)
- **Adaptive streaming**: Client-side auto-downgrade on poor metrics (normal → degraded → panic)
- **Video surface recovery**: Detach/reattach native renderer on panic
- No pointer lock (mobile doesn't have a mouse)
- No snapshot feature
- No bot detection / captcha

**Parity gaps**:
- PWA has **pointer lock gaming mode** — not applicable on mobile
- PWA has **snapshot** — mobile missing
- PWA has **share session URL** — mobile missing
- PWA has **bot detection** — mobile missing (but also not needed for native app)
- PWA has **VM log stream** — mobile missing
- Mobile has **inactivity timer** — PWA doesn't
- Mobile has **adaptive streaming** — PWA relies on server-side GCC only
- Mobile has **video panic recovery** — PWA doesn't need it (browser handles)
- Both have **virtual keyboard** and **virtual gamepad** overlays

---

## 5. Authentication

### 5.1 Login

#### PWA

**Route**: `/{locale}/login`

**Methods**: Email/Password, Google OAuth2, Email OTP

**Components**: Login form with tab/toggle between password and OTP login

**API**: PocketBase `authWithPassword()`, `authWithOAuth2()`, OTP send/verify

#### Mobile

**Route**: `/login`

**Methods**: Email/Password, Google OAuth2, Email OTP

**Parity**: Both support the same three auth methods. Mobile uses PocketBase Dart SDK with same endpoints.

### 5.2 Registration

#### PWA

**Route**: `/{locale}/register`

**Fields**: Email, password, confirm password, name

**Post-registration**: Email verification required → navigates to confirm-verification

#### Mobile

**Route**: `/sign-up`

**Parity**: Same fields and verification flow.

### 5.3 Password Reset

#### PWA

**Routes**: `/{locale}/reset-password` → email sent → `/{locale}/confirm-reset-password?token=...` → `/{locale}/enter-new-password`

#### Mobile

**Routes**: `/forgot-password` → email sent → `/enter-new-password?token=...`

**Parity**: Same flow, same token-based reset mechanism.

---

## 6. Payment and Subscription

### 6.1 Subscription Management

#### PWA

**Route**: `/{locale}/payment`

**Providers**: PayOS, Stripe, Dana, OVO, PayerMax

**Features**:
- Plan selection and comparison
- Upgrade/downgrade flows
- Wallet balance display
- Multi-currency support
- Payment status tracking

#### Mobile

**Route**: `/payment`, `/subscription`, `/upgrade-and-services`

**Parity gaps**:
- Mobile has separate subscription and payment screens
- Mobile has upgrade/downgrade success screens
- Mobile has deposit and bank transfer deposit screens
- Mobile has transaction history and detail screens
- Mobile has refund confirmation flow (`/confirm-refund`) — **deprecated 2026-06-07**; remove UI per [`mobile/TASK.md`](../../mobile/TASK.md) #6
- PWA payment page integrates more features in fewer screens

### 6.2 Deposit

**PWA**: Integrated into payment flow  
**Mobile**: Separate screens (`/deposit`, `/deposit-bank-transfer`, `/deposit-bank-transfer-success`)

---

## 7. Storage and Add-ons

### 7.1 PWA

**Route**: `/{locale}/storage` — Add-on service page  
**Route**: `/{locale}/storage/[slug]` — Storage detail/configuration

**Features**:
- Toggle add-on services (e.g., extra storage buckets)
- Service status display

### 7.2 Mobile

**Missing entirely** — no storage or add-on management screens.

---

## 8. Snapshots

### 8.1 PWA

**Route**: `/{locale}/setting/(other)/snapshots`

**Features**:
- List VM snapshots
- Restore a snapshot
- Create new snapshot

**API**: `GET /snapshots`, `POST /snapshots/restore` (PocketBase routes registered in `worker/daemon/pocketbase/pocketbase.go`)

### 8.2 Mobile

**Missing entirely** — no snapshot management screens.

---

## 9. Onboarding and Tours

### 9.1 PWA

**Library**: `nextstepjs`

**Tours**:
- **Dashboard overview** — introduces volume cards, connect button, notifications
- **Remote play** — introduces streaming controls, side panel, quality settings
- **Store** — introduces AI search, game cards, install flow

### 9.2 Mobile

**Route**: `/onboarding_virtual` (partial — references exist but implementation may be minimal)

**Parity gaps**:
- Mobile lacks the structured tour system that PWA has
- No `nextstepjs` equivalent for step-by-step onboarding

---

## 10. Explore / Discovery

### 10.1 PWA

**Route**: `/{locale}/discovery` (marketing/e-commerce page)  
Also `/{locale}/discovery/[slug]` for category pages

### 10.2 Mobile

**Route**: `/explore`, `/explore-search`

**Parity**: Mobile has explore and search screens but these appear to be simpler than PWA's full discovery experience with AI recommendations.

---

## 11. Error Handling

### 11.1 PWA

- Auth failure during streaming → error overlay with retry
- Server down → `ServerDownState` with refresh
- Bot detection → captcha challenge overlay
- Network issues → reconnect automatically

### 11.2 Mobile

- Auth failure → streaming auth failure state
- Server down → error state in dashboard
- Network issues → adaptive streaming (degrade/panic mode)
- Inactivity → 8-minute auto-close with warning

---

## 12. Priority Implementation Order for Mobile

Based on user impact and PWA parity, recommended implementation order:

1. **Store / Install from template** — core product loop for acquiring new users
2. **Bitrate FPS controls** — mobile lacks FPS slider and min/max bitrate range
3. **Client cursor toggle** — affects streaming usability
4. **Fill screen / Object-fit toggle** — affects streaming layout
5. **Auto relative mouse** — affects streaming usability with mouse
6. **Snapshots** — data protection feature, already in PWA
7. **Storage / Add-ons** — monetization and upsell
8. **Share session URL** — viral growth feature
9. **Onboarding tours** — new user activation
10. **VM log stream** — debugging and support tool

---

## 13. Source File Mapping

| Flow | PWA (Reference) | Mobile |
|------|-----------------|--------|
| Dashboard | `website/app/[locale]/(app)/play/page.tsx`, `website/components/dashboard/` | `mobile/lib/presentation/screen/dashboard/` |
| Remote | `website/app/[locale]/remote/page.tsx`, `website/core/core/index.ts` | `mobile/lib/presentation/screen/remote/` |
| Store | `website/app/[locale]/(app)/store/`, `website/components/store/` | `mobile/lib/presentation/screen/store/`, `game_detail/` |
| Settings | `website/app/[locale]/(app)/setting/` | `mobile/lib/presentation/screen/setting/`, `advanced_settings/` |
| Auth | `website/app/[locale]/(auth)/` | `mobile/lib/presentation/screen/login/`, `sign_up/`, `forgot_password/`, etc. |
| Payment | `website/app/[locale]/(app)/payment/` | `mobile/lib/presentation/screen/payment/`, `deposit/`, `subscription/` |
| Storage | `website/app/[locale]/(app)/storage/` | Missing |
| Snapshots | `website/app/[locale]/(app)/setting/(other)/snapshots/` | Missing |
