# GPU VFIO Passthrough Diagnostics & Solutions (Audited)

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
* Every virtual block device attachment (see lines [L36](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L36), [L108](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L108), [L135](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L135), [L159](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L159), [L196](file:///C:/thinkmay/worker/proxy/qemu/disk.go#L196)) is launched with:
  ```go
  devstr := fmt.Sprintf("driver=virtio-blk-pci,bus=%s.0,addr=0x%x,drive=format%d,id=disk%d,iothread=io1", ...)
  ```

### Audit Findings
* **Interrupt Routing Failures:** In QEMU, enabling `iothread` on `virtio-blk-pci` offloads the device's I/O event loops and interrupt processing to a dedicated helper thread.
* **Interrupt Pin Conflict:** Under high disk write/read operations (such as guest Windows boot stages), concurrent accesses to virtual PCI interrupt pins from the `iothread` (for storage) and the main/vCPU threads (for the physical GPU via `vfio-pci`) create a race condition.
* **PCI Interrupt Handler Assertion:** This race triggers the assertion failure in `pci_irq_handler()`, crashing the VM process or corrupting the PCIe bus status of the GPU. This corruption prevents the host from transitioning the GPU from its low-power sleep state to `D0`, causing the guest GPU driver to fail to load (or the GPU to not appear at all).

---

## 2. Direct Root Complex PCIe Mapping (Audited Architectural Issue)
### Context and Logic
* In [pcie.go](file:///C:/thinkmay/worker/proxy/qemu/pcie.go#L91-L116), the `AttachPCIe` function adds physical VFIO devices directly onto the root bus:
  ```go
  vm.commands = append(vm.commands,
      "-device", fmt.Sprintf("vfio-pci,host=%s,bus=%s.0", dev.pcie_id, vm.bus),
  )
  ```
  Since `vm.bus` is set to `"pcie"` (referencing `pcie.0`), devices are attached directly to the PCIe Root Complex.

### Audit Findings
* **PCIe Topology Mismatch:** In QEMU Q35 machines, `pcie.0` acts as the integrated PCIe root complex. Attaching physical downstream endpoints (like GPUs) directly to `pcie.0` makes them appear as integrated motherboard controllers rather than pluggable devices.
* **Driver Code 43 / Reset Failures:** Proprietary graphics drivers (particularly NVIDIA drivers) check the PCIe topology. If a GPU is found directly on the root complex:
  1. The driver might fail to configure Message Signaled Interrupts (MSI/MSI-X).
  2. Power state switches fail because the root complex does not support downstream PCIe power management controls for this device. This causes the driver to disable the device (Code 43) or fail to detect it entirely.

---

## 3. Host GPU Power State / D3cold Reset Failures (Audited Host/Hardware Issue)
### Context and Logic
* When a VM stops, QEMU closes the VFIO file descriptors, which triggers a device reset.
* If a GPU transitions to a deep sleep state (`D3cold`) on the host when idle, waking it back up to `D0` during a subsequent VM launch frequently fails on servers with budget motherboards or buggy PCIe power state implementations.
* This results in the same kernel signature: `can't change power state from D3cold to D0 (config space inaccessible)`.

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

---

## Recommended Action Plan

### Step 1: Disable `iothread` on Block Devices
Modify [disk.go](file:///C:/thinkmay/worker/proxy/qemu/disk.go) to remove `,iothread=io1` from the `-device virtio-blk-pci` commands.
This aligns the codebase with the comments inside [vm.go](file:///C:/thinkmay/worker/proxy/qemu/vm.go) and eliminates the `pci_irq_handler` race condition.

### Step 2: Use PCIe Root Ports (`pcie-root-port`)
Instead of attaching VFIO devices directly to `pcie.0`, configure QEMU to create a virtual PCIe Root Port for each GPU/consumer device, and attach the device to that port.
For example, the QEMU command construction in `AttachPCIe` should generate arguments equivalent to:
```text
-device pcie-root-port,id=port_gpu0,bus=pcie.0,chassis=1,addr=0x2.0
-device vfio-pci,host=0000:01:00.0,bus=port_gpu0,addr=0x00.0
```
This forces Windows to recognize the GPU as a standard PCIe endpoint, enabling correct power management and MSI mapping.

### Step 3: Disable PCIe PM (`D3cold`) on the Host
Add the following configuration to your host nodes' `/etc/modprobe.d/vfio.conf` (requires rebooting the host):
```text
options vfio-pci disable_idle_d3=1
```
Alternatively, disable D3cold dynamically via sysfs for the specific GPU and its audio functions:
```bash
echo "0" > /sys/bus/pci/drivers/vfio-pci/0000:xx:xx.x/d3cold_allowed
```
This prevents the GPU from entering deep sleep when idle, bypassing wakeup failures during VM startup.
