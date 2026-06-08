# Mobile App Sync Checklist

Actionable checklist of items the mobile app needs to synchronize with the PWA (reference implementation). Derived from the [User Flow Contract](./client_user_flow_contract.md), [Platform Divergence Registry](./client_platform_divergence.md), and [Protocol Contract](./client_protocol_contract.md).

**Status legend**: `[ ]` = not started, `[~]` = partial/in progress, `[x]` = done, `[-]` = not applicable

---

## A. Critical Bugs (Fix Now)

- [x] **D-1: Mouse wheel deltaX encoding bug** — Fixed: `((data['deltaX'] as num?)?.toInt() ?? 0) + 2048` in `mobile/lib/core/models/event_code.dart`

---

## B. Protocol Sync (Streaming Core)

- [x] EventCode enum values match PWA (0–23)
- [x] MessageType enum values match PWA (0–8)
- [x] HIDMsg buffer() encoding matches PWA for all event types (except D-1 above)
- [x] WebSocket signaling flow matches PWA (open → SDP → ICE → status → close)
- [x] SDP normalization strips `a=ice-renomination`
- [x] Codec preference negotiation (H.264 + RTX + FlexFEC-03)
- [x] H.265 alias handling (`hevc` included in codec filter)
- [x] Cursor binary protocol (cu/cp) parsing matches PWA
- [x] Cursor interpolation algorithm (32ms EMA) matches PWA
- [x] Stream health status handling matches PWA
- [x] Metrics calculation formulae match PWA (video decode, jitter, bitrate, etc.)
- [x] Clipboard encoding parity — Fixed: changed `text.codeUnits` (UTF-16) to `utf8.encode(text)` (UTF-8) in `HIDMsg.encodeClipboard()`, now matches PWA's `TextEncoder().encode(val)`. **File**: `mobile/lib/core/models/event_code.dart`
- [x] Gamepad `gconn` reconnect on "controller not found" notification — Fixed: now parses gamepad ID from notification text (matching PWA's `Number.parseInt(str.replaceAll(ctrlNotFound, ''))`), uses `utf8.decode` instead of `String.fromCharCodes`, and sends `gconn` with parsed gid. **File**: `mobile/lib/core/thinkmay_client.dart`

---

## C. Advanced Settings Sync

- [x] HQ / Stability quality preset radio
- [x] Disable GCC toggle + fixed bitrate slider
- [x] Use H.265 toggle
- [x] Always 1080p toggle
- [x] Enable microphone toggle
- [x] VSync toggle
- [x] Keyboard compatibility (scancode) toggle
- [ ] **FPS slider** — PWA has steps [40, 60, 90, 120, 144, 240]; mobile has no FPS control. Add FPS slider to advanced settings. **PWA file**: `website/app/[locale]/(app)/setting/(other)/advance/page.tsx` → `FPS_STEPS` array
- [ ] **Bitrate min/max dual range slider** — PWA has dual slider for GCC bitrate range (1–60 mbps min & max); mobile only has single fixed-bitrate slider when GCC disabled. Add min/max range. **PWA file**: `DualRangeSlider` component in advance/page.tsx
- [ ] **Keyboard lock toggle** — PWA has `toggle_keyboard_lock`; mobile missing. **PWA Redux**: `state.remote.keyboard_lock`
- [ ] **Gamepad touch toggle** — PWA has `toggle_gamepad_touch` (show virtual gamepad on touch); mobile missing (gamepad is always available via side panel). **PWA Redux**: `state.remote.touch_gamepad`
- [ ] **Client cursor toggle** — PWA has `toggle_client_cursor` (show/hide client-side cursor overlay); mobile missing. **PWA Redux**: `state.remote.client_cursor`
- [ ] **Fill screen / object-fit toggle** — PWA has `toggle_objectfit` (stretch vs letterbox); mobile missing. **PWA Redux**: `state.remote.objectFitFill`
- [ ] **Auto relative mouse toggle** — PWA has `toggle_auto_relative_mouse`; mobile missing. **PWA Redux**: `state.remote.auto_relative_mouse`

---

## D. Dashboard / VM Management Sync

- [x] Volume card rendering with availability states
- [x] Connect flow (claim → deploy → watch → navigate to remote)
- [x] Deploy watch overlay with progress steps
- [x] Restart volume action
- [x] Close/shutdown volume action
- [ ] **Share session** — PWA copies session URL to clipboard; mobile missing. **PWA file**: `website/components/dashboard/index.tsx` → `share()` function
- [ ] **Debug / VNC window** — PWA opens debug VNC in popup window; mobile missing (may not be applicable but should have equivalent diagnostics access)
- [ ] **Port forwards display** — PWA volume card shows port forwards; mobile missing. **PWA component**: `ControlPannel` → `port_forward` prop
- [ ] **Server down / Wrong server / No subscription** — verify mobile renders all three error states identically to PWA. **PWA components**: `ServerDownState`, `WrongDomainState`, `NoSubscriptionState`
- [ ] **Notifications panel** — PWA dashboard has a notifications sidebar; verify mobile has equivalent. **PWA component**: `Notifications`

---

## E. Remote / Streaming Screen Sync

- [x] Video streaming (H.264)
- [x] Audio streaming (Opus)
- [x] Keyboard HID (scancode)
- [x] Mouse HID
- [x] Touch HID
- [x] Virtual gamepad
- [x] Virtual keyboard
- [x] Server-side cursor
- [x] Client-side cursor overlay
- [x] Microphone pass-through
- [x] Stream health monitoring
- [x] Resolution change
- [ ] **Gamepad touch toggle in remote** — PWA has a toggle in side panel to show/hide virtual gamepad; mobile should have the same toggle. Currently mobile always shows gamepad via side panel button but no on/off setting persists
- [ ] **Side panel quick settings** — PWA remote side panel has inline toggles for HQ, scancode, mic, etc.; verify mobile side panel has parity. **PWA component**: side panel in `website/app/[locale]/remote/`
- [ ] **VM log stream** — PWA connects to a log WebSocket and displays VM logs; mobile missing. **PWA file**: `website/core/core/index.ts` → `handleLog(url)`

---

## F. Store / Install from Template

- [ ] **Store catalog screen** — Replace debug placeholder (`StoreScreen` shows raw JSON) with polished game catalog matching PWA. **PWA file**: `website/app/[locale]/(app)/store/page.tsx`
- [ ] **AI search bar** — PWA has natural language game search; mobile missing. **PWA component**: `AISearchBar`
- [ ] **AI recommendations** — PWA has personalized game suggestions; mobile missing. **PWA component**: `AIRecommendations`
- [ ] **Game detail page** — Verify mobile `GameDetailScreen` matches PWA's game detail with install/subscribe buttons. **PWA file**: `website/app/[locale]/(app)/store/[slug]/page.tsx`
- [ ] **Install from template flow** — End-to-end: browse → select → install → new volume appears on dashboard. PWA wires this; mobile needs full flow.

---

## G. Settings Pages Sync

- [x] Profile page
- [x] Change password page
- [x] Keyboard test screen
- [x] Gamepad test screen
- [x] Network test screen
- [x] Language settings
- [ ] **Snapshots page** — PWA has snapshot list/restore/create at `/setting/(other)/snapshots`; mobile missing entirely. **PWA file**: `website/app/[locale]/(app)/setting/(other)/snapshots/page.tsx`. **API**: `GET /snapshots`, `POST /snapshots/restore`
- [ ] **Community links** — PWA settings has Facebook and Discord links; mobile missing. **PWA file**: `website/app/[locale]/(app)/setting/page.tsx` → Community section
- [ ] **Support links** — PWA has Discord support, Terms, Privacy links; mobile has Terms but missing Discord and Privacy links. **PWA file**: settings page → Support section
- [ ] **Button mapping** — PWA mobile layout links to `/remote?mobile=true&dev=true` for button mapping; mobile has gamepad test but no in-remote button mapping mode

---

## H. Storage / Add-ons

- [ ] **Storage / Add-on service page** — PWA has `/storage` page with service toggles (extra buckets, etc.); mobile missing entirely. **PWA file**: `website/app/[locale]/(app)/storage/page.tsx`, `website/components/profile/SubscriptionAddons.tsx`

---

## I. Onboarding

- [ ] **Structured onboarding tours** — PWA uses `nextstepjs` with 3 tours (dashboard, remote, store); mobile has no equivalent. Should implement step-by-step introduction for new users. **PWA library**: `nextstepjs`

---

## J. Metrics / Diagnostics

- [x] Video metrics (FPS, bitrate, decode time, jitter, packet loss, freezes, etc.)
- [x] Audio metrics
- [x] Stream health state tracking
- [ ] **Stream health richer state types** — PWA uses TypeScript union type `'healthy' | 'recovering_video' | 'video_stalled' | 'encoder_stalled' | 'backend_reconnecting' | 'control_blocked'`; mobile uses free-form string. Consider sealed class or enum for compile-time safety. **PWA file**: `website/core/core/models/metrics.model.ts` → `StreamHealthState`

---

## K. Payment / Subscription Sync

- [x] Payment screen
- [x] Deposit screen
- [x] Bank transfer deposit
- [x] Transaction history
- [x] Transaction detail
- [x] Subscription screen
- [x] Upgrade/downgrade flows
- [ ] Verify payment provider parity — PWA supports PayOS, Stripe, Dana, OVO, PayerMax; verify mobile supports same providers. **PWA files**: `website/app/[locale]/(app)/payment/`

---

## Summary

| Category | Total | Done | Remaining |
|----------|-------|------|-----------|
| A. Critical Bugs | 1 | 1 | 0 |
| B. Protocol Sync | 14 | 14 | 0 |
| C. Advanced Settings | 15 | 7 | 8 |
| D. Dashboard / VM Mgmt | 10 | 5 | 5 |
| E. Remote / Streaming | 16 | 11 | 5 |
| F. Store / Install | 5 | 0 | 5 |
| G. Settings Pages | 10 | 6 | 4 |
| H. Storage / Add-ons | 1 | 0 | 1 |
| I. Onboarding | 1 | 0 | 1 |
| J. Metrics / Diagnostics | 4 | 3 | 1 |
| K. Payment / Subscription | 8 | 7 | 1 |
| **Total** | **75** | **53** | **22** |

### Recommended execution order

1. ~~**A1** — Fix mouse wheel bug~~ **DONE**
2. ~~**B7–B8** — Clipboard and gamepad reconnect protocol fix~~ **DONE**
3. **C1–C6** — FPS slider, bitrate range, keyboard lock, gamepad touch, client cursor, fill screen (settings that directly affect streaming UX)
4. **D4–D5** — Share session, port forwards (growth + power-user features)
5. **F1–F5** — Store and install flow (core product loop for new users)
6. **E1–E3** — Side panel parity, VM log stream (streaming polish)
7. **G1** — Snapshots page (data protection)
8. **H1** — Storage / add-ons page (monetization)
9. **I1** — Onboarding tours (new user activation)
10. **J1** — Stream health type safety (code quality)
