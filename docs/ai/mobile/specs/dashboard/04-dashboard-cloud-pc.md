# 04 — Dashboard & Cloud PC Management

## Overview

**Cloud PC** tab: display VM from `GlobalCubit.workerInfo`, power on/off/restart, deploy SSE, connect remote.

Website: `components/dashboard/GetStarted` on `/play`.

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md)

| Component | Status |
|-----------|--------|
| Worker / sessions / volume status | ✅ `GlobalCubit` ← preload `GET /info` |
| Power on/off/restart | ✅ PocketBase `/new`, `/close`, `/restart` + SSE |
| `openStream` | ✅ `StartSessionUseCase` — fresh session (new token) |
| Games carousel | ✅ `GlobalState.games` ← Supabase preload |
| Card specs (RAM/CPU/GPU/DISK) | 🔴 Hardcoded `_planSpecs` map in `dashboard_cubit.dart` |
| `shareVolume` | 🔴 TODO empty |

**Display condition:** `DashboardCubit` subscribes to `GlobalCubit.stream`. If `!fetched` → loading. New login **without** preload → dashboard may stuck loading (see [02-authentication](../auth/02-authentication.md)).

---

## Mobile

### Files

| Layer | Path |
|-------|------|
| UI | `presentation/screen/dashboard/dashboard_screen.dart` |
| Cubit | `dashboard_cubit.dart` |
| Deploy overlay | `widgets/deploy_watch_overlay.dart` |

### ViewModel flags

Built from `GlobalState`:

- `metadata` ← `configuration` (PB volumes)
- `volumeStatus` ← `workerInfo`
- `isNoSub`, `isWrongServer`, `isServerDown` — `noNode` logic + compare `subscription.cluster` with `_currentAddr()`
- `_currentAddr()` = host from `Endpoint.baseUrl` (not user-selected domain at login)

### Actions

| Action | Use case |
|--------|----------|
| `powerOnCloudPC` | `StartSessionUseCase` + SSE `onStatus` → `deployWatch` |
| `powerOffCloudPC` | `CloseSessionUseCase` |
| `restartCloudPC` | `RestartVolumeUseCase` |
| `openStream` | `StartSessionUseCase` (does not use cached session) |
| After VM ops | `GlobalCubit.refreshWorker()` |

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| `GlobalCubit` | Redux `worker`, `user.subscription` |
| `wait_and_claim_volume` | `StartSessionUseCase` |
| Deploy watch | `popup.deployWatch` |
| Connect | `constructRedirect('/remote')` |

---

## Links

- [05-remote-streaming](../remote/05-remote-streaming-webrtc.md)
- [07-worker-api-session](../07-worker-api-session.md)
- [01-app-bootstrap](../01-app-bootstrap-global-state.md)
