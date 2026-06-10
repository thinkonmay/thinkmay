# 16 — Network, Domain & Diagnostics

## Tổng quan

Kiểm tra kết nối tới cluster/domain, test bàn phím và gamepad ngoài remote session.

---

## Trạng thái API

> Tổng hợp: [API-COVERAGE.md](../API-COVERAGE.md)

| Màn hình | Trạng thái | Chi tiết |
|----------|------------|----------|
| Network check — danh sách domain | ✅ | `FetchDomainsUseCase` |
| Network check — chọn routing server | ✅ | User chọn domain → `BaseUrlProvider.updateBaseUrl('https://<domain>')`; chỉ ảnh hưởng WebRTC routing |
| Network check — ping / download / upload | 🟡 Best-effort | Đo client-side bằng TCP handshake + HTTPS GET/POST tới domain đã chọn; chưa phải speed-test chuẩn vì backend chưa có endpoint payload riêng |
| Remote stream stats | ✅ | Đo realtime từ `RTCPeerConnection.getStats()` khi đã vào RemoteScreen |
| Check keyboard | ⚪ | Local test, không API |
| Gamepad test | ⚪ | WebView tester |

**Lưu ý:** Network Check hiện chưa có backend speed-test API riêng. Các số `Ping`, `Download Speed`, `Upload Speed` là **client-side best-effort diagnostics**, dùng để so sánh tương đối tình trạng kết nối từ thiết bị tới routing server đã chọn. Không claim là ICMP ping hoặc speed-test chuẩn.

---

## Mobile

### Network check

| File | `network_check_screen.dart`, `network_check_cubit.dart` |
|------|-----------------------------------------------------------|
| Use case/service | `FetchDomainsUseCase`, `ServerProbeService`, `SpeedTestService`, `BaseUrlProvider` |
| State | Initial picker → Checking → Done/Error |
| Route | `/network-check` |

**Flow hiện tại:**

1. `init()` gọi `FetchDomainsUseCase` để load danh sách domain.
2. Cubit đọc `BaseUrlProvider.getRoutingServerUrl()` để preselect domain đang được dùng làm routing server.
3. Màn initial hiển thị nút tròn **Kiểm tra** và card **Server** dạng radio list.
4. User tap server:
   - `selectServer(server)` gọi `BaseUrlProvider.updateBaseUrl('https://<domain>')`
   - URL được lưu vào `SERVER_URL_KEY`
   - `PocketBase` vẫn bị pin về `Endpoint.baseUrl` (`saigon2`) trong `BaseUrlProvider`
   - metric cũ (`pingMs`, `downloadMbps`, `uploadMbps`) được clear.
5. User bấm **Kiểm tra**:
   - `runSpeedTest()` chuyển sang `NetworkCheckLoadingState`
   - đo `Ping` → emit từng bước
   - đo `Download Speed` → emit từng bước
   - đo `Upload Speed` → emit `NetworkCheckSuccessState`
6. Nếu fetch domain fail, emit `NetworkCheckErrorState` và UI hiển thị retry.
7. Sau khi đo xong, nút **Kiểm tra lại** reset về picker nhưng không đổi routing server đã lưu.

**UI states theo design:**

| State | UI | Dữ liệu |
|-------|----|---------|
| Initial picker | Heading + nút tròn `Kiểm tra` + card `Server` radio list | `availableServers`, `selectedServer` |
| Checking | Heading + `Đang kiểm tra, vui lòng chờ...` + card server + 3 metric cards spinner | `isProbing=true`, metric nào đo xong thì hiện số |
| Done | Heading + `Kiểm tra hoàn tất` + card server + Download/Ping/Upload values | `downloadMbps`, `pingMs`, `uploadMbps`; null hiển thị `---` |
| Error | Error icon/message + retry | `NetworkCheckErrorState.exception` |

**Implementation files:**

| File | Trách nhiệm |
|------|-------------|
| `lib/presentation/screen/network_check/network_check_screen.dart` | Render 3 UI states, metric cards, server picker |
| `lib/presentation/screen/network_check/cubit/network_check_cubit.dart` | Load domain, chọn/lưu routing server, chạy speed test tuần tự |
| `lib/presentation/screen/network_check/view_model/network_check_view_model.dart` | `availableServers`, `selectedServer`, `downloadMbps`, `uploadMbps`, `pingMs`, `isProbing` |
| `lib/data/network/probe/server_probe_service.dart` | Đo ping bằng DNS once + TCP connect samples |
| `lib/data/network/probe/speed_test_service.dart` | Best-effort đo download/upload bằng HTTPS GET/POST |
| `lib/presentation/screen/network_check/widgets/network_result_card.dart` | Card shell có icon/title |
| `lib/presentation/screen/network_check/widgets/network_speed_item.dart` | Metric tile có spinner/value/unit |

**Probe / speed strategy (không cần backend API mới):**

| Probe | Đo được | Ưu điểm | Hạn chế |
|-------|---------|---------|---------|
| DNS lookup `InternetAddress.lookup(domain)` | Domain resolve được không | Resolve 1 lần rồi tái dùng IP, tránh inflate latency vì DNS lookup lặp | Không dùng làm số Ping |
| TCP connect `Socket.connect(ip, 444)` | TCP handshake latency tới WebRTC routing port | Gần đường signaling/stream hơn HTTPS | Firewall có thể block port 444 |
| TCP fallback `Socket.connect(ip, 443)` | TCP handshake latency tới HTTPS port | Có fallback nếu `:444` không reach được | Ít sát stream path hơn |
| HTTPS GET `https://<domain>/` | Approx download Mbps | Không cần backend mới nếu domain có HTTPS root | Nếu response nhỏ thì under-report; không phải speed-test chuẩn |
| HTTPS POST `https://<domain>/` | Approx upload Mbps | Đo bytes client flush được trong timed window | Server có thể đóng sớm/không đọc body; số chỉ best-effort |

**Metric hiện có trong Network Check:**

| Metric UI | Source | Code | Fail value |
|-----------|--------|------|------------|
| Ping | Median của 3 TCP handshake samples | `ServerProbeService.measurePingMs()` | `--- ms` |
| Download Speed | Bytes đọc từ HTTPS GET / elapsed | `SpeedTestService.measureDownloadMbps()` | `--- mbps` |
| Upload Speed | Bytes gửi qua HTTPS POST / elapsed | `SpeedTestService.measureUploadMbps()` | `--- mbps` |

**Các thông số chưa đo được trước khi stream:**

| Metric | Lý do |
|--------|------|
| FPS | Cần video frames từ WebRTC stream |
| Bitrate WebRTC thực tế | Cần `bytesReceived` từ `RTCStatsReport` khi stream đang chạy |
| Jitter RTP | Cần inbound RTP stats |
| Buffer/decode/processing delay | Cần decoder + jitter buffer stats |
| Freeze/drop | Cần decoded video frames |
| Packet loss / IDR | Cần RTP + decoder stats |
| WebRTC RTT thật (`candidate-pair.currentRoundTripTime`) | Cần `RTCPeerConnection` đã connect |

**Lưu routing server:**

Network Check là nơi chọn routing server chính thức. Khi user chọn server:

1. Save `https://<domain>` vào `SERVER_URL_KEY`
2. `BaseUrlProvider.updateBaseUrl(...)` chỉ lưu routing URL và đảm bảo `PocketBase` vẫn ở `Endpoint.baseUrl`
3. `SessionServiceImpl.parseRequest()` dùng `BaseUrlProvider.getRoutingServerUrl().host` khi build WebRTC host override

Không được dùng domain đã chọn để login/auth, vì production auth chỉ chạy ở `saigon2`.

**Không còn dùng trong implementation hiện tại:**

- Không probe song song tất cả domain.
- Không sort domain theo latency.
- Không hiển thị `good/slow/offline`.
- Không có badge `Recommended` / `In use`.
- Không dùng `SaveServerUrlUseCase` trong `NetworkCheckCubit`; tránh double-write cùng `SERVER_URL_KEY`, giữ một path qua `BaseUrlProvider.updateBaseUrl`.
- Không còn `ServerProbeResult` model; ping service trả trực tiếp `int?`.

### Remote stream stats

RemoteScreen đã có realtime stats overlay (`StatsOverlay`) khi bật show stats. Nguồn dữ liệu là `RTCPeerConnection.getStats()` trong `MediaRTC`, xử lý tại `ThinkmayClient._handleMetrics`.

| Metric trên UI | Source | Ghi chú |
|----------------|--------|---------|
| Route | Current routing host/session context | Nên hiển thị domain đang dùng để stream |
| Decoder | `decoderImplementation` | Ví dụ H264 / hardware decoder |
| FPS | Delta `framesDecoded` / second | Chỉ có khi video đang decode |
| Ping | `candidate-pair.currentRoundTripTime / 2` | Đây là WebRTC RTT/2, không phải ICMP ping |
| Buf | `jitterBufferDelay / jitterBufferEmittedCount` delta | Jitter buffer delay per frame |
| Dec | `totalDecodeTime + totalAssemblyTime` delta / frame | Decoder/assembly time |
| Proc | `totalProcessingDelay` delta / frame | Processing delay |
| Bitrate | Delta `bytesReceived` * 8 / second | Receive bitrate |
| PL | Delta `packetsLost` | Packet loss |
| IDR | Delta `keyFramesDecoded` | Keyframe/IDR proxy |
| Jt | inbound RTP `jitter` | RTP jitter |
| Avg | `totalInterFrameDelay` / frame + stddev | Frame pacing |
| Freeze/Drop | `freezeCount`, `framesDropped` | Playback quality |

Các metric này **không thể dùng để chọn server trước khi stream**, nhưng rất hữu ích để debug khi user đang trong remote session. Có thể cân nhắc lưu snapshot cuối phiên hoặc nút copy diagnostics cho support.

**Future idea:** sau khi user chạy Network Check và chọn server, khi vào stream có thể hiển thị so sánh:

- Probe latency trước stream: `28ms`
- WebRTC RTT/2 trong stream: `35ms`
- Bitrate/FPS/drop thực tế

Nếu chênh lệch lớn, có thể gợi ý “server reachable tốt nhưng stream quality thấp, khả năng do VM/encoder/network congestion”.

**Đối chiếu dashboard:** `isWrongServer` khi `metadata` empty và cluster ≠ current addr.

### Check keyboard

| File | `check_keyboard_screen.dart` |
|------|-------------------------------|
| Cubit | Không |
| Logic | Local `Set<String> pressedKeys` |
| Widget | `TmVirtualKeyboard` read-only test |

### Gamepad test

| File | `gamepad_test_screen.dart` |
|------|----------------------------|
| Implementation | WebView load HTML gamepad tester |

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| `/network-check` | `/setting/(diagnostic)/network` |
| `/check-keyboard` | `/setting/(diagnostic)/keyboard` |
| `/gamepad-test` | `/setting/(diagnostic)/gamepad` |
| FetchDomains | Same domain list API |
| Wrong domain UX | `WrongDomainState` component on dashboard |

**State website:** Diagnostic pages dùng trực tiếp singleton streaming helpers để gửi test HID.

**State mobile:** Keyboard test không cần active `ThinkmayClient`; gamepad test isolated WebView.

---

## Liên kết

- [08-settings](08-settings-configuration.md)
- [04-dashboard](../dashboard/04-dashboard-cloud-pc.md)
