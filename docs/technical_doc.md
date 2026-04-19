# Thinkmay CloudPC - Developer Documentation

## Overview
Thinkmay CloudPC is a high-performance cloud PC service tailored for gamers and 3D designers, providing low-latency Windows 11 virtual desktop environments. Out of the box, instances support up to 4K resolution at 240fps.

## System Architecture

### Instances & OS
* **Operating System**: Windows 11
* **Hardware Tiers**:
  * **Standard Plan**: EPYC Milan CPU, 1x RTX 5060ti GPU.
  * **Performance Plan**: Intel Xeon CPU, 1x RTX 3060ti GPU.
* **Storage Persistence**:
  * *Trial Plan*: Ephemeral. Data is wiped exactly 3 hours after creation.
  * *Standard/Performance Plans*: Persistent storage. Data is automatically wiped 2 days after the subscription expires.

### Streaming & Network
* **Protocol**: WebRTC is the core streaming protocol, chosen for real-time, low-latency delivery. Supports FlexFEC and NACK + RTX.
* **Congestion Control**: Uses Google Congestion Control (GCC) for adaptive bitrate.
* **Routing Strategy**: Implements multi-routing where users can manually choose their ingress route independently of the server's region. (e.g., A user in Hanoi connecting to a HCM server can route through Hai Phong into our internal backbone). This manual selection doubles as a user-driven failover mechanism.

### Video & Input
* **Codecs & Hardware Acceleration**: GPU accelerated H.264 / H.265 (HEVC).
* **Clipboard Sync**: Text copy/paste between local and remote is supported. File drag-and-drop is currently unsupported.
* **Responsive Inputs**: Full Touch/Multi-Touch, Gamepad, Virtual Gamepad (mobile), and Microphone pass-through. No multi-monitor support.

### Auth & Infrastructure
* **Authentication Services**: Email/Password, Google OAuth2, Email OTP.
* **Edge Locations**: Ho Chi Minh City (HCM) and Hai Phong (HP).
* **Boot lifecycle**: Provisioning and OS boot typically take 2-5 minutes but can vary under high load or due to GPU recovery mechanisms.
* **Client access**: Strictly browser-based. PWA (Add to Homescreen) behavior is the expected path for mobile client native feel.

## Codebase Onboarding Guide (For New Engineers)

Welcome to the Thinkmay CloudPC backend! If you are getting up to speed, focus your attention on the three core pillars of the backend architecture listed below:

### 1. Streaming Logic (`worker\proxy\forwarder\webrtc`)
* **What it does**: This module acts as the WebRTC gateway, responsible for transmitting the actual video and audio data to the client's browser.
* **Key Components**: 
  * `forwarder.go`: Manages the RTP/RTCP packet flow. This is where advanced streaming features live, such as **FlexFEC** (Forward Error Correction) and **Google Congestion Control** (GCC).
  * **Optimization Flow**: GCC adaptively tracks available network bandwidth. When a `bitrate_change` event triggers, the module commands the video encoder to scale down its output to prevent stuttering. If a packet loss reaches an unrecoverable limit, the module catches `PictureLossIndication` or `FullIntraRequest` from the RTCP channel and enforces an `IDR` frame (full frame reset) to unfreeze the client's video.

### 2. Backend & Database Logic (`worker\daemon\pocketbase`)
* **What it does**: Thinkmay uses Pocketbase as a customized backend as a service, extending it heavily via Golang to orchestrate user authorizations, sessions, and machine allocations.
* **Key Components**:
  * `pocketbase.go`: Bootstraps the DB and registers custom REST endpoints (`/new`, `/close`, `/restart`, `/reallocate`). It runs critical **Cron jobs** for reclaiming inactive VM storage, expiring trial buckets, and keeping sessions alive via Ping mechanisms.
  * **Event Hooks**: Pay attention to the `OnRecordCreateRequest` webhooks. When users or operations request a new volume/bucket in the database, these hooks automatically intercept the database write to trigger actual allocation logic in the hypervisor layer.
  * `db.go`: Houses the API endpoints managing active WebRTC stream sessions and tracks live Client states synchronized via Server-Sent Events (SSE).
  * **Access Control & Security Models**: Zero-trust policies are rigorously enforced here. Endpoints like `/new` explicitly extract the user's context via `c.Auth.Id`. Functions such as `filterVolume(uid)` bind database queries exclusively to the invoker's ID, structurally preventing users from booting or interfacing with CloudPCs they do not own. Streaming session handshakes emit a randomized UUID (`randid`) mapped cleanly for only a 5-second lifetime intercept, killing the link rapidly to neutralize interception vectors. Internal daemon-to-daemon cluster routes heavily rely on a `p2pcred` pre-shared environment key for secure cluster orchestration.

### 3. Infrastructure Logic (`worker\daemon\hypervisor.go`)
* **What it does**: The Hypervisor module translates instructions from Pocketbase and directly interacts with the cluster nodes to deploy Virtual Machines, assign GPUs, and attach storage.
* **Key Components**:
  * `deployVM` and deployment methods: Orchestrates VM boot sequencing. It parses the hardware limits (vCPU / RAM targets) from incoming configurations. 
  * **Resource Claiming**: Before spinning up a Windows 11 VM, the code claims an available GPU (`ClaimGPU`) using an internal queue system. If a requested storage volume doesn't exist locally, it negotiates adding a "Network Disk" (NDisk) so the remote node can serve the volume via NBD/MFS.

#### Deep Dive: Deployment Queues & Plan Priorities
The platform operates on a two-tier queuing system to manage machine availability correctly and elegantly enforce subscription tiers.
* **Master Node / Global Queue** (`globalQueue` in `daemon/hypervisor.go`): The central master tracks all worker nodes and determines where a deployment occurs based on available GPUs.
  * **Priority Logic**: Subscriptions dictate deployment priority through the `pref_node` parameters. The **Standard Plan** / Trial plans trigger standard deployment, placing the user at the back of the FIFO queue (`queue.AddTail`). The **Performance Plan** configurations specify a preferred node. When `preferred_nodes` exist, the system overrides FIFO by injecting the user directly to the *front* of the global queue (`queue.AddHead`), giving them supreme priority over standard traffic.
* **Worker Node / Local Queue** (`ClaimGPU` in `proxy/qemu/manager.go`): Once routed to the proper node, the deployment enters a worker-specific queue (`LocalDeployQueue`). It uses a strict FIFO structure where users effectively wait for local hardware to safely spin down existing sessions before claiming an available PCI-E GPU for QEMU passthrough (`takeGPU`).

#### Hardware Bridges & Network Isolation
The architecture treats a VM's internet access and its proxy video transmission as two independent, physically isolated pathways to guarantee unmatched resilience.
* **Public Network (Internet)**: Standard internet outbound traffic utilizes paravirtualized network drivers. `EnableQPublicNet` constructs `virtio-net-pci` devices and binds them to local Host `tap` interfaces before adding them to an OpenVSwitch (OVS) bridge spanning the targeted VLAN schema. 
* **Streaming Network (IVSHMEM)**: Critically, the WebRTC streaming agent does **NOT** use TCP/IP inside the guest OS. Instead, it interacts directly with custom Host-to-Guest Shared Memory (IVSHMEM) arrays (`EnableShmem`). The proxy maps a 128MB chunk for video rendering and a 4MB chunk for mouse/keyboard inputs. 
This physical memory bridge inherently bypasses the guest's Windows network stack. Consequently, users can install restrictive VPNs or entirely mangle their virtual IP routing tables without disrupting or locking themselves out of the video feed.

### 4. Volume Configurations API
The VM's hardware limits and features are controlled by a JSON payload stored in the `configuration` column of the `volumes` collection in Pocketbase. 

When a volume boots, Pocketbase parses this JSON string into a `configuration` struct overriding default values:
* `Template` / `Transient`: Base OS image, and whether disk writes are ephemeral (discarded on shutdown).
* `TPM` / `Extend`: Virtual hardware toggles for Windows 11 compatibility and secondary displays.
* `DisableGPU` / `Headless` / `MCP`: Bypasses GPU allocation, disables remote VNC UI listeners, or exposes Model Context Protocol external ports.
* `PrefNodes` / `Vlans` / `Ports` / `MAC`: Controls Node-priority Queue overrides (`queue.AddHead`), VLAN routing, and network bridging settings.

To apply these programmatically via your backend clients, simply pass a stringified JSON object containing these keys into the `configuration` property when creating or updating a `volumes` record through the Pocketbase REST API.

### 5. Database Schema Structure (Pocketbase)
The system models its data using Pocketbase's collection architecture. Development revolves around interacting with these distinct categories:

**Core & Auth**
* `users`: The standard auth collection. Enhanced with custom `metadata` (JSON) and OTP settings.
* `_authOrigins`, `_externalAuths`, `_mfas`, `_otps`: Internal collections managing Google OAuth2 logic, multi-factor, and One-Time-Password handshakes.

**Infrastructure Provisioning**
* `volumes`: Links a `user` relation to a generic VM disk's `local_id` and the JSON `configuration` struct highlighted above.
* `buckets`: Network storage bounds linked to users, complete with a strict `size` quota.
* `template`: Defines the base Machine images. Combines a string `name` (e.g., "win11.template") with baseline default `configuration` JSONs limits.
* `binaries`: Capable of hosting up to 5GB files. Distributes core utilities and heavy OS patches directly to decentralized nodes.

**Application & User State**
* `sessions`: Stores transient streaming statuses under `internal` (JSON) to track active P2P/WebRTC handshakes and connections.
* `setting` & `persona`: Syncs client-side user UI preferences (`setting`) alongside background-computed User Profiles and behavior Recommendations (`persona`).
* `app_access` & `llmModels`: Usage metering records heavily tracking how a `user` leverages integrated internal apps or LLM tools (`model`, `prompt`, `history`, `usage`). 
* `mail`: A centralized backend ledger storing system-generated payloads. Contains columns like `finalHTML`, `cta`, `errors`, and `sents`, enabling a robust historical audit of system notifications.

### 6. Hypervisor Architecture Deep Dive (QEMU/KVM)
The cluster utilizes a highly modified QEMU/KVM stack natively integrated using Go wrappers to guarantee maximum cloud gaming performance.
* **TPM & Anti-Cheat Evasion (VM Hiding)**: Standard enterprise VMs are rapidly flagged and banned by gaming anti-cheat engines (e.g., Vanguard, BattlEye). To bypass architectural detection, the `vm.go` configuration acts to heavily spoof the hardware. The code strips KVM virtualization flags (`hypervisor=off`, `kvm=off`) and injects counterfeit SMBIOS hardware signatures masking the machine strictly as a physical generic Gigabyte rack server (`vendor=GIGABYTE, product=G292-Z20-00`). A software TPM 2.0 object is attached to ensure strict Windows 11 compliance.
* **GPU VFIO Passthrough**: Found in `pcie.go`, graphic cards bypass OS virtualization completely via PCI-E passthrough (`vfio-pci`). The system iterates through the Host's `/sys/bus/pci/drivers/vfio-pci` directory to map physical graphical nodes (and their internal consumers like GPU audio interfaces) dynamically into the Windows OS.
* **Hardware CPU & NUMA Pinning**: To eliminate cache-level micro-stutters during heavy gaming, the hypervisor queries the Host physical topology to locate the exact NUMA node the claimed GPU belongs to (`numa_node`). It then actively pins the guest's `vCPUs` to align precisely parallel with the physical CPU threads handling that PCI-E lane using `cputune`.
* **Dynamic Storage Pools**: Traced within `disk.go`, user data sets aren't mapped as standard virtual SATA drives. Instead, they are paravirtualized utilizing `virtio-blk-pci` and `io_uring`. Depending on network layouts, routing attaches either via localized Network Block Devices (`nbd`), distributed MooseFS mounts (`mfsmount`), or localized layered `qcow2` clone images.

### 7. Over-The-Air (OTA) Software Updates (`local_version_control_v1`)
The daemon utilizes a self-updating mechanism in `job.go` (`checkForSoftwareUpdates`) that ensures worker nodes stay synchronized with the global cluster version without requiring manual intervention.
* **Component Versioning**: Updates are structured across four independent core layers: the frontend `App`, the `Pocketbase` database backend, the core `virtdaemon` orchestrator, and the WebRTC `proxy` stream layer.
* **RPC Fetching & Hash Validation**: The daemon securely pings the Global Supabase backend using the `local_version_control_v1` Remote Procedure Call (RPC) to pull authoritative binary URLs and expected MD5 validation hashes. If the local hash differentiates, the payload is downloaded to a hidden temporary partition and MD5 validated before an atomic binary `mv` swap occurs, physically eliminating risks of corrupted or intercepted OS package deployments.
* **Zero-Downtime Strategy**: Software patching aggressively respects currently live sessions (`has_session()` flags). The updater loops forcefully pause their `systemctl restart` executions if an active user CloudPC session or queued hardware deployment is detected, ensuring strict service uptime and prioritizing active gaming experiences until the local hardware spins down fully.

### 8. Deployment & CI/CD Pipelines
The software relies on extreme end-to-end continuous integration entirely managed within GitHub Actions (`.github/workflows/`), pushing code from repository commits directly into node orchestration clusters.
* **Linux Worker Pipeline (`linux.yml`)**: On pushes to `master`, the runner compiles Go applications natively (`proxy`, `virtdaemon`, `mgmt`, `pb`) and runs customized localized Docker builds simulating hypervisor configurations (`Dockerfile.qemu22` & `Dockerfile.qemu24`).
* **Windows Pipeline (`window.yml`)**: Uses an `msys2` Ninja build loop to compile native Windows dependencies like the display-capture elements (`sunshine.exe`). All packages and external firmware arrays (`ivshmem` setups) are zipped before being statically pushed through a PowerShell NSIS installer builder (`makensis`).
* **Direct Database Injection**: The absolute magic of the project unfolds at the "Publish" GitHub stages. Once CI compilers generate `.exe` or `linux.zip` artifacts, the GitHub runner calculates a local MD5 Checksum. Using automated cURLs, the runner dynamically POSTs the artifact package and the `md5sum` directly into the live production Pocketbase database `binaries` collection. This single action inherently triggers the `local_version_control_v1` OTA hooks (mentioned above) on all nodes across the world simultaneously rolling out the update instantly.

### 9. Advanced Streaming Variables & WebRTC Configs
Under the hood, the CloudPC engine exposes several deep-level frontend WebRTC flags (`setting/index.tsx`) that directly hook into the Go-based WebRTC Session interceptors (`worker/proxy/forwarder/webrtc/forwarder.go`).
* **Google Congestion Control (GCC) & Bitrate**: The frontend provides a `min_bitrate` and `max_bitrate` array. When configured, the Go WebRTC stack initializes `cc.NewInterceptor` defining the `BandwidthEstimator`. The backend dynamically sweeps the backend video encoder (NVENC or x264) bitrate on the fly based on realtime network packet conditions bounded perfectly by the limits the user explicitly set.
* **Forward Error Correction (FlexFEC-03)**: Handled deeply in `webrtc.ConfigureFlexFEC03`, the stream injects redundant parity packets alongside the video payloads. This allows browsers to recover lost `h264` chunks immediately upon corruption without forcing costly Network Acknowledgment (NACK) re-transmission delays, keeping streams smooth on unstable Wifi.
* **HQ Mode Presets**: The frontend React app features a single-click "HQ vs High Stability" toggle. Technically, this toggle merely manipulates the local UI `framerate` state, pushing the hardware cap to 120 FPS vs dropping to 60 FPS natively.
* **Codec Enforcement**: When the user switches between `H264`, `H265`, or `AV1`, the WebRTC server destructs and restarts the internal payloaders (`&codecs.H265Payloader{}`) routing traffic utilizing explicitly modified SDP parameters.
