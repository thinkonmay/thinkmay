# Advanced Settings Parity Checklist

PWA reference: `website/app/[locale]/(app)/setting/(other)/advance/page.tsx`  
Mobile: `mobile/lib/presentation/screen/advanced_settings/advanced_settings_screen.dart`

## Streaming quality section

| Control | PWA | Mobile | Status |
|---------|-----|--------|--------|
| High quality preset | Radio | Radio (`setHqPreset`) | [x] |
| High stability preset | Radio | Radio (`setHqPreset`) | [x] |
| Fixed bitrate slider (GCC off) | Sets min + max together | `setFixedBitrate` | [x] |
| Dual min/max range (GCC on) | Log-scale dual thumb | Log-scale `RangeSlider` | [x] |
| Max FPS slider (40–240 steps) | 6 discrete steps + 144+ warning | `_FpsSlider` | [x] |
| Disable adaptive bitrate | Toggle | Toggle (`setDisableGcc`) | [x] |
| Use H.265 | Toggle | Toggle | [x] |
| Enable microphone | Toggle | Toggle | [x] Runtime wired 2026-06-09 |
| VSync & frame queuing | Toggle (streaming section) | Toggle in streaming section (`kMobileVideoVsyncEnabled`) | [x] |

## Compatibility section

| Control | PWA | Mobile | Status |
|---------|-----|--------|--------|
| Keyboard compatibility (scancode) | Toggle | Toggle | [x] |
| Keyboard lock | Toggle | Toggle (`keyboardLock` in `RemoteSettings`) | [~] UI only — no native Keyboard API |
| Touch while gamepad | Toggle | Toggle | [x] |
| Client cursor | Toggle | Toggle | [~] Gaming mode only; touch uses native PNG path |
| Stretch video (fill) | Toggle | Toggle | [x] |
| Auto relative mouse | Toggle | Toggle | [~] UI only — blocked L-3 log WS |
| Always force 1080p | Toggle (compatibility) | Toggle (compatibility) | [x] Runtime wired 2026-06-09 |

## Footer / navigation

| Behavior | PWA | Mobile | Status |
|----------|-----|--------|--------|
| Save → persist + toast | `cache_setting()` + toast | `applyCurrentToClient()` + snackbar | [x] |
| Save from remote → return to remote | `?remote=true` → `/remote` | `?remote=true` → `/remote-screen` | [x] |
| Reset → defaults + toast | `reset_setting()` + toast | `reset()` + snackbar | [x] |
| Back from remote | `backHref: /remote` | App bar back → remote screen | [x] |

## Intentional mobile omissions

| Control | Reason |
|---------|--------|
| Desktop app / custom URL launch | Desktop-only (`desktop_custom_url_launch`) |
| QUIC / High MTU network section | Not present on PWA advance page (was erroneous mobile-only section) |

## UI polish (L-8, 2026-06-09)

| Item | Status |
|------|--------|
| Safe-area scroll body | [x] |
| Slider min/max badge overflow (narrow screens) | [x] `Wrap` layout |
| Toggle label/switch layout (PWA: label left, switch right) | [x] |
| Title/description contrast (`#FFFFFF` / `#A3A3A3`) | [x] |
| Slider inactive track + switch off-state dark-theme contrast | [x] |
| `TmSwitch` syncs external value after Reset | [x] `didUpdateWidget` |
| Sticky footer top border | [x] |

## Runtime notes

- **Enable microphone**: Wired (2026-06-09) — `RemoteCubit` passes `creds.microUrl` when `enableMicrophone`; toggle triggers reconnect (`_needsReconnect`).
- **Always 1080p**: Wired (2026-06-09) — `ThinkmayClient.changeResolution` + `applyAlways1080pIfNeeded` on connect and video resize (PWA `ChangeResolution(1920, 1080)`).
- **Keyboard lock**: PWA uses `navigator.keyboard.lock()`. Mobile persists the setting; no browser Keyboard API equivalent on native yet.
- **Auto relative mouse**: Persisted in `RemoteSettings`; blocked until VM log WebSocket ships (L-3).
- **Client cursor**: Toggle honored in gaming mode (`relativeMouse`). Normal touch mode always uses `nativeCursorReplacement` (finger PNG) — differs from PWA where `isMobile` applies `client_cursor` without pointer lock. Not blocked; needs product decision to align.
- **VSync**: Gated by `kMobileVideoVsyncEnabled` in `receiver_tuning.dart`.
