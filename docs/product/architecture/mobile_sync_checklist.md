# Mobile App Sync Checklist

Actionable checklist of items the mobile app needs to synchronize with the PWA (reference implementation). Derived from the [User Flow Contract](./client_user_flow_contract.md), [Platform Divergence Registry](./client_platform_divergence.md), [Protocol Contract](./client_protocol_contract.md), and the [pre-release task list](../../checklist.md).

**Status legend**: `[ ]` = not started, `[~]` = partial/in progress, `[x]` = done, `[-]` = not applicable

**Architecture reference**: Flutter client uses Clean Architecture (`presentation/` → `domain/` → `data/` + `core/` for WebRTC/HID). State: `flutter_bloc` + `get_it`/`injectable`. Streaming orchestrator: `ThinkmayClient` (4 WebRTC connections). Bootstrap: `SplashCubit` → `GlobalCubit.preload()` → `AppRouter.isAppInitialized`. See [mobile_architecture.md](./mobile_architecture.md) and [docs/ai/mobile/specs/01-app-bootstrap-global-state.md](../../ai/mobile/specs/01-app-bootstrap-global-state.md).

---

## L. Pre-Release Blockers (Release Gate)

Items from [docs/checklist.md](../../checklist.md) that must ship before app-store release. Each maps to longer parity work elsewhere in this doc (cross-refs in **Related**).

- [ ] **L-1: Startup performance — main-thread jank (3–5 s)**
  - **Symptom**: First 3–5 s after cold start feel sluggish; device logs report *"skipped frames"* / *"too much work on main thread"*.
  - **Root causes (mobile)**:
    - `main()` runs `configureDependencies()` synchronously before first frame — large `injectable` graph registers every service up front (`mobile/lib/main.dart`, `dependency_injection/injection.config.dart`).
    - `PreloadUseCaseImpl` decodes JSON on the main isolate: wave 1 (subscription, domains, worker, wallet) then wave 2 (store catalog, configuration, settings) — wave 2 was added to reduce stacking but still blocks splash exit (`mobile/lib/data/use_case/preload/preload_use_case_impl.dart`).
    - `SplashScreen` animates progress on a 50 ms timer while awaiting auth + preload on the same isolate (`mobile/lib/presentation/screen/splash/splash_screen.dart`).
  - **PWA reference**: `preload()` is deferred via `requestIdleCallback` / `setTimeout(0)` in `website/components/providers/stateProvider.tsx` so first paint is not blocked; critical fetches run after shell render.
  - **Fix approach**: Profile with Flutter DevTools timeline; move heavy JSON parsing / Freezed model mapping to `compute()` isolates; lazy-register non-splash DI modules; defer wave-2 preload until after first dashboard frame (match PWA idle scheduling); consider shrinking splash asset decode (PNG → WebP).
  - **Related**: L-7 (bootstrap gate), §D dashboard first paint.

- [ ] **L-2: Dashboard volume card — `ControlPannel` parity audit**
  - **PWA reference**: `website/components/dashboard/VmState.tsx` — volume card with template image, availability dot, connect/restart/shutdown, share, debug VNC, port-forward list, played-hours meter, disk-resize CTA, expired → payment redirect.
  - **Mobile reference**: `mobile/lib/presentation/screen/dashboard/dashboard_screen.dart` (`_VolumeCard` widget) + `DashboardCubit`.
  - **Known gaps** (audit each prop/action against PWA):
    | PWA `ControlPannel` | Mobile status |
    |---------------------|---------------|
    | `open` / connect | ✅ `openStream` / `powerOnCloudPC` |
    | `close` / shutdown | ✅ `powerOffCloudPC` |
    | `restart` | ✅ `restartCloudPC` |
    | `share` | ❌ button wired but `shareVolume()` is empty TODO — see L-4 |
    | `debug` (VNC popup) | ❌ missing — see L-3 |
    | `port_forward[]` display | ❌ not rendered |
    | Disk resize button | ❌ TODO stub — see L-10 |
    | `transient` volume handling | ⚠️ verify hide share/connect rules |
    | Expired → `/payment` | ⚠️ verify `isExpired` UX matches PWA `ShareWF` / `Connect` guards |
  - **Acceptance**: Side-by-side screenshot + behavior matrix for `ready`, `started`, `headless`, `unknown`, expired subscription states.

- [ ] **L-3: Deploy watch — VNC preview + log WebSocket (PWA `deployWatch.tsx`)**
  - **PWA reference**: `website/components/dashboard/deployWatch.tsx`
    - **Friendly mode**: YouTube tutorial iframe keyed by game `code_name`.
    - **Technical mode**: live VNC (`VncScreen` from `components/popup/internal`) when `DeployWatch.vnc` path is set; `QueueModal` when waiting in queue; WebSocket log stream on `DeployWatch.log` path (`wss://{host}:444{log}`); progress step list; elapsed boot timer; cancel → `CancelDeployment`.
  - **Mobile current**: `DeployWatchOverlay` shows title, progress text list, boot timer, cancel only — no VNC, no log WS, no friendly/technical toggle (`mobile/lib/presentation/screen/dashboard/widgets/deploy_watch_overlay.dart`).
  - **Data model**: `DeployState` already has `vnc`, `log`, `progress` fields (`mobile/lib/domain/models/worker/worker_state_models.dart`) but `DashboardCubit.powerOnCloudPC` only appends `onStatus` strings to `progress`; does not capture `vnc`/`log` URLs from session response.
  - **Implementation plan**:
    1. Extend `StartSessionUseCase` / session callback to populate `DeployState.vnc` and `.log` from daemon deploy payload (same fields PWA Redux `state.popup.deployWatch` receives).
    2. Add `[vnc_viewer](https://pub.dev/packages/vnc_viewer)` widget in technical mode — follow package example for `VncViewer` + `scaleViewport` to mirror PWA `scaleViewport`.
    3. Open `WebSocketChannel` on `log` URL; prepend incoming lines to progress list (PWA prepends newest first).
    4. Add friendly/technical segmented control; persist mode in `SharedPreferences` (PWA: `state.remote.watchMode` + `cache_setting`).
    5. Queue detection: if first log line contains `"you are in"`, show queue UI with upgrade CTA (PWA `QueueModal`).
  - **Related**: §D *Debug / VNC window*.

- [ ] **L-4: Share link logic — dashboard volume card**
  - **PWA reference**: `website/components/dashboard/index.tsx` → `share(volume_id)`:
    1. `getVmSession(computer, volume_id)` → session `{ id, thinkmay }`.
    2. `ParseRequest(id, thinkmay)` → streaming tokens; `save_reference(result)` into Redux `state.remote.ref`.
    3. Build URL: `https://{host}/{locale}/{remote|share}?ref={uid}&vmid=…&video=…&audio=…&data=…`.
    4. `navigator.clipboard.writeText` + `AppToast.success('copied to clipboard')`.
  - **Mobile partial**: Remote control panel already implements equivalent via `ControlPanelActions.buildShareUri` / `copySessionLink` / `shareSession` (`mobile/lib/presentation/screen/remote/widgets/control_panel/control_panel_actions.dart`) using `SessionService.parseRequest` and hardcoded host `https://thinkmay.net`.
  - **Mobile missing**: `DashboardCubit.shareVolume(String volumeId)` is an empty TODO (`dashboard_cubit.dart` L308); dashboard Share button calls it (`dashboard_screen.dart` L595).
  - **Implementation**: Reuse `ControlPanelActions.sessionRefParams` pattern but source session from `GlobalCubit.state.workerInfo` + `getVmSession` equivalent (worker sessions map) without entering RemoteScreen; copy to clipboard; show toast via L-9.
  - **Related**: §D *Share session*.

- [ ] **L-5: Onboarding flow audit**
  - **PWA reference**: `nextstepjs` guided tours defined in `website/backend/utils/tour.tsx` — three tours (`onboarding-mobile-guide`, dashboard guide, store guide) triggered via `useTourGuide()` on dashboard. Steps cover device selection, streaming quality, toggles, routing domain, sharing, advanced settings.
  - **Mobile current**:
    - `OnboardingVirtualScreen` — interactive **remote-only** tutorial (mouse move, keyboard, gamepad, control panel steps) opened from remote side panel (`ControlPanelActions.openUsageGuide`). Not shown on first launch.
    - No dashboard or store tour equivalent.
  - **Audit checklist**:
    - [ ] First-run detection flag (PWA: tour completion in local storage).
    - [ ] Dashboard: volume card, connect, domain switcher, subscription states.
    - [ ] Remote: side panel, virtual controls, advanced settings entry.
    - [ ] Store / install flow (when §F ships).
    - [ ] Decide: Flutter overlay package (e.g. `tutorial_coach_mark`) vs custom `OverlayPortal` vs re-use `OnboardingVirtualScreen` pattern.
  - **Related**: §I *Structured onboarding tours*.

- [ ] **L-6: Profile tab — gamification parity (`/profile`)**
  - **Product spec**: [gamification.md](../features/gamification.md) — Profile tab is **not** account edit; it is rank, stars, quests, leaderboard, heatmap hub.
  - **PWA reference**: `website/app/[locale]/(app)/profile/page.tsx` + `website/components/profile/*` — `RankBanner`, `RoadmapCard`, `LeaderboardCard`, `QuestsCard`.
  - **Mobile current**: `ProfileScreen` shows account card with **hardcoded/mock** usage stats, server picker, static subscription card (`mobile/lib/presentation/screen/profile/profile_screen.dart`). `ProfileCubit.init()` reads `GlobalCubit` but preload phase 2 never emits quests/stars/heatmap into `GlobalState` (`docs/ai/mobile/specs/profile/09-profile-account.md`).
  - **APIs to wire**: RPC `get_star_balance`, `get_quests_v2`, `get_star_leaderboard`, `get_heatmap`; action `claim_mission_v2`.
  - **Acceptance**: Profile tab matches PWA layout per `thinkmay_mobile_design.md`; account edit stays on `/setting` → `/update-profile`.
  - **Related**: §G *Profile page* (status corrected below).

- [ ] **L-7: Bootstrap preload gate — exit splash only when data is ready**
  - **PWA reference**: `website/backend/actions/background.ts` → `preloadSilent()` **awaits** subscription, configuration, domains, worker, settings, positions before `finish_fetching()`; non-critical fetches are fire-and-forget afterward.
  - **Mobile current**:
    - `SplashCubit.checkIsLoggedIn()` awaits `GlobalCubit.preload()` then sets `AppRouter.isAppInitialized = true` and navigates (`splash_cubit.dart`).
    - `GlobalCubit.preload()` emits `fetched: true` even on partial failure (empty lists) — dashboard may render empty then populates (`global_cubit.dart`).
    - Preload phase 2 (recommendations, mails, quests, heatmap, star balance) is fire-and-forget and **never updates** `GlobalState` (`preload_use_case_impl.dart` L116–142).
    - Login/sign-up paths call `preload()` but do not block navigation on `GlobalState.fetched` (`login_cubit.dart`, spec 01 🟡).
  - **Target behavior**: Splash (and post-login redirect) waits until wave-1 preload completes successfully; dashboard reads from populated `GlobalCubit` without flash-of-empty; optionally gate on `workerInfo != null` for logged-in users.
  - **Router**: `AppRouter` redirect should respect `GlobalCubit.state.fetched && !isLoading` before `/home`.
  - **Related**: L-1 (performance — don't block longer than necessary; optimize first, then gate).

- [ ] **L-8: Advanced settings screen — UI polish / bug fixes**
  - **Mobile file**: `mobile/lib/presentation/screen/advanced_settings/advanced_settings_screen.dart`
  - **PWA reference**: `website/app/[locale]/(app)/setting/(other)/advance/page.tsx`
  - **Scope**: Fix minor layout/overflow/visual glitches reported on device (safe-area, slider label alignment, section spacing, dark-theme contrast). Verify toggles persist via `RemoteSettingsCubit` → `RemoteSettingsRepository` (SharedPreferences) and apply live when opened from remote (`?remote=true`).
  - **Parity gaps to verify while fixing UI** (see §C): keyboard lock, gamepad touch, client cursor, fill-screen, auto relative mouse toggles may exist in `RemoteSettings` model but need UI wiring if missing.
  - **Related**: §C *Advanced Settings Sync*.

- [ ] **L-9: `AppToast` notification system**
  - **PWA reference**: `website/components/providers/stateProvider.tsx` → `AppToast` wrapper over `react-hot-toast`:
    - `AppToast.success(message)` — green check, top-left, 4 s, glass gradient border.
    - `AppToast.error(message)` — red X icon.
    - `AppToast.loading(message)` — spinner (used for in-progress connect).
    - Used across dashboard share, login errors, disk resize, log callbacks (`background.ts` → `logCallback`).
  - **Mobile current**: Inconsistent — `flutter_easyloading` for blocking loaders (login/sign-up), ad-hoc `SnackBar` / `ScaffoldMessenger` in remote and control panel (`control_panel_actions.dart` → `_showSnack`), no global styled toast.
  - **Implementation plan**:
    1. Create `AppToast` utility (or `TmToast`) in `mobile/lib/presentation/components/` mirroring three variants + duration/position.
    2. Register overlay in `MaterialApp.router` `builder` (alongside or replacing `EasyLoading` for non-blocking cases).
    3. Replace `_showSnack` / scattered SnackBars with `AppToast.success` for copy-link, errors, deployment status.
    4. Match PWA visual tokens: `#112E29` → `#0A1A1A` gradient, `#29D69F` accent, `#1F3E39` border.
  - **Related**: L-4 (share copied feedback), L-10 (disk resize errors).

- [ ] **L-10: Disk resize popup**
  - **PWA reference**: `website/components/popup/disk.tsx` — opened via `popup_open({ type: 'diskResize', data: { volume_id } })` from `ControlPannel` disk button.
    - Shows current vs plan max disk from subscription policy + addon charges (`fetch_addon_charges`).
    - Selectable size steps; storage usage bar (`total_data_credit` vs free credit).
    - Confirm → `Resize(volume_id, size)` API → success closes popup + `AppToast`; failure → `AppToast.error`.
    - `hour1` plan → redirect to `/payment` instead of resize.
  - **Mobile current**: `_VolumeCard` secondary button calls empty TODO (`dashboard_screen.dart` L657: `// TODO: Implement resize disk popup`).
  - **APIs**: PocketBase `Resize` (via worker API — same as PWA `#/api`), `FetchAddonChargesUseCase` / `FetchPlanDetail` for pricing display.
  - **Implementation**: Bottom sheet or dialog widget `DiskResizeSheet`; wire `DashboardCubit.openDiskResize(volumeId)`; refresh worker info on success via `GlobalCubit.refreshWorker()`.
  - **Related**: §D *ControlPannel* disk button, §H *Storage / Add-ons*.

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

### H.265 (mobile-specific)

- [x] Gate H.265 toggle by `deviceSupportsH265Decode()` (RTP caps)
- [x] Downgrade `preferredCodec` on unsupported devices at load / reset
- [ ] **TODO:** Custom `flutter_webrtc` fork + custom `libwebrtc` build — see [mobile_h265_investigation.md](./mobile_h265_investigation.md)

- [x] HQ / Stability quality preset radio
- [x] Disable GCC toggle + fixed bitrate slider
- [x] Use H.265 toggle (disabled when `deviceSupportsH265Decode()` is false)
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
- [~] Deploy watch overlay with progress steps — text progress only; VNC/log/friendly mode missing. **See**: L-3.
- [x] Restart volume action
- [x] Close/shutdown volume action
- [~] **Share session** — Remote side panel: ✅ `ControlPanelActions.copySessionLink` / `shareSession`. Dashboard volume card: ❌ `DashboardCubit.shareVolume` TODO. **PWA file**: `website/components/dashboard/index.tsx` → `share()`. **See**: L-4.
- [~] **Debug / VNC window** — PWA opens debug VNC in popup (`debug()` → `constructRedirect('/debug')`). Mobile deploy overlay lacks VNC entirely. **See**: L-3.
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

- [~] **Profile page** — Account/settings screens exist; Profile **tab** still mock stats, missing gamification widgets (rank, quests, leaderboard, heatmap). **See**: L-6, [09-profile-account.md](../../ai/mobile/specs/profile/09-profile-account.md).
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

- [~] **Structured onboarding tours** — PWA uses `nextstepjs` with 3 tours (dashboard, remote, store). Mobile has remote-only `OnboardingVirtualScreen`, no first-run dashboard/store tours. **PWA**: `website/backend/utils/tour.tsx`. **See**: L-5.

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

| Category | Total | Done | Partial | Remaining |
|----------|-------|------|---------|-----------|
| A. Critical Bugs | 1 | 1 | 0 | 0 |
| B. Protocol Sync | 14 | 14 | 0 | 0 |
| C. Advanced Settings | 15 | 7 | 0 | 8 |
| D. Dashboard / VM Mgmt | 10 | 4 | 3 | 3 |
| E. Remote / Streaming | 16 | 11 | 0 | 5 |
| F. Store / Install | 5 | 0 | 0 | 5 |
| G. Settings Pages | 10 | 5 | 1 | 4 |
| H. Storage / Add-ons | 1 | 0 | 0 | 1 |
| I. Onboarding | 1 | 0 | 1 | 0 |
| J. Metrics / Diagnostics | 4 | 3 | 0 | 1 |
| K. Payment / Subscription | 8 | 7 | 0 | 1 |
| **L. Pre-Release Blockers** | **10** | **0** | **0** | **10** |
| **Total** | **95** | **52** | **5** | **38** |

### Recommended execution order

**Release gate (do first — blocks app-store ship):**

1. **L-1 + L-7** — Startup perf + preload gate (fix jank, then gate splash on wave-1 data)
2. **L-9** — AppToast (unblocks consistent feedback for items below)
3. **L-4 + L-10** — Dashboard share link + disk resize popup
4. **L-2** — ControlPannel audit (verify matrix after L-4/L-10 land)
5. **L-3** — Deploy watch VNC + log WebSocket (`vnc_viewer` package)
6. **L-8** — Advanced settings UI fixes
7. **L-6** — Profile tab gamification parity
8. **L-5** — Onboarding flow audit + first-run tours

**Broader parity (post-release or parallel if capacity allows):**

9. ~~**A1** — Fix mouse wheel bug~~ **DONE**
10. ~~**B7–B8** — Clipboard and gamepad reconnect protocol fix~~ **DONE**
11. **C1–C6** — FPS slider, bitrate range, keyboard lock, gamepad touch, client cursor, fill screen (settings that directly affect streaming UX)
12. **D6–D8** — Port forwards, error states, notifications panel
13. **F1–F5** — Store and install flow (core product loop for new users)
14. **E1–E3** — Side panel parity, VM log stream (streaming polish)
15. **G1** — Snapshots page (data protection)
16. **H1** — Storage / add-ons page (monetization)
17. **J1** — Stream health type safety (code quality)
