# Control Panel Parity Checklist (PWA vs Mobile)

Actionable checklist comparing the PWA **SettingsPanel** with the Flutter **ControlPanel** on the remote streaming screen.

| | PWA | Mobile |
|---|-----|--------|
| **Component** | `website/components/control/setting/index.tsx` | `mobile/lib/presentation/screen/remote/widgets/control_panel/` |
| **State** | Redux `sidepane` + `remote` | `SidepaneCubit` + `RemoteSettingsCubit` |
| **Audit date** | 2026-06-09 | |
| **Last updated** | 2026-06-09 | |

**Scope:** Critical and medium mismatches that affect real user workflows. Cosmetic polish and intentional mobile differences are listed separately and are **not** action items.

**Status legend:** `[ ]` not started · `[~]` partial · `[x]` done · `[-]` N/A (intentional exception)

---

## Critical — broken or missing functionality

These controls are visible in the mobile panel but do not perform the expected action.

| ID | Item | PWA behavior | Mobile gap | Primary files |
|----|------|--------------|------------|---------------|
| C-1 | [x] **Copy session link** | Builds share URL (`ref` + session params), copies to clipboard, shows toast | Wired via `ControlPanelActions.copySessionLink` | `setting_section.dart`, `control_panel_actions.dart` |
| C-2 | [x] **Share session** | `navigator.share({ url })` | Wired via `SharePlus` | same |
| C-3 | [x] **Advanced settings entry** | Navigates to `/setting/advance?remote=true` | `context.push(RoutePaths.advancedSettings)` | same |
| C-4 | [x] **Restart VM** | `restart_session({ id: vmid })` when session exists | `RestartVolumeUseCase` via `ControlPanelActions.restartVm` | `device_section.dart` |
| C-5 | [x] **Power off VM** | `close_session({ id: vmid })` when session exists | `CloseSessionUseCase` via `ControlPanelActions.powerOffVm`; pops remote on success | `device_section.dart` |
| C-6 | [x] **Support / Discord** | Opens Discord support URL | `url_launcher` → Discord server URL | `control_panel_actions.dart` |

---

## Medium — behavior differs in a user-visible way

These work partially or use a different interaction model than PWA; users may get confused or a different streaming outcome.

| ID | Item | PWA behavior | Mobile gap | Primary files |
|----|------|--------------|------------|---------------|
| M-1 | [x] **Edit gamepad layout** | Toggle in control list; reflects `gamepad.draggable`; does not close panel | `_PanelToggleRow` + `toggleGamepadDraggable()`; panel stays open | `setting_section.dart` |
| M-2 | [x] **Edit gaming keyboard layout** | Toggle (`toggle_keyboard_draggable`); reflects `editState` | `_PanelToggleRow` + `toggleGamingKeyboardDraggable()` | same |
| M-3 | [x] **Usage guide** | Starts in-remote onboarding tour (`nextstepjs`) | Pushes `OnboardingVirtualScreen` fullscreen dialog | `control_panel_actions.dart` |
| M-4 | [x] **Fixed bitrate slider initial value** | Slider local state seeded from `min_bitrate` (PWA panel) | Local `_fixedBitrate` from `minBitrate`; debounced live `changeBitrate` | `setting_section.dart`, `remote_settings_cubit.dart` |
| M-5 | [x] **Routing domain list** | Uses `worker.availableDomains` (all routing entries) | `BlocBuilder<GlobalCubit>` → `domains` (same `fetch_domains` RPC as PWA) | `setting_section.dart` |

---

## Verified parity (no action)

| Area | Notes |
|------|--------|
| HQ / Stability presets | `setHqPreset` matches PWA `toggle_hq` (framerate, bitrates, reconnect) |
| Fixed bitrate debounce | 3s debounce → `ChangeBitrate` when GCC disabled |
| Network route switch | `updateBaseUrl` + stream restart ≈ `remote_domain` + reconnect |
| Control toggles (core) | Native touch, gaming mode, stats, hide shortcuts |
| Shortcuts grid | Same 16 shortcuts; HID send path equivalent |
| Shell tabs | Settings + Device side nav with accent styling |
| Panel scrim dismiss | Tap outside closes panel (mobile overlay pattern) |

---

## Panel vs Advanced Settings — toggle placement audit

Reference: PWA in-session panel uses `listMobileSettings` + `statsControl` in `website/backend/utils/sidepane.ts`. PWA **Advanced Settings** (`setting/(other)/advance/page.tsx`) holds compatibility/streaming toggles that are not quick-access during play.

### Control panel toggles today (`setting_section.dart`)

| Toggle | PWA panel | PWA advanced | Mobile advanced | Verdict |
|--------|-----------|--------------|-----------------|---------|
| Touch control (`native_touch`) | Yes | No | No | **Keep in panel** |
| Gaming mode (`relative_mouse`) | Yes | No | No | **Keep in panel** |
| Edit gamepad layout | Yes | No | No | **Keep in panel** |
| Edit gaming keyboard layout | Yes | No | No | **Keep in panel** |
| Connection stats (`show_stats`) | Yes | No | No | **Keep in panel** |
| Hide shortcuts (`plugin_hide`) | Yes | No | No | **Keep in panel** |
| Client cursor | No | Yes | Yes | [x] **Moved to advanced** |
| Touch while gamepad | No | Yes | Yes | [x] **Moved to advanced** |
| Keyboard scancode | No | Yes | Yes | [x] **Removed from panel** (advanced only) |
| Object fit fill | No | Yes | Yes | [x] **Moved to advanced** |

**Summary:** Done — panel keeps 6 PWA quick-access toggles; compatibility toggles live on `AdvancedSettingsScreen` only.

### Non-toggle controls — duplication note

| Control | In panel | In mobile advanced | PWA pattern | Note |
|---------|----------|-------------------|-------------|------|
| HQ / High stability presets | Yes | Yes | Both | Acceptable quick preset in panel; full tuning in advanced |
| Fixed bitrate slider (GCC off) | Yes | Yes | Both | Panel = live debounced knob; advanced = persisted min/max — align semantics |
| Disable GCC | No | Yes | Advanced only | Correct on mobile |
| H.265 / mic / 1080p / vsync | No | Yes | Advanced only | Correct on mobile; H.265 toggle **disabled** when `deviceSupportsH265Decode()` is false |

### Mobile advanced gaps vs PWA (not in panel either)

These exist on PWA advanced but have **no UI** on mobile advanced yet:

| Setting | PWA advanced | Mobile |
|---------|--------------|--------|
| Keyboard lock | Yes | No UI (`SettingItem` only in profile/setting cubit) |
| Auto relative mouse | Yes | Cubit method exists; no UI |
| Max FPS slider | Yes | No UI |
| Dual min/max bitrate (GCC on) | Yes | No UI |

### Recommended panel after cleanup (6 toggles)

1. Touch control  
2. Gaming mode  
3. Edit gamepad layout  
4. Edit gaming keyboard layout  
5. Connection stats  
6. Hide shortcuts  

Left column (copy, share, guide, advanced entry, Discord, routing) unchanged.

---

## Intentional mobile exceptions (do not fix for PWA parity)

Documented differences that are acceptable—or preferable—on native mobile.

| ID | Topic | Rationale |
|----|--------|-----------|
| E-1 | **Exit remote** | Mobile `Navigator.pop()` from `RemoteScreen` returns to dashboard; PWA uses `router.push('/play')`. Same user outcome, different navigation stack. |
| E-2 | **Fullscreen / watch mode toggle** | Mobile remote uses `SystemUiMode.immersiveSticky` on enter; no browser fullscreen API equivalent. |
| E-3 | ~~**Extra quick toggles in panel**~~ | **Superseded** by panel vs advanced audit above — those four toggles should move to Advanced Settings for PWA parity. |
| E-4 | **Close chevron in side nav** | Explicit dismiss control; standard native overlay pattern. PWA relies on click-outside only. |
| E-5 | **Onboarding implementation** | Mobile uses `OnboardingVirtualScreen` wizard instead of PWA `nextstepjs` in-panel tour. Same intent (usage guide), different UX shell. |

---

## Excluded from this checklist (polish only)

Not tracked here—no meaningful UX impact or native layout constraints:

- Panel vertical anchor (top-right vs center-right)
- Tab transition animation (`translateX` vs `AnimatedSwitcher`)
- Always two-column layout vs responsive stack
- `ScreenUtil` button heights / compact typography
- Routing checkmark icon vs gradient-only selected state
- Section title copy ("Control Support" vs "Assistive control")
- `Network` icon on routing chips
- Shortcut label i18n for literal `"Alt + Tab"`

---

## H.265 device gating (mobile)

| Item | Status |
|------|--------|
| [x] Detect HEVC in `getRtpReceiverCapabilities('video')` | `deviceSupportsH265Decode()` |
| [x] Disable advanced-settings H.265 toggle on unsupported devices | `AdvancedSettingsScreen` |
| [x] Downgrade saved `preferredCodec` on load / reset | `RemoteSettingsCubit` |
| [x] Remove field-trial patch + runtime H264 fallback | See [mobile_h265_investigation.md](./mobile_h265_investigation.md) |
| [ ] **TODO:** Custom `flutter_webrtc` fork + custom `libwebrtc` build | Unblocks reliable H.265 on devices that work in Chrome |

---

## Related docs

- [Mobile sync checklist](./mobile_sync_checklist.md) — broader PWA parity tracker
- [Mobile H.265 investigation](./mobile_h265_investigation.md) — capability gating + fork TODO
- [Client user flow contract](./client_user_flow_contract.md)
- [Client platform divergence](./client_platform_divergence.md)
- [Input mode controls](./input_mode_controls.md)
