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
| Enable microphone | Toggle | Toggle | [x] |
| VSync & frame queuing | Toggle (streaming section) | Toggle in streaming section (`kMobileVideoVsyncEnabled`) | [x] |

## Compatibility section

| Control | PWA | Mobile | Status |
|---------|-----|--------|--------|
| Keyboard compatibility (scancode) | Toggle | Toggle | [x] |
| Keyboard lock | Toggle | Toggle (`keyboardLock` in `RemoteSettings`) | [x] |
| Touch while gamepad | Toggle | Toggle | [x] |
| Client cursor | Toggle | Toggle | [x] |
| Stretch video (fill) | Toggle | Toggle | [x] |
| Auto relative mouse | Toggle | Toggle | [x] |
| Always force 1080p | Toggle (compatibility) | Toggle (compatibility) | [x] |

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

## Runtime notes

- **Keyboard lock**: PWA uses `navigator.keyboard.lock()`. Mobile persists the setting; no browser Keyboard API equivalent on native yet.
- **Auto relative mouse**: Persisted in `RemoteSettings`; game-detection hook mirrors PWA state storage pattern.
- **VSync**: Gated by `kMobileVideoVsyncEnabled` in `receiver_tuning.dart`.
