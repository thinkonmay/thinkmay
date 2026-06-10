# 04 — Dashboard & Cloud PC Management

## Tổng quan

Tab **Cloud PC**: hiển thị VM từ `GlobalCubit.workerInfo`, power on/off/restart, deploy SSE, connect remote.

Website: `components/dashboard/GetStarted` trên `/play`.

---

## Trạng thái API

> [API-COVERAGE.md](../API-COVERAGE.md)

| Thành phần | Trạng thái |
|------------|------------|
| Worker / sessions / volume status | ✅ `GlobalCubit` ← preload `GET /info` |
| Power on/off/restart | ✅ PocketBase `/new`, `/close`, `/restart` + SSE |
| `openStream` | ✅ `StartSessionUseCase` — session mới (token fresh) |
| Games carousel | ✅ `GlobalState.games` ← Supabase preload |
| **Hero carousel (Home tab)** | ✅ `PlayHeroCarousel` + `FetchPlayBannersUseCase` → Supabase `banner`; YouTube + 2 game spotlight |
| Card specs (RAM/CPU/GPU/DISK) | ✅ `FetchPlansUseCase` → ViewModel; **RAM/GPU** có fallback; **CPU/DISK** chỉ hiện khi API có data (hour1 thường chỉ RAM+GPU) |
| `shareVolume` | 🔴 TODO empty |

**Điều kiện hiển thị:** `DashboardCubit` subscribe `GlobalCubit.stream`. Nếu `!fetched` → loading. User login mới **không** preload → dashboard có thể kẹt loading (xem [02-authentication](../auth/02-authentication.md)).

---

## Mobile

### Files

| Layer | Path |
|-------|------|
| UI | `presentation/screen/dashboard/dashboard_screen.dart` |
| Hero carousel | `widgets/play_hero_carousel.dart` — YouTube + Supabase banners + 2 game slides |
| Cubit | `dashboard_cubit.dart` |
| Deploy overlay | `widgets/deploy_watch_overlay.dart` |

### ViewModel flags

Build từ `GlobalState`:

- `metadata` ← `configuration` (PB volumes)
- `volumeStatus` ← `workerInfo`
- `isNoSub`, `isWrongServer`, `isServerDown` — logic `noNode` + so sánh `subscription.cluster` với `_currentAddr()`
- `_currentAddr()` = host từ `Endpoint.baseUrl` (không phải domain user chọn lúc login)

### Actions

| Action | Use case |
|--------|----------|
| `powerOnCloudPC` | `StartSessionUseCase` + SSE `onStatus` → `deployWatch` |
| `powerOffCloudPC` | `CloseSessionUseCase` |
| `restartCloudPC` | `RestartVolumeUseCase` |
| `openStream` | `StartSessionUseCase` (không dùng cache session) |
| Sau VM ops | `GlobalCubit.refreshWorker()` |

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| Hero carousel | `#banner` Carousel trên `/play` — YouTube + `FetchBanners` + 2 game overview cards |
| `GlobalCubit` | Redux `worker`, `user.subscription` |
| `wait_and_claim_volume` | `StartSessionUseCase` |
| Deploy watch | `popup.deployWatch` |
| Connect | `constructRedirect('/remote')` |

---

## Liên kết

- [05-remote-streaming](../remote/05-remote-streaming-webrtc.md)
- [07-worker-api-session](../07-worker-api-session.md)
- [01-app-bootstrap](../01-app-bootstrap-global-state.md)
