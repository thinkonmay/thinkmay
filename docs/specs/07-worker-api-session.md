# 07 — Worker API & Session

## Tổng quan

Giao tiếp **PocketBase worker API** (`/info`, `/new`, `/close`, …) và parse **session credentials** cho WebRTC.

> **Doc gốc:** [client_protocol_contract.md](../../docs/product/architecture/client_protocol_contract.md), [technical_doc.md](../../docs/product/architecture/technical_doc.md) § worker/PocketBase

Website: `core/api/index.ts` — `GetInfo`, `StartThinkmay`, `ParseRequest`, `getVmSession`.

---

## Mobile — services & models

| File | Vai trò |
|------|---------|
| `lib/data/network/worker/worker_service.dart` | REST + SSE |
| `lib/data/network/session/session_service.dart` | `parseRequest` → URLs |
| `lib/domain/models/worker/worker_models.dart` | `Computer`, `Session`, `ThinkmayCreds`, … |
| `lib/domain/models/worker/volume_status.dart` | Volume state enum |
| Use cases | `fetch_worker_info`, `start_session`, `close_session`, `restart_volume` |

### Endpoints (PocketBase custom)

Base: `Endpoint.baseUrl` = `https://saigon2.thinkmay.net`

| Method | Path | Mô tả |
|--------|------|-------|
| GET | `/info` | Worker state: volumes, sessions, GPUs |
| POST | `/new` | Start VM session |
| GET | `/new/sse?id=<volumeId>` | Deploy progress events |
| POST | `/restart` | Restart session |
| DELETE | `/close` | Close session |
| DELETE | `/resource` | Deallocate volume |
| POST | `/reallocate` | Reinstall OS (+ SSE) |

Auth: Header dùng `PocketBase.authStore.token` (set khi `authWithPassword` / Splash `authStore.save`). `WorkerService` gọi `pb.send(...)` với token hiện tại.

### WorkerService — GET /info

Trả `Computer` gồm:
- `volumeStatus: Map<String, VolumeStatus>`
- `sessions: List<Session>`
- Metadata cluster address

`FetchWorkerInfoUseCase` → `GlobalCubit.workerInfo`.

### StartSession — POST /new + SSE

`StartSessionUseCase` → `WorkerService.startSession`:

1. POST body `{ id: volumeId }`
2. Lắng nghe SSE lines — callback `onStatus(message, code)`
3. Kết quả: `Session` với `id` (VM session UUID), `thinkmay` (listener creds)

**Quan trọng:** `session.id` dùng làm `vmid`/`token` trong WebRTC URL — **khác** `volumeId` (PocketBase volume config id).

### SessionService.parseRequest

Input:
- `sessionId` — VM session UUID
- `thinkmay` — object có `listener: string[]`
- `addrOverride` — optional host thay thế

Output `ParsedCredentials`:
- `videoUrl`, `audioUrl`, `hidUrl`, `microUrl?`

Logic mirror `ParseRequest(id, thinkmay)` website — scan listener URLs cho recvonly/sendonly + codec query params.

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| `worker_service.dart` | `core/api/index.ts`, `database.ts` |
| `Computer` model | `state.worker.data[address]` |
| `wait_and_claim_volume` | `StartSessionUseCase` + deploy SSE |
| `worker_refresh` | `GlobalCubit.refreshWorker()` |
| `getVmSession(computer, volume_id)` | `DashboardCubit.getActiveSession` |
| `unclaim_volume` | `CloseSessionUseCase` |
| `restart_volume` | `RestartVolumeUseCase` |

### SSE deploy

Website: Redux `popup.deployWatch` + component `deployWatch.tsx`.

Mobile: `DashboardViewModel.deployWatch` + `DeployWatchOverlay`.

Event format: text progress messages appended to list (timestamp + message).

---

## Data model: Session

```dart
Session {
  id: String,           // WebRTC token
  thinkmay: ThinkmayCreds?,
  vm: VmInfo?,          // volume name mapping
}
```

Connect flow **luôn ưu tiên fresh session**:

```dart
// dashboard_cubit.dart — openStream
// "Không dùng cached session vì tokens có thể stale"
```

Website `GetStarted` cũng gọi claim trước khi redirect remote khi cần.

---

## Liên kết

- [04-dashboard](dashboard/04-dashboard-cloud-pc.md)
- [05-remote-streaming](remote/05-remote-streaming-webrtc.md)
- [18-backend-integration](18-backend-integration.md)
