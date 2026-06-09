# 16 — Network, Domain & Diagnostics

## Overview

Check connectivity to cluster/domain, test keyboard and gamepad outside remote session.

---

## API status

> Summary: [API-COVERAGE.md](../API-COVERAGE.md)

| Screen | Status | Details |
|--------|--------|---------|
| Network check — domain list | ✅ | `FetchDomainsUseCase` |
| Network check — select routing server | ✅ | User selects domain → `BaseUrlProvider.updateBaseUrl('https://<domain>')`; only affects WebRTC routing |
| Network check — ping / download / upload | 🟡 Best-effort | Client-side measurement via TCP handshake + HTTPS GET/POST to selected domain; not a standard speed test because backend has no dedicated payload endpoint |
| Remote stream stats | ✅ | Real-time measurement from `RTCPeerConnection.getStats()` when in RemoteScreen |
| Check keyboard | ⚪ | Local test, no API |
| Gamepad test | ⚪ | WebView tester |

**Note:** Network Check currently has no dedicated backend speed-test API. `Ping`, `Download Speed`, `Upload Speed` numbers are **client-side best-effort diagnostics**, used to compare relative connectivity from the device to the selected routing server. Do not claim ICMP ping or standard speed test.

---

## Mobile

### Network check

| File | `network_check_screen.dart`, `network_check_cubit.dart` |
|------|-----------------------------------------------------------|
| Use case/service | `FetchDomainsUseCase`, `ServerProbeService`, `SpeedTestService`, `BaseUrlProvider` |
| State | Initial picker → Checking → Done/Error |
| Route | `/network-check` |

**Current flow:**

1. `init()` calls `FetchDomainsUseCase` to load domain list.
2. Cubit reads `BaseUrlProvider.getRoutingServerUrl()` to preselect domain currently used as routing server.
3. Initial screen shows round **Check** button and **Server** card as radio list.
4. User taps server:
   - `selectServer(server)` calls `BaseUrlProvider.updateBaseUrl('https://<domain>')`
   - URL saved to `SERVER_URL_KEY`
   - `PocketBase` still pinned to `Endpoint.baseUrl` (`saigon2`) in `BaseUrlProvider`
   - old metrics (`pingMs`, `downloadMbps`, `uploadMbps`) cleared.
5. User taps **Check**:
   - `runSpeedTest()` transitions to `NetworkCheckLoadingState`
   - measure `Ping` → emit each step
   - measure `Download Speed` → emit each step
   - measure `Upload Speed` → emit `NetworkCheckSuccessState`
6. If domain fetch fails, emit `NetworkCheckErrorState` and UI shows retry.
7. After measurement completes, **Check again** button resets to picker but does not change saved routing server.

**UI states per design:**

| State | UI | Data |
|-------|-----|------|
| Initial picker | Heading + round `Check` button + `Server` radio list card | `availableServers`, `selectedServer` |
| Checking | Heading + `Checking, please wait...` + server card + 3 metric cards with spinner | `isProbing=true`, show number when metric completes |
| Done | Heading + `Check complete` + server card + Download/Ping/Upload values | `downloadMbps`, `pingMs`, `uploadMbps`; null shows `---` |
| Error | Error icon/message + retry | `NetworkCheckErrorState.exception` |

**Implementation files:**

| File | Responsibility |
|------|----------------|
| `lib/presentation/screen/network_check/network_check_screen.dart` | Render 3 UI states, metric cards, server picker |
| `lib/presentation/screen/network_check/cubit/network_check_cubit.dart` | Load domains, select/save routing server, run speed test sequentially |
| `lib/presentation/screen/network_check/view_model/network_check_view_model.dart` | `availableServers`, `selectedServer`, `downloadMbps`, `uploadMbps`, `pingMs`, `isProbing` |
| `lib/data/network/probe/server_probe_service.dart` | Measure ping via DNS once + TCP connect samples |
| `lib/data/network/probe/speed_test_service.dart` | Best-effort download/upload via HTTPS GET/POST |
| `lib/presentation/screen/network_check/widgets/network_result_card.dart` | Card shell with icon/title |
| `lib/presentation/screen/network_check/widgets/network_speed_item.dart` | Metric tile with spinner/value/unit |

**Probe / speed strategy (no new backend API needed):**

| Probe | Measures | Advantage | Limitation |
|-------|----------|-----------|------------|
| DNS lookup `InternetAddress.lookup(domain)` | Whether domain resolves | Resolve once then reuse IP, avoid inflating latency from repeated DNS | Not used as Ping number |
| TCP connect `Socket.connect(ip, 444)` | TCP handshake latency to WebRTC routing port | Closer to signaling/stream path than HTTPS | Firewall may block port 444 |
| TCP fallback `Socket.connect(ip, 443)` | TCP handshake latency to HTTPS port | Fallback if `:444` unreachable | Less aligned with stream path |
| HTTPS GET `https://<domain>/` | Approx download Mbps | No new backend if domain has HTTPS root | Small response under-reports; not standard speed test |
| HTTPS POST `https://<domain>/` | Approx upload Mbps | Measure bytes client flushes in timed window | Server may close early/not read body; numbers are best-effort only |

**Metrics in Network Check:**

| UI metric | Source | Code | Fail value |
|-----------|--------|------|------------|
| Ping | Median of 3 TCP handshake samples | `ServerProbeService.measurePingMs()` | `--- ms` |
| Download Speed | Bytes read from HTTPS GET / elapsed | `SpeedTestService.measureDownloadMbps()` | `--- mbps` |
| Upload Speed | Bytes sent via HTTPS POST / elapsed | `SpeedTestService.measureUploadMbps()` | `--- mbps` |

**Metrics not measurable before streaming:**

| Metric | Reason |
|--------|--------|
| FPS | Needs video frames from WebRTC stream |
| Actual WebRTC bitrate | Needs `bytesReceived` from `RTCStatsReport` while stream running |
| RTP jitter | Needs inbound RTP stats |
| Buffer/decode/processing delay | Needs decoder + jitter buffer stats |
| Freeze/drop | Needs decoded video frames |
| Packet loss / IDR | Needs RTP + decoder stats |
| Real WebRTC RTT (`candidate-pair.currentRoundTripTime`) | Needs connected `RTCPeerConnection` |

**Routing server persistence:**

Network Check is the official place to select routing server. When user selects server:

1. Save `https://<domain>` to `SERVER_URL_KEY`
2. `BaseUrlProvider.updateBaseUrl(...)` only saves routing URL and ensures `PocketBase` stays at `Endpoint.baseUrl`
3. `SessionServiceImpl.parseRequest()` uses `BaseUrlProvider.getRoutingServerUrl().host` when building WebRTC host override

Do not use selected domain for login/auth, because production auth only runs on `saigon2`.

**No longer used in current implementation:**

- No parallel probe of all domains.
- No sort domains by latency.
- No display `good/slow/offline`.
- No `Recommended` / `In use` badge.
- No `SaveServerUrlUseCase` in `NetworkCheckCubit`; avoid double-write of `SERVER_URL_KEY`, keep single path via `BaseUrlProvider.updateBaseUrl`.
- No `ServerProbeResult` model; ping service returns `int?` directly.

### Remote stream stats

RemoteScreen already has real-time stats overlay (`StatsOverlay`) when show stats is enabled. Data source is `RTCPeerConnection.getStats()` in `MediaRTC`, processed in `ThinkmayClient._handleMetrics`.

| UI metric | Source | Notes |
|-----------|--------|-------|
| Route | Current routing host/session context | Should show domain used for streaming |
| Decoder | `decoderImplementation` | e.g. H264 / hardware decoder |
| FPS | Delta `framesDecoded` / second | Only when video is decoding |
| Ping | `candidate-pair.currentRoundTripTime / 2` | This is WebRTC RTT/2, not ICMP ping |
| Buf | `jitterBufferDelay / jitterBufferEmittedCount` delta | Jitter buffer delay per frame |
| Dec | `totalDecodeTime + totalAssemblyTime` delta / frame | Decoder/assembly time |
| Proc | `totalProcessingDelay` delta / frame | Processing delay |
| Bitrate | Delta `bytesReceived` * 8 / second | Receive bitrate |
| PL | Delta `packetsLost` | Packet loss |
| IDR | Delta `keyFramesDecoded` | Keyframe/IDR proxy |
| Jt | inbound RTP `jitter` | RTP jitter |
| Avg | `totalInterFrameDelay` / frame + stddev | Frame pacing |
| Freeze/Drop | `freezeCount`, `framesDropped` | Playback quality |

These metrics **cannot be used to select server before streaming**, but are very useful for debugging when user is in remote session. Consider saving last session snapshot or copy diagnostics button for support.

**Future idea:** after user runs Network Check and selects server, when entering stream could show comparison:

- Pre-stream probe latency: `28ms`
- In-stream WebRTC RTT/2: `35ms`
- Actual bitrate/FPS/drop

If gap is large, could suggest "server reachable but stream quality low, possibly VM/encoder/network congestion".

**Dashboard comparison:** `isWrongServer` when `metadata` empty and cluster ≠ current addr.

### Check keyboard

| File | `check_keyboard_screen.dart` |
|------|-------------------------------|
| Cubit | None |
| Logic | Local `Set<String> pressedKeys` |
| Widget | `TmVirtualKeyboard` read-only test |

### Gamepad test

| File | `gamepad_test_screen.dart` |
|------|----------------------------|
| Implementation | WebView load HTML gamepad tester |

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| `/network-check` | `/setting/(diagnostic)/network` |
| `/check-keyboard` | `/setting/(diagnostic)/keyboard` |
| `/gamepad-test` | `/setting/(diagnostic)/gamepad` |
| FetchDomains | Same domain list API |
| Wrong domain UX | `WrongDomainState` component on dashboard |

**Website state:** Diagnostic pages use singleton streaming helpers directly to send test HID.

**Mobile state:** Keyboard test does not need active `ThinkmayClient`; gamepad test isolated WebView.

---

## Links

- [08-settings](08-settings-configuration.md)
- [04-dashboard](../dashboard/04-dashboard-cloud-pc.md)
