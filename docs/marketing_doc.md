# Thinkmay CloudPC - Marketing & SEO Playbook

This document is strictly tailored for the Thinkmay Marketing, SEO, and Graphic Design teams. Use this guide to structure your advertising conversion funnels, prioritize SEO tracking, and design universally consistent brand materials.

---

## 💥 Brand Identity Core Pillars
Thinkmay isn't just a cloud provider; we are democratizing high-end computing. Ensure all marketing materials reflect our **Core Brand Pillars**:
1. **Community-Oriented**: We don't just have "users"; we have a vibrant tribe. Emphasize Discord hangouts, co-op gaming, and sharing custom setups. Speak *with* our users, not *at* them.
2. **Tech-Savvy**: Let the impressive engineering shine through without being overly intimidating. We proudly flex our "WebRTC Sub-Millisecond Magic" and "Dedicated RTX allocations", showing power users and casuals alike that we speak their language. 
3. **Consumer Friendly (Access for Everyone)**: AAA gaming or heavy 3D rendering shouldn't require a $2,000 rig. Our message is pure accessibility: *Play Cyberpunk 2077 flawlessly on your 5-year-old MacBook or your daily school laptop.*

---

## 1. The User Conversion Funnel

The Thinkmay platform uses a distinct funnel bridging our public e-commerce tracking routes into our high-performance gated web application. 

### Step 1: Organic Discovery (The `/(e-commerce)` Router)
Users typically find us via Google through our heavily indexed public routes:
* `/` (Marketing Homepage)
* `/blog/[slug]` (SEO Content, Community Spotlights & Update Patch Notes)
* `/discovery` (Game/Software Discovery Catalogs)
* **Goal**: The immediate Call-to-Action (CTA) across all these pages must drive the user forcefully to the **Registration Pipeline**. 
* **The Message**: Break down barriers. Highlight our USPs: "Zero-Lag WebRTC Streaming", "Runs directly in your Chrome Browser", and "Anti-Cheat Safe". Empower the user with the fact that they don't need an expensive gaming rig to join their friends' lobbies tonight.

### Step 2: Frictionless Authentication
* We use a strict Passwordless / Social-First approach. Users authenticate in a single click using **Google OAuth** or **Email OTP**, completely bypassing tedious password creation friction. 
* **Marketing Action**: Ensure landing page CTAs explicitly mention *"Jump into the game in 1 Click with Google"*.

### Step 3: Trial vs Monetization Hook (The `hour1` tier)
* Once authenticated, users enter the `/(app)` dashboard.
* **The Hook**: Drive new users towards the **3-Hour Free Trial (`hour1` tier)**. This lets them test-drive our tech-savvy architecture entirely risk-free. Give them the "Aha!" moment of feeling zero lag.
* **The Conversion event**: Upon the 3-hour expiration, our system safely locks their session and introduces our transparent **Wallet System**. Follow-up emails should feel like community updates rather than bills. We tell them: *Top up your wallet via local gateways like VietQR/PayOS, Dana, or Stripe to keep your rig alive and keep playing with the squad.*

---

## 2. SEO Optimization Strategy

Our Next.js architecture heavily separates our organically crawled public SEO content from the secure internal web app.

### Public SEO Hotspots (The Optimization Zones)
* **High-Value Pages**: `/pricing`, `/discovery`, `/blog`.
* **Metadata Strategy**: Every public page MUST implement dynamic metadata.
  * *Titles*: Should follow `[Topic] - Thinkmay | Democratizing Cloud PC Gaming`.
  * *Descriptions*: Embed core keywords heavily, balancing tech with accessibility: "GPU Accelerated", "Browser-based Cloud PC", "No Download", "Play PC Games on Mac", "Anti-Cheat Safe Virtualization".
* **Language/Locale Subdirectories**: Our web application natively scales using `/[locale]/...` routing. Marketing MUST ensure canonical `<link rel="alternate" hreflang="...">` tags are actively maintained for English (`en`), Vietnamese (`vi`), and Indonesian (`id`) to aggressively prevent Google keyword cannibalization across our international communities!

### What NOT to Optimize
* Do not waste precious SEO crawl budgets analyzing app routes like `/remote`, `/play`, `/storage`, `/payment`, or `/setting`. These are hidden securely behind authentication gates.

---

## 3. Visual Guidelines for Posters & Ad Creatives

When creating visual assets (Posters, Social Media Ads, Discord Banners, Event Backdrops), strictly adhere to our platform aesthetics:

### 1. The Identity & Core Imagery
* **Target Audience Focus**: Gamers (Esports/AAA titles) and creators who feel unfortunately priced out of modern hardware.
* **Key Visual Layouts**: Show an incredibly high-end AAA game running flawlessly on a dented, sticker-covered college laptop or a standard MacBook. This instantly validates our core pillar: **Accessibility for Everyone**. Put our community front and center—show friends playing together via browser tabs.

### 2. Core Technical Badges (Trust Builders)
Gamers are naturally skeptical of "Cloud Gaming" lag. Win their trust by flexing our tech-savviness right on the posters:
* 🔋 `Dedicated RTX 5060Ti / 3060Ti Rigs`
* ⚡ `Ultra-Low Latency WebRTC Engine`
* 🛡️ `Easy Anti-Cheat & BattlEye Compatibility` (Crucial for our Esports community)
* 🌐 `Powered by Google Chrome` (Visually stamp the Chrome Logo to emphasize *Zero Downloads Required*).

### 3. Aesthetics & The Call-To-Action
* **Color Schemes**: Lean heavily into our application's dark mode schema: Deep Emeralds (`#112E29`), Cyber Greens (`#29D69F`), dark carbon UI backing, and glowing neon UI elements mapped directly from our React frontend. It should feel like a premium hacker/gaming terminal without being unapproachable.
* **The Typography**: Emulate clean, sleek, and structural sans-serif tracking. 
* **CTA Buttoning**: Design stark, highly contrasting CTA bars stating **"Join the Community & Play Free"** or **"Play Now Without Downloads"**.
