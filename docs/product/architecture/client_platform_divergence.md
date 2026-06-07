# Client Platform Divergence Registry

This document catalogs **intentional differences** between the three Thinkmay client implementations, along with known bugs and drift risks. It complements the [Client Protocol Contract](./client_protocol_contract.md) which defines the shared baseline.

## Client Maturity and Approach

| Client | Maturity | Transport | Rendering | Input | Adaptation |
|--------|----------|-----------|-----------|-------|------------|
| **Browser PWA** | **Production, battle-tested** | WebRTC (4 connections, WebSocket signaling) | Browser `<video>` / insertable streams | DOM events, `navigator.getGamepads()` | Server-side GCC only |
| **Mobile app** | **In development** | WebRTC (mirrors PWA) | `RTCVideoRenderer` (flutter_webrtc native surface) | Platform channels, touch gestures | Client-side adaptive policy (normal/degraded/panic) |
| **Desktop client** | **Production** | QUIC (4 independent streams, no WebRTC) | FFmpeg HW decode → D3D11/Metal/VAAPI/SDL | SDL events, native gamepad | Fixed FPS/bitrate via IVSHMEM controls |

**Rule**: PWA is the reference. Divergence from the PWA is acceptable only when driven by platform constraints (mobile hardware, native rendering), architectural differences (QUIC vs WebRTC), or deliberate product decisions. All divergence must be documented here.

---

## 1. Video Receiver Tuning

### 1.1 Playout Delay Hint

| Aspect         | PWA (Reference)                           | Mobile                                     | Desktop |
|----------------|--------------------------------------------|--------------------------------------------|---------|
| Mechanism      | `RTCRtpReceiver.playoutDelayHint` (native WebRTC API) | Platform channel `com.thinkmay/webrtc_tuning` → native Android/iOS code | N/A — receives whole encoded samples, not RTP |
| HQ mode        | `0.015` (15ms)                             | `0.015` (15ms) — same target                | N/A |
| Stability mode | `0.070` (70ms)                             | `0.070` (70ms) — same target                | N/A |
| Availability   | Available in Chrome/Edge/Firefox           | Requires custom native plugin; falls back silently if unavailable | N/A |

**Risk**: If the native plugin is not included in the build, mobile defaults to the system's jitter buffer (~100-200ms), adding significant baseline latency with no warning to the user.

### 1.2 Jitter Buffer Target

| Aspect         | PWA                          | Mobile                                         | Desktop |
|----------------|-------------------------------|------------------------------------------------|---------|
| Mechanism      | Not explicitly set (browser default) | `jitterBufferMinimumDelaySec` via same platform channel | N/A |
| VSync off      | —                             | `0.0` (0ms, lowest latency)                    | N/A |
| VSync on       | —                             | `0.033` (33ms, ~2 frames at 60fps)             | N/A |

This is **mobile-only** — the browser does not expose `jitterBufferMinimumDelay` in a usable way, so the PWA relies on `playoutDelayHint` alone.

### 1.3 Insertable Streams (Frame Watchdog)

| Aspect         | PWA                                        | Mobile                                      | Desktop |
|----------------|--------------------------------------------|---------------------------------------------|---------|
| Mechanism      | `RTCRtpReceiver.createEncodedStreams()` + TransformStream | **Not available** (flutter_webrtc doesn't expose this) | N/A — receives whole samples, uses decode stall timer |
| Purpose        | Per-frame timeout watchdog (300ms)         | Stats-based watchdog (250ms polling + 300ms timer) | Decode loop stall timer (15s after first frame, 20s before) |
| Latency        | Detects stall within ~300ms                | Detects stall within 250+300 = 550ms worst case | Detects stall within 15s (much higher tolerance) |

**Mitigation**: Mobile polls `getStats()` at 250ms intervals (4x faster than PWA's 1s) and arms a 300ms `Timer` when `framesDecoded` doesn't advance, achieving near-parity detection speed with the PWA.

### 1.4 Content Hint

PWA and mobile both set `track.contentHint = 'motion'` on the video track. On mobile this is done via the same platform channel. Desktop does not use WebRTC tracks.

---

## 2. Adaptive Streaming (Mobile-Only)

Neither the PWA nor the desktop client implement client-side adaptive framerate/bitrate:

- **PWA**: Relies entirely on server-side GCC (Google Congestion Control). The browser's WebRTC stack handles congestion feedback natively.
- **Desktop**: Sends fixed FPS/bitrate via IVSHMEM controls. The proxy-side forwarder handles bitrate adaptation internally.
- **Mobile**: Adds a client-side state machine because mobile hardware decoders are slower (10-35ms vs ~5ms on Chrome), mobile networks are more variable, and `flutter_webrtc` has no built-in congestion control adaptation.

### 2.1 Adaptive Modes

| Mode      | Framerate    | Bitrate     | IDR Backoff | Description                           |
|-----------|-------------|-------------|-------------|---------------------------------------|
| Normal    | target (≤60) | target      | 3s          | Healthy streaming                     |
| Degraded  | reduced     | reduced     | 3-5s        | Intermittent bad samples              |
| Panic     | ≤30 fps     | ≤4 Mbps     | 5-10s       | Sustained decode stall / zero frames  |

### 2.2 Panic Recovery

When entering panic mode, the mobile client:
1. Detaches the video renderer (`srcObject = null`) to let the native ImageReader drain
2. Calls `onVideoSurfaceReset` (UI recreates the native surface)
3. Re-attaches the video track
4. Suspends video reconnection for 20 seconds to allow recovery
5. Throttles cursor overlay repaints (32ms → 64ms)
6. Activates HID panic budget (drops coalesced moves more aggressively)

Neither PWA nor desktop have an equivalent — PWA simply requests IDR frames and waits; desktop uses a 15s stall timer before reconnecting.

### 2.3 Mobile Decoder Profiles

| Profile      | Framerate | Bitrate  | Who gets it                                    |
|-------------|-----------|----------|------------------------------------------------|
| Standard     | 60 fps    | 10 Mbps  | Hardware decoders (c2.qcom, c2.exynos, etc.)   |
| Conservative | 30 fps    | 4 Mbps   | Software/ffmpeg decoders, or after downgrade   |

Profiles are applied at bootstrap (all mobile) and refined after first `decoderImplementation` is discovered.

### 2.4 Threshold Differences

| Metric          | PWA / Desktop | Mobile  | Reason                                        |
|-----------------|--------------|---------|-----------------------------------------------|
| Heavy decode    | 24ms         | 35ms    | Mobile HW decoders naturally slower           |
| Heavy processing| 32ms         | 55ms    | OS scheduling variance on Android             |
| Heavy buffer    | 80ms         | 100ms   | Cellular/network jitter                       |
| Backlog IDR defer| 80ms        | 80ms    | Same — prevents keyframe bursts               |

---

## 3. HID Handling

### 3.1 DataChannel `maxRetransmits` / Transport

| Client | Transport | Reliability | Reason |
|--------|-----------|-------------|--------|
| PWA    | WebRTC DataChannel | `ordered: true, maxRetransmits: 3` | Standard reliability |
| Mobile | WebRTC DataChannel | `ordered: true, maxRetransmits: 1` | Fewer retransmits reduces head-of-line blocking for high-rate HID (touch at 60+ Hz) |
| Desktop | QUIC bidirectional stream | Reliable ordered (QUIC default) | Go QUIC stream provides reliable delivery |

### 3.2 HID Send Queuing

| Aspect          | PWA                                      | Mobile                                      | Desktop |
|-----------------|------------------------------------------|---------------------------------------------|---------|
| Queue mechanism | Array + async drain with 0ms/10ms yield | Frame-aligned coalescing via `SchedulerBinding.scheduleFrameCallback` | HID writer goroutine flushes at ~video FPS |
| Move coalescing | None (sends every event)                 | `HidCoalesce.partitionMessages` merges pending mouse/touch moves per-frame | `appendHIDPending` coalesces into batch buffer |
| Backpressure    | None                                     | `HidBackpressure` — drops coalesced batches when SCTP buffer exceeds threshold | QUIC flow control (built-in) |

Mobile's coalescing is a **superset** of PWA behavior. Desktop's batching is similar in effect but achieved through Go's channel/goroutine model rather than frame callbacks.

### 3.3 Keyboard Input

| Aspect          | PWA                                      | Mobile                                      | Desktop |
|-----------------|------------------------------------------|---------------------------------------------|---------|
| Key capture     | Browser `keydown`/`keyup` events          | `HardwareKeyboard.instance.addHandler` + raw key events | SDL `SDL_KEYDOWN`/`SDL_KEYUP` events |
| Scancode mode   | `convertJSKey()` maps JS `event.code` → Windows scancode | Direct physical scan codes from platform | SDL scancodes → Windows virtual keys (`keycode.go`) |
| Stuck key reset | `hid.ResetKeyStuck()` + `ResetAllKey()`   | `keyboard.resetStuckKeys()` + `mouse.releaseAllButtons()` | Focus loss releases stuck keys/buttons |

### 3.4 Gamepad

| Aspect          | PWA                                      | Mobile                                      | Desktop |
|-----------------|------------------------------------------|---------------------------------------------|---------|
| Physical gamepad| `navigator.getGamepads()` polling          | `MethodChannelGamepadPhysicalSource` (platform channel) | SDL gamecontroller subsystem |
| Rumble feedback | `gamepad.vibrationActuator.playEffect('dual-rumble')` or `navigator.vibrate()` | `HapticFeedback.heavyImpact()` (single-actuator, no dual-motor) | SDL haptic rumble (full dual-motor when supported) |
| Poll rate       | 10ms (active gamepad) / 1000ms (no gamepad) | Driven by platform channel events           | Gamepad poll goroutine at ~video FPS |

### 3.5 Mouse Wheel DeltaX Bug (Mobile)

**Mobile has a bug** in the `mw` (mouse wheel) encoding:

```dart
// BUG: operator precedence — evaluates as (0 + 2048) when deltaX is null
(data['deltaX'] as num?)?.toInt() ?? 0 + 2048
```

Correct (matching PWA):
```typescript
this.data.deltaX + 2048  // always adds 2048
```

When `deltaX` is null/0 on mobile, this sends `2048` instead of the correct `2048`. When `deltaX` is non-null, the null-aware path works correctly. **This needs a fix**: wrap as `((data['deltaX'] as num?)?.toInt() ?? 0) + 2048`.

PWA and desktop do not have this bug.

---

## 4. Cursor Rendering

| Aspect          | PWA                                      | Mobile                                      | Desktop |
|-----------------|------------------------------------------|---------------------------------------------|---------|
| Rendering       | `<img>` element with CSS `transform: translate3d()` | Flutter `Positioned` widget overlay            | Composited onto video frame by presenter; SDL cursor in windowed mode |
| Native cursor   | CSS `cursor: url()` on video element      | Not applicable — overlay-only                | SDL system cursor or composited overlay |
| Image decode    | `btoa()` base64 → `data:image/png;base64` URL | `ui.instantiateImageCodec()` → `ui.Image`    | Decode PNG to SDL surface or D3D11 texture |
| Animation loop  | `requestAnimationFrame`                   | Flutter `Ticker` (vsync-aligned)              | Polled at display refresh rate (no interpolation needed) |
| Panic throttle  | None                                      | 64ms repaint cap (vs 32ms normal)           | N/A |
| Layout cache    | `ResizeObserver` on `<video>` element      | Manual `updateLayout()` from widget build    | Windowed: SDL client cursor; Fullscreen: composited into present path |

The interpolation algorithm (32ms glide, EMA clock smoothing, out-of-order rejection) is implemented by **PWA and mobile only**. Desktop composites cursor position directly onto the video frame at display refresh rate, which eliminates the need for interpolation.

---

## 5. Metrics Collection

### 5.1 Stats Polling Interval

| Client | Interval | Reason                                      |
|--------|----------|---------------------------------------------|
| PWA    | 1000ms   | `setInterval` on `getStats()`               |
| Mobile | 250ms    | Faster polling to compensate for lack of insertable streams watchdog |
| Desktop | N/A     | No RTCStatsReport — uses `perf.Tracker` with decode/present counters |

Mobile still runs full metric calculations at ~1Hz (gated on `timeDelta >= 0.9s`), but the fast-path checks `framesDecoded` every 250ms for the missing-frame watchdog.

### 5.2 Additional Mobile Metrics

These are **mobile-only** and not present in the PWA or desktop:

- `HidMetric`: DataChannel send diagnostics (batches, drops, backpressure, coalesced count)
- `AdaptiveMetric`: Adaptive streaming state machine (mode, effective/target framerate/bitrate, IDR backoff)
- `StreamHealthMetric.lastEvent`: Simplified string (PWA uses richer `StreamHealthState` union type)

### 5.3 PWA-Only Metrics

- `StreamHealthState` richer type union: `'healthy' | 'recovering_video' | 'video_stalled' | 'encoder_stalled' | 'backend_reconnecting' | 'control_blocked'`
- `StreamHealth.details`: Optional details string
- `StreamHealth.updated_at`: Numeric timestamp
- `StreamHealth.last_event`: Full event string (mobile simplifies to `lastEvent`)

### 5.4 Desktop Metrics

The desktop client does not use RTCStatsReport. Its metrics come from:
- FFmpeg decode counters (decode FPS, error count, HW decoder name)
- Presentation counters (present FPS, zero-copy vs CPU upload)
- QUIC stream byte counters (bandwidth estimation)
- Optional HTTP stats dashboard at `127.0.0.1:8765`

---

## 6. Microphone Connection

| Aspect          | PWA                                      | Mobile                                      | Desktop |
|-----------------|------------------------------------------|---------------------------------------------|---------|
| Mic capture     | `getUserMedia({audio: {sampleRate: {ideal: 48000}, channelCount: {ideal: 2}}})` | `getUserMedia({audio: true, video: false})` — no sample rate/channel constraints | SDL capture → FFmpeg Opus encoder |
| Codec setup     | Finds `audio/opus` in sender capabilities, sets on transceiver | Same approach via `getRtpSenderCapabilities('audio')` | FFmpeg Opus encoder at 48kHz stereo |
| ptime injection | Adds `a=ptime:60` after each `m=audio` line in the offer SDP | **Not done** (flutter_webrtc may not support raw SDP mutation) | N/A — no SDP |
| Signaling timeout | 3s                                      | 30s                                         | 5s per QUIC dial attempt |
| Retry on fail   | Up to 3 track failures                    | Same — `_micTrackFailCount >= 3`            | Per-channel reconnect with exponential backoff |
| Mic sample header | N/A                                     | N/A                                         | 32-byte header (session UUID, timestamp, RTP ts, seq) |

---

## 7. Connection State Handling and Reconnection

| Aspect          | PWA                                      | Mobile                                      | Desktop |
|-----------------|------------------------------------------|---------------------------------------------|---------|
| `disconnected` state | Closes connection immediately       | **Ignored** — may recover; only `failed`/`closed` trigger close | N/A (QUIC has no equivalent transient state) |
| Video reconnect delay | 1s fixed                              | 2-10s variable (depends on adaptive mode and panic state) | 400ms debounce + exponential backoff (1s → 30s) |
| Video reconnect strategy | Close then reconnect                 | Close then reconnect                        | **Make-before-break** (dial new before closing old) |
| Video surface recovery | Not needed (browser handles this)    | Full detach/reset/reattach cycle for native renderer | Pipeline reset: `PrepareForNewVideoStream`, drain + `ResetStreamState` |
| Per-channel reconnect | Each connection independent           | Each connection independent                  | Each QUIC channel independent with own `clientSlot` |
| Auth failure | Terminal, no retry                        | Terminal, no retry                           | Terminal, no retry |
| Window during reconnect | PWA shows loading overlay              | Mobile shows loading overlay                 | Window stays visible with reconnecting title |

Mobile's decision to ignore `disconnected` state is intentional — on Android, brief disconnects are common during network handoff (WiFi ↔ cellular) and the WebRTC stack often recovers without intervention.

Desktop's make-before-break approach is unique: it dials a new video QUIC connection before closing the old one, swaps atomically, then closes the old stream asynchronously. This minimizes the gap visible to the user.

---

## 8. Desktop-Specific Divergence (QUIC Architecture)

The desktop client is architecturally separate from the WebRTC clients. It does not use WebSocket signaling, SDP, ICE, TURN/STUN, or RTP. Key differences:

### 8.1 Transport

| Aspect | PWA / Mobile (WebRTC) | Desktop (QUIC) |
|--------|----------------------|----------------|
| Connection setup | WebSocket signaling → SDP offer/answer → ICE | QUIC dial → JSON `FinalTarget{VmID, ListenerID}` on auth stream |
| Media delivery | RTP packets over WebRTC | Whole encoded samples (4-byte BE length prefix + payload) |
| Flow control | GCC / NACK / RTX / FlexFEC | QUIC congestion control (built-in) |
| FEC | FlexFEC-03 (optional) | None — QUIC retransmission handles loss |
| Head-of-line blocking | Per-connection (separate WebRTC PCs) | Per-stream (separate QUIC connections) |
| TLS | DTLS (via WebRTC) | QUIC TLS with `InsecureSkipVerify` (internal network) |
| Auth | Listener UUID in WebSocket URL `?token=` param | Listener UUID in JSON `FinalTarget` on QUIC auth stream |

### 8.2 Video Decode and Present

| Aspect | PWA / Mobile | Desktop |
|--------|-------------|---------|
| Decode | Browser/OS hardware decoder (opaque) | FFmpeg/astiav with explicit HW device selection (CUDA, D3D11VA, VideoToolbox, VAAPI, etc.) |
| Presentation | `<video>` element / `RTCVideoRenderer` | D3D11 / Metal / VAAPI-EGL / SDL (zero-copy when possible) |
| Fallback | Browser falls back to software decode automatically | Runtime decoder fallback: after 8 consecutive errors, swaps to next compatible HW device |
| Frame pacing | Browser vsync / `playoutDelayHint` | `-vsync` flag + optional Moonlight-style dual-queue pacer (`-frame-pacing`) |
| Codec support | H.264, H.265 (device-dependent) | H.264, H.265/HEVC, AV1 (via FFmpeg) |
| Sample format | RTP packets → jitter buffer → decode | 17-byte LE envelope + codec payload → FFmpeg decode |

### 8.3 Congestion Control

| Aspect | PWA / Mobile | Desktop |
|--------|-------------|---------|
| Mechanism | Server-side GCC via WebRTC RTCP feedback | Client sends fixed FPS/bitrate via IVSHMEM controls; proxy-side forwarder handles adaptation |
| Client visibility | Full metrics (bitrate, packet loss, jitter, GCC state) | Limited — proxy handles adaptation; client sees decode/present FPS |

### 8.4 Startup Flow

| Aspect | PWA / Mobile | Desktop |
|--------|-------------|---------|
| Session provisioning | Same backend flow (PocketBase `/new`, SSE) | Same backend flow — website builds `thinkmay:` URL with listener tokens |
| Launch trigger | Browser navigates to `/remote` | OS opens `thinkmay:` custom URL → Go client parses config |
| Connection order | 4 parallel WebSocket connects | 4 parallel QUIC dials |
| Progress UI | In-page loading overlay | Local HTTP connect UI page at `127.0.0.1:8766` |
| First frame | Loading overlay → video appears | Hidden window → show window on first present |
| Window | Browser tab or PWA window | Native resizable/fullscreen SDL window |

### 8.5 Desktop-Only Features

These features exist only in the desktop client:

| Feature | Description |
|---------|-------------|
| USB forwarding | `-usb` flag forwards local USB devices over the data QUIC stream |
| Auto-update | Windows: checks PocketBase binaries collection for new versions |
| Connect UI | Local HTTP page showing dial/decode/present progress with abort button |
| Bootlog | Structured startup step logging for packaged builds |
| Decoder fallback | Automatic HW decoder swap on 8 consecutive decode errors |
| Frame pacing | Moonlight-style dual-queue pacer for smoother cadence |
| AV1 codec | Supported via FFmpeg (not available in browser WebRTC) |

---

## 9. Feature Parity Checklist

| Feature                   | PWA | Mobile | Desktop | Notes |
|---------------------------|-----|--------|---------|-------|
| Video streaming (H.264)   | ✅  | ✅     | ✅      | |
| Video streaming (H.265)   | ✅  | ⚠️     | ✅      | Mobile: device-dependent HW support |
| Video streaming (AV1)     | ❌  | ❌     | ✅      | Desktop only via FFmpeg |
| Audio streaming (Opus)    | ✅  | ✅     | ✅      | |
| Keyboard HID (scancode)   | ✅  | ✅     | ✅      | |
| Mouse HID                 | ✅  | ✅     | ✅      | |
| Touch HID                 | ✅  | ✅     | ❌      | Desktop has no touch input |
| Virtual gamepad           | ✅  | ✅     | ❌      | Desktop uses physical gamepad only |
| Physical gamepad          | ✅  | ⚠️     | ✅      | Mobile requires platform channel |
| Gamepad rumble (dual)     | ✅  | ❌     | ✅      | Mobile: single-actuator haptic only |
| Clipboard sync            | ✅  | ✅     | ✅      | |
| Microphone pass-through   | ✅  | ✅     | ✅      | |
| Server-side cursor        | ✅  | ✅     | ✅      | |
| Client-side cursor overlay| ✅  | ✅     | ✅      | Desktop: composited into video frame |
| Cursor interpolation      | ✅  | ✅     | ❌      | Desktop renders at display Hz — no interpolation needed |
| Insertable streams        | ✅  | ❌     | N/A     | Not available in flutter_webrtc |
| Playout delay hint        | ✅  | ⚠️     | N/A     | Mobile requires custom native plugin |
| Jitter buffer tuning      | ❌  | ✅     | N/A     | Mobile-only via platform channel |
| Client-side adaptive      | ❌  | ✅     | ❌      | Mobile-only (adaptive video policy) |
| Video panic recovery      | ❌  | ✅     | ❌      | Mobile-only (surface detach/reattach) |
| VSync mode                | ✅  | ✅     | ✅      | Different mechanisms, same intent |
| Stream health monitoring  | ✅  | ✅     | ⚠️      | Desktop receives status datagrams but does not surface in UI |
| Resolution change         | ✅  | ✅     | ✅      | Mobile auto-applies 720p on constrained devices |
| USB forwarding            | ❌  | ❌     | ✅      | Desktop-only |
| Snapshot                  | ✅  | ❌     | ❌      | Canvas-based, not applicable elsewhere |
| VM log stream             | ✅  | ❌     | ❌      | Not yet implemented on mobile/desktop |
| Inactivity timer          | ❌  | ✅     | ❌      | Mobile closes session after 8min idle |
| Auto-update               | ❌  | ❌     | ✅      | Windows-only |
| Connect UI                | ❌  | ❌     | ✅      | Local HTTP progress page |

---

## 10. Known Bugs and Drift Risks

### 10.1 Active Bugs

| ID   | Client    | Component     | Description                                                         | Status   |
|------|-----------|---------------|---------------------------------------------------------------------|----------|
| D-1  | Mobile    | HID           | `mouseWheel` deltaX operator precedence: `?? 0 + 2048` → should be `(?? 0) + 2048` | Open     |
| D-2  | Mobile    | Metrics       | `StreamHealthMetric.state` is a free-form string vs PWA's union type — no compile-time exhaustiveness check | By design |

### 10.2 Drift Risks

| Risk                          | Affected Clients | Mitigation                                                          |
|-------------------------------|------------------|----------------------------------------------------------------------|
| EventCode enum gets new entries | All three      | Update [Protocol Contract Section 4.1](./client_protocol_contract.md#41-eventcode-enum) and all code files simultaneously |
| MessageType values change      | PWA, Mobile    | Update Section 3 — desktop uses IVSHMEM controls, not MessageType |
| Cursor binary layout changes   | All three      | Update Section 5 — this is the most fragile protocol element         |
| Metrics fields diverge         | PWA, Mobile    | Update Section 6 — ensure shared fields stay identical               |
| `maxRetransmits` change        | PWA, Mobile    | Document here if intentional; otherwise sync to same value           |
| Adaptive policy adds states    | Mobile         | Update Section 2 and the Metrics contract                            |
| QUIC wire protocol changes     | Desktop        | Update [Desktop client architecture](../../../desktop_client_architecture.md) |
| Stream health status types change | All three   | Update Section 6 — ensure all clients handle new status types        |

---

## 11. Version History

| Date       | Change                                                       |
|------------|--------------------------------------------------------------|
| 2026-06-07 | Initial registry created from codebase audit                 |
| 2026-06-07 | Added desktop/QUIC client divergence, framed PWA as reference, marked mobile as in-development |
