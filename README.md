# Thinkmay CloudPC Platform

Welcome to the Thinkmay CloudPC Engine! This repository powers a highly optimized, dynamically scalable Virtual Machine orchestration layer tailored specifically for high-performance cloud gaming and secure distributed workspaces. 

## 📖 Complete Documentation Suite

To fully understand the orchestration, we have broken down our core operation manuals into three robust documents located inside the `docs/` folder:

1. **[Technical Architecture & Onboarding (`docs/technical_doc.md`)](./docs/technical_doc.md)**: 
   The ultimate guide for Engineers. Covers WebRTC GCC optimization, QEMU/KVM spoofing, VFIO GPU passthrough architectures, and the custom Pocketbase schemas.
   
2. **[Employee & Support Playbook (`docs/employee_doc.md`)](./docs/employee_doc.md)**:
   The ultimate guide for Customer Support and Operations. Highlights our pricing tiers, Priority Queue deployment behaviors, Database troubleshooting, and system anti-cheat capabilities to confidently resolve user tickets.
   
3. **[User-facing Guide (`docs/user_doc.md`)](./docs/user_doc.md)**:
   A fully-featured FAQ to assist our cloud-gaming customers. Explains basic "how-tos", robust streaming latency optimizations, connection diagnostics, and robust VPN-compatibility guarantees.

---

## ⚡ Core Infrastructure Feats

* **Anti-Cheat & Hardware Spoofing (`worker/proxy/qemu`)**: Our QEMU implementation completely disables hypervisor footprints and injects physical Gigabyte rack-server SMBIOS. This guarantees customers can play notoriously restrictive games (requiring Vanguard or Easy Anti-cheat) without VM detection bans.
* **Flawless Bare-Metal Framing**: We execute deep `VFIO` PCI-E GPU Passthrough accompanied by explicit `cputune` guest-to-host physical NUMA socket threading. Say goodbye to micro-stutters.
* **Isolated WebRTC Handshakes (`worker/proxy/forwarder`)**: Network architectures are physically bifurcated. Standard internet flows through OpenVSwitch (OVS). Meanwhile, our WebRTC stream connects exclusively through a 128MB Shared Memory (IVSHMEM) bridge. You can break your CloudPC's firewall or utilize thick VPNs without *ever* disconnecting from your display!
* **Over-The-Air Patches (`worker/daemon/job.go`)**: Fully orchestrated zero-downtime cluster updates. Nodes securely poll the RPC for core `virtdaemon`, `pocketbase`, and `proxy` updates. When pushed, a mathematical hash completes before actively pausing installations on machines that have a live active game session.

---

## 🚀 Quick Starts

**Developers**: Please consult `technical_doc.md` to map the Go `daemon` worker relationships alongside the Pocketbase schema architectures located in `docs/db/schema.json` before actively pushing `local_version_control_v1` patches.