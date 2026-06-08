# Input Mode Controls

This document defines three user-facing input settings shared across the PWA and mobile client: **Gaming Mode** (relative mouse), **Client Cursor** (overlay visibility), and **Native Touch** (touch-to-HID mapping). These controls determine how the user's input devices interact with the remote Windows desktop and how the cursor is rendered.

## 1. Gaming Mode (Relative Mouse)

### 1.1 What It Does

Switches mouse input from **absolute positioning** to **relative positioning**. In absolute mode, the cursor on the remote desktop jumps to wherever the user points on the screen. In relative mode, only the *delta* of each movement is sent — the cursor continues from its current position, exactly like a physical mouse on a desktop PC.

This is essential for FPS games, 3D applications, and any software that uses raw mouse input (e.g., first-person camera control), where the user needs continuous unbounded mouse movement without the cursor hitting screen edges.

### 1.2 HID Events

| Mode | Event sent | Description |
|------|-----------|-------------|
| Absolute (default) | `mma` (mouse move absolute) | Maps screen coordinates 1:1: `x/65535 × desktop_width`, `y/65535 × desktop_height` |
| Relative (gaming) | `mmr` (mouse move relative) | Sends delta: `(dX + 16384)`, `(dY + 16384)` |

### 1.3 Platform Behavior

#### PWA (Browser)

- Redux state: `state.remote.relative_mouse`
- When enabled, clicking the video element calls `videoEl.requestPointerLock()` — the browser's Pointer Lock API
- Pointer Lock: hides the OS cursor, captures all mouse events to the video element, provides raw `movementX/movementY` deltas
- Auto-activation: `state.remote.auto_relative_mouse` automatically enables relative mouse when the user enters fullscreen (useful for gaming — most users enter fullscreen to play)
- Exit: press Escape to release pointer lock; the setting remains toggled on for the next click-to-enter

#### Mobile (Flutter)

- `MouseHandler.relativeMouse` / `TouchHandler.relativeMouse` flags
- When enabled: `MouseHandler.onPointerMove()` sends `mmr` instead of `mma`
- **Input Lock** is the mobile equivalent of Pointer Lock: `PointerCapture.request()` (platform channel) captures all touch input to the remote surface, hides the system cursor and status bar, and shows an "Exit gaming mode" button
- No auto-activation — the user explicitly toggles gaming mode from the control panel

### 1.4 Settings UI Location

| Client | Where to toggle |
|--------|----------------|
| PWA | Sidepane toolbar → "Gaming mode" button; Advanced Settings → "Auto relative mouse" toggle |
| Mobile | Control panel → Settings → "Gaming mode" toggle |

### 1.5 Key Difference from PWA

The browser's Pointer Lock API is an OS-level feature: once active, the native cursor is completely hidden and the OS delivers raw deltas. Mobile cannot use Pointer Lock (it's a browser API), so it simulates the effect via a platform channel that captures touch events and hides the system UI. The HID behavior (sending `mmr` deltas) is identical.

---

## 2. Client Cursor

### 2.1 What It Does

Controls whether the **client-side rendered cursor overlay** is visible when the native/OS cursor is hidden.

When the OS cursor is visible (desktop browser, no pointer lock), the user can see where they're pointing. But when the OS cursor is hidden (pointer lock on PWA, or gaming mode on mobile), the user still needs to see the cursor position on the remote desktop. The server continuously sends cursor position (`cp`) and cursor image (`cu`) binary packets. The client renders these as an overlay on top of the video. `client_cursor` toggles whether that overlay is shown.

### 2.2 Cursor Rendering Architecture

There are two ways the cursor appears on screen:

| Method | How it works | When used |
|--------|-------------|-----------|
| **Native cursor** | OS/browser renders the cursor natively | Desktop browser without pointer lock |
| **Client cursor overlay** | Client renders a `<img>` (PWA) or `Positioned` widget (mobile) on top of the video, driven by `cu`/`cp` packets | When native cursor is hidden (pointer lock, mobile) |
| **Server-side cursor** | Server renders the cursor directly into the video frames (pixel-level) | Fallback when client overlay is disabled |

### 2.3 Avoiding Double Cursors

If both the client overlay cursor AND the server-rendered cursor are visible simultaneously, the user sees two cursors — one slightly ahead of the other due to network latency. The system prevents this with a coordination rule:

```
native_cursor_hidden = pointer_lock_active || is_mobile_device

if native_cursor_hidden AND client_cursor ON  → server cursor OFF, client overlay ON
if native_cursor_hidden AND client_cursor OFF → server cursor ON, client overlay OFF
if native cursor visible (desktop, no lock)   → server cursor OFF, client overlay OFF
```

The PWA implements this in `remote/page.tsx`:
```typescript
const native_cursor_hidden = pointer_lock || isMobile;
const server_cursor = native_cursor_hidden && !client_cursor;   // Message: Pointer(0)
const _client_cursor = native_cursor_hidden && client_cursor;   // overlay visibility
SetClientCursor(_client_cursor);
SetServerCursor(server_cursor);
```

Mobile mirrors this in the control panel settings sync.

### 2.4 Binary Protocol (See Protocol Contract §5)

| Packet | Code | Content |
|--------|------|---------|
| Cursor position (`cp`) | 23 | x (Uint16), y (Uint16), visible (Uint8), cursorId (Uint64), serverTime (Uint64) |
| Cursor update (`cu`) | 22 | x, y, hotspot, width, height, visible, cursorId, serverTime, PNG image bytes |

Both packets drive the cursor overlay. The `visible` field tells the client whether the server thinks the cursor should be showing (e.g., cursor is over a text field vs. hidden during video playback).

### 2.5 Display Decision

```typescript
// PWA: cursor.ts line 150
this.serverVisible && this.client_cursor ? 'block' : 'none'
```

```dart
// Mobile: cursor_handler.dart
bool get shouldDisplay => visible && clientCursor;
```

Both `serverVisible` (from `cp`/`cu` packets) AND `clientCursor` (user setting) must be true for the overlay to render.

### 2.6 Settings UI Location

| Client | Where to toggle |
|--------|----------------|
| PWA | Advanced Settings → "Client cursor" toggle |
| Mobile | Control panel → Settings → "Client cursor" toggle |

### 2.7 Default Value

`true` — the client cursor overlay is shown by default when the native cursor is hidden. This gives the best experience for most users. Power users who prefer the server-rendered cursor (lower latency, but slightly blurry since it's baked into the video frame) can disable it.

---

## 3. Native Touch

### 3.1 What It Does

Switches touch input between two fundamentally different HID mapping modes:

| Mode | Touch behavior | HID events | Use case |
|------|---------------|-----------|----------|
| **Trackpad mode** (`native = false`) | 1-finger tap = left/right click (left/right half), drag = relative mouse move × speed multiplier | `mmr`, `md`, `mu` | Desktop apps, mouse-driven UIs, general Windows use |
| **Native touch mode** (`native = true`) | Multi-touch maps 1:1 to the remote desktop's touch input | `td`, `tm`, `tu` | Touch-friendly apps, mobile games, drawing tablets, on-screen keyboards |

### 3.2 Trackpad Mode (Default)

When `native = false`, touch acts like a laptop trackpad:

- **1-finger tap** (left half of screen) → left click (`md` button 0, then `mu` button 0)
- **1-finger tap** (right half of screen) → right click (`md` button 2, then `mu` button 2)
- **1-finger drag** → relative mouse move (`mmr`) with speed multiplier (`MOUSE_SPEED = 3.5` on PWA, same on mobile)
- Tap detection threshold: movement < 10px from touch-down point counts as a tap, not a drag

This is the default because the remote Windows desktop is primarily mouse-driven. Trackpad mode gives mobile users a familiar laptop-like experience.

### 3.3 Native Touch Mode

When `native = true`, each finger maps directly to a touch point on the remote desktop:

- **Touch down** → `td` (touch down) with absolute coordinates mapped to video content rect
- **Touch move** → `tm` (touch move) with updated absolute coordinates
- **Touch up** → `tu` (touch up) with final absolute coordinates

Coordinate mapping:
```
serverX = (clientX - contentRect.left) / contentRect.width    → clamped to [0.001, 0.999]
serverY = (clientY - contentRect.top) / contentRect.height   → clamped to [0.001, 0.999]
```

Encoded as `round(value × 2^32) - 1` in the HID message (32-bit unsigned, see Protocol Contract §4.2).

### 3.4 Platform Behavior

#### PWA (Browser)

- Redux state: `state.remote.native_touch`
- Default: `false` on desktop, auto-set to `true` on mobile browsers (`!isMobile()` logic)
- Toggled from sidepane toolbar or settings

#### Mobile (Flutter)

- `TouchHandler.native` flag
- Default: `false` (trackpad mode)
- Auto-overridden to `true` when the virtual keyboard is shown (`setKeyboardNativeTouchOverride(true)`) — the user needs direct touch to tap text fields while the keyboard is open
- Reverts to the saved value when the keyboard is dismissed
- Uses `TouchIdPool` to map Flutter pointer IDs to stable touch IDs required by the `td/tm/tu` protocol (the server expects consistent IDs per finger across a touch gesture)

### 3.5 Settings UI Location

| Client | Where to toggle |
|--------|----------------|
| PWA | Sidepane toolbar → "Native touch" button; Advanced Settings |
| Mobile | Control panel → Settings → "Touch control" toggle |

---

## 4. Interaction Between the Three Settings

These three settings interact in specific ways:

### 4.1 Gaming Mode + Client Cursor

When gaming mode activates (pointer lock / input lock), the native cursor is hidden. The client cursor overlay becomes the user's only way to see the cursor. If the user disables client cursor while in gaming mode, the server-side cursor activates as a fallback — rendered into the video stream rather than as a client overlay.

### 4.2 Gaming Mode + Native Touch

These are independent toggles, but they're commonly used together:
- Gaming mode ON + native touch OFF → touch acts as a trackpad with relative mouse (common for non-touch PC games)
- Gaming mode ON + native touch ON → touch acts as direct touch (common for mobile games ported to PC)

### 4.3 Native Touch + Client Cursor

In native touch mode, the user's finger is the cursor — they tap directly where they want to interact. The client cursor overlay shows where the server's cursor has moved to in response, which provides feedback that the touch was received and processed. Most users leave client cursor ON in both modes.

### 4.4 Typical Presets

| Scenario | Gaming Mode | Client Cursor | Native Touch |
|----------|------------|---------------|-------------|
| Casual desktop use | OFF | ON | OFF (trackpad) |
| FPS / 3D gaming | ON | ON | OFF (trackpad) |
| Touch-friendly app | OFF | ON | ON |
| Mobile game on PC | ON | ON | ON |
| Power user (low latency) | ON | OFF | OFF |

---

## 5. Source File Mapping

### PWA (TypeScript)

| Component | File |
|-----------|------|
| Relative mouse toggle | `website/backend/reducers/remote.ts` (`toggle_relative_mouse`, `toggle_auto_relative_mouse`) |
| Pointer lock activation | `website/app/[locale]/remote/page.tsx` (`gopointerlock`, `exitpointerlock`) |
| Sidepane buttons | `website/backend/utils/sidepane.ts` (`gaming_mode`, `native_touch`) |
| Client cursor toggle | `website/backend/reducers/remote.ts` (`toggle_client_cursor`) |
| Cursor overlay rendering | `website/core/core/cursor.ts` (`SetClientCursor`, `client_cursor` field) |
| Native touch toggle | `website/backend/reducers/remote.ts` (`toggle_native_touch`) |
| Touch handler | `website/core/core/hid/touch.ts` (`native` flag, `handleStart/Move/End`) |
| Cursor/pointer coordination | `website/app/[locale]/remote/page.tsx` (lines 229–270) |

### Mobile (Dart)

| Component | File |
|-----------|------|
| Relative mouse (MouseHandler) | `mobile/lib/core/hid/mouse_handler.dart` (`relativeMouse` flag) |
| Relative mouse (TouchHandler) | `mobile/lib/core/hid/touch_handler.dart` (`relativeMouse` flag) |
| Input lock (Pointer Lock equiv.) | `mobile/lib/core/platform/pointer_capture.dart` |
| Client cursor toggle | `mobile/lib/core/cursor/cursor_handler.dart` (`CursorState.clientCursor`) |
| Native touch toggle | `mobile/lib/core/hid/touch_handler.dart` (`native` flag) |
| Keyboard native touch override | `mobile/lib/core/thinkmay_client.dart` (`setKeyboardNativeTouchOverride`) |
| Settings UI | `mobile/lib/presentation/screen/control_panel_virtual/widgets/setting_section.dart` |
| Remote settings state | `mobile/lib/domain/models/remote_settings/remote_settings.dart` |
