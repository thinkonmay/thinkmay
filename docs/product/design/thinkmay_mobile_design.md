# Thinkmay Mobile Design

This document describes the Thinkmay mobile app design direction. It is a product design document, not an architecture document. Use it alongside `docs/product/design/thinkmay_design_language.md`.

Source of truth: [Figma — Thinkmay Mobile App, Webapp, Landing page](https://www.figma.com/design/LaEXIXc42MwmlIMiO2h3Jr/%F0%9F%93%B1-Thinkmay---Mobile-App--Webapp--Landing-page--Copy-?m=auto&t=PcEoaToTxqQ2pFoz-6)

Only the Figma design is authoritative. Existing app or web implementation may drift and should not override this document.

## Mobile design intent

The Thinkmay mobile app should feel like a compact command center for a personal cloud PC. It must make a remote high-performance Windows machine feel close, private, and ready to launch from a phone.

The mobile design is not a generic account dashboard. Its primary job is to help users:

1. Understand what cloud PC they have.
2. Start or return to a session quickly.
3. Manage account, plan, server, and payment state clearly.
4. Diagnose controls/network when streaming does not feel right.
5. Trust that the cloud PC and data belong to them.

## Mobile experience principles

1. **Launch-first hierarchy** — the user should always know the fastest path to start or resume a cloud PC.
2. **Dark premium shell** — default screens use the deep Cloud Teal background, glass cards, and white text.
3. **Calm technical confidence** — make server, plan, device, and diagnostic information visible without making the app feel like an admin console.
4. **Thumb-first interaction** — primary actions should sit in reachable zones, with large enough touch targets.
5. **Readable Vietnamese UI** — keep labels direct and preserve line-height for Vietnamese diacritics.
6. **Streaming context awareness** — controls, diagnostics, and settings should acknowledge microphone, controller, keyboard, network, and cloud PC state.

## Canonical mobile surfaces

### Splash screen

Purpose: brand entry and app loading.

Design rules:

- Use the dark Cloud Teal background.
- Center the white Thinkmay cloud logo.
- Avoid extra text unless loading or version information is required.
- If animation is used, use a subtle teal glow or fade; do not bounce or spin the logo aggressively.

### Authentication screens

Purpose: login, account creation, server selection, and social sign-in.

Observed Figma material includes:

- `Đăng nhập`
- `Tạo tài khoản`
- Server selection section
- Social media sign-in row
- Forgot password link
- Divider text

Design rules:

- Use a dark app background with a clear form card or stacked form group.
- Use H1/H2 for screen title, Body 1 for supporting text, Body 2 for helper/error text.
- Text fields use dark glass fill, white text, and muted placeholder.
- Primary CTA uses the Cloud Teal button treatment.
- Social sign-in stays secondary; it should not outshine the primary login/register action.
- Server selection should communicate location/performance in simple terms, not infrastructure jargon.

### Home / Cloud PC overview

Purpose: show cloud PC availability and the main start/resume action.

Observed Figma material includes:

- Work/game card patterns
- `Công việc của bạn`
- `Truy cập nhanh các công cụ làm việc`
- Recent time metadata such as `13 tiếng trước`
- Game/work details and quick action controls

Design rules:

- Main card should show the current cloud PC/session first.
- Use a large rounded product card with thumbnail/icon, title, status, metadata, and primary action.
- Primary action should be obvious: start, open, connect, or resume.
- Secondary actions should be compact icon buttons.
- Use status color only when meaningful: green for ready/success, yellow for warning/renewal, red for blocking problem.
- Empty states should still feel productive: explain what the user can do next.

### Store / package / renewal surfaces

Purpose: package discovery, renewal warnings, and payment flow entry.

Observed Figma material includes:

- `Gói dịch vụ sắp gia hạn`
- Package renewal warning copy
- Cards for service/package information

Design rules:

- Put package name, renewal date, price, and balance state in one card.
- Use yellow accent for renewal warning or insufficient balance warning.
- Use red only when the service is blocked or the action is destructive.
- Price and plan names should use bold text.
- Long payment/renewal copy should be split into a title, one short paragraph, and one clear action.

### Settings

Purpose: account, diagnostics, app settings, support, community, and logout.

Observed Figma material includes:

- `Cài đặt`
- `Tài khoản`
- `Thông tin cá nhân`
- `Đổi mật khẩu`
- `Công cụ chuẩn đoán`
- `Kiểm tra bàn phím`
- `Kiểm tra tay cầm`
- `Kiểm tra mạng`
- `Cài đặt khác`
- `Cài đặt nâng cao`
- `Ứng dụng`
- `Ngôn ngữ: Tiếng Việt`
- `Cài đặt thông báo`
- `Hỗ trợ`
- `Báo lỗi/ Hỗ trợ`
- `Điều khoản`
- `Chính sách hoàn tiền`
- `Cộng đồng Thinkmay`
- `Thinkmay trên Facebook`
- `Thinkmay trên Discord`
- `Đăng xuất`

Design rules:

- Settings should be grouped into rounded glass sections.
- Each row uses icon + label + optional value + arrow.
- Section labels use H4 or Body 1 bold depending on density.
- Row labels use Body 1 medium; values/help text use Body 2.
- Diagnostics rows should feel useful, not hidden; keyboard, gamepad, and network checks are important for streaming trust.
- Logout should be visually separated and use red only if needed for emphasis.

### Streaming controls and diagnostics

Purpose: support remote desktop/cloud gaming use from a phone.

Observed Figma material includes:

- Keyboard layouts
- Control/diagnostic tools
- Sound collection/card patterns
- Restart/shutdown icon patterns

Design rules:

- Controls must remain large enough for touch and should avoid tiny Body 4 labels unless purely decorative.
- Use glass panels over streaming content when controls overlay video.
- Critical actions such as shutdown, restart, disconnect, or logout require visual separation and confirmation.
- Network/keyboard/gamepad checks should use simple pass/fail/attention states.
- When an overlay covers the stream, keep the background dimmed and maintain contrast.

## Mobile navigation

The Figma direction favors a dark shell with compact navigation and glass active states.

Navigation rules:

- Use bottom navigation or tab bar for primary app areas.
- Keep labels short and literal.
- Default nav item: white/neutral icon and muted label.
- Active nav item: stronger white overlay and/or Cloud Teal cue.
- Avoid more than 5 primary nav items.
- Do not hide core actions behind deep menus when the action affects starting or controlling a cloud PC.

Recommended primary areas:

| Area | Purpose |
| --- | --- |
| Home / Play | Cloud PC status and start/resume action |
| Store / Plan | Packages, renewal, top-up/payment path |
| Diagnostics | Keyboard, gamepad, microphone, network checks |
| Settings | Account, app, support, community, logout |

If navigation must be reduced, diagnostics can live inside Settings, but it should remain easy to find.

## Mobile layout system

### Canvas and safe areas

- Design for modern mobile screens with safe-area awareness.
- Preserve top status-bar spacing; Figma references `Space-44px (Status Bar)`.
- Bottom navigation must account for home indicator/safe area.
- Content should not sit flush to screen edges.

### Spacing

Use the shared 8px spacing system with mobile emphasis:

| Value | Mobile use |
| --- | --- |
| `8px` | Tiny gaps inside dense controls |
| `12px` | Icon-to-label gaps, compact row gaps |
| `16px` | Row/card inner padding minimum |
| `20px` | Common card horizontal padding |
| `24px` | Standard screen section gap |
| `32px` | Large group separation |
| `44px` | Status bar/safe-area reference |

### Radius

| Radius | Mobile use |
| --- | --- |
| `12px` | Buttons, compact pills, small actions |
| `16px` | Dense setting rows or chips |
| `20px` | Text fields, icon tiles, default small cards |
| `24px` | Main cards and media cards |
| `32px` | Hero cards or large visual containers |

### Touch targets

- Minimum touch target: `44x44px`.
- Preferred primary button height: `52-56px`.
- Icon-only action buttons should be at least `44x44px`.
- Keep destructive icon-only actions away from primary action clusters.

## Mobile typography

Use the canonical typography rows from `docs/product/design/thinkmay_design_language.md`.

Mobile-specific application:

| Use | Style |
| --- | --- |
| Screen title | H1 Medium/Bold or H2 Bold depending on density |
| Section title | H3/H4 Bold |
| Card title | H3 Medium/Bold or H4 Bold |
| Row label | Body 1 Medium |
| Row value | Body 2 Medium/Regular |
| Helper text | Body 2 Regular |
| Dense metadata | Body 3 Regular/Medium |
| Micro labels | Body 4 only when non-critical |
| Primary button label | Body 1 Bold or H4 Bold |

Rules:

- Keep Vietnamese text readable by preserving line-height.
- Do not use Body 3/4 for primary actions, warnings, payment amounts, or session status.
- Use bold for prices, plan names, GPU names, warnings, and active session state.

## Mobile components

### Primary button

Reference: `docs/shared/assets/ui-elements/primary-cta-button.svg`.

- Fill: deep teal with gradient border/highlight.
- Radius: `12px`.
- Height: `52-56px` in app screens.
- Label: white, Body 1 Bold or H4 Bold.
- Use for login, create account, start, connect, pay, recharge, confirm.

### Secondary button

- Fill: white overlay on dark surface.
- Border: white opacity `8-10%`.
- Text/icon: white or Cloud Teal.
- Use for cancel, alternate sign-in, settings actions, minor controls.

### Text field

- Fill: dark glass/surface.
- Border: white opacity `8%`.
- Radius: `20px`.
- Placeholder: muted white/neutral.
- Text: white.
- Error: red accent with short helper text.

### Settings row

- Height: comfortable enough for thumb scanning.
- Left: icon tile or icon.
- Middle: label and optional subtitle/value.
- Right: arrow or current value.
- Group rows inside a rounded card section.

### Product/session card

Reference: `docs/shared/assets/ui-elements/glass-product-card.svg`.

- Thumbnail or cloud PC icon on the left/top.
- Title and status clearly visible.
- Recent activity metadata below.
- Primary action inside the card.
- Optional compact secondary actions.

### Feature bullet

Reference: `docs/shared/assets/ui-elements/feature-bullet-row.svg`.

- Use in onboarding, marketing panels, plan explanation, or empty states.
- Icon tile uses teal low-opacity fill.
- Copy is short and direct.

### Warning/payment card

- Use yellow accent for renewal/insufficient balance.
- Title is bold and direct.
- Body is Body 1/2, split into short lines.
- CTA is primary teal unless the action is destructive.

## Mobile states

| State | Visual treatment |
| --- | --- |
| Ready | Green/success accent or Cloud Teal active cue |
| Connecting | Teal pulse/progress; keep text explicit |
| Streaming | Active session card/control state; avoid excessive decoration |
| Warning | Yellow accent, short explanation, clear next action |
| Error/blocking | Red accent, concise error text, recovery action |
| Empty | Dark card with useful explanation and primary next step |
| Disabled | Lower opacity surface/text; never rely only on disabled color if action matters |

## Mobile visual hierarchy

A good Thinkmay mobile screen should read in this order:

1. Where am I? — screen title or active navigation.
2. What is my cloud PC/session state? — primary card/status.
3. What should I do next? — primary CTA.
4. What else can I manage? — secondary cards/rows.
5. Where do I get help? — support/diagnostic paths.

If a screen does not answer the first three questions quickly, simplify it.

## Mobile marketing inside app

Promotional or package surfaces inside mobile should use the brand language but remain calmer than external ads.

Use:

- Device/cloud PC card as proof.
- One headline, one short paragraph, one action.
- Teal highlight on price or strongest promise.
- Yellow only for renewal/warning, not as a general campaign color.

Avoid:

- Full ad composition inside every app screen.
- Too many floating icons inside functional UI.
- Long paragraphs above the primary action.

## Accessibility and readability

- Text on dark backgrounds should use white or high-opacity neutral.
- Avoid placing text directly on busy images.
- Use clear labels for icon-only buttons where possible.
- Maintain `44x44px` touch targets.
- Do not use color alone to communicate error/success/warning.
- Keep Vietnamese copy short enough to avoid awkward truncation.

## Mobile handoff checklist

For each mobile screen, designers should provide:

- Screen name and purpose.
- Primary user action.
- Empty/loading/error states.
- Safe-area behavior.
- Navigation state.
- Component variants used.
- Typography rows used.
- Color tokens used.
- Required icons/assets.
- Motion/transition notes.
- Copy in Vietnamese and any localized variants.

For developers, implementation should:

- Map all colors to the Figma tokens in the design language document.
- Preserve the typography size/line-height pairs.
- Implement shared component variants instead of one-off screen styling.
- Keep banner/promo artwork as design assets, not hardcoded product UI.
- Treat Figma as source of truth when existing implementation disagrees.

## Related design material

- `docs/product/design/thinkmay_design_language.md`
- `docs/shared/assets/ui-elements/primary-cta-button.svg`
- `docs/shared/assets/ui-elements/glass-product-card.svg`
- `docs/shared/assets/ui-elements/feature-bullet-row.svg`
- `docs/shared/assets/ui-elements/typography-scale.svg`
- `docs/shared/assets/ui-elements/mobile-ad-composition.svg`
