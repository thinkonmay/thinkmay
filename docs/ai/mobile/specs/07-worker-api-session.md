# 07 — Worker API & Session

## Overview

Communicates with **PocketBase worker API** (`/info`, `/new`, `/close`, …) and parses **session credentials** for WebRTC.

> **Canonical doc:** [client_protocol_contract.md](../../../product/architecture/client_protocol_contract.md), [technical_doc.md](../../../product/architecture/technical_doc.md) § worker/PocketBase

Website: `core/api/index.ts` — `GetInfo`, `StartThinkmay`, `ParseRequest`, `getVmSession`.

---

## Mobile — services & models

| File | Role |
|------|------|
| `lib/data/network/worker/worker_service.dart` | REST + SSE |
| `lib/data/network/session/session_service.dart` | `parseRequest` → URLs |
| `lib/domain/models/worker/worker_models.dart` | `Computer`, `Session`, `ThinkmayCreds`, … |
| `lib/domain/models/worker/volume_status.dart` | Volume state enum |
| Use cases | `fetch_worker_info`, `start_session`, `close_session`, `restart_volume` |

### Endpoints (PocketBase custom)

Base: `Endpoint.baseUrl` = `https://saigon2.thinkmay.net`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/info` | Worker state: volumes, sessions, GPUs |
| POST | `/new` | Start VM session |
| GET | `/new/sse?id=<volumeId>` | Deploy progress events |
| POST | `/restart` | Restart session |
| DELETE | `/close` | Close session |
| DELETE | `/resource` | Deallocate volume |
| POST | `/reallocate` | Reinstall OS (+ SSE) |

Auth: Header uses `PocketBase.authStore.token` (set on `authWithPassword` / Splash `authStore.save`). `WorkerService` calls `pb.send(...)` with current token.

### WorkerService — GET /info

Returns `Computer` with:
- `volumeStatus: Map<String, VolumeStatus>`
- `sessions: List<Session>`
- Cluster address metadata

`FetchWorkerInfoUseCase` → `GlobalCubit.workerInfo`.

### StartSession — POST /new + SSE

`StartSessionUseCase` → `WorkerService.startSession`:

1. POST body `{ id: volumeId }`
2. Listen to SSE lines — callback `onStatus(message, code)`
3. Result: `Session` with `id` (VM session UUID), `thinkmay` (listener creds)

**Important:** `session.id` is used as `vmid`/`token` in WebRTC URL — **different** from `volumeId` (PocketBase volume config id).

### SessionService.parseRequest

Input:
- `sessionId` — VM session UUID
- `thinkmay` — object with `listener: string[]`
- `addrOverride` — optional host override

Output `ParsedCredentials`:
- `videoUrl`, `audioUrl`, `hidUrl`, `microUrl?`

Logic mirrors website `ParseRequest(id, thinkmay)` — scan listener URLs for recvonly/sendonly + codec query params.

---

## Website — comparison

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

Connect flow **always prefers fresh session**:

```dart
// dashboard_cubit.dart — openStream
// "Do not use cached session because tokens may be stale"
```

Website `GetStarted` also calls claim before redirecting to remote when needed.

---

## Links

- [04-dashboard](dashboard/04-dashboard-cloud-pc.md)
- [05-remote-streaming](remote/05-remote-streaming-webrtc.md)
- [18-backend-integration](18-backend-integration.md)
