# Thinkmay CloudPC Data Privacy Policy & Protection Guide

At Thinkmay, we take your personal data rights incredibly seriously. We believe that gaming on the cloud should afford you the exact same security and privacy as playing offline on a physical rig. This document outlines in depth how we protect your information, how our analytics engine works, and why your data rights are never violated.

## 1. How we protect your data in-depth
Your physical sessions and files are protected mathematically through zero-trust architectures:
- **Strict Network Isolation**: The video stream you watch is completely isolated from the Windows networking pipeline using a proprietary hardware memory bridge mechanism. You can run external corporate VPNs without risking your session's video stream being captured.
- **Hardware-Level Segmentation**: Your CloudPC instance is uniquely cryptographically signed against your user ID. It is structurally impossible for other users on the distributed cluster to view, access, or boot up your CloudPC.
- **Decentralized Secure Storage**: Your personal files are stored via the decentralized Storj framework. Your files are granted temporary ephemeral decryption keys purely during the moment your session is active, meaning no static cloud databases are vulnerable to mass data scraping.
- **Data Evaporation**: For Hourly Trial and standard transient sessions, your data drive is permanently incinerated and shredded the minute your session shuts down. For persistent monthly plans, data is isolated securely specifically to you and permanently destroyed shortly after your plan fully expires to free up cluster drives.

## 2. How we analyze your "Persona" (Rybbit Analytics)
To provide an excellent cloud gaming experience, Thinkmay uses an automated internal AI tool named internal **Rybbit Analytics** to power user experiences without invasive human auditing or manual oversight.
- **The Telemetry Blacklist Filter**: Rybbit does not spy on your personal computer usage. It operates on a strict algorithmic blacklist that entirely ignores your system applications (like Windows tasks), personal software, messaging clients, and background processes. It solely listens for high-intent applications (like heavy AAA games or GPU-heavy 3D rendering software).
- **Algorithmic Summarization**: Once these high-intent metrics are gathered (such as duration played and the name of the game launched), Rybbit anonymizes and sends that usage fingerprint into a private backend AI model (Gemini).
- **What is a "Persona"?**: The AI analyzes the data and returns a mathematical, anonymized tag representing your gamer profile (e.g., *"The Late-night Competitive FPS Player"*). We use your Persona to power our Game Store Recommendation AI, helping users discover new titles they'll love. It also helps our backend infrastructure implicitly understand how frequently you'll need the server resources, allowing us to balance GPU queues efficiently so an RTX rig is always ready when you want to log in.

## 3. How we do not violate your rights
You have absolute control and rights over your digital life on Thinkmay.
- **We never sell your data**: The telemetry, analytics, and Persona profiles we generate are inherently siloed and exclusively utilized internally by Thinkmay to personalize the App Store recommendation engine and stabilize our hardware load-balancers. We never sell, rent, or lease your gaming behaviors, telemetry, or user identities to 3rd-party ad networks or brokers.
- **No Human Review**: Because Rybbit interfaces securely with algorithmic LLM interpretation layers to anonymously cluster similar gamers, Thinkmay technical staff members do not sit and manually monitor your gameplay telemetry.
- **Freedom of Compute**: Your CloudPC behaves practically indistinguishable from a personal hardware tower securely segmented from outside observers. We don't invasively scan the files you store or restrict your legal personal downloads on your primary user drive. What you choose to do inside your personal secure container belongs exclusively to you.
