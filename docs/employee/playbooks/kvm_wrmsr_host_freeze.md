# KVM WRMSR Host Freeze (Intel Nodes)

Internal ops guide for a **whole-node lockup** caused by repeated `Unhandled WRMSR(0x1d9)` messages on Intel worker nodes.

## Symptom — entire physical node, not one VM

This is **not** a single-user stream problem. When it hits, the **whole worker node** goes down:

- **SSH unreachable** — the host OS stops responding to network; you cannot log in remotely.
- **All VMs on the node affected** — every CloudPC on that server freezes, not just the VM that triggered it.
- **Daemon/proxy dead** — deployments, session management, and WebRTC forwarding on that node stop.
- **Console may be unresponsive** — serial/IPMI may still work for hard reboot; SSH will not.

Recovery typically requires **out-of-band access** (IPMI, physical console, or power cycle) unless the storm subsides on its own.

`dmesg` (if you can read it afterward) floods with lines like:

```
kvm_intel: kvm [<pid>]: vcpuN, guest RIP: 0xfffff80... Unhandled WRMSR(0x1d9) = 0x2
```

Example capture: [`../../shared/assets/images/image.png`](../../shared/assets/images/image.png)

| Log field | Meaning |
| --- | --- |
| `kvm_intel` | Intel KVM on the **host** kernel |
| Multiple `<pid>` values | **Several guest VMs** on the same node all contributing to the storm |
| `vcpu0`–`vcpu7` | All vCPUs of affected VMs |
| `guest RIP: 0xfffff80...` | Windows **kernel-mode** code |
| `WRMSR(0x1d9) = 0x2` | Guest writes MSR `IA32_DEBUGCTL` with LBR (Last Branch Record) enable bit set |

One misbehaving guest can saturate shared host resources and take down **every other tenant** on that machine.

## Stack context

Thinkmay workers run **QEMU/KVM on Linux** with **Windows 11 guests** and **GPU VFIO passthrough**:

1. **worker/daemon** — deploys VMs, claims GPUs, manages volumes/sessions.
2. **worker/proxy/qemu** — launches QEMU, pins vCPUs to NUMA, attaches IVSHMEM bridges.
3. **Windows guest** — runs Sunshine for NVENC capture/encode.
4. **IVSHMEM** — video and HID bypass the guest network stack.
5. **WebRTC forwarder** — RTP to client; RTCP drives bitrate/IDR recovery.

See [Technical architecture](../../product/architecture/technical_doc.md) for the full pipeline.

## Root cause

Each `WRMSR` is a **VM exit**: the vCPU traps from guest mode into the **host** KVM hypervisor, which rejects the write and logs a warning. When Windows (or a kernel driver) retries this across many vCPUs — and multiple VMs on the same node do the same — the **physical host** is overwhelmed.

### Why the whole node dies (including SSH)

The failure happens in the **Linux host kernel**, not inside one guest's network stack:

1. **VM-exit storm** — every rejected MSR write forces a full hypervisor round-trip. With 6–8 vCPUs per VM × several VMs, the host can hit **millions of exits per second**, consuming all physical CPU cores.
2. **No CPU left for the host** — the kernel cannot schedule SSH, networking, `virtdaemon`, `proxy`, or disk I/O because hypervisor work starves everything else.
3. **`printk` flood** — each unhandled MSR emits a kernel log line. At high rates this blocks on the console lock and can trigger **soft lockups** (`watchdog: BUG: soft lockup`).
4. **Shared node, shared fate** — KVM, networking, and the daemon are **one OS instance** serving all VMs. There is no isolation boundary that keeps one guest's MSR loop from killing SSH and other tenants.

Our VM CPU profile in `worker/proxy/qemu/vm.go` contributes to the mismatch:

```
-cpu host,kvm=off,migratable=no,hv-time=on,hypervisor=off
```

- **`host`** — guest sees real CPU features, including debug/profiling MSRs.
- **`kvm=off`, `hypervisor=off`** — guest is masked as bare metal for anti-cheat evasion (see [technical_doc.md §6](../../product/architecture/technical_doc.md)).

The guest therefore behaves like physical Intel hardware and tries to enable LBR tracing. KVM does not safely virtualize that MSR write, so the guest retries and the **host OS** locks up — not merely one stream.

Typical guest-side triggers:

- Windows kernel / ETW / security subsystems
- Anti-cheat or game kernel drivers
- Boot or game-launch paths that probe CPU debug features

## Affected hardware

Primarily **Intel Xeon nodes** (`kvm_intel`), e.g. Trial/Standard tiers (Xeon 8171M). AMD EPYC nodes use `kvm_amd` with different LBR virtualization and are less likely to show this exact pattern.

## Distinguish from stream freeze

| Symptom | Scope | Cause | Layer |
| --- | --- | --- | --- |
| Video stutters 1–3s, then recovers | **One user session** | Packet loss → IDR reset | WebRTC / client |
| SSH dead, all VMs frozen, node unreachable | **Entire physical worker** | MSR VM-exit storm saturates host kernel | KVM / host OS |

If SSH to the worker fails while users report all sessions on that IP died at once, suspect this — not packet loss.

For client-side video freezes, see `idrcount` / `realfreezecount` in [user_doc.md](../../product/guides/user_doc.md).

## Mitigation (keep anti-cheat hiding)

**Do not remove `kvm=off` or `hypervisor=off`.** Those flags hide the hypervisor from CPUID and the KVM signature — required for BattlEye / EAC. SMBIOS spoofing in `vm.go` stays unchanged.

The freeze is caused by **how the host kernel handles MSR traps**, not by the anti-cheat CPU profile itself. All options below keep the guest-facing VM disguise intact.

### Recommended tier 1 — `ignore_msrs` (auto-applied by proxy)

**Status: applied automatically.** On every proxy startup (`NewQemuManager`), the worker runs `tuneKvmHost()` in `worker/proxy/qemu/kvm_tune_linux.go`, which:

1. Writes `/etc/modprobe.d/kvm.conf` with `options kvm ignore_msrs=1 report_ignored_msrs=0` (survives reboot).
2. Live-applies the same values via `/sys/module/kvm/parameters/ignore_msrs` and `report_ignored_msrs` so the fix takes effect **without** reloading the kvm module or rebooting.
3. Logs the result, e.g. `kvm host tune: kvm modprobe config written to /etc/modprobe.d/kvm.conf; kvm.ignore_msrs live-set=Y; kvm.report_ignored_msrs live-set=N`.

Requires the proxy to run as root (it already does, for VFIO/IVSHMEM). On non-Linux hosts the call is a no-op stub.

**Manual fallback** if the proxy hasn't run yet on a fresh node, or to verify:

```bash
echo "options kvm ignore_msrs=1 report_ignored_msrs=0" > /etc/modprobe.d/kvm.conf
echo Y > /sys/module/kvm/parameters/ignore_msrs
echo N > /sys/module/kvm/parameters/report_ignored_msrs
```

**Verify on a running node:**

```bash
cat /sys/module/kvm/parameters/ignore_msrs          # expect: Y
cat /sys/module/kvm/parameters/report_ignored_msrs  # expect: N
```

| What it does | Anti-cheat impact |
| --- | --- |
| Guest writes to unhandled MSRs (including `0x1d9`) are **silently ignored** — no VM exit, no `dmesg` line | **None** — `kvm=off`, `hypervisor=off`, and SMBIOS are untouched |
| Guest CPUID still reports bare-metal Intel; hypervisor bit stays clear | Anti-cheat detection paths unchanged |
| Write appears to succeed from guest's perspective (value dropped) | Drivers stop retrying → exit storm ends |

This is the standard production fix used on Proxmox/RHEL hosts with `host` CPU passthrough. It fixes the **whole-node lockup** without weakening VM hiding.

`report_ignored_msrs=0` alone is **not enough** — it only suppresses logging; the VM exit still happens. Both options are required.

### Recommended tier 2 — virtualize LBR properly (QEMU change, Intel nodes)

On kernels with **guest LBR support** (Linux ~5.11+, recent QEMU), enable vPMU so KVM handles `IA32_DEBUGCTL` instead of rejecting it.

Add to the Intel `-cpu` line in `worker/proxy/qemu/vm.go` (keep existing flags):

```
-cpu host,kvm=off,migratable=no,hv-time=on,hypervisor=off,pmu=on,lbr-fmt=<N>
```

Where `<N>` is the host's LBR format (low 6 bits of `IA32_PERF_CAPABILITIES`). Read it on the worker:

```bash
# Example — value varies by CPU generation
sudo rdmsr -p 0 0x345
# low 6 bits = lbr-fmt, e.g. 0x5 → use lbr-fmt=5
```

Or on recent QEMU, `-cpu host,migratable=no,pmu=on` may auto-match host `lbr-fmt` when the kernel supports `KVM_CAP_X86_GUEST_LBR`.

| What it does | Anti-cheat impact |
| --- | --- |
| First `WRMSR(0x1d9)` is intercepted once; KVM sets up a **guest LBR perf event** and then pass-throughs LBR MSRs | **None on hiding** — `kvm=off` / `hypervisor=off` unchanged |
| Guest gets working LBR emulation instead of a denied write loop | May look *more* like physical hardware to profiling-aware drivers |

**Caveat:** requires kernel/QEMU versions that support guest LBR on your Xeon 8171M fleet. Test on one node before fleet rollout. Can be combined with tier 1 as belt-and-suspenders.

Suggested placement: add `,pmu=on,lbr-fmt=N` only in the `"rest"` (Intel) entry in `worker/proxy/qemu/utils.go`, not the AMD `"gooxi"` board.

### Tier 3 — kernel / QEMU upgrade

Newer `kvm_intel` implements full guest LBR virtualization (`IA32_DEBUGCTL`, LBR stack MSRs) with low ongoing exit cost. If tier 2 fails at VM boot (capability mismatch), upgrading the host kernel and QEMU often unlocks it.

This does not require changing anti-cheat flags.

### Tier 4 — operational containment (while rolling out tier 1)

- Apply `ignore_msrs` to all Intel nodes **before** the next incident — no guest downtime required beyond module reload/reboot window.
- Reduce VM density on Intel Xeon nodes if storms recur before fix lands.
- Route new Performance-tier load to AMD EPYC nodes (`kvm_amd`) where this exact MSR pattern is rare.
- Keep IPMI/console access documented for hard recovery when SSH is dead.

### Do **not** do (breaks anti-cheat or doesn't fix the freeze)

| Change | Why avoid |
| --- | --- |
| Remove `kvm=off` / `hypervisor=off` | Exposes hypervisor to guest; EAC/BattlEye may flag or ban |
| Switch from `-cpu host` to `qemu64` / `Skylake-Server` | Changes CPUID fingerprint; games and anti-cheat expect host-like Intel features |
| `-cpu host,-pdcm` or stripping perf/debug CPUID bits | May stop LBR probes but makes VM look *less* like the physical Xeon you're spoofing |
| `report_ignored_msrs=0` only | Stops log spam but **VM exits continue** — node can still freeze |

## Related code and docs

- **Auto-applied fix**: `worker/proxy/qemu/kvm_tune_linux.go` (wired into `NewQemuManager` in `worker/proxy/qemu/manager.go`)
- VM CPU flags: `worker/proxy/qemu/vm.go`
- Hypervisor deep dive: [technical_doc.md §6](../../product/architecture/technical_doc.md)
- Hardware tiers: [employee_doc.md](./employee_doc.md)
