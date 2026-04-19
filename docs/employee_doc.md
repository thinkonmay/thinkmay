# Thinkmay CloudPC - Internal Employee Playbook

## Welcome

This document is for Thinkmay employees (Sales, Support, Marketing, and Operations). It provides a high-level overview of our cloud computer service to help you sell and support the product effectively.

## Our Target Audience

Our primary users are **Gamers** and **3D Designers** who require high-performance, GPU-accelerated computing without the upfront cost of expensive local hardware.

## Pricing Plans & Hardware Tiers

We run a subscription-based model with three main tiers:

1. **Trial Plan**: 3 hours of trial access. User data/machine is permanently wiped after 3 hours.
2. **Standard Plan**: 120 hours/month (30 days limit). Backed by EPYC Milan CPUs and RTX 5060ti GPUs. Data is kept persistent.
3. **Performance Plan**: 360 hours/month (30 days limit). Backed by Intel Xeon CPUs and RTX 3060ti GPUs. Data is kept persistent.
   *Note: For all paid plans, user data is securely wiped exactly 2 days after a subscription expires to free up capacity.*

## Key Selling Points & Capabilities

* **Incredible Performance**: Smooth streaming up to 4K resolution at an ultra-fast 240fps (dictated by the user's local display limits).
* **Zero Installation**: Entirely browser-based. Users can add our service to their mobile home screen (PWA) to make it feel like a native application.
* **Reliability via Multi-Routing**: If a user experiences lag, they can manually change their networking 'route' directly through our interface to hit a different backbone entry point, avoiding local ISP congestion.
* **Peripheral Support**: Microphones, Gamepads, and Virtual Mobile Gamepads are fully supported. Text copy/paste works seamlessly between local and CloudPC.
* **Supreme Deployment Priority**: Customers on the Performance Plan automatically bypass the standard server wait line (FIFO). During peak times, the backend queue places Performance users at the absolute front of the line, immediately granting them hardware access and drastically minimizing their boot wait times compared to Standard or Trial users.
* **Guaranteed Privacy & Zero-Trust Security**: Backend endpoints strictly bind deployment requests to the invoking user's unique authenticated ID. Streaming connection links are given a 5-second expiration to prevent cross-session hijacking. It is technically and structurally impossible for a user to boot up, access, or peek into the CloudPC instance of another customer.
* **Stream & Network Isolation (VPN Safe)**: The video stream is completely isolated from the Windows networking using a physical hardware memory bridge. A customer can install a corporate VPN inside their CloudPC or tinker with firewalls securely without accidentally disconnecting or locking themselves out of the display stream.
* **Anti-Cheat & Bare-Metal Compatibility**: Our hypervisor completely masks all Virtual Machine footprint signals. For paying gaming clientele, their CloudPC reads and functions identically to a physical gaming rig. This ensures notoriously strict online video game anti-cheats (like Vanguard or Easy Anti-Cheat) run flawlessly without flagging the user.

## Need to Know (Support & Ops)

* **Database Troubleshooting**: If a customer reports missing data, or an inability to log in, immediately consult the `pocketbase` backend database:
  * Check the `volumes` table to verify if their core OS image still exists. Modifying the JSON `configuration` column heavily dictates whether they spawn headless or bypass GPUs.
  * Check the `sessions` table to review real-time active streaming handshakes, or forcibly kill an active session.
  * Look into the `app_access` usage analytics rows if someone contests a rate limit block on internal LLM services.
* **Automated Zero-Downtime Patching (`local_version_control_v1`)**: Operations personnel never need to SSH into individual cluster nodes to push software updates! Worker nodes automatically poll the Global Database daily to check for remote patches. If a core update is found, the script mathematically hashes the binary natively, swaps files, and performs rolling service restarts. Critically, nodes will **pause** their patch restarts dynamically if a customer session is actively using the machine, guaranteeing zero game interruptions or unannounced downtime for your users!
* **Boot Times**: When a customer starts their CloudPC, it takes between 2 to 5 minutes to boot Windows 11. Heavy server load or GPU checks may extend this.
* **Authentication**: Customers can log in via Google OAuth2, Email/Password, or Email OTP.
* **Customer Support Channels**: All official technical support is handled via **Email** and **Discord**.
* **Current Service Regions**: Servers are located in Ho Chi Minh City (HCM) and Hai Phong (HP).

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

## Database Structure & Terminology (Where to look)
If a user submits a ticket, use the **Pocketbase Admin UI** to search for their data across these main tables (collections):
* **`users`**: The core account table. Check here to verify standard info like `email`, `phone`, and profile data.
* **`volumes` & `buckets`**: These represent the actual CloudPC hard drives (`volumes`) and temporary cloud storage (`buckets`). If a user complains about lost data, verify these records exist.
* **`sessions`**: Represents currently active streaming links.
* **`setting` & `persona`**: Stores the user's saved software configurations and algorithm-generated custom profiles (`persona`).
* **`mail`**: Logs all system emails and campaigns sent to the user. Ops can verify here if a customer actually received an OTP or marketing email, diagnosing delivery completely based on the `errors` or `finalHTML` columns.
* **`app_access` & `llmModels`**: Tracks user quotas and usage counts for specific internal tools and AI. If a user says they are rate-limited, check their `usage` meters here.
