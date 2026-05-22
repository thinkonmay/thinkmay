# Thinkmay Design Language

This document is the shared product design material for Thinkmay app, web app, landing pages, banners, and video creative. It is intentionally separate from architecture documentation: it describes how Thinkmay should look, feel, and communicate, not how the platform is implemented.

Source of truth: [Figma — Thinkmay Mobile App, Webapp, Landing page](https://www.figma.com/design/LaEXIXc42MwmlIMiO2h3Jr/%F0%9F%93%B1-Thinkmay---Mobile-App--Webapp--Landing-page--Copy-?m=auto&t=PcEoaToTxqQ2pFoz-6)

Only the Figma design should be treated as the reference for this document. Existing implementation under `website/` or any other app code may drift from the intended design language and should not override the Figma direction.

## Design material package

Use this package as the canonical handoff index for designers, frontend developers, mobile developers, and marketing/video creators.

| Material | Location | Purpose |
| --- | --- | --- |
| Design source | Figma file linked above | Canonical product direction, visual style, component intent, and marketing composition |
| Design language document | `docs/product/design/thinkmay_design_language.md` | Human-readable design philosophy, rules, tokens, components, and production checklist |
| Mobile design document | `docs/product/design/thinkmay_mobile_design.md` | Mobile app screen patterns, navigation, components, states, and handoff rules |
| Desktop design document | `docs/product/design/thinkmay_desktop_design.md` | Desktop app shell, wide-screen layouts, navigation, states, and handoff rules |
| Landing page design document | `docs/product/design/thinkmay_landing_page_design.md` | Landing page storytelling, section order, conversion structure, and responsive rules |
| Brand Design sample | `docs/shared/assets/ui-elements/brand-design-sample.svg` | Logo treatment and approved dark brand surfaces |
| Colors sample | `docs/shared/assets/ui-elements/colors-sample.svg` | Figma Colors section: Cloud Teal, accents, and gradient recipes |
| Token swatch sample | `docs/shared/assets/ui-elements/token-swatch-card.svg` | Quick visual reference for Cloud Teal and surface recipes |
| Typography scale sample | `docs/shared/assets/ui-elements/typography-scale.svg` | Visual reference for Figma Typography / STYLES rows |
| Buttons sample | `docs/shared/assets/ui-elements/buttons-sample.svg` | Figma Buttons section: primary, secondary, compact, destructive states |
| Primary CTA sample | `docs/shared/assets/ui-elements/primary-cta-button.svg` | Button shape, color, glow, border, and label treatment |
| Text Fields sample | `docs/shared/assets/ui-elements/text-fields-sample.svg` | Figma Text fields section: search, focused, filled, error, disabled states |
| Toggle sample | `docs/shared/assets/ui-elements/toggle-sample.svg` | Figma Toggle section: on, off, disabled, warning states |
| Glass product card sample | `docs/shared/assets/ui-elements/glass-product-card.svg` | Product card surface, thumbnail, text, and action hierarchy |
| Feature bullet sample | `docs/shared/assets/ui-elements/feature-bullet-row.svg` | Marketing/app feature icon and text treatment |
| Desktop app shell sample | `docs/shared/assets/ui-elements/desktop-app-shell.svg` | Wide-screen desktop shell, sidebar, top bar, dashboard cards, and diagnostics |
| Landing page structure sample | `docs/shared/assets/ui-elements/landing-page-structure.svg` | Landing page nav, hero, proof cards, pricing, FAQ, and final CTA structure |
| Mobile ad composition sample | `docs/shared/assets/ui-elements/mobile-ad-composition.svg` | Repeatable banner/video composition pattern |
| PNG preview sheet | `docs/shared/assets/ui-elements/ui-elements-preview.png` | Raster preview/contact sheet for docs, briefs, and non-SVG tools |

When adding new design material, place the written specification in `docs/product/design` and place reusable exported SVG/PNG samples in `docs/shared/assets`.

## Surface system model

Thinkmay has one shared brand language, but multiple surface-specific design systems. Do not force app UI, landing pages, and marketing creative to reuse the same layout/component patterns one-to-one.

| Surface system | Primary purpose | Design expression | What it should reuse | What it should not copy blindly |
| --- | --- | --- | --- | --- |
| Product App UI | Help users control cloud PCs, sessions, plans, settings, and diagnostics | Functional, calmer, denser, state-driven | Cloud Teal tokens, typography rows, logo, buttons, cards, status colors | Landing-page hero composition, oversized marketing headlines, decorative floating elements |
| Mobile App UI | Thumb-first cloud PC control from phone screens | Compact, focused, safe-area aware | Product app semantics, mobile spacing, shared tokens/components | Desktop sidebars, wide grids, dense tables |
| Desktop/Webapp UI | Wide-screen cloud PC command center | Spacious control shell with sidebar/top bar, metrics, diagnostics | Product app semantics, shared tokens/components, desktop interaction states | Landing-page conversion sections as core app navigation |
| Landing Page UI | Acquisition, education, and conversion | Cinematic, persuasive, spacious, proof-led | Brand tokens, typography rhythm, logo, CTA language, product screenshots | Product app shell, settings rows, dense diagnostics, desktop sidebar patterns |
| Marketing Creative | Banners, social posts, video, ads | Most expressive and motion-friendly | Brand tokens, headline rhythm, device continuity, product proof | Functional app layouts as-is; detailed settings/payment UI |

Use this rule of thumb: **the brand stays consistent, but each surface has its own layout system, density, and component emphasis**.

## Design philosophy

Thinkmay should feel like a personal high-performance cloud computer: powerful, fast, private, and ready to launch from any device. The visual language combines a dark cloud-control-room base with bright teal energy to suggest low latency, GPU performance, and always-on access.

The brand should not feel like generic SaaS, crypto, or consumer social media. It should feel like a premium gaming/workstation product that is technically serious but still simple enough for first-time cloud gaming users.

### Core principles

1. **Performance first** — lead with speed, GPU power, low latency, and instant access. Hero visuals should show devices, gaming/workstation UI, connection states, or product screenshots instead of abstract decoration alone.
2. **Personal cloud ownership** — reinforce security and control with copy such as `Cloud của bạn, dữ liệu của bạn` and private-cloud visual motifs.
3. **Dark premium foundation** — use deep green-black surfaces as the default environment. White backgrounds should be rare and mostly reserved for documentation, exports, or neutral product surfaces.
4. **Teal energy, not rainbow color** — teal is the signature action/accent color. Other accent colors exist for system states only.
5. **Simple Vietnamese-first messaging** — copy should be direct, practical, and benefit-led. Prefer short phrases users can understand in one glance.
6. **Device continuity** — web, mobile, banners, and videos should all show that the same cloud PC follows the user across phone, laptop, browser, controller, and microphone flows.

## Brand identity

### Logo

Use the white Thinkmay cloud logo on dark green surfaces. The logo works best when it has generous breathing room and is not placed on busy screenshots.

Guidelines:

- Prefer white logo on `Cloud 10` / `#0A2926` or dark gradient backgrounds.
- Keep the logo sharp and flat; do not add heavy bevels, shadows, outlines, or extra color fills.
- In banners, place the logo in a quiet corner or as a small trust mark; the product/device hero should remain dominant.
- Do not recolor the logo into random accent colors.

## Color system

The Figma file labels the main hue ramp as `Golden Purple`, but the actual product color is a teal/cloud-green ramp. In implementation and design discussion, use the clearer alias **Cloud Teal** while preserving the Figma token mapping where needed.

### Cloud Teal palette

| Role | Figma token | Hex | Use |
| --- | --- | --- | --- |
| Deep background | `Golden Purple / 10` | `#0A2926` | Main product background, guide background, dark brand canvas |
| Deep surface | `Golden Purple / 9` | `#134E48` | Cards, secondary filled surfaces, button base |
| Elevated dark surface | `Golden Purple / 8` | `#125D56` | Alternating table rows, panels, dense content backgrounds |
| Active surface | `Golden Purple / 7` | `#107569` | Active rows, selected states, medium emphasis surfaces |
| Primary brand | `Golden Purple / 6` | `#0E9384` | Header bars, primary UI color, brand blocks |
| Strong accent | `Golden Purple / 5` | `#15B79E` | CTA depth, progress, glow start |
| Action highlight | `Golden Purple / 4` | `#2ED3B7` | Primary gradient highlight, icon highlights |
| Electric highlight | `Golden Purple / 3` | `#5FE9D0` | Marketing emphasis, bullet icons, glow, price highlights |
| Soft highlight | `Golden Purple / 2` | `#99F6E0` | Light glow, hover sheen, selected halos |
| Pale highlight | `Golden Purple / 1` | `#CCFBEF` | Rare high-contrast highlights or illustrations |

### Neutral system

| Token | Use |
| --- | --- |
| `White 100%` | Primary text and logo on dark backgrounds |
| `White 85%` | High-emphasis secondary text |
| `White 65%` | Secondary text and metadata |
| `White 45%` | Captions, labels, disabled text on dark backgrounds |
| `White 30%`, `20%`, `12%`, `8%`, `4%` | Dividers, overlays, disabled surfaces, and glass layering |
| `Black 85%`, `65%`, `45%`, `25%`, `15%`, `6%`, `4%`, `2%` | Dark overlays, inverse surfaces, shadows, and depth layers |

Use white opacity overlays for glass and borders:

- `rgba(255,255,255,0.04)` for barely visible surfaces.
- `rgba(255,255,255,0.08)` for card borders and secondary panels.
- `rgba(255,255,255,0.10)` for guide/documentation frame borders.
- `rgba(255,255,255,0.23)` for active navigation fills.
- Avoid pure gray borders that are not tinted by the brand background.

### Accent colors

| Token | Value | Use |
| --- | --- | --- |
| `red-accent` | `#DD2D4A` | Error, danger, destructive actions only |
| `blue-accent` | `#0CBCD4` | Informational state or network/diagnostic details |
| `yellow-accent` | `#F1CA36` | Warning, upcoming renewal, attention |
| `green-accent` | `#33BE3F` | Success, healthy connection, ready states |

Do not use accent colors as brand campaign colors unless the message is explicitly a system state.

### Gradients and surface recipes

Use gradients to make the product feel energetic and technical, but keep them restrained.

| Recipe | Value | Use |
| --- | --- | --- |
| App background | `linear-gradient(180deg, #0F463F 0%, #071F1C 68.13%)` | Full-screen app shell, landing hero background |
| Primary teal gradient | `linear-gradient(180deg, #2ED3B7 -6.9%, #134E48 108.42%)` | Primary illustrations, highlight slabs |
| Dark-to-brand gradient | `linear-gradient(180deg, #0A2926 16.17%, #15B79E 92.96%)` | Marketing glow, video transitions |
| Diagonal teal glow | `linear-gradient(111.68deg, #134E48 16.37%, #2ED3B7 88.94%)` | Device halo, badge depth |
| Primary CTA border/fill | layered teal border + `#134E48` base + soft glow | Main action buttons |
| Glass card | transparent white layer over dark + optional `rgba(95,233,208,0.03)` | Navigation, cards, overlays |

Marketing banners can add blur, glow, and device reflections. Product UI should use less glow and more clear hierarchy.

## Typography

The Figma system uses `SF UI Display` and `SF UI Text` heavily, with `Rubik` for some product headings and `Roboto` in a few body samples. Treat SF UI as the design source; map to platform-appropriate fonts when SF UI is unavailable.

Recommended platform mapping:

- **iOS/macOS:** `SF UI Display` / `SF UI Text`, or native San Francisco system fonts.
- **Android:** `Roboto`, matching the same size, line-height, and weight.
- **Web:** preserve the Figma metrics and map the type scale into the web font stack. If SF UI is unavailable, use `Inter`, `Roboto`, or system sans as fallback.
- **Marketing exports:** use the Figma typography directly when exporting from Figma.

### Type scale

Reference asset: `docs/shared/assets/ui-elements/typography-scale.svg`.

The Figma `Typography / STYLES` rows below are canonical. Keep the size and line-height pair together; do not reuse a size with a different line-height unless the new use case is intentionally outside the product design system.

#### Titles

| Group | Figma row | Size | Line | Style | Weight | Primary use |
| --- | --- | --- | --- | --- | --- | --- |
| `TITLES / H1` | `H1 40 | 45 | Light` | 40 | 45 | Light | 300 | Large screen titles, rare quiet hero titles |
| `TITLES / H1` | `H1 40 | 45 | Regular` | 40 | 45 | Regular | 400 | Large readable titles when bold is too loud |
| `TITLES / H1` | `H1 40 | 45 | Medium` | 40 | 45 | Medium | 500 | Default major screen title |
| `TITLES / H1` | `H1 40 | 45 | Bold` | 40 | 45 | Bold | 700 | Hero title, major campaign/app promise |
| `TITLES / H2` | `H2 32 | 40 | Light` | 32 | 40 | Light | 300 | Spacious section title, low emphasis |
| `TITLES / H2` | `H2 32 | 40 | Regular` | 32 | 40 | Regular | 400 | Default landing section title |
| `TITLES / H2` | `H2 32 | 40 | Medium` | 32 | 40 | Medium | 500 | Product section title, modal title |
| `TITLES / H2` | `H2 32 | 40 | Bold` | 32 | 40 | Bold | 700 | Strong section title, feature block title |
| `TITLES / H3` | `H3 24 | 30 | Light` | 24 | 30 | Light | 300 | Quiet card/section heading |
| `TITLES / H3` | `H3 24 | 30 | Regular` | 24 | 30 | Regular | 400 | Standard card title |
| `TITLES / H3` | `H3 24 | 30 | Medium` | 24 | 30 | Medium | 500 | Default product/card title |
| `TITLES / H3` | `H3 24 | 30 | Bold` | 24 | 30 | Bold | 700 | Emphasized card title or offer title |
| `TITLES / H4` | `H4 20 | 30 | Light` | 20 | 30 | Light | 300 | Quiet compact section heading |
| `TITLES / H4` | `H4 20 | 30 | Regular` | 20 | 30 | Regular | 400 | Standard compact heading |
| `TITLES / H4` | `H4 20 | 30 | Medium` | 20 | 30 | Medium | 500 | Default compact heading/navigation group |
| `TITLES / H4` | `H4 20 | 30 | Bold` | 20 | 30 | Bold | 700 | Compact emphasis, tab/header label |

#### Body text

| Group | Figma row | Size | Line | Style | Weight | Primary use |
| --- | --- | --- | --- | --- | --- | --- |
| `TEXT / BODY 1` | `B1 15 | 22 | Light` | 15 | 22 | Light | 300 | Long secondary descriptions on spacious surfaces |
| `TEXT / BODY 1` | `B1 15 | 22 | Regular` | 15 | 22 | Regular | 400 | Default paragraph/body copy |
| `TEXT / BODY 1` | `B1 15 | 22 | Medium` | 15 | 22 | Medium | 500 | Default UI body, form values, card content |
| `TEXT / BODY 1` | `B1 15 | 22 | Bold` | 15 | 22 | Bold | 700 | Inline body emphasis, important values |
| `TEXT / BODY 2` | `B2 13 | 18 | Light` | 13 | 18 | Light | 300 | Low-emphasis metadata |
| `TEXT / BODY 2` | `B2 13 | 18 | Regular` | 13 | 18 | Regular | 400 | Helper text, metadata, compact descriptions |
| `TEXT / BODY 2` | `B2 13 | 18 | Medium` | 13 | 18 | Medium | 500 | Compact labels and field values |
| `TEXT / BODY 2` | `B2 13 | 18 | Bold` | 13 | 18 | Bold | 700 | Small but important labels/status values |
| `TITLES / BODY 3` | `B3 11 | 14 | Light` | 11 | 14 | Light | 300 | Dense annotation only |
| `TITLES / BODY 3` | `B3 11 | 14 | Regular` | 11 | 14 | Regular | 400 | Dense metadata and tiny helper text |
| `TITLES / BODY 3` | `B3 11 | 14 | Medium` | 11 | 14 | Medium | 500 | Small labels in dense controls |
| `TITLES / BODY 3` | `B3 11 | 14 | Bold` | 11 | 14 | Bold | 700 | Tiny emphasis; avoid for primary actions |
| `TITLES / BODY 4` | `B4 08 | 11 | Regular` | 8 | 11 | Regular | 400 | Micro labels only, not core readable content |
| `TITLES / BODY 4` | `B4 08 | 11 | Bold` | 8 | 11 | Bold | 700 | Micro emphasis only, such as tiny badges in artwork |

#### Typography application rules

- Use H1/H2 for page and marketing hierarchy; use H3/H4 for cards, feature groups, and compact product surfaces.
- Use Body 1 for default readable UI content; Body 2 for metadata/helper text; Body 3/4 only where density requires it.
- Preserve Vietnamese diacritics by keeping the Figma line-height values.
- Use bold for decisive actions, prices, GPU names, product promises, and card titles.
- Use medium/regular for ordinary UI content. Avoid very light text on small sizes.
- Marketing headlines may scale above H1, but should preserve the same rhythm: short line, teal emphasized line, strong contrast.

Example marketing hierarchy:

```text
5060Ti trên mọi thiết bị
Dùng ngay chỉ từ 59k
```

Use white for the first line and electric teal for the second line or price/benefit emphasis.

## Layout and composition

### Product screens

Product UI should feel like a focused control surface:

- Use a dark full-screen shell.
- Use rounded cards with subtle white/teal overlays.
- Keep primary content centered and readable; avoid decorative clutter inside functional screens.
- Group settings and diagnostics into clear card sections.
- Use bottom navigation/tab bars with glassy active states.
- Keep destructive or shutdown controls visually distinct but not alarming unless action is final.

### Marketing and banner composition

Banners and videos should be more cinematic than app screens while still using the same tokens.

Recommended composition:

1. Dark teal/black blurred background.
2. Device mockup or product screenshot as the hero.
3. Floating app/game cards, controllers, or connection icons as depth elements.
4. Short headline with one teal-highlighted proof point.
5. 3-4 benefit bullets max.
6. Logo placed quietly, not competing with the headline.

For the existing mobile ad direction, the repeatable structure is:

- Background image or abstract cloud/gaming scene.
- Dark translucent green overlay with blur.
- Large central phone/device screenshot.
- Floating icon cards around the device.
- White headline with teal line break.
- Product proof subtitle: `Thinkmay - Cloud Gaming số 1 Việt Nam`.
- Feature bullets using teal icons.

### Spacing

Use an 8px spacing foundation with these common values:

| Token | Value | Use |
| --- | --- | --- |
| `space-1` | `4px` | Tiny offsets, icon optical correction |
| `space-2` | `8px` | Dense gaps |
| `space-3` | `12px` | Button inner gaps |
| `space-4` | `16px` | Compact card padding |
| `space-6` | `24px` | Standard mobile/card spacing |
| `space-8` | `32px` | Section and component group spacing |
| `space-11` | `44px` | Mobile status/navigation safe-area reference |
| `space-15` | `60px` | Large app sections |
| `space-30` | `120px` | Design-system guide padding and large desktop sections |

### Radius

| Radius | Use |
| --- | --- |
| `12px` | Primary CTA buttons, compact controls |
| `20px` | Icon tiles, text fields, small cards |
| `24px` | Product cards and media cards |
| `32px+` | Hero cards, large panels, device wrappers |
| `80px` | Design guide frames and large showcase containers only |

### Button material

Reference asset: `docs/shared/assets/ui-elements/primary-cta-button.svg`.

| Property | Primary CTA |
| --- | --- |
| Height | `54-68px`, depending on density and canvas |
| Radius | `12px` |
| Fill | Deep teal base, usually `#134E48` |
| Border | Teal gradient highlight using `#15B79E`, `#2ED3B7`, `#99F6E0` |
| Shadow | Soft teal glow, low opacity |
| Text | White, medium/bold, centered |
| Icon | Optional left icon in `#5FE9D0` |

### Card material

Reference asset: `docs/shared/assets/ui-elements/glass-product-card.svg`.

| Property | Product card |
| --- | --- |
| Fill | Dark green surface with subtle white overlay |
| Border | `rgba(255,255,255,0.08)` |
| Radius | `20-24px` |
| Thumbnail | Rounded rectangle, 16-20px radius |
| Title | White H3/H4 bold |
| Metadata | White 45-65% neutral |
| Action | Primary teal button or compact icon action |

### Feature bullet material

Reference asset: `docs/shared/assets/ui-elements/feature-bullet-row.svg`.

| Property | Feature bullet |
| --- | --- |
| Icon tile | 36-48px, rounded, teal low-opacity fill |
| Icon | Electric teal `#5FE9D0` |
| Copy | White, medium, short phrase |
| Layout | Two-column on wide banners, one-column on narrow mobile/story layouts |

## Component language

### Buttons

Primary buttons should look like energetic cloud controls:

- Dark teal base (`#134E48`).
- Teal gradient border/highlight.
- 12px radius.
- Soft teal shadow or glow.
- Bold or medium label.

Use primary buttons for actions such as login, start, connect, confirm, buy, and recharge. Secondary buttons should be glass cards with white/teal overlays. Destructive buttons should use red only at the final action layer.

### Text fields

Text fields should sit on dark surfaces with low-contrast borders and clear placeholder text.

- Background: dark green glass/surface.
- Border: `rgba(255,255,255,0.08)` or similar.
- Placeholder: `neutral-white-45`.
- Text: white or `neutral-white-85`.
- Search fields may use icon-leading layout and compact 20px radius.

### Toggles and status controls

Toggles should communicate connection/availability clearly:

- On state: teal gradient or strong teal fill.
- Off state: muted dark surface with white opacity border.
- Disabled state: low-opacity text and border; do not rely on color alone.

### Cards

Cards are the main product container:

- Dark green background with subtle white overlay.
- 1px or 0.5px white-opacity border.
- Rounded corners, typically 20-24px.
- Use shadows/glow sparingly; content hierarchy should come from spacing, typography, and color.
- Game/work cards should show thumbnail, title, recent activity/time, and quick action.

### Navigation

Navigation should be glassy and quiet:

- Default: subtle transparent white + faint teal overlay.
- Active: stronger white overlay (`~23%`) and/or teal cue.
- Icons should be simple and legible at small sizes.
- Keep labels short.

### Badges

Badges can be more expressive in marketing and product discovery:

- Use teal for active/live/available.
- Use yellow for renewal or warning.
- Use red for errors or destructive state.
- Keep badge copy short: `HOT`, `Mới`, `Sắp gia hạn`, `Live`, `Ready`.

## Iconography and illustration

Icon style should be rounded, modern, and technical. The Figma file uses Vuesax-style bold icons in guide headers, and the ad creative uses Font Awesome-style symbolic bullets.

Guidelines:

- Use consistent stroke/fill style within a screen.
- Use teal for feature icons and active states.
- Use white or neutral icons for default navigation.
- Use icons to support scanning, not to replace critical text.
- For banners, icons can float in depth around devices, but they should use rounded app-card containers and subtle borders.

## Imagery, screenshots, and device mockups

Thinkmay imagery should make the cloud PC feel tangible.

Use:

- Phone or desktop device frames showing the actual product UI.
- Game/application thumbnails in rounded cards.
- Cloud, network, GPU, controller, microphone, browser, and shield motifs.
- Blurred dark backgrounds with teal highlights.

Avoid:

- Random stock technology imagery that does not show product value.
- Overly bright white screenshots without a dark brand container.
- Busy backgrounds behind logo or small text.
- Too many floating elements around functional product UI.

### Marketing composition material

Reference asset: `docs/shared/assets/ui-elements/mobile-ad-composition.svg`.

| Layer | Required treatment |
| --- | --- |
| Background | Dark teal/black image or abstract cloud field with blur |
| Overlay | Translucent green-black panel, stronger at bottom for text contrast |
| Hero object | Phone, desktop, or browser mockup showing actual product UI |
| Depth objects | Floating rounded app/game/icon cards, low opacity borders |
| Headline | White first line, teal price/proof line |
| Proof line | Short brand proof such as `Thinkmay - Cloud Gaming số 1 Việt Nam` |
| Feature bullets | 3-4 max, teal icons, white copy |
| Logo | White, quiet corner or top-left, not larger than the headline |

## Motion and video direction

Motion should communicate instant access and low latency.

Recommended motion language:

- Smooth fades and vertical slides for app transitions.
- Teal pulse/glow for connect, ready, stream, and active states.
- Device/screenshot parallax for marketing intros.
- Floating icons moving slowly in depth, not bouncing aggressively.
- Fast but readable CTA reveal after the value proposition.

Video structure for ads:

1. Hook: device + GPU/price promise in the first 1-2 seconds.
2. Proof: show app/browser/device continuity.
3. Benefits: microphone, controller, data ownership, local infrastructure.
4. CTA: start/use now with price or package cue.

Keep motion premium and controlled. Avoid meme-style shake, random neon colors, or chaotic transitions unless the campaign explicitly calls for a different tone.

## Copywriting voice

Thinkmay copy should be practical, confident, and benefit-led.

Preferred patterns:

- `5060Ti trên mọi thiết bị`
- `Dùng ngay chỉ từ 59k`
- `Thinkmay - Cloud Gaming số 1 Việt Nam`
- `App browser trên mọi thiết bị`
- `Hỗ trợ microphone, tay cầm`
- `Cloud của bạn, dữ liệu của bạn`
- `Hạ tầng trong nước, độ trễ tối ưu`

Guidelines:

- Prefer direct user benefit over technical explanation.
- Mention hardware/GPU names when they are campaign-critical.
- Mention latency and local infrastructure when trust/performance matters.
- Keep UI labels short and literal.
- Use Vietnamese as the default product/marketing language unless the surface is explicitly localized.

## Implementation guidance

### Web frontend

When implementing web UI:

- Derive the web token layer from the Figma tokens in this document.
- If existing web styles conflict with the Figma direction, prefer Figma and update the implementation tokens to match.
- Convert Figma-generated code into project components and design tokens before production use.
- Preserve the design metrics even when the exact Figma font is unavailable.
- Keep decorative banner code separate from reusable app UI components.

### Mobile app

When implementing mobile UI, mirror the same token names in the mobile theme layer:

- Define Cloud Teal palette, neutral overlays, accent colors, radii, and spacing in one place.
- Use native platform typography but preserve size/line-height/weight hierarchy.
- Match the product shell: dark background, teal primary action, glass cards, compact readable labels.
- Treat banners and promotional art as assets/marketing components, not as core app widgets.

### Designer handoff

For any new app screen, banner, or video concept, provide:

- Target format: app screen, landing page section, banner, story/reel, desktop video, etc.
- Canvas size and safe areas.
- Token names or palette references.
- Type scale used.
- Source screenshots/device frames.
- Interaction or motion notes if applicable.
- Export requirements and localization variants.

## Do and don't

### Do

- Use deep green-black backgrounds as the default brand environment.
- Highlight one key line, number, price, or hardware term in electric teal.
- Show real product UI or believable device mockups.
- Use subtle glass cards and rounded surfaces.
- Keep marketing copy short and benefit-led.
- Keep app screens quieter than marketing assets.

### Don't

- Do not make Thinkmay look like a generic blue SaaS dashboard.
- Do not introduce unrelated brand colors for campaigns.
- Do not overuse glow in functional UI.
- Do not place long Vietnamese copy on busy imagery.
- Do not shrink text below the defined type scale for important content.
- Do not copy Figma-generated code directly into production without converting it to the project styling system.

## Quick production checklist

Before shipping a screen, banner, or video:

- Uses Cloud Teal + dark neutral foundation.
- Primary action is clearly teal and high contrast.
- Typography follows the shared scale or a deliberate marketing enlargement.
- Text is readable with Vietnamese diacritics.
- Device screenshots are current and not distorted.
- Logo has quiet space and is not competing with the hero.
- System accents are used only for status meaning.
- Web/mobile implementation uses shared tokens, not one-off hardcoded colors.
- Banner/video still reads clearly in the first second or at thumbnail size.
