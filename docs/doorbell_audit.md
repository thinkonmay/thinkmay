# IVSHMEM Doorbell Logic Audit

This document outlines the end-to-end architecture and implementation details for the `ivshmem-doorbell` system bridging the QEMU host proxy and the Windows guest daemon.

## Architecture Overview

The `ivshmem` doorbell system uses eventfds passed over Unix domain sockets to signal events between QEMU and the host proxy. Within the Windows guest, QEMU translates these eventfds into hardware interrupts, which a custom Windows driver maps to event handles that the daemon waits on. This establishes a bidirectional, zero-copy signaling mechanism for shared memory segments, eliminating the need for CPU-intensive busy polling.

### Key Components

1. **Host Proxy (`worker/proxy`)**
   - Configures QEMU to launch with `ivshmem-doorbell` or falls back to `ivshmem-plain`.
   - If enabled, spins up `ivshmem-server` to broker `SCM_RIGHTS` Unix domain sockets.
   - Connects as an `ivshmem` client to receive vector-mapped eventfds.
   - Triggers (rings) or listens (waits) on eventfds.

2. **Windows Guest Daemon (`worker/daemon`)**
   - Discovers `ivshmem` hardware via PCI configuration.
   - Exposes shared memory mapping and doorbell interactions through the `df576976-569d-4672-95a0-f57e4ea0b210` device interface driver.
   - Rings doorbells using `IOCTL_IVSHMEM_RING_DOORBELL`.
   - Waits for interrupts by registering native Windows Events via `IOCTL_IVSHMEM_REGISTER_EVENT` and waiting on them with `WaitForSingleObject`.

## Fallback Mechanisms

If the `ivshmem-server` binary is unavailable in the environment, or if the server crashes or fails to start during VM initialization, the host proxy gracefully falls back to configuring QEMU with `ivshmem-plain`. 

When in plain mode:
- The QEMU `ivshmem-plain` device uses standard `memory-backend-file` allocations.
- The `QemuVM` state returns `false` for `DataDoorbellEnabled()` and `MediaDoorbellEnabled()`.
- The proxy skips socket connections for `ivshmem.Client`.
- Queues bypass the eventfd blocking mechanism and automatically degenerate into polling loops (`SetPopWaitFunc` and `SetPushNotifyFunc` remain unset).

## Vector Mappings

Each `ivshmem` device designates multiple vectors for multiplexed interrupts over a single PCI device.

### Data Shared Memory (4MB)
Supports 6 doorbell vectors:
* **Vector 0**: Proxy → Guest Microphone
* **Vector 1**: Proxy → Guest HID
* **Vector 2**: Proxy → Guest Session
* **Vector 3**: Guest → Proxy Microphone
* **Vector 4**: Guest → Proxy HID
* **Vector 5**: Guest → Proxy Session

### Media Shared Memory (128MB)
Supports 5 doorbell vectors (matching Sunshine streaming implementations):
* **Vector 0**: Proxy Control Wakeup
* **Vectors 1-3**: Video Streams
* **Vector 4**: Audio Stream

## Known Fixes & Edge Cases

1. **Truncated Control Messages (`MSG_CTRUNC`)**: The proxy's Unix socket client provisions a large enough `sys.CmsgSpace` buffer to accommodate the max vectors (up to 32) ensuring no eventfds are truncated during the `SCM_RIGHTS` transmission.
2. **Double Map Leaks**: File mapping strictly occurs once per segment. The `Watch()` method maps the `ivshmem.Host` into process memory securely, preventing duplicate mmap leakage that could exhaust host memory on frequent restarts.
3. **Invalid PCI Topologies**: The Windows daemon parser cleanly parses bus and device attributes, accommodating device IDs > 9 correctly without zero-truncation string errors.
