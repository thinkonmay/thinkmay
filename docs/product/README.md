# Product Docs

Use this section for product-facing and engineering-facing documentation about how Thinkmay works.

## Architecture
- [Technical architecture](./architecture/technical_doc.md)
- [Client protocol contract](./architecture/client_protocol_contract.md) — canonical binary/signaling protocol across all clients (PWA as reference, mobile, desktop/QUIC)
- [Client platform divergence](./architecture/client_platform_divergence.md) — intentional differences, known bugs, and drift risks between PWA, mobile, and desktop clients
- [Client user flow contract](./architecture/client_user_flow_contract.md) — user-facing flow parity map between PWA (reference) and mobile app
- [Mobile sync checklist](./architecture/mobile_sync_checklist.md) — actionable checklist of 75 items to bring mobile app to PWA parity (25 remaining)
- [Mobile architecture](./architecture/mobile_architecture.md)
- [Native app architecture](./architecture/native_app.md) — Flutter streaming client feasibility analysis (pre-build)
- [Desktop connection initialization](./architecture/desktop_connection_initialization.md) — end-to-end flow from website Connect click to live QUIC session
- [Desktop client URL handler](./architecture/desktop_client_url_handler.md)
- [Desktop client launch arguments](./architecture/desktop_client_launch_arguments.md)
- [Desktop client architecture](../../desktop_client_architecture.md) — Go native client: QUIC transport, FFmpeg decode, SDL presentation, reconnect
- [Design doc](./architecture/design_doc.md)
- [Windows bundle](./architecture/windows_bundle.md)

## Guides
- [User guide](./guides/user_doc.md)
- [Data privacy guide](./guides/data_privacy.md)

## Features
- [Gamification](./features/gamification.md)
- [Reward mission](./features/reward_mission.md)
