# QEMU VM Thread Reference

When inspecting a running Thinkmay CloudPC VM on Linux, QEMU exposes named threads under `/proc/<pid>/task/*/comm`. Thread names are enabled unconditionally on QEMU 11+ (and via `debug-threads=on` on older builds), plus kernel/KVM helpers.

Example from a 12-vCPU VM (PID 17630):

```
windows
qemu-system-x86
IO mon_iothread
CPU 0/KVM
CPU 1/KVM
...
CPU 11/KVM
vnc_worker
kvm-nx-lpage-re
iou-wrk-17630
```

## Thread overview

| Thread name | Count | Role |
|-------------|-------|------|
| `windows` | 1 | Main QEMU event loop |
| `qemu-system-x86` | 1 | Auxiliary QEMU thread (default binary name) |
| `IO mon_iothread` | 1 | QMP / monitor I/O |
| `CPU N/KVM` | N = vCPU count | Guest virtual CPUs via KVM |
| `vnc_worker` | 1 | VNC + WebSocket display server |
| `kvm-nx-lpage-re` | 0–1 | Kernel KVM NX / hugepage helper |
| `iou-wrk-<pid>` | 1+ | io_uring disk I/O worker |

## Per-thread details

### `windows`

Main QEMU thread, renamed by VM launch config:

```
-name windows,process=windows
```

Runs the central event loop: timers, signals, device coordination, and dispatch to other threads. QEMU 11+ names threads unconditionally on supported platforms; older builds used `debug-threads=on`.

Configured in `worker/proxy/qemu/vm.go`.

### `qemu-system-x86`

QEMU thread that retains the default binary-based name (Linux `comm` is limited to 15 characters). Normal and harmless — not a second VM process.

### `IO mon_iothread`

Monitor I/O thread for the QMP control socket. Handles asynchronous QMP traffic (shutdown, reset, status) so blocking monitor work stays off the main loop.

Created by `-qmp unix:<path>,server,nowait` in `worker/proxy/qemu/monitor.go`.

Thinkmay intentionally does **not** add per-device `iothread` objects (disabled due to a suspected GPU/PCIe IRQ issue), so this is typically the only dedicated QEMU I/O thread besides io_uring workers.

### `CPU N/KVM`

Virtual CPU threads — one per guest vCPU. Each runs guest code natively via KVM and traps to QEMU for emulated devices (virtio-net, TPM, etc.).

These are the performance-critical threads for cloud gaming. The proxy pins them to physical host CPUs on the GPU's NUMA node via `cputune.PinVMCpu` in `worker/proxy/qemu/vm.go`.

Default deployment uses 8 vCPUs unless overridden per session or in `cluster.yaml` (`ram` / `vcpu` with `forcehw`).

### `vnc_worker`

VNC display server thread. Serves the virtio-gpu framebuffer over VNC + WebSocket on localhost.

Configured in `worker/proxy/qemu/monitor.go`:

```
-display vnc=localhost:<port>,websocket=localhost:<wsport>
-vga virtio
```

End-user streaming normally uses **IVSHMEM → proxy → WebRTC**, not VNC. VNC is enabled for ops/debug; the proxy exposes it at `/broadcasters/vnc`.

### `kvm-nx-lpage-re`

Kernel KVM helper thread (name truncated from `kvm-nx-lpage-recovery`). Created when KVM manages NX (no-execute) semantics with large (2 MiB) pages — e.g. when a hugepage must be split for finer-grained guest memory permissions.

Common on VMs backed by hugepages (`worker/proxy/qemu/hugepages.go`). Kernel-side, not QEMU user code.

### `iou-wrk-<pid>`

io_uring worker thread for async disk I/O. `<pid>` is the QEMU process ID.

Disk backends use `aio=io_uring` in `worker/proxy/qemu/disk.go`. Handles virtio-blk read/write completion against qcow2, MFS, or NBD-backed volumes on the host, keeping disk I/O off vCPU threads.

One worker is typical; additional workers may appear under heavy parallel I/O.

## Expected thread count

For a VM with **V** vCPUs:

| Category | Threads |
|----------|---------|
| Control | 2 (`windows`, `qemu-system-x86`) |
| Monitor I/O | 1 |
| Guest vCPUs | V |
| Display | 1 |
| Disk I/O | 1+ |
| Kernel KVM | 0–1 |
| **Typical total** | **V + 5 to V + 6** |

A 12-vCPU VM therefore shows ~18 threads — normal, not a leak.

## Inspecting threads on a worker node

List thread names:

```bash
cat /proc/<qemu-pid>/task/*/comm
```

Map threads to CPU affinity (verify NUMA pinning):

```bash
for t in /proc/<qemu-pid>/task/*; do
  echo -n "$(cat $t/comm): "
  taskset -cp $(basename $t) 2>/dev/null
done
```

Find the QEMU PID for a VM:

```bash
ps aux | grep qemu-system-x86
# or match by guest name / UUID in ps output
```

## Related code

| File | Relevance |
|------|-----------|
| `worker/proxy/qemu/vm.go` | VM definition, `-name`, vCPU count, CPU pinning |
| `worker/proxy/qemu/monitor.go` | QMP, VNC display, IVSHMEM |
| `worker/proxy/qemu/disk.go` | io_uring disk backends |
| `worker/proxy/qemu/thread.go` | vCPU / I/O thread discovery for pinning |
| `worker/proxy/qemu/hugepages.go` | Guest RAM backed by hugepages |
