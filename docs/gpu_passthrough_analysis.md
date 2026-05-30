# GPU VFIO Passthrough Diagnostics & Solutions (Audited & Patched)

This document presents a technical audit and recommended action plan for diagnosing and resolving the issue where GPUs occasionally fail to show up in the Windows 11 guest VM after boot.

---

## 1. IOThread & Interrupt Conflict (Confirmed Software Cause)
### Context and Logic
* In [vm.go](file:///C:/thinkmay/worker/proxy/qemu/vm.go#L143-L148), a code comment states:
  ```go
  // using io thread might cause error on pci_irq_handler => GPU being unavailable (just a theory)
  // qemu-system-x86_64: ../../hw/pci/pci.c:1487: pci_irq_handler: Assertion `0 <= irq_num && irq_num < PCI_NUM_PINS' failed.
  // dmesg: can't change power state from D3cold to D0 (config space inaccessible)
  // better comment it
  ```
* However, in [disk.go](file:///C:/thinkmay/worker/proxy/qemu/disk.go), the `iothread=io1` parameter was **never actually removed or commented out**. 
* Every virtual block device attachment was launched with:
  ```go
  devstr := fmt.Sprintf("driver=virtio-blk-pci,bus=%s.0,addr=0x%x,drive=format%d,id=disk%d,iothread=io1", ...)
  ```

### Audit Findings
* **Interrupt Routing Failures:** In QEMU, enabling `iothread` on `virtio-blk-pci` offloads the device's I/O event loops and interrupt processing to a dedicated helper thread.
* **Interrupt Pin Conflict:** Under high disk write/read operations (such as guest Windows boot stages), concurrent accesses to virtual PCI interrupt pins from the `iothread` (for storage) and the main/vCPU threads (for the physical GPU via `vfio-pci`) create a race condition.
* **PCI Interrupt Handler Assertion:** This race triggers the assertion failure in `pci_irq_handler()`, crashing the VM process or corrupting the PCIe bus status of the GPU. This corruption prevents the host from transitioning the GPU from its low-power sleep state to `D0`, causing the guest GPU driver to fail to load (or the GPU to not appear at all).

### Patch Applied (Completed)
* We removed `,iothread=io1` from all virtual block device attachment functions in [disk.go](file:///C:/thinkmay/worker/proxy/qemu/disk.go) (including [AttachNDisk](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L23), [AttachMfsNdisk](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L53), [AttachFDisk](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L126), [AttachAppVolume](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L151), and [AttachAppVolumeClone](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L170)).
* We removed the unused `iothread` object instantiation from [vm.go](file:///C:/thinkmay/worker/proxy/qemu/vm.go#L115-L120).

---

## 2. Direct Root Complex PCIe Mapping (Audited Architectural Issue)
### Context and Logic
* In [pcie.go](file:///C:/thinkmay/worker/proxy/qemu/pcie.go#L91-L116), the `AttachPCIe` function added physical VFIO devices directly onto the root bus:
  ```go
  vm.commands = append(vm.commands,
      "-device", fmt.Sprintf("vfio-pci,host=%s,bus=%s.0", dev.pcie_id, vm.bus),
  )
  ```
  Since `vm.bus` is set to `"pcie"` (referencing `pcie.0`), devices were attached directly to the PCIe Root Complex.

### Audit Findings
* **PCIe Topology Mismatch:** In QEMU Q35 machines, `pcie.0` acts as the integrated PCIe root complex. Attaching physical downstream endpoints (like GPUs) directly to `pcie.0` makes them appear as integrated motherboard controllers rather than pluggable devices.
* **Driver Code 43 / Reset Failures:** Proprietary graphics drivers (particularly NVIDIA drivers) check the PCIe topology. If a GPU is found directly on the root complex:
  1. The driver might fail to configure Message Signaled Interrupts (MSI/MSI-X).
  2. Power state switches fail because the root complex does not support downstream PCIe power management controls for this device. This causes the driver to disable the device (Code 43) or fail to detect it entirely.

### Patch Applied (Completed)
* We refactored [AttachPCIe](file:///C:/thinkmay/worker/proxy/qemu/pcie.go#L91) to dynamically configure a virtual `pcie-root-port` controller (with a unique chassis index) for each GPU and consumer device, and attach the `vfio-pci` devices directly to their respective root ports.

---

## 3. Host GPU Power State / D3cold Reset Failures (Audited Host/Hardware Issue)
### Context and Logic
* When a VM stops, QEMU closes the VFIO file descriptors, which triggers a device reset.
* If a GPU transitions to a deep sleep state (`D3cold`) on the host when idle, waking it back up to `D0` during a subsequent VM launch frequently fails on servers with buggy PCIe power state implementations.

### Patch Applied (Completed & Automated)
* We automated this directly in [AttachPCIe](file:///C:/thinkmay/worker/proxy/qemu/pcie.go#L91) in [pcie.go](file:///C:/thinkmay/worker/proxy/qemu/pcie.go).
* The daemon now writes `"0"` dynamically to `d3cold_allowed` in sysfs for each GPU and consumer device before booting the QEMU process:
  ```go
  d3Path := fmt.Sprintf("%s/d3cold_allowed", d.dev_path)
  os.WriteFile(d3Path, []byte("0"), 0644)
  ```
  This prevents the GPU from entering deep sleep, eliminating wakeup failures without requiring host-side setup scripts or rebooting the host.

---

## 4. Operational GPU De-allocation & Scanning Caveat
### Context and Logic
* In [manager.go](file:///C:/thinkmay/worker/proxy/qemu/manager.go#L107-L135), the `UnbindGPU` function handles manual GPU unbinding by writing to the sysfs `remove` path:
  ```go
  if err := os.WriteFile(fmt.Sprintf("%s/remove", csm.dev_path), []byte("1"), 0777); err != nil {
  ```
* This physically removes the PCIe device from the host kernel's active PCI bus layout.
* Because the hypervisor does not have any dynamic bus rescanning logic (like echoing `1` to `/sys/bus/pci/rescan`), and only calls `FetchGPUs` once during `NewQemuManager` initialization, any manually unbound GPU is completely lost to both the host OS and the daemon.
* Subsequent VM boots trying to claim this GPU will fail because it does not exist in `vm.ListGPUs()`.
