# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

Thinkmay CloudPC is a monorepo for a cloud gaming / remote Windows desktop platform. The main runtime path is: PocketBase/API and cluster orchestration in `worker/daemon`, VM launch and WebRTC/QUIC streaming in `worker/proxy`, guest capture/encode in `worker/sunshine`, browser client in `website`, and Flutter client work in `native/mobile`.

Important docs to read when touching architecture-level work:

- `docs/technical_doc.md` — backend, cluster, PocketBase schema, streaming, QEMU/KVM, and deployment architecture.
- `docs/mobile_architecture.md` and `docs/native_app.md` — Flutter client architecture and WebRTC signaling protocol.
- `docs/snapshot_protocol.md` and `docs/snapshot_implementation_plan.md` — MFS snapshot protocol and implementation checklist.
- `README.md` — high-level product/infrastructure summary.

## Common commands

Run commands from the component directory unless noted. This repo contains multiple independent modules; do not assume a root-level build covers everything.

### Daemon / PocketBase (`worker/daemon`)

```powershell
cd worker/daemon
go mod download
go build -o daemon ./cmd/
go build -o pb ./cmd/pocketbase/
go build -o mgmt ./cmd/mgmt/
```

Linux CI installs `libevdev-dev` before building daemon binaries.

Tests:

```powershell
cd worker/daemon
go test ./storage/mfs -run TestMfsSnapshot
go test ./storage/mfs -run TestMfsListSnapshots
go test ./storage/mfs -run TestMfsPruneSnapshots
go test ./storage/mfs -run TestMfsRestoreSnapshot
go test ./... -run TestDoesNotExist
```

Caveats observed on Windows: full `go test ./...` currently fails in unrelated areas because `worker/daemon/test` has mixed packages, some tests are stale against current APIs, GStreamer pkg-config dependencies may be missing, and `pocketbase` currently has an `UpdatePersona` build issue. `storage/mfs` compiles with `-run TestDoesNotExist`; its snapshot tests require a live MFS setup and hardcoded test volume data.

Regenerate daemon gRPC code after editing `worker/daemon/persistent/persistent.proto`:

```powershell
cd worker/daemon/persistent
.\gen.ps1
```

### Proxy (`worker/proxy`)

```powershell
cd worker/proxy
go mod download
go build -o proxy ./cmd/
go test ./... -run TestDoesNotExist
```

The proxy targets Linux host networking/QEMU APIs. On Windows, full package compilation can fail on Linux-only dependencies such as nftables/netlink/tap and current unrelated test/API drift.

Regenerate proxy helper protobuf code after editing `worker/proxy/helper/conductor.proto`:

```powershell
cd worker/proxy/helper
.\gen.ps1
```

### Website (`website`)

```powershell
cd website
npm install
npm run dev
npm run build
npm run lint
npm run format
```

The website is a Next.js app. Streaming client protocol code lives under `website/core/core/webrtc` and HID/input protocol code under `website/core/core/hid` and `website/core/core/models`.

### Flutter mobile app (`native/mobile`)

```powershell
cd native/mobile
flutter pub get
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test
```

There are currently no Dart tests in `native/mobile/test` or `native/mobile/integration_test`.

### Sunshine guest capture (`worker/sunshine`)

Windows CI builds Sunshine with MSYS2 MinGW, CMake, and Ninja:

```bash
cd worker/sunshine
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -G "Ninja" ..
ninja
```

Formatting helpers:

```powershell
cd worker/sunshine
npm run format
```

### Docker / compose

Root compose includes frontend and rybbit compose files plus the gateway service:

```powershell
docker compose up -d
```

Daemon README documents Docker image build/push for `pigeatgarlic/virtdaemon`, but current CI builds daemon/proxy as native binaries rather than Docker images.

## High-level architecture

### `worker/daemon`

This Go module (`github.com/thinkonmay/thinkshare-daemon`) is the control plane. `cmd/main.go` starts the worker daemon and registers the `persistent.Daemon` gRPC server. `cmd/pocketbase` starts the customized PocketBase process and connects to the local daemon gRPC address.

Key responsibilities:

- Cluster/manifest parsing from `cluster.yaml` via `cluster.NewClusterConfig`; production assets expect this under the assets path described in `utils/path` and `docs/technical_doc.md`.
- VM lifecycle orchestration in `hypervisor.go` and `session.go`.
- PocketBase custom REST routes, cron jobs, auth filtering, and record hooks in `pocketbase/`.
- Storage abstractions in `storage/`; MFS volumes use `mfsmount` and `mfsmakesnapshot`, while unified/local volumes do not implement snapshot support.
- gRPC contracts in `persistent/persistent.proto`; regenerate generated Go files whenever this changes.

The `/info` PocketBase API is the bridge between clients and physical node state. It queries daemon `Info()` and filters volumes/sessions by authenticated user before the dashboard/mobile client renders VM state.

### `worker/proxy`

This Go module (`github.com/thinkonmay/thinkremote-rtchub`) is the host-side media and VM runtime. `cmd/main.go` loads `cluster.yaml`, initializes QEMU config, starts QUIC, gRPC, TURN, and HTTP/WebRTC routes, then registers the proxy virtualization service.

Key responsibilities:

- `qemu/` launches VMs, configures PCIe/GPU passthrough, CPU pinning, TPM, public network TAP/OVS, IVSHMEM, disks, and cleanup ordering.
- `forwarder/webrtc` packetizes media with Pion WebRTC and handles RTCP/GCC feedback.
- `forwarder/quic` carries media/control streams across worker/master/peer routing paths.
- `util/memory` maps IVSHMEM media and input queues between host and guest.
- `router/` owns host networking/NAT details.

Cleanup functions are executed in reverse order by `qemu/vm.go`, which matters for disk locks, MFS snapshots, QMP shutdown, and temporary resources.

### Streaming data path

Guest Windows runs `worker/sunshine`, which captures/encodes frames and writes them into IVSHMEM. The host proxy reads IVSHMEM, wraps frames into internal samples, forwards locally or over QUIC as needed, then emits RTP through WebRTC to the browser/mobile client. RTCP feedback and control messages flow back through the same chain into IVSHMEM so Sunshine can adjust bitrate or force IDR frames.

The client protocol uses separate WebRTC connections for video, audio, HID data, and microphone. The website implementation is the reference in `website/core/core/webrtc`; Flutter mirrors it with `native/mobile/lib/core/webrtc` and HID/cursor handling in `native/mobile/lib/core`.

### `website`

Next.js app with app-router layout under `website/app`, reusable UI under `website/components`, API wrappers under `website/core/api`, and the streaming/HID client core under `website/core/core`. Package scripts are in `website/package.json`.

### `native/mobile`

Flutter app using clean architecture:

- `presentation/` for screens, widgets, routing, and blocs.
- `domain/` for models and use-case interfaces.
- `data/` for network clients, repositories, use-case implementations, and shared-preferences storage.
- `core/` for WebRTC, HID, cursor, metrics, and protocol primitives.
- `dependency_injection/` for `get_it` / `injectable` generated wiring.

Run `build_runner` after changing Freezed/JSON models or injectable registrations.

## MFS snapshot protocol status

The snapshot protocol described in `docs/snapshot_protocol.md` is mostly implemented in backend/proxy code:

- `storage.Snapshottable` and `SnapshotInfo` are in `worker/daemon/storage/virt.go`.
- MFS snapshot/list/prune/restore methods are in `worker/daemon/storage/mfs/chain.go`.
- gRPC messages/RPCs are in `worker/daemon/persistent/persistent.proto` and generated stubs.
- Daemon handlers are in `worker/daemon/snapshot.go`.
- PocketBase routes `GET /snapshots` and `POST /snapshots/restore` are registered in `worker/daemon/pocketbase/pocketbase.go`, with handlers in `jobs.go`.
- Daily cron calls `SnapshotAll` at `0 0 * * *`.
- Proxy shutdown snapshot hook is in `worker/proxy/qemu/disk.go`.

Known caveats to keep in mind before extending this feature:

- No client/mobile UI integration for `/snapshots` was found.
- PocketBase restore relies on daemon-side in-use validation rather than doing its own `/info` check.
- `SnapshotAll` snapshots local daemon volumes only; it does not fan out to all worker nodes.
- `RestoreSnapshot(snapshotName)` should validate that the name is a plain `data.<timestamp>` snapshot file before joining paths.
- Snapshot names use second precision and can collide if multiple snapshots occur in the same second.
- Docs disagree on shutdown ordering: protocol text says after lock release, while implementation snapshots before removing the lock so the MFS mount is still available and shutdown is not blocked.

## Development cautions

- This repo has checked-in generated files, submodules, and large dependency directories. Before broad edits, check `git status` and avoid touching `node_modules`, generated protobuf files, or submodule directories unless the task requires it.
- Many runtime paths assume Linux host capabilities: KVM/QEMU, VFIO, OVS/TAP, nftables/netlink, MooseFS, IVSHMEM, and GStreamer. Windows is useful for editing and some builds, but not for full runtime validation.
- For frontend/UI changes, run the relevant dev server and exercise the flow in a browser when possible. For streaming changes, type checks do not prove feature correctness; verify signaling and media behavior if an environment is available.
