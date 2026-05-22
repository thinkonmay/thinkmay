# Thinkmay Landing Page Design

This document describes the Thinkmay landing page design direction for marketing, acquisition, and product education pages. It is a product design document, not an architecture document. Use it alongside `docs/product/design/thinkmay_design_language.md`, `docs/product/design/thinkmay_mobile_design.md`, and `docs/product/design/thinkmay_desktop_design.md`.

Source of truth: [Figma — Thinkmay Mobile App, Webapp, Landing page](https://www.figma.com/design/LaEXIXc42MwmlIMiO2h3Jr/%F0%9F%93%B1-Thinkmay---Mobile-App--Webapp--Landing-page--Copy-?m=auto&t=PcEoaToTxqQ2pFoz-6)

Only the Figma design is authoritative. Existing website implementation may drift and should not override this document.

## Landing page intent

The landing page should convert curiosity into confidence and action. It must explain Thinkmay as a high-performance cloud PC / cloud gaming product quickly, prove that it works across devices, and lead users toward starting, choosing a plan, or learning enough to trust the product.

The page should feel like a premium gaming/workstation launch surface, not a generic SaaS homepage. The core emotion is: **my powerful cloud PC is ready, close, private, and usable from any device**.

## Landing page principles

1. **Hero promise first** — lead with hardware/performance, device continuity, price, or low-latency proof.
2. **Show the product early** — use device mockups or screenshots above the fold; do not rely on abstract illustration only.
3. **One dominant CTA** — each viewport should make the next action obvious.
4. **Proof before detail** — show latency, GPU, local infrastructure, supported devices, controller/microphone, and ownership claims before long explanations.
5. **Dark cinematic brand** — use deep Cloud Teal backgrounds, teal energy, and glass cards to match app/product surfaces.
6. **Vietnamese-first copy** — keep copy short, practical, and easy to scan.
7. **Reusable section system** — landing pages should compose from repeatable hero, proof, feature, pricing, FAQ, and CTA sections.

## Landing page design material

| Material | Location | Purpose |
| --- | --- | --- |
| Landing page structure sample | `docs/shared/assets/ui-elements/landing-page-structure.svg` | Full landing page composition reference: nav, hero, proof cards, pricing, final CTA |
| Shared design language | `docs/product/design/thinkmay_design_language.md` | Tokens, typography, components, visual philosophy |
| Mobile design | `docs/product/design/thinkmay_mobile_design.md` | Mobile responsive behavior and app-specific semantics |
| Desktop design | `docs/product/design/thinkmay_desktop_design.md` | Desktop shell and wide-screen app/product layouts |
| Buttons sample | `docs/shared/assets/ui-elements/buttons-sample.svg` | CTA and secondary action styling |
| Colors sample | `docs/shared/assets/ui-elements/colors-sample.svg` | Color/token reference |
| Typography sample | `docs/shared/assets/ui-elements/typography-scale.svg` | Type scale reference |
| Mobile ad composition | `docs/shared/assets/ui-elements/mobile-ad-composition.svg` | Short-form banner/video hero composition |

## Recommended page structure

A complete Thinkmay landing page should use this order unless a campaign has a more specific funnel.

| Section | Purpose | Key content |
| --- | --- | --- |
| Navigation | Trust, orientation, conversion access | Logo, short links, `Dùng ngay` CTA |
| Hero | Immediate value proposition | GPU/price/device promise, product visual, primary CTA |
| Proof strip | Fast trust signals | `5060Ti`, local infrastructure, latency, browser/mobile/desktop support |
| Product preview | Show actual product | Device/browser mockups, Cloud PC card, streaming controls |
| Feature blocks | Explain benefits | Any device, controller/mic, data ownership, local latency |
| Use cases | Broaden relevance | Gaming, work tools, remote Windows desktop, quick access |
| Pricing/package | Convert intent | Price anchor, plan cards, renewal clarity, CTA |
| Diagnostics/trust | Reduce anxiety | Network, keyboard, gamepad, microphone support |
| FAQ | Resolve blockers | Device support, payment, latency, account/data, refund |
| Final CTA | Close the page | Short restatement and action |

## Navigation design

Purpose: orient the user without stealing attention from the hero.

Rules:

- Use a dark glass nav bar over the Cloud Teal background.
- Place the white Thinkmay logo on the left.
- Keep links short: `Tính năng`, `Bảng giá`, `FAQ`, `Đăng nhập`.
- Use one primary CTA on the right: `Dùng ngay`, `Bắt đầu`, or `Chơi ngay`.
- Desktop nav may be horizontal; mobile nav should collapse into a compact menu.
- Do not overload navigation with product architecture terms.

## Hero section

Purpose: communicate the full product promise in one glance.

Recommended hero copy patterns:

```text
5060Ti trên mọi thiết bị
Dùng ngay chỉ từ 59k
```

```text
Cloud PC hiệu năng cao
Chơi và làm việc từ mọi thiết bị
```

```text
Cloud Gaming số 1 Việt Nam
Độ trễ tối ưu, dùng ngay trên browser
```

Hero visual rules:

- Use a large phone, desktop, or browser mockup showing actual product UI.
- Use floating game/app/control cards only as depth elements.
- Use a dark blurred background with a translucent green-black panel if text sits over imagery.
- First headline line should be white; the price/proof line should be electric teal.
- CTA cluster should include one primary CTA and at most one secondary CTA.
- Keep supporting copy to one short sentence.

Hero layout by breakpoint:

| Breakpoint | Layout |
| --- | --- |
| Desktop | Two-column hero: copy left, device/product visual right |
| Tablet | Stacked hero: copy top, visual below |
| Mobile | Centered hero: short headline, visual, CTA, compact proof bullets |

## Proof and trust signals

Use proof signals immediately after or inside the hero.

Preferred proof points:

- `5060Ti`
- `Hạ tầng trong nước`
- `Độ trễ tối ưu`
- `App browser trên mọi thiết bị`
- `Hỗ trợ microphone, tay cầm`
- `Cloud của bạn, dữ liệu của bạn`
- `Thinkmay - Cloud Gaming số 1 Việt Nam`

Visual treatment:

- Use compact glass cards or icon bullets.
- Icons use electric teal.
- Copy stays short and literal.
- Avoid abstract claims without concrete product proof.

## Product preview section

Purpose: prove the service is real and understandable.

Rules:

- Show product UI in a device/browser frame.
- Use captions to explain what the user sees: cloud PC card, launch action, diagnostics, package state.
- Keep screenshots current and not distorted.
- Use dark cards around bright screenshots to keep brand consistency.
- Do not place dense technical UI in the hero if it weakens the first impression.

Recommended preview modules:

| Module | Purpose |
| --- | --- |
| Cloud PC card | Shows current machine, status, and start/resume action |
| Streaming preview | Shows remote desktop/game context |
| Diagnostics strip | Shows keyboard, controller, microphone, network readiness |
| Package card | Shows plan/price/renewal clarity |

## Feature section

Use a 2x2 or 4-card feature grid on desktop, stacked cards on mobile.

Canonical feature cards:

| Feature | Message | Visual cue |
| --- | --- | --- |
| Any device | `App browser trên mọi thiết bị` | Laptop/phone/browser icon |
| Controls | `Hỗ trợ microphone, tay cầm` | Gamepad/microphone icon |
| Ownership | `Cloud của bạn, dữ liệu của bạn` | Shield/cloud icon |
| Local latency | `Hạ tầng trong nước, độ trễ tối ưu` | Location/network icon |

Card rules:

- Dark glass surface.
- 20-24px radius.
- Teal icon tile.
- H3/H4 bold title.
- Body 1/2 supporting copy.
- No more than 2 short lines of body text per feature on marketing pages.

## Pricing / package section

Purpose: convert interest into a clear plan decision.

Rules:

- Price must be visually strong and easy to compare.
- Use teal for recommended/active plan emphasis.
- Use yellow only for renewal or balance warning context, not as the main pricing color.
- Each package card should include price, core value, key specs, and CTA.
- Keep plan names simple and consistent with app terminology.
- If showing `chỉ từ 59k`, clarify the unit or condition nearby.

Recommended card hierarchy:

1. Plan name.
2. Price.
3. GPU/performance spec.
4. Key included features.
5. CTA.
6. Secondary details.

## FAQ section

Purpose: remove conversion blockers.

FAQ should answer:

- Thiết bị nào dùng được?
- Có cần cài app không?
- Độ trễ phụ thuộc vào gì?
- Có hỗ trợ tay cầm/microphone không?
- Dữ liệu cloud PC thuộc về ai?
- Thanh toán/gia hạn như thế nào?
- Chính sách hoàn tiền ra sao?

Design rules:

- Use accordion cards on dark glass surfaces.
- Question uses H4/Body 1 Bold.
- Answer uses Body 1/2 regular.
- Keep answers short; link to detailed policy only when needed.

## Final CTA

Purpose: close the page with the same value proposition as the hero.

Rules:

- Repeat the strongest promise, not a new message.
- Use one primary CTA.
- Add one trust/proof line if needed.
- Keep the logo or brand mark nearby but not dominant.

Example:

```text
Sẵn sàng vào Cloud PC?
Dùng ngay 5060Ti trên mọi thiết bị chỉ từ 59k.
```

## Visual style rules

### Backgrounds

- Use deep Cloud Teal or green-black gradients.
- Add blurred teal glow behind hero/device visuals.
- Use white backgrounds only for embedded neutral content or policy surfaces, not core landing sections.

### Cards

- Use glass cards with white opacity border.
- Use 20-32px radius depending on size.
- Use shadow/glow sparingly; contrast and spacing should do most of the hierarchy work.

### Imagery

- Prefer real product screenshots in device/browser frames.
- Floating cards should support the story: games, apps, controller, microphone, shield, location, network.
- Avoid unrelated stock photos or abstract 3D assets that do not explain the product.

### Typography

Use the canonical Figma typography rows in `docs/product/design/thinkmay_design_language.md`.

Landing-specific guidance:

| Use | Style |
| --- | --- |
| Hero headline | Enlarged H1 Bold, white + teal emphasized line |
| Section title | H1/H2 Bold |
| Feature title | H3/H4 Bold |
| Body copy | Body 1 Regular/Medium |
| Proof chips | Body 2 Bold |
| CTA label | Body 1/H4 Bold |
| FAQ answer | Body 1/2 Regular |

Marketing headlines may scale above the app H1 size, but keep the Figma rhythm: strong line-height, short lines, high contrast.

## Responsive behavior

| Width | Behavior |
| --- | --- |
| Desktop | Two-column hero, 4-card feature grid, side-by-side pricing/product proof |
| Tablet | Stacked hero, 2-card feature grid, pricing cards in 2 columns |
| Mobile | Single-column story, compact hero, proof bullets, stacked cards, sticky or repeated CTA |

Rules:

- Do not simply shrink desktop hero text; rewrite copy if needed for mobile.
- Keep CTA visible in the first mobile viewport.
- Preserve safe spacing around logo and device mockups.
- Avoid tiny cards with unreadable screenshots on mobile.

## Motion direction

Landing page motion should feel premium and fast.

Use:

- Hero device fade/slide/parallax.
- Soft teal glow pulse behind primary visual.
- Feature cards appearing in sequence.
- Smooth scroll reveal for proof and pricing sections.
- CTA hover glow on desktop.

Avoid:

- Chaotic bounce or shake.
- Too many simultaneous moving elements.
- Motion that delays reading the hero promise.
- Neon colors outside the Cloud Teal system.

## Copywriting rules

Landing copy should be short, direct, and concrete.

Preferred copy patterns:

- `5060Ti trên mọi thiết bị`
- `Dùng ngay chỉ từ 59k`
- `Cloud Gaming số 1 Việt Nam`
- `App browser trên mọi thiết bị`
- `Hỗ trợ microphone, tay cầm`
- `Cloud của bạn, dữ liệu của bạn`
- `Hạ tầng trong nước, độ trễ tối ưu`

Rules:

- Lead with benefit, then proof.
- Use hardware names only when they matter to the campaign.
- Avoid long technical explanations above the fold.
- Use Vietnamese as default; keep localization variants parallel in meaning, not word-for-word if it weakens clarity.

## Landing page handoff checklist

For designers:

- Page goal and target audience.
- Hero headline, subheadline, CTA copy.
- Section order and responsive behavior.
- Product screenshots/device mockups.
- Feature cards and proof points.
- Pricing/package card content.
- FAQ copy.
- Motion notes.
- Exported SVG/PNG support assets in `docs/shared/assets`.

For developers:

- Treat Figma as the source of truth.
- Map tokens to the shared design language.
- Build sections as reusable landing components.
- Keep product screenshots and marketing assets separated from core UI components.
- Preserve typography sizes/line-height relationships.
- Implement responsive behavior intentionally instead of only scaling desktop down.
- Use accessible headings, focus states, image alt text, and readable contrast.

## Related design material

- `docs/product/design/thinkmay_design_language.md`
- `docs/product/design/thinkmay_mobile_design.md`
- `docs/product/design/thinkmay_desktop_design.md`
- `docs/shared/assets/ui-elements/landing-page-structure.svg`
- `docs/shared/assets/ui-elements/buttons-sample.svg`
- `docs/shared/assets/ui-elements/colors-sample.svg`
- `docs/shared/assets/ui-elements/typography-scale.svg`
- `docs/shared/assets/ui-elements/mobile-ad-composition.svg`
