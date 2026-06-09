# CLAUDE.md — thinkmay_app (Flutter Mobile)

Guide for Claude Code when working with the Flutter client in the Thinkmay monorepo.

> **Canonical location:** `docs/ai/mobile/CLAUDE.md` (monorepo root — do not store the full copy inside the `mobile/` submodule).

## Project overview

Flutter app (Android/iOS) for Thinkmay CloudPC — manage and connect via WebRTC to a remote Windows cloud PC. Code: [`mobile/`](../../../mobile/) submodule.

Main screens: **Dashboard** → select Cloud PC → **RemoteScreen** (stream video/audio via WebRTC + HID via DataChannel).

## Work tracking

- **[`TASK.md`](./TASK.md)** — active tasks, checklist, done log
- **[`.CURSOR.md`](../.CURSOR.md)** — Cursor AI rules (monorepo)
- **[`specs/API-COVERAGE.md`](./specs/API-COVERAGE.md)** — Cubit ↔ API
- **[`specs/00-docs-hierarchy.md`](./specs/00-docs-hierarchy.md)** — doc layers; **canonical = [`../../product/`](../../product/)**

## Product docs (canonical)

| Doc | Purpose |
|-----|---------|
| [gamification.md](../../product/features/gamification.md) | Profile tab, Stars, missions |
| [mobile_sync_checklist.md](../../product/architecture/mobile_sync_checklist.md) | Parity PWA ↔ mobile |
| [client_user_flow_contract.md](../../product/architecture/client_user_flow_contract.md) | Route map |
| [client_protocol_contract.md](../../product/architecture/client_protocol_contract.md) | WebRTC/HID protocol |
| [mobile_h265_investigation.md](../../product/architecture/mobile_h265_investigation.md) | H.265 Chrome vs flutter_webrtc Android |
| [thinkmay_mobile_design.md](../../product/design/thinkmay_mobile_design.md) | Mobile UI intent |

## Common commands

```bash
cd mobile

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run --flavor dev   # or ./run_android.ps1 on Windows
flutter build apk --release
```

> No Dart tests in `mobile/test/` or `mobile/integration_test/`.  
> After changing `@freezed`, `@JsonSerializable`, or `@injectable` → re-run `build_runner`.

## Overall architecture (Clean Architecture)

```
mobile/lib/
├── main.dart
├── core/                        # WebRTC streaming engine
├── domain/                      # Models + UseCase interfaces
├── data/                        # Network, repository, storage
├── presentation/                # Screens, cubits, widgets
├── dependency_injection/
└── utils/
```

Implementation details per screen: [`specs/`](./specs/).

## Backend integration

- **PocketBase** — `GET /info`, `POST /new`, session lifecycle (`mobile/lib/data/network/`)
- **NextJS RPC** — encrypted RPC (`NextjsRpcClient`)
- **Supabase** — auth / realtime

## WebRTC Streaming Protocol

`ThinkmayClient` (`mobile/lib/core/`) manages 4 WebRTC connections: video, audio, hid, microphone.  
URLs from `SessionServiceImpl.parseRequest()`. Canonical protocol: [client_protocol_contract.md](../../product/architecture/client_protocol_contract.md).

## State management & DI

- **flutter_bloc** (Cubit) per screen
- **get_it** + **injectable** — run `build_runner` after changing annotations

## RemoteScreen

- Landscape only; WebRTC + virtual controls
- `RemoteCubit` → `StreamingManager` → `ThinkmayClient`

## Important notes

- Endpoint / keys: `mobile/lib/utils/api/endpoint.dart` — do not commit new secrets
- `flutter_screenutil` design size `375×812`
- Generated `*.freezed.dart` / `*.g.dart` are checked in — regenerate, do not edit by hand
