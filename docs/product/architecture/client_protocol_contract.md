# Client Protocol Contract

This document defines the **canonical binary and signaling protocols** that govern communication between Thinkmay clients and the proxy server. It serves as the single source of truth for protocol elements shared across clients.

## Client Hierarchy

Thinkmay has **three client implementations** with different maturity levels and transport approaches:

| Client | Codebase | Transport | Maturity | Role |
|--------|----------|-----------|----------|------|
| **Browser PWA** | `website/core/core` | WebRTC (4 connections over WebSocket signaling) | **Production, battle-tested** | **Reference implementation** — protocol changes land here first |
| **Mobile app** | `mobile/lib/core` | WebRTC (mirrors browser PWA protocol) | **In development** | Must stay in sync with PWA; see [Client Platform Divergence](./client_platform_divergence.md) |
| **Desktop client** | `worker/proxy/client` | QUIC (4 independent streams, no WebRTC) | **Production** | Separate transport; shares HID binary protocol and backend session flow only |

**Rule**: The browser PWA is the reference. When a protocol element changes, it must be implemented in the PWA first, then propagated to the mobile app. The desktop client is architecturally separate (QUIC, not WebRTC) and is documented in [Desktop client architecture](../../../desktop_client_architecture.md) and [Desktop connection initialization](./desktop_connection_initialization.md).

### What This Document Covers

| Protocol Layer | PWA | Mobile | Desktop |
|---------------|-----|--------|---------|
| Backend session provisioning (PocketBase `/new`, SSE, `/info`) | ✅ | ✅ | ✅ (via website handoff) |
| WebRTC signaling (WebSocket → SDP/ICE) | ✅ | ✅ | ❌ (uses QUIC) |
| HID binary protocol (EventCode, HIDMsg encoding) | ✅ | ✅ | ✅ (same encoding, over QUIC data stream) |
| Cursor binary protocol (cu/cp wire format) | ✅ | ✅ | ✅ (same wire format, over QUIC data stream) |
| Binary control messages (MessageType: FPS/bitrate/IDR/pointer) | ✅ | ✅ | ❌ (uses IVSHMEM control messages over QUIC uni stream) |
| Stream health status events | ✅ | ✅ | ✅ (same JSON status envelopes over QUIC datagrams) |
| Metrics contract (RTCStatsReport fields) | ✅ | ✅ | ❌ (uses FFmpeg/proxy-side metrics) |
| Codec preference negotiation (setCodecPreferences) | ✅ | ✅ | ❌ (codec set via CLI flag, no SDP negotiation) |

Sections 1–3 below apply to **PWA and mobile only** (WebRTC transport). Sections 4–5 (HID and cursor binary protocols) apply to **all three clients**. The desktop client's QUIC-specific protocol is not duplicated here; see the desktop docs linked above.

---

## 1. WebRTC Connection Topology

Every WebRTC streaming session (PWA and mobile) establishes **4 independent WebRTC connections**, each with its own WebSocket signaling channel:

| # | Name        | Direction  | URL pattern                                                                  | Purpose              | Offerer  |
|---|-------------|-----------|------------------------------------------------------------------------------|----------------------|----------|
| 1 | Video       | recv-only  | `wss://{host}:444/broadcasters/webrtc/recvonly?token={id}&codec=h264&...`   | Video stream         | Server   |
| 2 | Audio       | recv-only  | `wss://{host}:444/broadcasters/webrtc/recvonly?token={id}&codec=opus&...`   | Audio stream         | Server   |
| 3 | HID (Data)  | send-only  | `wss://{host}:444/broadcasters/webrtc/sendonly?token={id}&...`              | HID DataChannel      | Client   |
| 4 | Microphone  | send-only  | `wss://{host}:444/broadcasters/webrtc/sendonly?token={id}&...`              | Mic audio stream     | Client   |

**Offer direction**: For recv-only connections (video, audio), the **server** sends the SDP offer and the client answers. For send-only connections (HID, microphone), the **client** sends the SDP offer and the server answers.

### URL Query Parameters

| Param         | Values        | Purpose                          |
|---------------|---------------|----------------------------------|
| `token`       | UUID          | Session auth token (5s TTL)      |
| `vmid`        | UUID          | Target VM identifier             |
| `mtu`         | `1200`        | RTP packet MTU                   |
| `fec`         | `true/false`  | FlexFEC-03 enable                |
| `gcc`         | `true/false`  | Google Congestion Control enable |
| `codec`       | `h264/h265`   | Preferred video codec            |
| `max_bitrate` | number (bps)  | GCC upper bound                  |
| `min_bitrate` | number (bps)  | GCC lower bound                  |
| `bitrate`     | number (bps)  | Fixed bitrate (when gcc=false)   |

---

## 2. WebSocket Signaling Protocol

All 4 WebRTC connections share the same WebSocket-based signaling flow. Messages are JSON-encoded unless otherwise noted.

### 2.1 Signaling Sequence (recv-only: video, audio)

```
Client                                    Server
  |── WS connect ──────────────────────────▶|
  |◀── { event: "open", data: {username, password} } ──|  (TURN credentials)
  |── create RTCPeerConnection ──|
  |◀── { event: "sdp", data: {type:"offer", sdp:"..."} } ──|
  |── setRemoteDescription(offer) ──|
  |── setCodecPreferences(preferred) ──|
  |── createAnswer() ──|
  |── { event: "sdp", data: {type:"answer", sdp:"..."} } ──▶|
  |◀── { event: "ice", data: {...} } ──| (trickle)
  |── { event: "ice", data: {...} } ──▶| (trickle)
  |          ... ICE exchange ...           |
  |── ontrack → video/audio stream ──|
```

### 2.2 Signaling Sequence (send-only: HID, microphone)

```
Client                                    Server
  |── WS connect ──────────────────────────▶|
  |◀── { event: "open", data: {username, password} } ──|
  |── create RTCPeerConnection ──|
  |── createDataChannel("data", {ordered, maxRetransmits}) or addTrack(mic) ──|
  |── createOffer() ──|
  |── { event: "sdp", data: {type:"offer", sdp:"..."} } ──▶|
  |◀── { event: "sdp", data: {type:"answer", sdp:"..."} } ──|
  |── setRemoteDescription(answer) ──|
  |◀── { event: "ice", data: {...} } ──|
  |── { event: "ice", data: {...} } ──▶|
  |          ... ICE exchange ...           |
```

### 2.3 Message Formats

**Open event** (server → client):
```json
{ "event": "open", "data": { "username": "string", "password": "string" } }
```

**SDP exchange**:
```json
{ "event": "sdp", "data": { "type": "offer|answer", "sdp": "string" } }
```

**ICE candidate trickle**:
```json
{ "event": "ice", "data": { "candidate": "string", "sdpMid": "string|null", "sdpMLineIndex": "number|null" } }
```

**Backend status** (server → client, DataChannel only):
```json
{ "event": "status", "data": { "type": "string", ... } }
```

**Close** (server → client):
```json
{ "event": "close" }
```

**Auth failure**:
```json
{ "type": "application error", "code": number, "message": "string" }
```

### 2.4 ICE Server Configuration

Derived from the `open` event:
```json
{
  "iceServers": [
    { "urls": ["turn:{host}:3478"], "credential": password, "username": username },
    { "urls": ["stun:{host}:3478"] }
  ]
}
```

Additional PeerConnection config:
- `bundlePolicy`: `"max-bundle"` (video/audio only)
- `iceTransportPolicy`: `"all"`
- SDP normalization: strip `a=ice-renomination` lines from all SDP strings

---

## 3. Binary Control Messages (WebSocket → video/audio conn)

Binary `Uint8Array` messages sent **via the WebSocket** to the video connection to control encoder behavior. **PWA and mobile only** — the desktop client sends equivalent IVSHMEM control messages over a QUIC uni stream instead.

### MessageType Enum

| Value | Name            | Parameters                   | Description                        | Desktop Equivalent |
|-------|-----------------|------------------------------|------------------------------------|--------------------|
| 0     | Pointer         | `enable: 0\|1`              | Toggle server-side cursor render   | `ivshmem.PointerMode` via QUIC control |
| 1     | Bitrate         | `kbps: value/1000`           | Request bitrate change (kbps)      | `ivshmem.Bitrate` via QUIC control |
| 2     | Framerate       | `fps: value/2`               | Request framerate change           | `ivshmem.FPS` via QUIC control |
| 3     | Idr             | `1`                          | Request IDR keyframe               | `ivshmem.IDR` via QUIC control |
| 4     | Hdr             | —                            | HDR toggle (reserved)              | — |
| 5     | Stop            | —                            | Stop stream                        | — |
| 6     | BufferOverflow  | —                            | Buffer overflow signal             | — |
| 7     | Resolution      | `width/20, height/20`        | Request resolution change          | `ivshmem.Resolution` via QUIC control |
| 8     | EventMax        | —                            | Sentinel                           | — |

**Wire format**: `[MessageType, ...params]` as `Uint8Array`.

**Scaling rules** (PWA/mobile):
- Bitrate: server expects `value / 1000` (bps → kbps)
- Framerate: server expects `value / 2` (client sends half the desired fps)
- Resolution: server expects `width / 20` and `height / 20`

**Desktop note**: The desktop client sends IVSHMEM control structs directly over the QUIC control uni stream. The proxy translates these into the same IVSHMEM writes that the WebRTC `MessageType` binary messages trigger. The semantic effect is identical; the wire format and transport differ.

---

## 4. HID Binary Protocol

All HID events use the same binary encoding across **all three clients**. The transport differs (WebRTC DataChannel for PWA/mobile, QUIC data stream for desktop), but the wire format is identical.

### 4.1 EventCode Enum

| Value | Name               | Direction   | Description                         |
|-------|--------------------|-------------|-------------------------------------|
| 0     | ping               | bidir       | Heartbeat                           |
| 1     | mma                | client→srv  | Mouse move absolute                 |
| 2     | mmr                | client→srv  | Mouse move relative                 |
| 3     | mw                 | client→srv  | Mouse wheel                         |
| 4     | mu                 | client→srv  | Mouse button up                     |
| 5     | md                 | client→srv  | Mouse button down                   |
| 6     | ku                 | client→srv  | Key up (JS keycode)                 |
| 7     | kd                 | client→srv  | Key down (JS keycode)               |
| 8     | kus                | client→srv  | Key up (hardware scancode)          |
| 9     | kds                | client→srv  | Key down (hardware scancode)        |
| 10    | kr                 | client→srv  | Key reset (release all)             |
| 11    | gconn              | client→srv  | Gamepad connect                     |
| 12    | gdis               | client→srv  | Gamepad disconnect                  |
| 13    | gs                 | client→srv  | Gamepad slider/trigger (analog)     |
| 14    | ga                 | client→srv  | Gamepad axis (analog)               |
| 15    | gb                 | client→srv  | Gamepad button (digital)            |
| 16    | grum               | server→cli  | Gamepad rumble                      |
| 17    | cs                 | client→srv  | Clipboard set                       |
| 18    | noti               | server→cli  | Notification text                   |
| 19    | td                 | client→srv  | Touch down                          |
| 20    | tm                 | client→srv  | Touch move                          |
| 21    | tu                 | client→srv  | Touch up                            |
| 22    | cu                 | server→cli  | Cursor update (PNG + metadata)      |
| 23    | cp                 | server→cli  | Cursor position only                |

### 4.2 HID Message Format

**Standard HID messages**: Each message is 4 × Uint32 = 16 bytes (little-endian).

```
[EventCode, param1, param2, param3]
```

### 4.3 Encoding Rules per EventCode

| EventCode       | param1                              | param2                              | param3  |
|-----------------|-------------------------------------|-------------------------------------|---------|
| ku, kd          | `keycode`                           | 0                                   | 0       |
| kus, kds        | `keycode` (scancode)                | 0                                   | 0       |
| kr              | 0                                   | 0                                   | 0       |
| mu, md          | `button`                            | 0                                   | 0       |
| mmr             | `dX + 16384`                        | `dY + 16384`                        | 0       |
| mma             | `round(x * 2^32) - 1`              | `round(y * 2^32) - 1`              | 0       |
| mw              | `deltaY + 2048`                     | `deltaX + 2048`                     | 0       |
| td, tm, tu      | `touchId`                           | `round(x * 2^32) - 1`              | `round(y * 2^32) - 1` |
| gconn, gdis     | `gamepadId`                         | 0                                   | 0       |
| gb              | `gamepadId`                         | `buttonIndex`                       | `pressed ? 1 : 0` |
| ga, gs          | `gamepadId`                         | `axisIndex`                         | `round((clamped+1) * 2^31) - 1` |
| grum (incoming) | `gamepadId`                         | `weak (0-255)`                      | `strong (0-255)` |
| ping            | —                                   | —                                   | —       |

**Clamping rule for ga/gs**: `val` is clamped to `[-0.999, 0.999]` before encoding. If `val >= 1`, use `0.999`. If `val <= -1`, use `-0.999`.

**Clipboard (cs)** — Special format (not Uint32Array):
```
Uint8Array: [EventCode.cs, 0, 0, 0, ...UTF-8 bytes of text]
```

### 4.4 Transport Comparison

| Aspect | PWA / Mobile (WebRTC) | Desktop (QUIC) |
|--------|----------------------|----------------|
| Transport | WebRTC DataChannel (`"data"`) | QUIC bidirectional data stream |
| Channel config | `ordered: true, maxRetransmits: 3 (PWA) / 1 (mobile)` | QUIC stream (reliable ordered by default) |
| Send batching | PWA: array + async drain; Mobile: frame-aligned coalescing | HID writer flushes at ~video FPS |
| Delivery | `Uint32Array.buffer` / `RTCDataChannelMessage.fromBinary()` | Length-prefixed samples on QUIC stream |
| Inbound messages | DataChannel `onmessage` | QUIC data receiver goroutine |

### 4.5 Incoming Server Messages (server → client)

**grum (0x10)**: Gamepad rumble. `Uint8Array`: `[16, gamepadId, weak, strong]`. PWA triggers `gamepad.vibrationActuator` or `navigator.vibrate()`. Mobile triggers `HapticFeedback.heavyImpact()`. Desktop triggers SDL haptic rumble.

**noti (0x12)**: Notification text. `Uint8Array`: `[18, 0, 0, 0, ...UTF-8 text]`. Special case: if text contains `"controller not found "`, client should re-send `gconn` with the parsed gamepad ID.

**cu (0x16)**: Cursor update with PNG image. See Section 5.

**cp (0x17)**: Cursor position only. See Section 5.

---

## 5. Cursor Binary Protocol

Both `cu` and `cp` use the same wire format across **all three clients**. The transport differs (DataChannel for PWA/mobile, QUIC data stream for desktop) but the binary layout is identical.

### 5.1 Cursor Position (cp, code 23)

```
Offset  Size   Field
0       1      EventCode.cp (23)
1       2      x (Uint16 LE) — range [0, 65535]
3       2      y (Uint16 LE) — range [0, 65535]
5       1      visible (Uint8) — 0 or 1
6       8      cursorId (Uint64 LE)
14      8      serverTime (Uint64 LE, nanoseconds)
```

### 5.2 Cursor Update (cu, code 22)

```
Offset  Size   Field
0       1      EventCode.cu (22)
1       2      x (Uint16 LE)
3       2      y (Uint16 LE)
5       1      hotspotX (Uint8)
6       1      hotspotY (Uint8)
7       2      width (Uint16 LE)
9       2      height (Uint16 LE)
11      1      visible (Uint8)
12      8      cursorId (Uint64 LE)
20      8      serverTime (Uint64 LE, nanoseconds)
28      4      pngLength (Uint32 LE)
32      N      PNG image bytes (N = pngLength)
```

### 5.3 Interpolation Algorithm

PWA and mobile implement **motion interpolation** with 32ms glide paths. Desktop composites cursor position directly onto the video frame at display refresh rate (no interpolation needed — native rendering pipeline).

1. Maintain a smoothed clock offset: `smoothedOffset = (smoothedOffset * 9 + currentOffset) / 10` (EMA, alpha=0.1)
2. On each cursor packet, compute target screen position by mapping `(x/65535) * contentWidth` etc.
3. If first packet: snap start to target. Otherwise: capture current interpolated position as new start.
4. Render loop: `t = clamp01((currentServerTime - lastPacketServerTime) / 32ms)`, then `pos = start + (target - start) * t`
5. Ignore packets where `serverTime <= maxServerTime` (out-of-order rejection)

---

## 6. Stream Health Status Events

All three clients receive backend status events. The proxy sends these over different transports but with the same semantic content:

| Client | Transport | Format |
|--------|-----------|--------|
| PWA | WebSocket `{ event: "status" }` on DataChannel signaling | JSON |
| Mobile | WebSocket `{ event: "status" }` on DataChannel signaling | JSON |
| Desktop | QUIC datagrams | JSON status envelope |

### Stream Health States

| State                   | Trigger                                              |
|-------------------------|------------------------------------------------------|
| `healthy`               | Heartbeat with new seq, or `hid_alive`               |
| `recovering_video`      | `waiting_for_keyframe` or `backend_reconnected`      |
| `video_stalled`         | Server reports `video_stalled`                       |
| `encoder_stalled`       | Server reports `encoder_stalled`                     |
| `control_blocked`       | Server reports `control_path_blocked`                |
| `backend_reconnecting`  | Server reports `backend_disconnected`                |

---

## 7. Metrics Contract (PWA and Mobile)

The metrics pipeline collects RTCStatsReport data at regular intervals and exposes structured metrics to the UI. **This section applies to WebRTC clients only.** The desktop client uses its own `perf.Tracker` with FFmpeg-side decode metrics and optional HTTP stats dashboard.

### 7.1 Shared Metrics (PWA and mobile)

| Category    | Field                              | Source (RTCStatsReport)             |
|-------------|------------------------------------|--------------------------------------|
| Video/Frame | `totalframes`                      | `framesDecoded`                      |
| Video/Frame | `persecond`                        | delta frames / delta time            |
| Video/Frame | `decodetime`                       | delta `totalDecodeTime + totalAssemblyTime` / frameDelta |
| Video/Frame | `bufferdelay`                      | delta `jitterBufferDelay` / emitted count |
| Video/Frame | `processingdelay`                  | delta `totalProcessingDelay` / frameDelta |
| Video/Frame | `delay`                            | delta `totalInterFrameDelay` / frameDelta |
| Video/Frame | `processingtime`                   | `decodetime + bufferdelay + processingdelay` |
| Video/Frame | `roundtriptime`                    | `currentRoundTripTime` from candidate-pair |
| Video/Frame | `jitter`                           | `jitter * 1000` (ms)                 |
| Video/Frame | `totalfreezes`                     | `freezeCount`                        |
| Video/Frame | `totalfreezeduration`              | `totalFreezesDuration`               |
| Video/Frame | `totalframesdropped`               | `framesDropped`                      |
| Video/Frame | `interframedelaystddev`            | sqrt(variance of inter-frame delay) * 1000 |
| Video/Bitrate | `total`, `persecond`             | `bytesReceived`, delta / time * 8 / 1024 |
| Video/PacketLoss | `current`, `last`              | delta `packetsLost`                  |
| Video/IdrCount  | `current`, `last`               | delta `keyFramesDecoded`             |
| Video/Decoder   | `name`, `isHardwareAccelerated`  | `decoderImplementation`, `powerEfficientDecoder`, `codecName` |
| Video       | `webrtcSupport`                    | Codec MIME types from `setCodecPreferences` |
| Audio       | `status`, `sample.received`        | `totalSamplesReceived`               |
| Data        | `status`                           | Connection state                     |
| Both        | `errors[]`, `backendStatus[]`     | Error strings and backend status labels |

### 7.2 Mobile-Only Metrics

The mobile client extends the metrics with these additional fields:

| Category         | Fields                                                | Purpose                            |
|------------------|-------------------------------------------------------|------------------------------------|
| `HidMetric`      | `sentBatches`, `sentMessages`, `droppedBackpressure`, `bufferedAmount`, `pendingCoalesced`, `touchPoolExhausted` | HID backpressure and coalescing diagnostics |
| `AdaptiveMetric` | `mode`, `effectiveFramerate`, `targetFramerate`, `effectiveBitrateKbps`, `targetBitrateKbps`, `idrBackoffSec`, `zeroFrameStreak` | Client-side adaptive streaming state |
| `StreamHealth`   | `lastEvent`                                           | Last backend status event type (simplified string) |

---

## 8. Auto-Reconnect Protocol (PWA and Mobile)

Both WebRTC clients implement establishment loops that automatically reconnect when a connection drops:

1. On connection close/failure, schedule reconnection after **1 second** (PWA) or **1-10 seconds** (mobile, depends on adaptive mode).
2. On reconnection, reset metrics for that connection type and restart the signaling sequence from scratch.
3. Video: after reconnection, wait up to 5s for track, then wait up to 5s for first decoded frame.
4. Audio: after reconnection, wait up to 30s for connection.
5. Microphone: retry up to 3 times on track failure, then give up.

The desktop client uses a different reconnection strategy (make-before-break for video, per-channel reconnect with exponential backoff). See [Desktop client architecture — Reconnection](../../../desktop_client_architecture.md#reconnection).

---

## 9. Codec Preference Rules (PWA and Mobile)

### Video (recv-only)

When receiving the SDP offer, the client:
1. Gets `RTCRtpReceiver.getCapabilities('video')` codecs.
2. Filters to preferred codec (from `?codec=` URL param, default `h264`) + `rtx` + `flexfec-03`.
3. For `h265` on mobile: also include `hevc` as alias.
4. Applies via `transceiver.setCodecPreferences()`.
5. Reports unsupported codec if the preferred codec is absent.

The desktop client does not negotiate codecs via SDP. Codec is set via `-codec` CLI flag and the proxy sends raw encoded samples (not RTP), so no codec preference negotiation is needed.

### Audio/Microphone

- Audio recv: Opus at 48kHz, 2 channels.
- Microphone send: Capture via `getUserMedia`, set Opus codec preference on sender transceiver.
- Microphone offer SDP: inject `a=ptime:60` after each `m=audio` line (PWA only).

---

## 10. Source File Mapping

### PWA and Mobile (WebRTC clients)

| Component         | PWA — Reference (TypeScript)            | Mobile (Dart)                              |
|-------------------|------------------------------------------|--------------------------------------------|
| Orchestrator      | `website/core/core/index.ts`            | `mobile/lib/core/thinkmay_client.dart`    |
| EventCode enum    | `website/core/core/models/keys.model.ts` | `mobile/lib/core/models/event_code.dart` |
| HIDMsg encoding   | `website/core/core/models/keys.model.ts` | `mobile/lib/core/models/event_code.dart` |
| MessageType enum  | `website/core/core/webrtc/media.ts`      | `mobile/lib/core/models/event_code.dart` |
| Video/Audio conn  | `website/core/core/webrtc/media.ts`      | `mobile/lib/core/webrtc/media_rtc.dart`   |
| DataChannel conn  | `website/core/core/webrtc/data.ts`       | `mobile/lib/core/webrtc/data_rtc.dart`    |
| Microphone conn   | `website/core/core/webrtc/microphone.ts` | `mobile/lib/core/webrtc/microphone_rtc.dart` |
| Cursor system     | `website/core/core/cursor.ts`            | `mobile/lib/core/cursor/cursor_handler.dart` |
| HID (keyboard/mouse) | `website/core/core/hid/hid.ts`        | `mobile/lib/core/hid/keyboard_handler.dart`, `mouse_handler.dart` |
| Touch handler     | `website/core/core/hid/touch.ts`         | `mobile/lib/core/hid/touch_handler.dart`  |
| Metrics model     | `website/core/core/models/metrics.model.ts` | `mobile/lib/core/models/metrics.dart` |
| Platform utils    | `website/core/core/utils/platform.ts`    | `mobile/lib/core/platform/`               |
| Keymap conversion | `website/core/core/utils/convert.ts`     | `mobile/lib/core/utils/`                  |

### Desktop (QUIC client)

| Component         | Desktop (Go)                                |
|-------------------|---------------------------------------------|
| Entry / lifecycle | `worker/proxy/cmd/client/main.go`, `client/app/app_new.go`, `run.go` |
| QUIC transport    | `worker/proxy/client/stream/quic_client.go`, `worker/proxy/forwarder/quic/` |
| HID encoding      | `worker/proxy/client/hid/` — same EventCode/Uint32 layout |
| Cursor handling   | `worker/proxy/client/app/cursor*.go` — same cu/cp binary parsing |
| Video pipeline    | `worker/proxy/client/pipeline/`, `client/decoder/`, `client/presenter/` |
| Audio / mic       | `worker/proxy/client/audio/`, `client/app/media_loops.go` |
| Config / URL      | `worker/proxy/client/config/config.go` |
| Connect UI        | `worker/proxy/client/connectui/` |

---

## 11. Change Protocol

When modifying any shared protocol element:

1. **Update this document first** with the new/changed element.
2. **Implement in the PWA first** — it is the reference implementation. Test in production.
3. **Propagate to mobile** — the mobile app must follow the PWA's behavior. Reference this doc in the PR.
4. **Check desktop impact** — if the change affects HID binary protocol, cursor wire format, or stream health semantics, update the desktop client too.
5. **Add a comment** in each code file referencing the canonical definition here: `// See docs/product/architecture/client_protocol_contract.md Section N`.
6. **If backward-incompatible**: coordinate a server-side migration window with the proxy team. The proxy must accept both old and new formats during the transition.

### Mobile-specific changes

Changes that only affect the mobile app (e.g., adaptive streaming thresholds, decoder profiles) do not require PWA changes, but must be documented in [Client Platform Divergence](./client_platform_divergence.md).

### Desktop-specific changes

Changes to the QUIC transport layer, FFmpeg decode pipeline, or native presentation do not require PWA/mobile changes. Document in [Desktop client architecture](../../../desktop_client_architecture.md).
