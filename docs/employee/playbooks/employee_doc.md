# Thinkmay CloudPC - Internal Employee Playbook

## Welcome

This document is for Thinkmay employees (Sales, Support, Marketing, and Operations). It provides a high-level overview of our cloud computer service to help you sell and support the product effectively.

## Our Target Audience

Our primary users are **Gamers** and **3D Designers** who require high-performance, GPU-accelerated computing without the upfront cost of expensive local hardware.

## Subscriptions & Hardware Privileges Matrix

We run a subscription-based tiering system. When debugging user accounts or explaining plans, reference these exact Database constraints globally pushed across the Daemon configurations:

1. **Hour1 (Free Trial Tier)**:
   * **Duration**: 3 hours.
   * **Hardware**: Intel Xeon 8171M (6 Cores), RTX 3060Ti (8GB), 16GB DDR4 RAM.
   * **Configuration (`transient: true`)**: These users are severely restricted. Explain that they DO NOT save data. Furthermore, their `configuration` strictly injects `"timeout": 30`, meaning the `jobs.go` daemon intrinsically terminates their container if they are away for 30 minutes!
2. **Month1 (Standard Plan)**:
   * **Duration**: 120 hours/month.
   * **Hardware**: Intel Xeon 8171M (6 Cores), RTX 3060Ti (8GB), 16GB DDR4 RAM.
   * **Configuration (`transient: null`)**: Grants persistent `.raw` user volumes isolated on stable disks (200GB allocation limit). Generous application allowances (20 total) and 100K LLM tokens.
3. **Month2 (Premium Performance Plan)**:
   * **Duration**: 360 hours/month.
   * **Hardware**: Heavy-duty AMD EPYC Milan-X (14 Cores), RTX 5060Ti (16GB), 24GB DDR4 RAM! Enormous 400GB Disk quota.
   * **Configuration (`pref_nodes`)**: *A crucial operational note!* This plan uniquely injects the strict array `pref_nodes: ["10.30.30.41", ...]`. This inherently overrides the data center Load Balancers completely bypassing generic FIFO queues and routes these users straight into private VIP priority node channels ensuring zero boot latency during peak traffic!

*Note: For all paid persistent plans, user data is securely wiped exactly 2 days after a subscription expires to free up cluster capacity.*

## Key Selling Points & Capabilities

* **Incredible Performance**: Smooth streaming up to 4K resolution at an ultra-fast 240fps (dictated by the user's local display limits).
* **Zero Installation**: Entirely browser-based. Users can add our service to their mobile home screen (PWA) to make it feel like a native application.
* **Reliability via Multi-Routing**: If a user experiences lag, they can manually change their networking 'route' directly through our interface to hit a different backbone entry point, avoiding local ISP congestion.
* **Peripheral Support**: Microphones, Gamepads, and Virtual Mobile Gamepads are fully supported. Text copy/paste works seamlessly between local and CloudPC.
* **Supreme Deployment Priority**: Customers on the Performance Plan automatically bypass the standard server wait line (FIFO). During peak times, the backend queue places Performance users at the absolute front of the line, immediately granting them hardware access and drastically minimizing their boot wait times compared to Standard or Trial users.
* **Guaranteed Privacy & Zero-Trust Security**: Backend endpoints strictly bind deployment requests to the invoking user's unique authenticated ID. Streaming connection links are given a 5-second expiration to prevent cross-session hijacking. It is technically and structurally impossible for a user to boot up, access, or peek into the CloudPC instance of another customer.
* **Stream & Network Isolation (VPN Safe)**: The video stream is completely isolated from the Windows networking using a physical hardware memory bridge. A customer can install a corporate VPN inside their CloudPC or tinker with firewalls securely without accidentally disconnecting or locking themselves out of the display stream.
* **Anti-Cheat & Bare-Metal Compatibility**: Our hypervisor extensively masks Virtual Machine footprint signals. For paying gaming clientele, their CloudPC reads and functions nearly identically to a physical gaming rig. This ensures normal online video game anti-cheats (like Easy Anti-Cheat or BattlEye) run flawlessly without flagging the user. *However, Support must advise users that deeply rigid Ring-0 Anti-Cheats (specifically Riot Vanguard / Valorant) will fundamentally refuse to boot on our hypervisors.*

## How the Video Stream Works (Under the Hood)

If a customer asks how we achieve such low latency, or if you are debugging a profound stream freeze, here is the exact life cycle of a single frame of video:

1. **Video Capture (Sunshine)**: Inside the user's CloudPC, our custom software (`Sunshine`) captures the game screen physically off the GPU up to 240 times a second and compresses it into a tiny video frame.
2. **The Memory Bridge (IVSHMEM)**: Instead of sending this frame out through the Windows network card (which adds lag), Sunshine dumps the frame directly into a shared physical hardware memory stick called the **IVSHMEM**.
3. **The Proxy Forwarder**: The host data-center server reads that memory stick instantly on the other side. Our Go WebRTC Forwarder chops that frame into tiny network packets (RTP) and shoots it over the internet directly to the user's Web Browser.
4. **Auto-Recovery**: If a user's home Wi-Fi drops some packets, their browser complains back to the server (via RTCP). Our WebRTC forwarder catches this and writes a "Panic/IDR" or "Lower Bitrate" command backwards through the IVSHMEM memory stick. Sunshine reads that, drops the game's streaming resolution immediately, and forces an instant full-screen refresh (IDR frame) to unfreeze the user's screen in milliseconds!

## How the Personal Cloud Storage Works (Operations Guide)

* **Decentralized Backends (Storj)**: Instead of costly AWS S3 buckets natively tied to servers, user files uniquely save across the distributed **Storj** decentralized network! 
* **Zero-Trust Login Mounts**: When a user hits "Power On", the Proxy Backend secretively generates an "Ephemeral Connection Token" natively off their ID. This token completely automatically mounts their designated hardware bucket safely inside the Windows Drive ecosystem, guaranteeing secure zero-configuration mapping without exposing passwords.
* **Direct Browser Downloading (307 Redirects)**: If a user executes a file download off the Web Dashboard's Storage Tab, they aren't actively downloading *through* our daemon servers (which would lethally choke our stream bandwidth)! The internal Go engine rapidly calculates an isolated Storj `DownloadableURL` and HTTP **307 Redirects** the request out! This physically routes their multi-gigabyte traffic directly onto the local CDN Edge layer gracefully.

## Need to Know (Support & Ops)

* **Database Troubleshooting**: If a customer reports missing data, or an inability to log in, immediately consult the `pocketbase` backend database:
  * Check the `volumes` table to verify if their core OS image still exists. Modifying the JSON `configuration` column heavily dictates whether they spawn headless or bypass GPUs.
  * Check the `sessions` table to review real-time active streaming handshakes, or forcibly kill an active session.
  * Look into the `app_access` usage analytics rows if someone contests a rate limit block on internal LLM services.
* **Automated Zero-Downtime Patching (`local_version_control_v1`)**: Operations personnel never need to SSH into individual cluster nodes to push software updates! Worker nodes automatically poll the Global Database daily to check for remote patches. If a core update is found, the script mathematically hashes the binary natively, swaps files, and performs rolling service restarts. Critically, nodes will **pause** their patch restarts dynamically if a customer session is actively using the machine, guaranteeing zero game interruptions or unannounced downtime for your users!
* **Boot Times**: When a customer starts their CloudPC, it takes between 2 to 5 minutes to boot Windows 11. Heavy server load or GPU checks may extend this.
* **Authentication**: Customers can log in via Google OAuth2, Email/Password, or Email OTP.
* **Customer Support Channels**: All official technical support is handled via **Email** and **Discord**.
* **Data Privacy & Analytics (Rybbit)**: Support staff must inform users that our telemetry and persona systems (Rybbit) strictly filter out personal system processes and applications. We only log high-intent behaviors (gaming/browsing) anonymously to generate recommendations via AI routing. Tell users their specific usage logs are never sold to advertisers or tracked manually.
* **Current Service Regions**: Servers are located in Ho Chi Minh City (HCM) and Hai Phong (HP).

## Cluster Configuration (`cluster.yaml`) — For Ops

Every data-center server runs a master daemon that reads its infrastructure topology from a single file: `~/assets/cluster.yaml`. This file tells the daemon **which worker nodes exist, how networking is wired, where storage pools live, and how to reach peer clusters**. You will never need to write this file from scratch — it is pre-configured during server provisioning — but you may need to edit it for common operational tasks.

### Where to Find It

SSH into the master node and open `~/assets/cluster.yaml` (the home directory of the daemon user, typically `root`).

### Common Ops Edits

| Task                                       | What to Change                                 | Example                                                      |
| ------------------------------------------ | ---------------------------------------------- | ------------------------------------------------------------ |
| **Add a new worker node**            | Append to the `nodes:` list                  | `- ip: "10.30.30.44"`                                      |
| **Temporarily disable a node**       | Set `inactive: true` on the node entry       | `- ip: "10.30.30.42"` ⟶ add `inactive: true`            |
| **Change default VM RAM/CPU**        | Edit the top-level `ram:` / `vcpu:` values | `ram: 24` / `vcpu: 14`                                   |
| **Add a storage pool**               | Append to `pools:` with type, path, and name | `- type: "user_data"  path: "/data/nvme2"  name: "pool-2"` |
| **Skip OTA updates for a component** | Add the component name to `skip_updates:`    | `skip_updates: ["proxy"]`                                  |
| **Change default VLANs**             | Edit the `default_vlans:` array              | `default_vlans: [100, 300]`                                |

### Applying Changes

After editing, **restart the daemon**: `systemctl restart virtdaemon`. The config is read once at startup — there is no hot-reload. The daemon will reconnect to all declared nodes, peers, and routers on restart.

> ⚠️ **Warning**: Restarting the daemon during active user sessions does NOT kill running VMs. However, the management API will be unavailable for ~10 seconds during restart. Coordinate restarts during low-traffic windows when possible.

## Multi-Node Cluster Architecture — How It Works

The Thinkmay infrastructure is **not a single server** — it is a cluster of cooperating machines sharing GPUs and storage. Understanding this is critical for diagnosing deployment failures and capacity issues.

### The Four Roles

| Role             | What It Does                                                        | How to Identify                                        |
| ---------------- | ------------------------------------------------------------------- | ------------------------------------------------------ |
| **Master** | Orchestrates all deployments, owns the GPU queue, runs Pocketbase   | Has `nodes:` entries in its `cluster.yaml`         |
| **Worker** | Runs the actual VMs with GPUs. Reports state to the master via gRPC | Listed as an IP in the master's `nodes:`             |
| **Peer**   | A separate cluster entirely. The master queries its VMs for routing | Listed in `peers:` (e.g., `haiphong.thinkmay.net`) |
| **Router** | Handles DNAT port forwarding for VMs in VLANs                       | Listed in `routers:` with a VLAN number              |

### How Deployments Work (Simplified)

1. User clicks "Turn On" → Pocketbase tells the master daemon.
2. The master checks if the user's disk volume is stored locally or on a worker.
3. If the volume is on a different server than the available GPU, the master creates a **Network Disk bridge** (NBD) so the GPU node can access the volume over the network.
4. The master places the user in the **GPU queue**. Standard users go to the back; Performance users go to the front.
5. When a GPU is free, the master tells the worker to boot the VM.

### Maintenance & Troubleshooting

| Scenario                                        | What to Check                                                                                                               |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **User stuck at "you are in X position"** | All GPUs are occupied. Check worker nodes for free GPUs.                                                                    |
| **"Server Down" but node is running**     | The master cannot reach the worker via gRPC. Check network/firewall between master → worker `:60000`.                    |
| **VM booted but streaming doesn't work**  | Routing DB may be stale. The `syncDatabase` loop (every 1s) pushes routing to the proxy. Check proxy logs.                |
| **Adding capacity**                       | Add the new server IP to `nodes:` in the master's `cluster.yaml` and restart `virtdaemon`.                            |
| **Taking a node offline**                 | Set `inactive: true` on the node in `cluster.yaml` + restart. Active VMs finish naturally; no new deployments go there. |

## Modifying CloudPC Configurations (For Ops)

As an Operations or Support team member, you may occasionally need to modify a customer's machine manually (e.g., removing a GPU for debugging, or granting them VIP queue access).
To do this:

1. Log into the internal **Pocketbase Admin UI**.
2. Navigate to the `volumes` collection and find the customer's volume record.
3. Locate the `configuration` text field (which stores data in a JSON format).
4. You can edit this JSON to inject specific overrides:
   * `{"transient": true}` - Turns the volume into a Trial environment (wiped after use).
   * `{"disable_gpu": true}` - Forces the machine to boot on the CPU without claiming a physical GPU.
   * `{"pref_nodes": ["<node_ip>"]}` - Upgrades the user to **Supreme Deployment Priority** by routing them to the front of the queue targeting a specific server.

5. **"Set Template" Permission**: To grant an operations member the ability to transform a CloudPC into a reusable Store Template, ensure their email is listed inside the internal `_superusers` collection. This unlocks the "Set template" button inside the frontend Store, which executes an instant `.old` backup and zero-downtime template copy!

## Technical Streaming Metrics (Debugging Connection Issues)

When solving customer tickets regarding "Lag" or "Blurry Streams", ask them to toggle "Show stats" in their Settings Panel. Cross-reference their metrics using this guide to pinpoint the exact bottleneck securely:

1. **Ping (`realroundtriptime / 2`)**: Anything over 60ms will feel noticeably laggy. **NEVER** advise the user to download or use an external VPN (like 1.1.1.1 WARP), as this completely destabilizes our WebRTC pipelines! Instead, explicitly instruct them to use our native **"Change Route"** feature inside their Settings Panel to manually bounce their connection across a different datacenter backbone, immediately bypassing local ISP congestion natively.
2. **Buf/Dec/Proc (`realdecodetime`)**: If `Decode` or `Proc` spikes massively above 15ms, the user's LOCAL hardware (their cheap laptop or older smartphone) is physically too weak to decode the high-resolution stream! Have them drop their Bitrate or turn off H.265 inside Advanced Settings transferring the weight back to standard H.264.
3. **PL/IDR (`packetloss / idrcount`)**: If `PL` climbs rapidly, their Local Home WiFi is heavily dropping packets causing the server to violently assert `IDR` frames trying to rescue the stream. Explicitly tell them to plug in an Ethernet cable or move significantly closer to their 5GHz network.
4. **Jt/Avg (`realjitter`)**: High Jitter means packets arrive entirely out of chronological order (highly typical on heavily congested 4G/LTE mobile networks). This natively induces severe visual stutter.

## Interaction Modes & HID Emulation (Support Knowledge)

When aiding users with controller, touch, or keyboard issues, understand that Thinkmay natively maps all Web Browser hardware events straight into the CloudPC using deep HID emulation:

* **Mouse Interactions**: The frontend dynamically toggles between **Absolute Cursor Mode** (ideal for standard desktop usage, mapping the exact screen bounds) and **Relative Pointer Lock** (transmitting raw X/Y deltas natively). The platform automatically enforces Relative Mode when users play 3D/FPS games (e.g., CS:GO, Minecraft) preventing screen-edge constraints!
* **Smart Cursor Engine (`cursor.ts` & `hid.go`)**: To eliminate UI latency, we do NOT bake the mouse into the video stream. Our Go backend (`hid.go`) intercepts the physical Windows OS Cursor state 10 times a second (100ms ping), safely securely caching the PNG to save bandwidth and only broadcasting updates when the `Cursor ID` changes! The WebRTC pipeline fires this PNG over data channels as a base64 Data URI straight into the React frontend.
  * *Algorithmic Smoothness*: Knowing ping fluctuates, `cursor.ts` does not just rigidly snap the mouse to arriving coordinates. It computes an algorithmic 32-millisecond `INTERPOLATION_DURATION` path! It tracks real-time "Clock Drift" (`smoothedOffset`) between the Server and Client internal clocks, mathematically gliding the custom `<img>` crosshair across the viewport continuously between network packets.
* **Touch & Mobile Playbook**: We support two independent mobile modes natively. If **Native Touch** is toggled, actual touchscreen pinches/taps are piped completely into the Windows 11 kernel as a recognized Touch Monitor. If disabled, touches emulate a generic Laptop Trackpad (where gestures slide the mouse pointer and screen sides act as Left/Right clicks).
* **Virtual Gamepads (ViGEm)**: You can reassure gamers that standard HTML5 gamepads (PS4/Xbox) don't undergo cheap keyboard-binding emulation! Our Go orchestration actively spins up an emulated Xbox 360 architecture (`gconn` via ViGEmBus) directly inside the Host, seamlessly transferring actual thumb-stick axis movements, triggers, and even translating force-feedback/rumble requests back to their physical controllers natively.
* **Keyboard Emulations**: When playing international titles, keys can be configured to transmit raw hardware **Scancodes** instead of Javascript strings, entirely bypassing client/host language localization mismatches.

## Database Structure & Terminology (Where to look)

The Thinkmay Platform operates a **Dual-Architecture Gateway**:

1. **The Global Database (Supabase)**: Operates the money and the queues. It handles the `pockets` (user wallets), handles App Store inventory searching, and handles 3rd Party APIs (PayOS, Stripe). It speaks directly to Pocketbase via SQL HTTP Webhooks. Support tickets regarding *Billing, Subscriptions, and User Wallets* belong here.

* **Payment/Wallet Inquiries playbook**: Thinkmay evaluates usage via a "Top-Up Ledger" called `pockets`. Users DO NOT buy subscriptions directly with Cards; they top up "System Credits" into their Wallet. If a user complains a payment hasn't hit their software, verify the `transactions` table to ascertain whether their Gateway connection (Stripe/PayOS) is stuck processing `_PENDING`. If they complain a subscription didn't boot their CloudPC despite paying, verify their `pockets.amount` actually exceeds the target `plans.credit` expense to afford clearance!

### The Frontend Checkout Engine (`/payment`)
If a user is confused about how to renew their plan, guide them through the frontend payment logic framework:
1. **The Catalog (`/payment`)**: When users hit the payment tab, if they already own an active subscription, they are presented with an `OwnedPlan` dashboard detailing their exact renewal dates and costs (accounting for Addons they attached). If they are completely new, they see the `<PlansGrid>`.
2. **The Checkout Customizer (`/payment/[id]`)**: Users use this interface to technically manipulate their checkout payload before routing to the payment gateways. Instruct them that they can toggle **"Wallet Deduction"** (which mathematically subtracts their existing `user.balance` from the required fiat deposit price), toggle `Addons`, and apply discount codes (`validate_discount_code`).
3. **Gateway Distributions (`/payment/[gateway]/[id]`)**:
   - *VietQR/PayOS*: The client renders a React `<QRCode>` mapping to their specific deposit request. The frontend actively polls the backend `isFinished()` loop every 3 seconds for 5 minutes. If a user complains their QR code randomly expired or kicked them out, they simply hit the 5-minute inactivity timeout!
   - *Stripe*: Renders standard Stripe Elements allowing either Single `payment` drops or Recurring `subscription` hooks.
   - *Dana/Ovo*: Standard Indonesian-localized digital wallets.

2. **The Local Worker Databases (Pocketbase)**: Resides locally on the data center servers. We use Pocketbase specifically to securely orchestrate bare-metal hardware functions locally. Support tickets regarding *Missing CloudPCs, Bad Networking, missing Hardware, or Auth failures* belong here.

### Handling "Lost Data" / Game Save Tickets (Transient vs Persistent Plans)

If a user submits an aggressive ticket complaining that "all their games or file saves randomly disappeared" after they closed out of their session, quickly check the plan they purchased via the Supabase Dashboard:

* **Transient Plans (Hourly Tiers)**: Inform them that the subscription they selected is intentionally designed as an Ephemeral / Transient system. The Thinkmay proxy daemon physically triggers a `MarkAsTransient()` sequence shredding their `.raw` user volume disk instance into the incinerator immediately upon session disconnect.
* **Persistent Plans (Monthly Tiers)**: These are non-transient tier machines. Their data rests safely mapped to persistent `.raw` files on the `user_data` storage pool! If they truly lost files here, it is a catastrophic infrastructure failure requiring immediate Level-3 escalation to the dev ops team.
* **"Disk is currently locked" / Reset Failures**: This indicates the user attempted to press the Reset or Restart buttons while their prior streaming session was still physically spinning down. The master infrastructure immediately catches this and flags a background `lock` ticking file to prevent them from accidentally formatting their hardware while it is still flushing saved game data! Tell them to wait approximately 3 to 5 minutes so the hardware can fully shut off naturally, which will remove the lock.
* **App Store Installation Stuck at 0% (/reallocate fails)**: If they complain a giant game install from the Thinkmay App Store is completely frozen, it implies their `/reallocate/sse` volume pipeline stream crashed while attempting to overlay the internal Game Template. Have them execute a Hard Reset from their dashboard to safely flush their `.raw` locking mechanism and cleanly redownload the target!

### Dashboard "Turn On" Issues (Troubleshooting VM Start Failures)

If a user complains that their dashboard does not allow them to start their VM (missing "Play" button or greyed out), this means the `GetStarted` UI is overriding the volume state based on a discrepancy between the static Pocketbase database and the live `/info` API of the physical worker node. **Here's exactly how to investigate and resolve it:**

* **"Server Down" / Missing VM Panel**: Occurs if the overarching `/info` API fails to return computer data, or if the user's specific volume ID is absent from the active hardware payload. This implies the backend worker is unresponsive or the disk hasn't successfully mounted natively.
  * *Action Plan*: Open **Pocketbase Admin UI -> `volumes`**. Find the user's volume by email and grab the `local_id`. If `transient: true` or the volume doesn't exist, their Trial expired! If the volume *does* exist, the data center node is likely rebooting. Escalate to Ops if it persists.
* **"Wrong Server Domain"**: Instruct the user to switch to the correct web portal; their subscription `.cluster` assignment does not match the active worker address.
  * *Action Plan*: Simply look at the URL the customer provided in a screenshot. If their subscription is on `saigon2` but they navigated to a `haiphong` dashboard link, tell them to swap URLs.
* **"Needs Refresh" / Waiting**: The `/info` API is explicitly returning `inuse: true` for their volume list, meaning the server is currently actively shutting down their last session. Tell them to wait 1-2 minutes and refresh the page.
  * *Action Plan*: Tell the user to wait up to 5 minutes. If it gets infinitely stuck "waiting", open Pocketbase Admin UI, go to the `sessions` table, find their active `internal` stranded session payload, and politely delete the row manually to instantly hard-flush the `inuse: true` lock!

### Missing Cursor & Overlays on Mobile (Desktop Mode Issue)

If a user submits a ticket stating they are playing on a mobile phone or tablet but **"the mouse cursor is invisible"** or **"the virtual gamepad buttons are gone"**, this is a browser configuration issue, not a backend crash.

* **The Cause**: The user has **"Request Desktop Site"** toggled ON in their mobile browser (Chrome/Safari). This spoofs their `UserAgent` signature to pretend to be a strict desktop PC (e.g., Windows/macOS). Our frontend UI strictly evaluates this fake user agent (`isMobile() === false`), permanently hiding all touch-specific video overlays (Gamepads) and disabling the internal `server_cursor`, expecting a physical hardware mouse that the mobile device does not physically possess!
* **Action Plan**: Look at their screenshot. If the website text is extremely tiny or zoomed out, they are definitely in Desktop Mode. Reply with instructions to immediately toggle off "Desktop site" via the Chrome 3-dot menu or Safari's "aA" icon.

### Missing Wallet Credits & Addon Storage Overages

If a customer submits an angry support ticket claiming their **Wallet Credits disappeared** without them manually buying a new Plan, they have triggered a **Storage Overage** or **Service Addon** dynamic charge!

* **How Overages Trigger**: Every plan (like Month-Standard) inherently grants base privileges (e.g. 200GB of disk space and 100k LLM AI Tokens on Standard, or 400GB/300k on Pro). If the user opts to download completely massive 300GB+ games on a Standard plan, they physically exceed their explicit plan limit! The backend tracks this overage natively as **accumulated debt**. Thinkmay does *not* randomly deduct credits mid-session! The charges are strictly deducted entirely in bulk as a requisite at the exact moment their plan expires and they attempt to **renew** their subscription!
* **Action Plan**: Do not arbitrarily issue refunds! Log into the Pocketbase Admin Console, review the user's `addon_subscriptions` unit counts or run `list_addon_charges_v2(user_email)` to track their debts. Kindly reply to their ticket confirming that by downloading massive games vastly expanding their disk footprint beyond their designated Baseline Privileges, their CloudPC dynamically tracked legitimate Storage Overage fees which were automatically deducted *when they requested their latest plan renewal*.

If a user submits a ticket relating to their hardware or machine session, use the **Pocketbase Admin UI** to search for their data across these main tables (collections):

* **`users`**: The core account table. Check here to verify standard info like `email`, `phone`, and profile data.
* **`volumes` & `buckets`**: These represent the actual CloudPC hard drives (`volumes`) and temporary cloud storage (`buckets`). If a user complains about lost data, verify these records exist.
* **`sessions`**: Represents currently active streaming links.
* **`setting` & `persona`**: Stores the user's saved software configurations and algorithm-generated custom profiles (`persona`).
* **`mail`**: Logs all system emails and campaigns sent to the user. Ops can verify here if a customer actually received an OTP or marketing email, diagnosing delivery completely based on the `errors` or `finalHTML` columns.
* **`app_access` & `llmModels`**: Tracks user quotas and usage counts for specific internal tools and AI. If a user says they are rate-limited, check their `usage` meters here.

## Explaining the Settings Dashboard (Support Guide)

If a customer is confused by the options inside the **Settings Panel** (`/setting`), use this operations guide to explain the exact technical capabilities exposed to their frontend component:

### Diagnostic Tools (`/setting/diagnostic`)
* **Network Router (`/setting/network`)**: This visually maps out the Active "Multi-Route" domain. If the user experiences severe backbone ISP routing issues, Operations can instruct them to manually select a different routing server here. This structurally pivots their proxy ingestion endpoint, immediately bypassing local ISP congestion!
* **Keyboard & Gamepad Testers**: Native sandboxes mapping raw physical presses exactly as the browser registers them, designed solely for debugging inputs before starting a session.

### Advanced WebRTC Configurations (`/setting/advance`)
* **Dual-Range Bitrate Limiters**: The slider doesn't just "set" the visual quality. It defines the explicit WebRTC `BandwidthEstimator` floor (`min_bitrate`) and ceiling (`max_bitrate`), natively capping at 60 Mbps. The server dynamically sweeps NVENC compression inside this user-defined bounds.
* **Adaptive Bitrate Override (Fixed Bitrate)**: If the user sets "High Stability", they can activate **Disable Adaptive Bitrate**. This converts the Dual-Range Limiters into a *Single Fixed Bitrate* control panel. The web client immediately sends `&gcc=false` upon connection, forcing host server encoders to maintain constant bitrates at the cost of higher potential jitter inside congested loops.
* **Video Presets (Speed vs Quality)**: The "High Quality" vs "High Stability" radio buttons explicitly alter the React `framerate` state, signaling the host machine to cap the renderer globally between 120 FPS vs 60 FPS natively.
* **H.265 / HEVC**: Support can instruct gamers with strong local GPUs (i.e. good decoding power) to toggle "Use H265". This massively drops network bandwidth requirements, but absolutely destroys the stream if their physical device lacks hardware decoding capabilities.
* **VSync Mode**: Toggling this forces VSync, dramatically eliminating screen-tearing algorithms natively.

### Compatibility Configurations (`/setting/advance`)
* **Scancode Keyboard Mapping**: This tells the system to transmit raw OS hardware binary presses instead of browser-interpreted strings. Essential for bypassing foreign language/QWERTY mismatch issues.
* **Client Cursor Engine**: Overrides their desktop mouse with a server-rendered `<img>` crosshair mapped to the relative `smoothedOffset` system. Activating this effectively bypasses system/browser mouse acceleration.
* **Auto-Relative Mouse**: Forces the browser into Pointer Lock immediately on click, perfect for 3D/FPS gamers circumventing the ESC pause menu.

### Hardware Modifications (`/setting/other`)
* **Disk Customizer (`/setting/disk`)**: Users can effortlessly resize their physical CloudPC storage (200GB vs 500GB) natively. The React frontend sends a Resize webhook mapping the limit physically against their Subscription `fetch_plan_policy()` limits safely!
* **Multi-Connection Proxy (`/setting/mcp`)**: Users demanding to hook into external third-party integrations or heavy server APIs can freely toggle their physical `api.EnableMCP()` connection here.

## Website Sitemap & SEO Routing

To assist our Marketing and SEO Operations teams, here is the architectural Next.js App Router topology natively extracted from the `website/app` directory. Note that internal folders enclosed in parentheses (e.g., `(e-commerce)`) are structural Route Groups and do not visibly append to the finalized web URL:

### 1. Public E-Commerce & SEO Targets `/(e-commerce)`

These routes are publicly accessible, completely open to Google bot crawling, and act as the core organic discovery funnel. They require highly strict metadata and keyword optimization:

* `/` - The primary Marketing Homepage (`page.tsx`).
* `/blog` & `/blog/[slug]` - Informational hubs for press releases and SEO keyword targeting.
* `/discovery` & `/discovery/[...slug]` - Public catalogs and product spotlights.
* `/pricing` & `/pricing/how-it-works` - Sales and conversion funnels.
* `/contact`, `/faq`, `/legal`, `/privacy` - General corporate compliance pages.

### 2. User Dashboard & Infrastructure `/(app)` & `/(auth)`

These routes are gated by authentication logic. SEO optimization and metadata indexing are completely irrelevant here!

* **The WebRTC Interfaces**: `/remote` and `/play` form the absolute core canvases where the virtual streaming displays are loaded.
* **Storefront**: `/store` and `/store/[...slug]` operate the Game Template swap commands.
* **Storage Hubs**: `/storage` and `/storage/backups` manipulate Buckets and Volumes.
* **Configuration Overlays**: Advanced `/setting` trees handle highly specific diagnostic tools like `/setting/network`, `/setting/advance` (where real-time video bitrates are set), and `/setting/gamepad`.
* **Financial Bridges**: `/payment/...` heavily controls transactions routing outward to gateways like Stripe, PayOS, Dana, and OVO.
* **Authentication Pipelines**: `/login`, `/login-otp`, `/register`, and `/reset-password` cleanly route user identity handshakes into Supabase.
