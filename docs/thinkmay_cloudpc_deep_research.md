# ThinkMay CloudPC Deep Research Report

> Scope note: this report is based on the local ThinkMay repository at `C:\thinkmay` and the checked-out submodules available during inspection. External web research/search was unavailable in this runtime, so this document does **not** validate product claims against public websites, customer-facing materials outside the repo, or third-party benchmarks.

## Executive Summary

ThinkMay CloudPC is a cloud gaming / remote Windows desktop platform built around GPU-backed Windows virtual machines, host-side QEMU/KVM orchestration, PocketBase-backed control APIs, and a browser/mobile WebRTC client stack. The repository shows a serious implementation effort, not just a landing page: there are Go control-plane services, a WebRTC/QUIC proxy, QEMU VM launch code, Sunshine-derived guest capture code, web and Flutter clients, payment-facing website routes, storage/snapshot logic, and cluster-routing code.

The strongest repo-backed architecture signals are:

- **Control plane:** `worker/daemon` manages sessions, volumes, node state, queues, PocketBase routes, and hypervisor requests.
- **Runtime plane:** `worker/proxy` owns host-side QEMU operation, GPU/PCIe passthrough helpers, network setup, WebRTC forwarding, QUIC forwarding, TURN/STUN utilities, and shared-memory media/input transport.
- **Guest capture path:** documentation and source references describe Windows guest capture through a Sunshine-based component writing encoded media into IVSHMEM/shared memory, then the host proxy packetizes it to WebRTC RTP.
- **Client plane:** `website` is a Next.js/React app with WebRTC protocol code; `mobile` and `native/mobile` are Flutter clients with PocketBase/WebRTC-oriented dependencies and ThinkMay client code.
- **Business/application layer:** website routes and dependencies indicate payments, account/profile flows, diagnostics, storage UI, referral/reward features, and app/store-facing surfaces.

However, the repo also contains **overconfident claims** that should be treated carefully. Claims such as “up to 4K/240fps,” “zero downtime,” “complete anti-cheat bypass,” “zero-trust,” “strictly browser-based,” and strong privacy/security guarantees require qualification unless backed by production metrics, deployment evidence, legal review, and security testing. Some documentation conflicts with the implementation, especially around browser-only access versus active Flutter/native mobile clients.

## Evidence Base Inspected

Primary local sources inspected include:

- `README.md`
- `CLAUDE.md`
- `.gitmodules`
- `docs/documentation_audit.md`
- `docs/technical_doc.md`
- `docs/mobile_architecture.md`
- `docs/native_app.md`
- `docs/business_model.md`
- `docs/data_privacy.md`
- `docs/reward_mission.md`
- `docs/affiliate_program.md`
- `worker/daemon/README.md`
- `worker/proxy/README.md`
- `worker/daemon/session.go`
- `worker/daemon/daemon.go`
- `worker/daemon/hypervisor.go`
- `worker/daemon/query.go`
- `worker/daemon/pocketbase/pocketbase.go`
- `worker/daemon/pocketbase/db.go`
- `worker/daemon/pocketbase/jobs.go`
- `worker/daemon/snapshot.go`
- `worker/daemon/storage/*`
- `worker/daemon/cluster/*`
- `worker/proxy/cmd/main.go`
- `worker/proxy/qemu/*`
- `worker/proxy/forwarder/webrtc/*`
- `worker/proxy/forwarder/quic/*`
- `worker/proxy/util/turn/turn.go`
- `website/package.json`
- `website/app/**`
- `website/core/api/index.ts`
- `website/core/core/webrtc/*`
- `mobile/pubspec.yaml`
- `mobile/lib/core/thinkmay_client.dart`
- `native/mobile/pubspec.yaml`
- `native/mobile/lib/core/thinkmay_client.dart`

Submodules were present during the latest inspection, including `assets`, `gateway`, `mobile`, `native/mobile`, `website`, `worker/daemon`, `worker/proxy`, and `worker/sunshine`.

## Repository and Submodule Structure

The root repository is a monorepo-style orchestrator with multiple product/runtime submodules. `.gitmodules` maps major areas to separate `thinkonmay/*` repositories:

- `worker/daemon` -> `thinkshare-daemon`
- `worker/proxy` -> `thinkremote-rtchub`
- `worker/sunshine` -> `sunshine-sdk`
- `website` -> `landing-page-v2`
- `mobile` and `native/mobile` -> `think_may_mobile`
- `gateway` -> `global-proxy`
- `assets` -> `assets`

This split matches a product with separate concerns: control plane, media/runtime proxy, client apps, gateway routing, and static/product assets.

Approximate inspected file counts from key areas:

- `worker/daemon`: 165 files
- `worker/proxy`: 101 files
- `website`: 387 files
- `mobile`: 722 files
- `native/mobile`: 754 files
- `docs`: 19 files

## Product Model

From local docs and source, ThinkMay CloudPC appears to target:

- Cloud gaming users.
- Remote Windows desktop users.
- 3D/design workloads needing GPU acceleration.
- Mobile and browser users who want a streamed Windows session.

The product promise is a GPU-backed Windows 11 VM accessed over WebRTC with low-latency video/audio, keyboard/mouse/touch/gamepad input, optional microphone pass-through, persistent or ephemeral storage depending on plan, and payment/subscription/account flows around it.

## High-Level Architecture

A grounded architecture view:

```text
User browser / mobile client
  -> Website / Flutter app
  -> PocketBase/API control calls
  -> WebSocket WebRTC signaling
  -> Edge / gateway / proxy route
  -> worker/proxy WebRTC or QUIC forwarder
  -> host shared-memory queues
  -> Windows VM running Sunshine-derived capture/input agent
  -> QEMU/KVM VM with GPU passthrough and attached volumes
  -> worker/daemon control plane managing allocation, session state, storage, cluster routing
```

### Main Components

#### 1. Website Client (`website`)

The website is a Next.js/React application. `website/package.json` includes modern frontend dependencies such as Next.js, React, PocketBase, Supabase, Stripe, Redux Toolkit, OpenAI-related packages, Radix/HeroUI components, and WebRTC-facing application code.

Observed app routes include:

- Play/session pages: `app/[locale]/(app)/play/*`
- Payment pages: `app/[locale]/(app)/payment/*`
- Profile/settings pages
- Storage pages
- Store pages
- Diagnostics pages for gamepad, keyboard, and network
- API routes for plans, referrals, app info, feedback, currency rates, global RPC, and user/admin helpers

The website is not only marketing; it includes the operational user interface for launching and interacting with CloudPC sessions.

#### 2. Mobile / Native Mobile Clients (`mobile`, `native/mobile`)

Both `mobile` and `native/mobile` are Flutter-based client trees. Their `pubspec.yaml` files and `thinkmay_client.dart` code indicate client-side integration with ThinkMay APIs and WebRTC/mobile playback/control concepts.

This contradicts older or overly narrow documentation saying access is “strictly browser-based.” The more accurate statement is:

> ThinkMay has a browser/PWA client and active Flutter mobile client implementations. Browser/PWA may be the primary or most mature path, but the repository contains native/mobile work that should not be ignored.

#### 3. Control Plane (`worker/daemon`)

`worker/daemon` is the backend control-plane service. It manages:

- Session lifecycle.
- VM deployment requests.
- GPU/resource allocation queues.
- Storage/volume checks and attachment.
- PocketBase integration and custom API endpoints.
- Cluster/node information and routing.
- Snapshot and cleanup jobs.
- Error code ranges for frontend, server, node, streaming, VM, and external dependency failures.

The daemon README identifies it as “Virt Daemon,” with Docker/deploy notes, protobuf generation, and error-code ownership ranges. `CLAUDE.md` describes it as the Go module `github.com/thinkonmay/thinkshare-daemon`, with `cmd/main.go` starting the daemon and `cmd/pocketbase` starting a PocketBase-integrated variant.

#### 4. Runtime Proxy (`worker/proxy`)

`worker/proxy` is the host-side media/VM runtime. It handles:

- QEMU VM startup and teardown.
- Linux host networking operations.
- PCIe/GPU passthrough helpers.
- CPU pinning/tuning.
- TAP/OVS network setup.
- WebRTC packetization and signaling.
- QUIC forwarding for cross-node or edge routing.
- TURN/STUN support.
- HID/input paths.
- Shared-memory transport between guest/host.

The proxy README identifies it as a Pion WebRTC-based app and includes references to client/server tests, C-Go binding, HID adapter, RTP broadcaster/listener, gRPC/websocket signaling, config, child processes, and GStreamer pipeline tests.

#### 5. Guest Capture (`worker/sunshine`)

Docs and code references describe a Sunshine-derived guest component that captures/encodes Windows desktop frames and writes media/control data into IVSHMEM/shared memory. The host proxy then consumes these queues and sends media to the client via WebRTC.

This is architecturally important: the stream path is designed to be independent of the guest Windows network stack, so a broken guest network configuration should not necessarily break the video/control path.

## Runtime Flow: Starting a CloudPC

Based on inspected docs and code, the likely flow is:

1. User authenticates in the website/mobile client.
2. Client requests account/session/node information from PocketBase/custom API routes.
3. User starts a ThinkMay session.
4. Control plane validates ownership, plan/subscription/volume state, and requested configuration.
5. Daemon maps the request into a hypervisor/session model.
6. Global and/or local queues allocate a node/GPU.
7. Proxy/QEMU launches a Windows VM with configured CPU, RAM, volumes, GPU devices, TPM/legacy settings, VLAN/network settings, shared-memory devices, and temporary/session directories.
8. Session/token/listener information is returned to the client.
9. Client opens WebSocket signaling endpoints for video/audio/data/microphone paths.
10. WebRTC connections are established using server-provided TURN/STUN credentials.
11. Guest capture writes encoded media into shared memory.
12. Host proxy packetizes RTP and sends it over WebRTC.
13. Client input travels back over data channels into host/guest input queues.
14. RTCP/GCC feedback can trigger bitrate or keyframe controls back toward the encoder.
15. Shutdown/cleanup may snapshot, detach, release GPU, remove temporary state, and update records.

## Streaming Architecture

The repo-backed streaming design is one of the strongest parts of the system.

### WebRTC

Docs and code reference Pion WebRTC, RTP/RTCP flows, WebSocket signaling, TURN/STUN, and separate media/control paths. The client-side web code includes WebRTC modules such as:

- `website/core/core/webrtc/media.ts`
- `website/core/core/webrtc/data.ts`
- `website/core/core/webrtc/microphone.ts`

The native/mobile docs describe four independent WebRTC connections:

- Video media receive-only.
- Audio media receive-only.
- HID/data send-only.
- Microphone send-only.

This separation can simplify stream-specific behavior and reconnect logic, but it also increases signaling/session coordination complexity.

### Adaptive Bitrate and Recovery

`docs/technical_doc.md` describes:

- WebRTC as the core protocol.
- FlexFEC and NACK/RTX support.
- Google Congestion Control (GCC) for adaptive bitrate.
- Picture Loss Indication / Full Intra Request handling to force IDR/keyframe recovery.

These claims are plausible and partially supported by the proxy/WebRTC module structure, but any specific performance statement such as “4K/240fps” should remain qualified until validated with test results.

### Shared Memory / IVSHMEM

The architecture emphasizes IVSHMEM/shared-memory queues between guest and host. This provides a low-latency local bridge for:

- Encoded video frames.
- Audio packets.
- HID input.
- Microphone data.
- Encoder control messages.

The documented benefit is that video/control transport does not depend on the guest Windows TCP/IP stack. That is a credible design advantage for remote desktop resilience, especially if users install VPNs or misconfigure networking inside the VM.

### QUIC Routing

`worker/proxy/forwarder/quic` and documentation describe QUIC forwarding for internal or cross-node routing. This suggests the platform can separate:

- The node running the VM.
- The edge/gateway the user connects to.
- Internal datacenter or peer routing between them.

This supports route selection/failover claims at an architecture level, but production quality depends on deployment topology, monitoring, failover automation, and real-world latency measurements.

## VM, GPU, and Host Runtime

The platform is heavily Linux/KVM/QEMU-oriented.

`CLAUDE.md` and source inspection indicate runtime dependencies on:

- QEMU/KVM.
- VFIO/GPU passthrough.
- OVS/TAP networking.
- Linux host networking APIs.
- PCIe device management.
- TPM/legacy VM configuration.
- MooseFS or other storage mounts in some paths.
- NBD/MFS-style network disk concepts.

`worker/proxy/qemu` includes files for VM launch, network setup, PCIe, disk, manager/queue, monitor, CPU tuning, OVS, and TAP. `worker/daemon/hypervisor.go` maps persistent session models into hypervisor VM models including CPU/RAM, volumes, GPUs, VLANs, TPM/legacy settings, and shared state.

### GPU Allocation

Docs describe a two-tier queue:

- Global/master queue in daemon logic.
- Local worker queue in proxy/QEMU manager logic.

The docs also describe plan-priority behavior through preferred nodes and queue insertion differences. This should be verified carefully against exact code before making customer-facing promises about priority, because queue semantics directly affect fairness and billing expectations.

### Anti-Cheat and Hardware Spoofing

The README contains risky language around anti-cheat/hardware spoofing, including claims that QEMU implementation “completely disables” hypervisor detection and presents “flawless bare-metal” framing.

This should be rewritten. Safer, grounded phrasing:

> The host runtime includes QEMU/KVM, VFIO GPU passthrough, TPM/SMBIOS/device configuration, and other compatibility-oriented VM presentation features. Compatibility with specific games or anti-cheat systems is not guaranteed and should be validated per title/vendor policy.

Reasons:

- Anti-cheat evasion claims create legal, platform, and reputational risk.
- “Completely disables hypervisor detection” is almost never defensible.
- Some anti-cheat vendors prohibit VM/cloud execution or treat spoofing as circumvention.
- Documentation should not position the product as an anti-cheat bypass tool.

## Storage, Volumes, and Snapshots

The daemon contains storage abstractions under:

- `worker/daemon/storage/mfs`
- `worker/daemon/storage/unified`
- `worker/daemon/storage/volume`

The code and docs reference:

- Volumes.
- Network disks.
- Pool size checks.
- Snapshot behavior.
- Storage cleanup / expiry jobs.
- S3/Storj/rclone/Ludusavi-related external dependency areas.

Docs describe plan-dependent persistence:

- Trial: ephemeral, wiped after a short duration.
- Paid plans: persistent storage, wiped after subscription expiry grace period.

This is a sensitive product area. The implementation should maintain exact user-facing data retention language, because “wiped exactly after X hours/days” is a strong claim that may not hold under queue delays, failed jobs, offline nodes, clock drift, or retry behavior.

Recommended wording:

> Trial storage is intended to be ephemeral and scheduled for cleanup after the trial window. Paid storage is intended to persist while the subscription is active and may be scheduled for deletion after a documented grace period following expiry.

## Backend and Auth Model

ThinkMay uses PocketBase heavily, extended by Go code.

Docs and inspected files indicate:

- Custom routes such as `/new`, `/close`, `/restart`, `/reallocate`, `/info`, snapshot routes, and stream-session endpoints.
- Auth context usage such as `c.Auth.Id` in route handlers.
- Filtering helpers such as `filterVolume(uid)` to scope data to the owner.
- Short-lived randomized session/listener tokens for WebRTC handshakes.
- SSE or live update patterns for deployment/session status.
- Cluster orchestration using a pre-shared peer credential in some internal routes.

This supports a basic claim that backend access control is implemented in code, but “zero-trust” should be used carefully unless the project has a formal threat model, security tests, audit logs, secret rotation, mTLS or equivalent internal auth, and independent review.

## Payments, Plans, Rewards, and Business Features

The website includes payment and business-facing routes/dependencies. Local evidence includes:

- Stripe dependency in `website/package.json`.
- Payment routes for Stripe and regional/payment-provider-looking paths such as PayOS, Dana, and OVO.
- Plans API route.
- Referral API route.
- Docs for business model, rewards/missions, and affiliate program.
- Store/storage/profile/account flows.

This suggests ThinkMay is not just a technical prototype; it includes monetization surfaces. The repo inspection does not validate payment correctness, fraud handling, taxation, refunds, accounting, or production payment-provider configuration.

## Privacy and Security Review

The system handles sensitive data:

- User identities/accounts.
- Payment/subscription state.
- Remote desktop sessions.
- Potentially files stored on CloudPC volumes.
- Input events, microphone streams, and telemetry.
- Session tokens and internal cluster credentials.

Security-positive signals:

- Backend route filtering by authenticated user context is documented and partly visible in code structure.
- Short-lived randomized WebRTC session tokens are documented.
- Separate guest network and shared-memory media/control path can reduce certain lockout/failure risks.
- The code has explicit error ranges for failures across frontend, daemon, node, stream, VM, and external dependencies.

Security concerns / gaps to verify:

- Whether all PocketBase collections have correct rules, not just custom routes.
- Whether internal daemon-to-daemon credentials are rotated, scoped, and protected.
- Whether TURN credentials are short-lived and not reusable across sessions.
- Whether WebRTC tokens are single-use and invalidated reliably.
- Whether logs can leak tokens, user IDs, payment IDs, or session URLs.
- Whether snapshots/backups are encrypted and access-controlled.
- Whether storage deletion claims are auditable.
- Whether microphone permissions and capture indicators are clear to users.
- Whether Stripe/regional payment callback verification is implemented securely.
- Whether user file browsing/storage APIs prevent path traversal and cross-user reads.

Privacy docs should avoid absolute statements like “we never” or “zero access” unless the implementation, logging, backup, support, and admin tooling are all aligned.

## Documentation Quality and Mismatches

The documentation has useful technical depth, especially in `technical_doc.md`, `native_app.md`, and `CLAUDE.md`. It captures real architectural decisions: WebRTC, GCC, shared memory, QEMU, PocketBase, cluster routing, snapshots, and client protocol separation.

But the docs also have issues:

### 1. Marketing claims are stronger than evidence

Examples:

- “up to 4K/240fps” without benchmark evidence.
- “zero downtime cluster updates” without operational proof.
- “completely disables hypervisor detection” in README.
- “zero-trust” phrasing without formal security/audit evidence.

### 2. Browser-only claim conflicts with mobile apps

`technical_doc.md` says client access is strictly browser-based/PWA, while the repo includes Flutter mobile clients and native mobile docs. Update to reflect actual client strategy.

### 3. File URLs in docs

Some docs reference local `file:///c:/tm/...` links. These should be changed to repo-relative links so they work across machines and GitHub renderers.

### 4. Production readiness is unclear

The repo includes real systems code, but research could not validate:

- Deployed infrastructure.
- Real-world latency.
- Capacity.
- Payment production readiness.
- Security posture.
- Customer support operations.
- Monitoring/alerting.
- Disaster recovery.

### 5. Windows developer caveats

`CLAUDE.md` notes that full tests/builds can fail on Windows because some runtime paths assume Linux host capabilities. This is expected for QEMU/KVM/VFIO/OVS systems, but onboarding docs should make the boundary explicit: Windows can inspect/build some parts; Linux hosts are required for full runtime validation.

## Strengths

- Clear separation of control plane, runtime proxy, client apps, and gateway concepts.
- Real WebRTC implementation direction with Pion and client protocol code.
- Sophisticated low-latency design using shared memory between guest and host.
- QEMU/KVM/GPU passthrough architecture appropriate for GPU-backed remote desktop/cloud gaming.
- PocketBase integration enables fast product iteration with custom Go extensions.
- Multiple clients and diagnostics surfaces exist in the repo.
- Snapshot/storage concepts are present, not just planned in prose.
- Route/gateway/QUIC architecture suggests awareness of network topology and latency constraints.

## Risks

- Anti-cheat/hardware-spoofing messaging is legally and commercially risky.
- Performance claims need benchmark evidence.
- Storage retention/deletion claims need precise operational guarantees.
- Payment and reward systems need fraud/security review.
- PocketBase collection rules and custom routes need a comprehensive access-control audit.
- Shared-memory and C-Go paths need memory-safety and bounds-checking review.
- TURN/STUN/WebRTC signaling token lifecycle needs security testing.
- Multi-route/cluster routing increases operational complexity.
- Mobile/native clients may lag behind browser features, especially advanced WebRTC options like codec preferences, playout delay, FlexFEC negotiation, and browser-specific APIs.

## Recommended Next Actions

### Documentation fixes

1. Replace anti-cheat bypass language with compatibility-oriented VM presentation language.
2. Replace absolute performance claims with measured/qualified claims.
3. Fix local `file:///c:/tm/...` links to repo-relative paths.
4. Update “strictly browser-based” wording to mention browser/PWA plus Flutter mobile clients.
5. Add a “validated vs intended” matrix for features.
6. Add deployment assumptions: Linux host, KVM, VFIO, OVS/TAP, GPU model/driver, TURN/UDP access, storage mounts.

### Engineering validation

1. Run Linux-host integration tests for QEMU launch, GPU claim/release, volume attach/detach, and cleanup ordering.
2. Add WebRTC session lifecycle tests for token expiry, replay prevention, and reconnect behavior.
3. Benchmark 1080p/1440p/4K and 60/120/240fps separately under controlled network conditions.
4. Validate GCC/FEC/NACK/RTX behavior under packet loss, jitter, and bandwidth drop.
5. Audit PocketBase rules and custom route auth together.
6. Review payment callback verification and idempotency.
7. Test snapshot restore while sessions are active/inactive and during node failure.
8. Verify storage deletion jobs under failed-node/retry scenarios.

### Product/legal/security review

1. Avoid claiming anti-cheat bypass.
2. Publish supported/unsupported game and workload policy only after testing and legal review.
3. Tighten privacy claims around logs, support access, snapshots, backups, and payment metadata.
4. Define retention windows and deletion guarantees precisely.
5. Document user responsibilities for licensed software inside CloudPC instances.

## Bottom Line

ThinkMay CloudPC, as represented by the local repository, is a technically ambitious GPU-backed remote Windows/cloud gaming platform. Its core design—QEMU/KVM + VFIO GPU passthrough, Sunshine-style guest capture, IVSHMEM host/guest transport, Pion WebRTC forwarding, QUIC internal routing, and PocketBase-backed control APIs—is coherent and implementation-backed.

The main issue is not lack of architecture; it is claim discipline. The repository supports a strong technical story, but customer-facing documentation should distinguish implemented mechanisms from measured production guarantees. If ThinkMay tightens its docs, removes anti-cheat bypass framing, and adds benchmark/security/deployment evidence, the project will read as much more credible and lower-risk.
