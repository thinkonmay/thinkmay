# Product Docs

Use this section for product-facing and engineering-facing documentation about how Thinkmay works.

## AI / mobile implementation

- [Mobile Claude guide](../ai/mobile/CLAUDE.md) — agent commands and architecture (canonical)
- [Mobile specs](../ai/mobile/specs/) — Cubit ↔ API implementation status

## Architecture
- [Technical architecture](./architecture/technical_doc.md)
- [Client protocol contract](./architecture/client_protocol_contract.md) — canonical binary/signaling protocol across all clients (PWA as reference, mobile, desktop/QUIC)
- [Client platform divergence](./architecture/client_platform_divergence.md) — intentional differences, known bugs, and drift risks between PWA, mobile, and desktop clients
- [Client user flow contract](./architecture/client_user_flow_contract.md) — user-facing flow parity map between PWA (reference) and mobile app
- [Mobile sync checklist](./architecture/mobile_sync_checklist.md) — actionable checklist of 75 items to bring mobile app to PWA parity (25 remaining)
- [Control panel parity checklist](./architecture/control_panel_parity_checklist.md) — PWA SettingsPanel vs mobile ControlPanel (critical/medium gaps only)
- [Advanced settings parity checklist](./architecture/advanced_settings_parity_checklist.md) — PWA advance page vs mobile Advanced Settings screen
- [Mobile architecture](./architecture/mobile_architecture.md)
- [Moonlight Android HID capture](./architecture/moonlight_android_hid_capture.md) — reference analysis of how moonlight-android captures keyboard, mouse, touch, and gamepad input on Android
- [Native app architecture](./architecture/native_app.md) — Flutter streaming client feasibility analysis (pre-build)
- [Desktop connection initialization](./architecture/desktop_connection_initialization.md) — end-to-end flow from website Connect click to live QUIC session
- [Desktop client URL handler](./architecture/desktop_client_url_handler.md)
- [Desktop client launch arguments](./architecture/desktop_client_launch_arguments.md)
- [Desktop client architecture](../../desktop_client_architecture.md) — Go native client: QUIC transport, FFmpeg decode, SDL presentation, reconnect
- [Design doc](./architecture/design_doc.md)
- [Windows bundle](./architecture/windows_bundle.md)
- [Windows display & capture](./architecture/windows_display_capture.md) — passthrough GPU capture, EDID dongle migration (replacing Parsec VDD), VNC debug path

## Guides
- [User guide](./guides/user_doc.md)
- [Data privacy guide](./guides/data_privacy.md)

## Features
- [Gamification](./features/gamification.md)
- [Reward mission](./features/reward_mission.md)

## Flutter mobile app (`mobile/`)

Implementation docs live beside the Flutter repo — **product truth stays in this `docs/product/` tree**:

| Doc | Role |
|-----|------|
| [`mobile/TASK.md`](../mobile/TASK.md) | Active tasks, mock→real API checklist, Profile parity phases |
| [`mobile/specs/00-docs-hierarchy.md`](../mobile/specs/00-docs-hierarchy.md) | How mobile specs map to `docs/product/` |
| [`mobile/specs/API-COVERAGE.md`](../mobile/specs/API-COVERAGE.md) | Cubit ↔ API status |
| [`mobile/specs/README.md`](../mobile/specs/README.md) | Per-screen implementation specs |

**Route note:** PWA bottom-nav `/profile` = gamification ([gamification.md](./features/gamification.md)). PWA `/setting/profile` = account edit → mobile `/update-profile`, not the Profile tab.
