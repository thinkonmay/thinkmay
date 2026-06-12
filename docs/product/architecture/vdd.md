# Virtual Display Driver — Product Requirements

Requirements for a suitable and functional virtual display driver (VDD) as **software fallback capture** when passthrough GPU + EDID dongle is unavailable.

**Implementation spec:** [thinkmay_vdd_fork_spec.md](./thinkmay_vdd_fork_spec.md)  
**Implementation plan:** [worker/vdd/docs/THINKMAY_CUSTOMIZATION_PLAN.md](../../../worker/vdd/docs/THINKMAY_CUSTOMIZATION_PLAN.md)  
**Task checklist:** [worker/vdd/docs/TASK_CHECKLIST.md](../../../worker/vdd/docs/TASK_CHECKLIST.md)  
**Capture context:** [windows_display_capture.md](./windows_display_capture.md)

## Requirements

1. **Compatible with current Parsec VDD operation model** — same Thinkmay session lifecycle (boot install, activate at fallback, `DisplaySwitch`, Sunshine capture, deactivate on close). See spec §7 for pipe + optional IOCTL migration.
2. **Refresh rates:** 60, 75, 90, 120, 144, 240 Hz (minimum set for all bundled resolutions).
3. **Aspect ratios:** broad range for desktop and **mobile clients** — 4:3, 16:9, 16:10, 21:9, **9:16 portrait**, **9:19.5 / 9:20 / 9:21 tall phone**, **3:4 / 2:3 tablet portrait** (see spec §6.3).
4. **Maximum mode:** up to **3840×2160 @ 240 Hz** (4K240); no modes above this cap (portrait **2160×3840 @ 240 Hz** is equivalent pixel load).
5. **Runtime mode control:** `worker/daemon` must change **desktop resolution and refresh rate on the fly** when the client requests it (IVSHMEM), without unplugging the virtual monitor or triggering a full driver reload.

## Priority

**Absolute highest stability** on VFIO gaming VMs. Feature requirements are satisfied only where they do not compromise stability (WARP render adapter, no HDR, single monitor, no Parsec-style ping watchdog). Details in the fork spec.

## Upstream

Fork [VirtualDrivers/Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver) (MttVDD), not Parsec VDD (proprietary, no source).
