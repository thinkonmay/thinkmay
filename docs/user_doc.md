# Getting Started with Thinkmay CloudPC

## Welcome to Thinkmay CloudPC!

Thinkmay CloudPC transforms your ordinary device into a powerhouse Windows 11 workstation. Built heavily for Gamers and 3D Designers, your CloudPC is ready to handle intense workloads and stream at up to 4K resolution at 240fps!

## Accessing Your CloudPC

No downloads required!

1. Log in using your Google Account, Email & Password, or an Email OTP.
2. **Browsers**: We officially support Chrome and Safari.
3. **Mobile Users**: For an app-like experience, open the website on your phone and tap "Add to Home Screen".

## Subscriptions and Your Data

* **Trial Plan**: Enjoy 3 hours of free access to test the waters. *Warning: Upon completion of the 3 hours, your storage is completely wiped.*
* **Standard Plan**: You get powerful dedicated hardware (up to 120 hours/month) and your files are saved securely between sessions.
* **Performance Plan**: Upgrading gives you our highest hardware tier (up to 360 hours/month) PLUS **VIP Queue Priority**! During peak hours, your CloudPC startup commands completely skip the general line and go straight to the front of our server waitlist, meaning your machine boots significantly faster than other tiers.
  * *Note: For all paid plans, if your subscription runs out, please renew quickly—we permanently clear your files 2 days after expiration!*

## Frequently Asked Questions

* **Can I play high-end games?** Yes! Our machines utilize RTX GPUs capable of 4K/240FPS limits if your local monitor and network support it!
* **Will I get banned by anti-cheats for playing on a CloudPC?** No! We execute specialized hardware spoofing that makes your CloudPC natively appear as a physical rack server from Gigabyte, effectively hiding the virtualization environment. You can safely play games with strict hypervisor anti-cheats (like Vanguard) without getting hardware banned.
* **Does it work on mobile?** Yes! You can use your mobile browser to connect. Furthermore, we feature complete "Virtual Mobile Gamepad" overlays allowing you to customize touchscreen controllers on-the-fly.
* **How long does it take for my PC to be ready?** Normally 2-5 minutes, depending on the queue size and GPU recovery mechanics.

## Security & Privacy (Who can see my CloudPC?)

Your data is exclusively yours! Our backend servers orchestrate CloudPCs using strict **zero-trust authentication architecture**.

* **Complete Isolation**: When you start your CloudPC, our server maps the request exclusively against your securely signed database ID. It is structurally impossible for another user to view, access, hijack, or boot up your CloudPC machine!
* **Anti-Hijacking Links**: The streaming handshakes built between our backbone servers and your browser expire intelligently. Network traffic is sealed tight, actively repelling third parties from piggybacking onto your hardware sessions.
* **Isolated "VPN Safe" Networks**: The network powering your display stream is structurally isolated from your CloudPC's internal internet connection! This ultra-secure architecture means you can install corporate VPNs, tweak Windows Firewall settings, or do deep networking work without *ever* having to worry about locking yourself out of your machine or losing your display stream.

**My connection feels laggy. What can I do?**
We offer a unique "Multi-Routing" feature. Even if your server is in HCM, you can manually select a different data route (like HP) in the settings. This lets your connection hop on our fast internal network, bypassing potential local internet bottlenecks!

**Can I transfer files to the CloudPC?**
While you cannot drag-and-drop files directly into the browser window, your text clipboard is synchronized! You can freely copy text on your local machine and paste it into the CloudPC, and vice versa.

**Does my gamepad or microphone work?**
Yes! You can plug in a microphone or gamepad. If you are gaming on a mobile phone, we even provide a built-in virtual on-screen gamepad. *Note that we currently support a single monitor setup per CloudPC.*

## Need Help?

Our servers are located in Ho Chi Minh City (HCM) and Hai Phong (HP).
If you run into any issues, our support team is ready to help via **Email** or on our official **Discord** server!

## Streaming Optimization & Troubleshooting

Thinkmay CloudPC utilizes advanced streaming features like Google Congestion Control (GCC) and Forward Error Correction (FlexFEC) to dynamically handle network fluctuations. However, you might still run into performance issues due to device limitations or unstable Wi-Fi.

We provide a **"Show stats" / "Technical Mode"** setting that allows you to see real-time streaming metrics. Here is a guide on how to read these metrics and fix common symptoms:

| Symptom                                               | Metric to Look At                                                          | How to Solve It                                                                                                                                                                                                                                                                                                                         |
| :---------------------------------------------------- | :------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Blurry/pixelated stream**                     | **`packetloss`**, **`realbitrate`**, **`realfps`** | Your network is struggling, so the server adaptively lowered the video quality (GCC). Try lowering the `max_bitrate` limit in your settings. If using Wi-Fi, ensure you are on a 5GHz band or switch to a wired Ethernet connection.                                                                                                  |
| **Video freezing for a few seconds frequently** | **`idrcount`**, **`realfreezecount`**                      | When packets are excessively lost, the server sends an "IDR" frame to reset the video, causing a freeze. Disable the "HQ" mode to lower the framerate (back to 60fps) or change your Data Route in settings.                                                                                                                            |
| **High input latency / Delay**                  | **`realdelay`**, **`realdecodetime`**                      | If `realdelay` is high, switch your data route to avoid ISP bottlenecks. If `realdecodetime` is high, your device is struggling to decode the video. Try switching your `preferred_codec` from H.265 to H.264 (or vice-versa), and check the `realdecodername` metric to ensure your browser has Hardware Acceleration enabled. |
