# Mobile App Sync Checklist

Actionable checklist of items the mobile app needs to synchronize with the PWA (reference implementation). Derived from the [User Flow Contract](./client_user_flow_contract.md), [Platform Divergence Registry](./client_platform_divergence.md), [Protocol Contract](./client_protocol_contract.md), and the [pre-release task list](../../checklist.md).

**Status legend**: `[ ]` = not started, `[~]` = partial/in progress, `[x]` = done, `[-]` = not applicable

**Architecture reference**: Flutter client uses Clean Architecture (`presentation/` → `domain/` → `data/` + `core/` for WebRTC/HID). State: `flutter_bloc` + `get_it`/`injectable`. Streaming orchestrator: `ThinkmayClient` (4 WebRTC connections). Bootstrap: `SplashScreen` → `SplashCubit` session restore (if any) → `GlobalCubit.bootstrap()` → **`PreloadUseCase.loadAll()`** (authed: 13 parallel API calls; guest: domains only) → splash progress bar until `isBootstrapReady` → `AppRouter.isAppInitialized` → `/home` or `/welcome`. See [mobile_architecture.md](./mobile_architecture.md) and [docs/ai/mobile/specs/01-app-bootstrap-global-state.md](../../ai/mobile/specs/01-app-bootstrap-global-state.md).

---

## L. Pre-Release Blockers (Release Gate)

Items from [docs/checklist.md](../../checklist.md) that must ship before app-store release. Each maps to longer parity work elsewhere in this doc (cross-refs in **Related**).

- [~] **L-1: Startup performance — main-thread jank**
  - **Symptom**: Cold start and early tab switches can feel sluggish; device logs report *"skipped frames"* / *"Davey!"* during splash decode, dashboard first paint, or heavy JSON handling.
  - **Root causes (mobile)**:
    - `main()` runs `configureDependencies()` synchronously before first frame — large `injectable` graph registers every service up front (`mobile/lib/main.dart`, `dependency_injection/injection.config.dart`).
    - `PreloadUseCaseImpl.loadAll()` fetches 13 endpoints in parallel but **JSON decode + model mapping still run on the main isolate** when responses return — store catalog (~4k games) is the worst offender (`mobile/lib/data/use_case/preload/preload_use_case_impl.dart`).
    - Dashboard first paint: volume card section + hero carousel still produce 200–400 ms builds on low-end devices even when data is preloaded (`dashboard_screen.dart`, `play_hero_carousel.dart`).
    - `flutter_webrtc` native plugin registration deferred until streaming entry (lazy init shipped) — startup cost moved off cold path.
  - **PWA reference**: `preloadSilent()` in `website/backend/actions/background.ts` awaits shell data before `finish_fetching()`; non-critical fetches fire-and-forget afterward — mobile now matches the **await-all** gate, not PWA idle deferral.
  - **Mobile shipped (2026-06-09)**:
    - **Full splash gate**: authed users do not leave splash until worker, volumes, subscription, wallet, domains, setting domain, gamification (6 RPCs), and store catalog are loaded — no post-navigate fetch on Profile or Explore tabs.
    - **`PreloadUseCase.loadAll()`**: single `Future.wait` with 13 parallel leaf API calls; splash progress bar maps `GlobalState.bootstrapProgress` (increments per completed call).
    - **`GlobalState.isBootstrapReady`**: `fetched && !isLoading && deferredPreloadComplete` — router/login/dashboard blocked until full batch completes.
    - **`ProfileCubit` / `ExploreCubit`**: read `GlobalCubit` only on tab open; pull-to-refresh / AI search still hit network on demand.
    - Asset/animation fixes: WebP splash/logo precache; removed global SVG precache; static splash progress bar; bounded hero `PageView`; volume-card repaint boundaries; `[perf]` / `[startup]` timing via `StartupProfiler`.
    - Lazy WebRTC: Android/iOS defer `flutter_webrtc` plugin registration until streaming screen (`LazyPluginRegistrant`, `WebRtcLazyInit`).
  - **Current obstacles**:
    - Splash duration bounded by slowest API (~3–10 s on real devices) — acceptable UX tradeoff vs half-loaded tabs, but **store + subscription RPC latency** still dominates.
    - Intermittent **`subs=0` / `wallet=0`** from account RPC on some sessions — server/API investigation, not client parallelization.
    - **Main-isolate JSON** after parallel fetch completes — need `compute()` / isolate offload for store catalog and large RPC payloads.
    - **Post-splash UI jank** on dashboard first frame — DevTools timeline profiling not yet done; volume cards / hero carousel may need further list virtualization.
    - `ExploreSearchCubit` still fetches **genres** on search screen open (lightweight vs catalog).
    - Release build: Play Store signing via `key.properties` not configured in repo.
  - **Remaining work**:
    - Profile cold start in Flutter DevTools timeline on Pixel-class hardware; quantify splash vs dashboard vs tab-switch hitches.
    - Offload store catalog JSON parse + `Game` mapping to isolates.
    - Lazy-register or split non-splash DI modules if `configureDependencies()` remains measurable.
    - Validate parallel preload under poor network (partial failure → empty sections vs error UI).
  - **Related**: L-7 (bootstrap gate ✅), §D dashboard first paint, §F Explore tab.

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

- [~] **L-6: Profile tab — gamification parity (`/profile`)**
  - **Product spec**: [gamification.md](../features/gamification.md) — Profile tab is **not** account edit; it is rank, stars, quests, leaderboard, heatmap hub.
  - **PWA reference**: `website/app/[locale]/(app)/profile/page.tsx` + `website/components/profile/*` — `RankBanner`, `RoadmapCard`, `LeaderboardCard`, `QuestsCard`.
  - **Mobile shipped (2026-06-09)**:
    - `GlobalCubit.refreshGamification()` loads quests, heatmap, star balance, leaderboard, rank rewards, addon charges into `GlobalState`.
    - APIs wired: `get_star_balance`, `get_user_missions_v2`, `get_star_leaderboard`, `get_user_heatmap`, `get_all_rank_rewards`, `list_addon_charges_v2`, `claim_mission_v2`.
    - Rank badges bundled locally (`mobile/assets/badges/*.png`); leaderboard avatars via PocketBase lookup + DiceBear PNG fallback (`UserAvatarImage`).
    - Gamification l10n (en/vi) in `app_*.arb`; account edit remains `/setting` → `/update-profile`.
    - **Splash preload (2026-06-09)**: gamification batch included in `PreloadUseCase.loadAll()` — Profile tab no longer fetches on first open; `ProfileCubit.init()` subscribes to `GlobalCubit` only.
  - **Remaining gaps**:
    - Discord OAuth link (`DiscordLinkCard` — UI stub only).
    - `ThemePicker` / `accent_rank` (optional PWA polish).
    - Mission telemetry `session_device`, `ai_search_used` (missions unlock server-side).
    - Exchange-rate formatting for addon charges (credits fallback today).
    - Side-by-side pixel audit vs PWA mobile `/profile`.
  - **Related**: §G *Profile page*.

- [x] **L-7: Bootstrap preload gate — exit splash only when data is ready**
  - **PWA reference**: `website/backend/actions/background.ts` → `preloadSilent()` **awaits** subscription, configuration, domains, worker, settings, positions before `finish_fetching()`; non-critical fetches are fire-and-forget afterward.
  - **Mobile shipped (2026-06-09, updated same day — full parallel preload)**:
    - `GlobalState.isBootstrapReady` = `fetched && !isLoading && deferredPreloadComplete`; `GlobalCubit.bootstrap()` / `preload()` share one in-flight future.
    - **Authed splash**: `PreloadUseCase.loadAll(email)` — **13 parallel API calls** (worker, configuration, subscription, wallet, domains, setting, 6× gamification, store catalog) before navigate; progress via `bootstrapProgress`.
    - **Guest splash**: domains only.
    - `GlobalState.domains` + `games` + gamification fields populated before `/home` — Profile/Explore tabs read cache, no tab-switch fetch storm.
    - `AppRouter` redirect + `refreshListenable` gates authenticated routes until `isBootstrapReady`.
    - `LoginCubit` blocks `LoginSuccessState` until `isBootstrapReady`; `DashboardCubit` loading until bootstrap ready.
    - Splash progress bar during bootstrap — `EasyLoading` not shown on login screen open (auth submit only).
    - Fire-and-forget after preload: recommendations + mails (`_scheduleDeferredNonCritical`, 5 s delay) — does not block shell.
  - **Related**: L-1 (perf — splash may take longer but tabs are instant; isolate offload still open).

- [x] **L-8: Advanced settings screen — UI polish / bug fixes**
  - **Mobile file**: `mobile/lib/presentation/screen/advanced_settings/advanced_settings_screen.dart`
  - **PWA reference**: `website/app/[locale]/(app)/setting/(other)/advance/page.tsx`
  - **Mobile shipped (2026-06-09)**:
    - Safe-area scroll body; sticky footer border; slider badge `Wrap` prevents min/max label overflow on narrow screens.
    - Toggle layout matches PWA (label left, switch right); title/description contrast (`#FFFFFF` / `#A3A3A3`).
    - `SliderTheme` inactive track + `TmSwitch` off-state use `white/10–20` for dark-theme contrast.
    - `TmSwitch.didUpdateWidget` syncs external value — fixes stale toggles after Reset.
    - All §C toggles wired: FPS steps, dual bitrate range, keyboard lock, touch gamepad, client cursor, fill-screen, auto relative mouse.
    - Persistence + live apply verified: `RemoteSettingsCubit` → `RemoteSettingsRepository` (SharedPreferences); `?remote=true` routes back to `RemoteScreen` and `onReconnectRequested` applies reconnect-sensitive changes.
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
- [x] Always 1080p toggle — UI + runtime (`changeResolution` / `applyAlways1080pIfNeeded`, 2026-06-09)
- [x] Enable microphone toggle — UI + runtime (`microUrl` + reconnect on toggle, 2026-06-09)
- [x] VSync toggle
- [x] Keyboard compatibility (scancode) toggle
- [x] **FPS slider** — steps [40, 60, 90, 120, 144, 240] in `advanced_settings_screen.dart` → `_FpsSlider`
- [x] **Bitrate min/max dual range slider** — `_DualBitrateSlider` when GCC enabled; `_FixedBitrateSlider` when disabled
- [~] **Keyboard lock toggle** — UI + persist; **runtime N/A** — no `navigator.keyboard` on native (PWA locks on fullscreen)
- [x] **Gamepad touch toggle** — `RemoteSettings.touchGamepad` + `setTouchGamepad` → `computeTouchEnabled` in `RemoteScreen`
- [x] **Client cursor toggle** — UI + persist; runtime follows PWA mobile (`isMobile` always true). See [cursor_render_behavior.md](../product/architecture/cursor_render_behavior.md).
- [x] **Fill screen / object-fit toggle** — `RemoteSettings.objectFitFill` + `setObjectFitFill`
- [~] **Auto relative mouse toggle** — UI + persist; **runtime blocked** until deploy log WebSocket (L-3) — PWA `logCallback` on game spawn

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

- [~] **Explore tab catalog** — Supabase store preloaded on splash via `PreloadUseCase.loadAll()` → `GlobalState.games`; `ExploreCubit` reads global cache (no fetch on tab switch). AI search wired (`SearchStoresUseCase`). **Remaining**: persona genre sections (#22), pixel parity vs PWA `/store`, game detail/install flow.
- [ ] **Store catalog screen** — Replace debug placeholder (`StoreScreen` shows raw JSON) with polished game catalog matching PWA. **PWA file**: `website/app/[locale]/(app)/store/page.tsx`
- [ ] **AI search bar** — PWA has natural language game search; mobile missing. **PWA component**: `AISearchBar`
- [ ] **AI recommendations** — PWA has personalized game suggestions; mobile missing. **PWA component**: `AIRecommendations`
- [ ] **Game detail page** — Verify mobile `GameDetailScreen` matches PWA's game detail with install/subscribe buttons. **PWA file**: `website/app/[locale]/(app)/store/[slug]/page.tsx`
- [ ] **Install from template flow** — End-to-end: browse → select → install → new volume appears on dashboard. PWA wires this; mobile needs full flow.

---

## G. Settings Pages Sync

- [~] **Profile page** — Profile **tab** gamification hub shipped (rank, quests, leaderboard, heatmap); account edit on `/update-profile` via Settings. Remaining: Discord OAuth, ThemePicker, mission telemetry, pixel audit. **See**: L-6, [09-profile-account.md](../../ai/mobile/specs/profile/09-profile-account.md).
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
| C. Advanced Settings | 15 | 11 | 3 | 1 |
| D. Dashboard / VM Mgmt | 10 | 4 | 3 | 3 |
| E. Remote / Streaming | 16 | 11 | 0 | 5 |
| F. Store / Install | 6 | 0 | 1 | 5 |
| G. Settings Pages | 10 | 5 | 1 | 4 |
| H. Storage / Add-ons | 1 | 0 | 0 | 1 |
| I. Onboarding | 1 | 0 | 1 | 0 |
| J. Metrics / Diagnostics | 4 | 3 | 0 | 1 |
| K. Payment / Subscription | 8 | 7 | 0 | 1 |
| **L. Pre-Release Blockers** | **10** | **2** | **1** | **7** |
| **Total** | **96** | **57** | **10** | **29** |

### Recommended execution order

**Release gate (do first — blocks app-store ship):**

1. **L-1** — Startup perf: parallel splash preload ✅; remaining isolate offload + dashboard first-frame jank — L-7 gate ✅ shipped
2. **L-9** — AppToast (unblocks consistent feedback for items below)
3. **L-4 + L-10** — Dashboard share link + disk resize popup
4. **L-2** — ControlPannel audit (verify matrix after L-4/L-10 land)
5. **L-3** — Deploy watch VNC + log WebSocket (`vnc_viewer` package)
6. ~~**L-8** — Advanced settings UI fixes~~ **DONE** (2026-06-09)
7. **L-6** — Profile tab polish (Discord OAuth, ThemePicker, mission telemetry, pixel audit) — core hub shipped `[~]`
8. **L-5** — Onboarding flow audit + first-run tours

**Broader parity (post-release or parallel if capacity allows):**

9. ~~**A1** — Fix mouse wheel bug~~ **DONE**
10. ~~**B7–B8** — Clipboard and gamepad reconnect protocol fix~~ **DONE**
11. ~~**C1–C6** — FPS slider, bitrate range, keyboard lock, gamepad touch, client cursor, fill screen~~ **DONE** (L-8 / §C)
12. **D6–D8** — Port forwards, error states, notifications panel
13. **F1–F5** — Store and install flow (core product loop for new users)
14. **E1–E3** — Side panel parity, VM log stream (streaming polish)
15. **G1** — Snapshots page (data protection)
16. **H1** — Storage / add-ons page (monetization)
17. **J1** — Stream health type safety (code quality)
