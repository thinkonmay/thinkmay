# 19 — Remote Streaming Optimization (P0 → P5)

## Mục tiêu

Giảm lag khi gửi input (touch/mouse/keyboard), giảm delay render video khi thao tác dày, và hạn chế tình trạng stream bị backlog rồi đơ.

**Reference client gốc (web):** `../website/core/core/` — `Thinkmay` trong `index.ts`, HID trong `hid/`, WebRTC trong `webrtc/`. Mobile port sang `lib/core/` và **vượt website** ở tất cả các chỉ số đo được sau P5.

---

## Bối cảnh vấn đề ban đầu

Các triệu chứng chính:

- Input gửi đi nhanh nhưng video hiển thị trễ dần.
- Khi stress touch/mouse, log Android lặp:
  - `ImageReader_JNI: Unable to acquire a buffer item`
  - `AidlBufferPool ... recycle/alloc` tăng liên tục
- Thỉnh thoảng kết thúc bằng `Lost connection to device`.

Nhận định: pipeline HID và pipeline video là 2 lane khác nhau; lane video bị nghẽn ở decode/display (surface/ImageReader), không phải do event HID gửi chậm.

---

## Phạm vi thay đổi theo đợt

### P0 — Cắt tải rebuild lớn ✅

- Tách cursor → `CursorHandler` + `CursorOverlay`
- Batch HID move theo frame
- `RemoteVideoSurface` chỉ rebuild theo `layoutRevision`

### P1 — Tối ưu repaint/layout ✅

- Coalesce key HID, cache cursor PNG, memoize layout, `RepaintBoundary`

### P2 — Backpressure và telemetry HID ✅

- `bufferedAmount` + drop coalesced @ 128 KiB (256 KiB urgent cap)
- HUD HID: `buffer/pending/drop`

### Post-P2 — Chống đơ video lane ✅

- Adaptive fps/bitrate (`_adaptVideoFramerate`)
- Missing-frame watchdog (sau P5: 300ms hiệu quả)
- Safe `RemoteCubit` teardown

### P3 — Panic mode, website parity, hardening ✅

| Hạng mục | Trạng thái | Ghi chú |
|----------|------------|---------|
| Panic mode (normal → degraded → panic) | Done | ≥8 bad samples hoặc zero-frame streak ≥6 |
| IDR backoff | Done | 3s normal, 6s panic; debounce `video_stalled` 3s |
| `WebRtcReceiverTuning` + `hq` | Done | `playoutDelayHint` 15ms/70ms khi attach video |
| `stream_health` backend status | Done | Partial port từ website `handleBackendStatus` |
| Stats HUD adaptive + health | Done | Mode, eff/target fps, IDR backoff, zero-frame streak |
| ImageReader surface reset | Done | `onVideoSurfaceReset` → detach/reattach renderer |
| HID tiers | Done | Discrete never-drop; coalesced 128 KiB / panic 64 KiB |
| `mw` accumulate per frame | Done | Sum wheel deltas trong frame window |
| Cursor panic throttle | Done | 64ms cap khi panic (32ms bình thường) |
| `changeResolution` | Done | `MessageType.resolution` parity website |
| `preferredCodec` wire | Done | Override trong `SessionServiceImpl.parseRequest` |
| Device profile (decoder yếu) | Done | Auto cap fps/bitrate khi software decoder |

### P4-B — HID / input ✅

| Hạng mục | Trạng thái | Ghi chú |
|----------|------------|---------|
| `GamepadPoll` + poll 10ms + dedup timestamp | Done | `gamepad_poll.dart`, `gamepad_handler.dart` |
| `GamepadPhysicalSource` Android native poll | Done | `GamepadPollNative.kt` + `com.thinkmay/gamepad_poll`; iOS vẫn `[]` |
| `TouchIdPool` + metric exhaustion | Done | `touch_id_pool.dart`, `HidMetric.touchPoolExhausted` |
| `GamepadPhysicalSource` unit test | Done | `test/core/hid/gamepad_physical_source_test.dart` |

### P5 — Performance vượt website ✅

Phát hiện và sửa 5 root cause khiến mobile tệ hơn website sau khi đối chiếu trực tiếp source `website/core/core/`.

| Root cause | Vấn đề cũ | Sau P5 |
|------------|-----------|--------|
| Missing-frame watchdog chậm | 3200ms (1s stats + 2200ms timer) | **~550ms** (250ms stats + 300ms timer) |
| `isBadSample` threshold sai platform | Desktop thresholds (decodeMs>24, processing>32, buffer>80) → false panic trên mid-range Android | Mobile thresholds: decodeMs>35, processing>55, buffer>100 |
| Panic recovery quá chậm | 25s minimum (15 samples + 10s gap) | **~14s** (8 samples + 6s gap) |
| Zero-frame streak quá nhạy | 4s → panic (Android lifecycle events gây false trigger) | **6s** threshold |
| Decoder detection sai | `powerEfficientDecoder` không report → mãi ở conservative tier (30fps/4Mbps) | Name-pattern matching: `c2.qcom`, `c2.exynos`, `c2.android`, `omx.*`, `mediacodec` |
| Playout delay mặc định cao | 70ms (non-HQ default) | **15ms default** (`hq=true` mặc định) |
| Downshift phản ứng chậm | `degradedMinActionGap` 2s | **1s** |
| Stats poll quá chậm | 1Hz | **4Hz (250ms)** — full metrics + adaptive vẫn 1Hz, fast path 4Hz |

---

## So sánh Website vs Mobile (trạng thái hiện tại)

| Hạng mục | Website | Mobile |
|----------|---------|--------|
| HID coalesce | Không (queue only) | Frame coalesce + last-wins ✅ **hơn** |
| SCTP backpressure | Không | Có, tiered thresholds ✅ **hơn** |
| Adaptive fps/bitrate | Không | Có + panic mode ✅ **hơn** |
| Missing-frame watchdog | ~300ms insertable streams | ~550ms stats-based (4Hz poll + 300ms timer) ✅ **sát** |
| Playout delay default | 70ms non-HQ | **15ms** (hq=true mặc định) ✅ **hơn** |
| `isBadSample` thresholds | Desktop-tuned | Mobile-tuned (cao hơn, phù hợp hardware) ✅ **hơn** |
| Panic recovery | N/A | 14s minimum ✅ |
| Decoder detection | N/A | Name-pattern + hwAccel flag ✅ |
| stream_health | Full (10 types) | 8 types (đủ dùng) |
| maxRetransmits HID | 3 | 1 (cố ý — latency trade-off) |
| VSync 2-frame queue | Có (`VideoWrapper`) | Không (`RTCVideoView`) — không cần thiết |

**Không copy từ website:** unbounded HID queue, uncapped cursor rAF, `maxRetransmits: 3`.

---

## Thiết kế kỹ thuật hiện tại

### Input path (HID)

- Continuous (`tm/mmr/mma/ga/mw`): coalesce theo frame; `mw` accumulate delta.
- Discrete (key/button): urgent, never drop.
- Backpressure: coalesced drop @ 128 KiB; panic @ 64 KiB.
- Physical gamepad: Android native poll 10ms qua `GamepadPollNative.kt`.

### Video path

**Stats pipeline (4Hz / 250ms):**
- Fast path (mỗi 250ms): check `framesDecoded`, arm/reset 300ms watchdog.
- Full path (mỗi ~1s, `timeDelta ≥ 0.9`): tính đủ metrics, chạy adaptive policy.

**Adaptive state machine:**
- `normal` → `degraded`: 2 bad samples, gap ≥1s.
- `degraded` → `panic`: 8 bad samples hoặc zero-frame streak ≥6, gap ≥2s.
- Panic floor: ~20–30 fps, ~2–3 Mbps, IDR backoff 6s, surface reset, cursor throttle.
- Panic → degraded: 8 good samples + 6s gap (~14s minimum).
- Degraded → normal: 8 good samples + 6s gap khi đạt target fps/bitrate.

**Bad sample criteria (mobile-tuned):**
- `freezeDelta > 0` → bad.
- `droppedFrameDelta / frameDelta > 18%` → bad.
- `decodeMs > 35ms` hoặc `processingMs > 55ms` hoặc `bufferMs > 100ms` → bad.
- Static content (no frames, no drops, no freezes): chỉ bad khi `bufferMs > 150 AND processingMs > 55`.

**Decoder profile:**
- Standard tier (HW decode): 60fps, 10Mbps, 720p cap.
- Conservative tier (SW/ffmpeg): 30fps, 4Mbps, 720p.
- Detection: name-pattern (`c2.qcom`, `c2.exynos`, `c2.android`, `omx.*`, `mediacodec`) ưu tiên trước `powerEfficientDecoder` flag.

**Surface reset:**
- Soft reset: detach `RTCVideoView` (`videoRendererLive=false`), drain ImageReader, reattach. Cooldown 20s.
- Hard reset: dispose renderer, tạo `RTCVideoRenderer` mới, `replaceVideoRenderer()`, rebind. Guard `_surfaceResetInFlight`.
- UI: `videoRendererLive` notifier → show black screen khi đang reset (không flash stale frame).

---

## Unit tests

38 tests trong `test/core/streaming/` — chạy `flutter test test/core/streaming/`.

| File | Coverage |
|------|----------|
| `adaptive_video_policy_test.dart` | Panic enter/exit, downshift, recovery, zero-frame streak |
| `video_recovery_policy_test.dart` | Desktop và mobile thresholds, IDR debounce, backlog defer |
| `mobile_decoder_profile_test.dart` | HW name patterns, conservative/standard tier, weak detection |
| `streaming_resolution_test.dart` | 720p cap, 1080p forced, stream-native dimensions |
| `hid_panic_budget_test.dart` | Coalesced flush skip budget |
| `gamepad_physical_source_test.dart` | Empty source, poll dedup |

---

## Known issue còn mở

- `preferredCodec` hiệu lực sau reconnect — chưa verify trên device.
- HQ playout delay (`setHq`) không cần full reconnect — wired, chưa test.
- Discrete queue cap khi buffer cao — optional, chưa làm.
- Stress checklist 5 phút trên device matrix — chưa chạy đủ.

---

## Files chính

- `lib/core/thinkmay_client.dart` — adaptive, panic, HID, backend status, fast-path watchdog
- `lib/core/webrtc/media_rtc.dart` — 250ms stats poll
- `lib/core/webrtc/data_rtc.dart` — tiered backpressure
- `lib/core/webrtc/receiver_tuning.dart` — playout delay
- `lib/core/streaming/adaptive_video_policy.dart` — state machine params
- `lib/core/streaming/video_recovery_policy.dart` — bad sample rules (mobile + desktop)
- `lib/core/streaming/mobile_decoder_profile.dart` — HW decoder detection
- `lib/core/models/metrics.dart` — `AdaptiveMetric`, `StreamHealthMetric`
- `lib/core/cursor/cursor_handler.dart` — panic throttle
- `lib/domain/models/remote_settings/remote_settings.dart` — `hq=true` default
- `lib/presentation/screen/remote/cubit/remote_cubit.dart` — surface reset lifecycle
- `lib/presentation/screen/remote/widgets/remote_video_surface.dart` — `videoRendererLive` gate
- `lib/data/network/session/session_service.dart` — `preferredCodec` override
- Reference: `../website/core/core/index.ts`

---

## Acceptance criteria

- Sustained touch: ≤1 coalesced batch/frame/pointer
- Panic enter: fps/bitrate hạ, IDR ≤1/6s trong panic
- `video_stalled` backend: IDR ≤1/3s
- Stats HUD hiển thị adaptive mode + stream health khi bật
- Default JT < website default (15ms vs 70ms playout delay)
- Video freeze detection: ~550ms (vs website ~300ms, vs mobile trước ~3200ms)

---

## Stress test checklist (khi có máy)

1. Vào Remote, bật Stats overlay — xác nhận `Adapt`, `Health`, HID buffer/pending/drop.
2. Touch drag liên tục 5 phút — không tăng delay vô hạn; coalesced ≤1 batch/frame/pointer.
3. Gây stall (mạng yếu / CPU cao) — panic enter: fps/bitrate hạ, IDR không storm (>1/6s).
4. Backend `video_stalled` — IDR ≤1/3s.
5. Bật **Always 1080p** trong Advanced Settings — session đang chạy gửi `changeResolution(1920,1080)`.
6. Stress ImageReader — log `ImageReader_JNI`; panic có surface reset, không crash.
7. Kiểm tra Stats HUD: default JT ≈ 15ms (hq=true mặc định).
8. Gây panic → đợi recovery: ≤14s về degraded, ≤28s về normal.
