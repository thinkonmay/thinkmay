# Thinkmay Desktop App Design

This document describes the Thinkmay desktop app and desktop web-app design direction. It is a product design document, not an architecture document. Use it alongside `docs/product/design/thinkmay_design_language.md` and `docs/product/design/thinkmay_mobile_design.md`.

Source of truth: [Figma — Thinkmay Mobile App, Webapp, Landing page](https://www.figma.com/design/LaEXIXc42MwmlIMiO2h3Jr/%F0%9F%93%B1-Thinkmay---Mobile-App--Webapp--Landing-page--Copy-?m=auto&t=PcEoaToTxqQ2pFoz-6)

Only the Figma design is authoritative. Existing web or app implementation may drift and should not override this document.

## Desktop design intent

The Thinkmay desktop app should feel like a wide-screen command center for cloud PCs: more spacious and data-rich than mobile, but still focused on fast launch, session clarity, plan status, and diagnostics.

Desktop should make Thinkmay feel powerful and professional. The user should understand at a glance which cloud PC is available, whether it is ready, what plan/session state exists, and what action to take next.

## Desktop experience principles

1. **Workspace control center** — desktop can show more panels, metrics, and diagnostics than mobile, but the primary Cloud PC action remains dominant.
2. **Wide-screen confidence** — use the extra space for status, previews, plan details, and quick diagnostics instead of simply stretching mobile layouts.
3. **Dark premium shell** — keep the deep Cloud Teal app environment, glass cards, and white/teal hierarchy.
4. **Clear operational state** — desktop users should see ready/connecting/streaming/warning/error state without hunting.
5. **Efficient pointer interaction** — support hover, focus, keyboard navigation, and dense rows where useful.
6. **Streaming-first utility** — diagnostics, input devices, microphone, controller, and network health should be first-class desktop controls.

## Desktop design material

| Material | Location | Purpose |
| --- | --- | --- |
| Desktop shell sample | `docs/shared/assets/ui-elements/desktop-app-shell.svg` | Wide-screen app layout, sidebar, status bar, main card, metrics, diagnostics |
| Shared design language | `docs/product/design/thinkmay_design_language.md` | Tokens, typography, component language, visual philosophy |
| Mobile design reference | `docs/product/design/thinkmay_mobile_design.md` | Mobile counterpart for responsive behavior and shared semantics |
| Product card sample | `docs/shared/assets/ui-elements/glass-product-card.svg` | Card surface and action hierarchy |
| CTA sample | `docs/shared/assets/ui-elements/primary-cta-button.svg` | Primary button appearance |
| Typography sample | `docs/shared/assets/ui-elements/typography-scale.svg` | Figma type scale rows |

## Desktop shell

The desktop shell should use a stable two- or three-zone layout:

1. **Sidebar navigation** — persistent primary navigation and account/brand anchor.
2. **Top status bar** — current page, global session status, user/plan status, and primary action when relevant.
3. **Main content area** — cloud PC preview/card, plan/session metrics, diagnostics, tables, or settings.

### Sidebar

Purpose: keep desktop navigation stable and scannable.

Rules:

- Width: around `240-280px` on large screens.
- Background: dark glass surface over the Cloud Teal shell.
- Logo: white Thinkmay logo at top with breathing room.
- Active nav item: stronger white overlay and/or Cloud Teal cue.
- Default nav item: muted white text/icon.
- Footer area may contain account, support, version, or logout.

Recommended primary desktop areas:

| Area | Purpose |
| --- | --- |
| Cloud PC | Current machine status, preview, launch/resume action |
| Gói dịch vụ | Plan, renewal, usage, payment/top-up |
| Cửa hàng | Package discovery and upgrades |
| Chẩn đoán | Keyboard, controller, microphone, network tools |
| Cài đặt | Account, app preferences, support, community, logout |

### Top status bar

Purpose: keep the page title, session status, and next action visible.

Rules:

- Use a rounded glass container.
- Left: page title in H2/H3 bold.
- Center/right: compact status chips, active plan, balance, latency, or server region.
- Far right: primary action if it applies globally, such as `Mở máy`, `Kết nối lại`, `Nạp tiền`.
- Do not overload the top bar with full settings forms or long copy.

### Main content grid

Desktop should use responsive grids, not stretched mobile stacks.

Recommended wide layout:

- Left/main column: large Cloud PC card, stream preview, session controls.
- Right column: latency, package, renewal, balance, server, or alerts.
- Bottom row: diagnostics, recent machines/apps, quick tools, support.

Grid guidance:

| Width | Layout |
| --- | --- |
| `>= 1280px` | Sidebar + top bar + 2-column dashboard grid |
| `1024-1279px` | Sidebar + stacked right panels under main card |
| `768-1023px` | Collapse sidebar or use compact rail; content becomes tablet layout |
| `< 768px` | Use mobile design document instead |

## Desktop canonical surfaces

### Cloud PC dashboard

Purpose: launch, resume, or inspect the current cloud PC.

Required hierarchy:

1. Cloud PC name/status.
2. Preview or symbolic thumbnail.
3. Primary action: start/open/resume/connect.
4. Key specs: GPU, package, latency/server, last access.
5. Secondary actions: restart, shutdown, diagnostics, settings.

Design rules:

- Use a large glass product card with a preview surface.
- Use Cloud Teal for ready/active state.
- Warning cards sit beside the main card, not above the primary action unless blocking.
- Shutdown/restart controls must be visually secondary and require confirmation.

### Streaming / remote desktop view

Purpose: host the actual remote desktop or game stream.

Rules:

- The stream should be visually dominant when active.
- Controls should overlay as glass panels or sit in a side/bottom control bar.
- Keep important controls reachable by mouse and keyboard.
- Use compact status chips for latency, bitrate, FPS, microphone, controller, and network.
- Critical actions such as disconnect/shutdown/restart must be separated from ordinary controls.
- When video is unavailable, show a dark branded placeholder with clear recovery action.

### Plan and renewal dashboard

Purpose: show package state, renewal date, balance, and upgrade/top-up actions.

Rules:

- Use desktop's width to place package summary and payment/renewal state side by side.
- Use yellow accent for upcoming renewal or insufficient balance.
- Use strong typography for plan name, price, and renewal date.
- Keep long renewal copy in a readable card with one clear action.

### Diagnostics dashboard

Purpose: make streaming support tools easy to find.

Desktop diagnostic modules:

- Keyboard test.
- Gamepad/controller test.
- Network/latency test.
- Microphone/audio test.
- Server/region status.
- Browser/device compatibility if relevant.

Design rules:

- Use a grid of diagnostic cards.
- Each card should show status, last result, and a primary test action.
- Pass/success uses green, warning uses yellow, error uses red.
- Include plain-language result text; do not rely only on colored dots.

### Settings

Purpose: account, security, preferences, support, and community.

Rules:

- Use a two-column layout when helpful: setting groups on left, detail panel on right.
- Group rows into glass cards.
- Keep destructive account/logout actions separated.
- Use Body 1 for row labels and Body 2 for descriptions/values.

## Desktop typography

Use the canonical rows in `docs/product/design/thinkmay_design_language.md`.

Desktop-specific application:

| Use | Style |
| --- | --- |
| Page title | H1/H2 Bold |
| Top bar title | H2/H3 Bold |
| Dashboard card title | H3 Bold |
| Panel title | H4 Bold |
| Table/list label | Body 1 Medium |
| Metadata | Body 2 Regular/Medium |
| Status chip | Body 2 Bold |
| Dense metric label | Body 3 Medium |
| Primary CTA | Body 1 Bold or H4 Bold |

Rules:

- Desktop can use H1/H2 more often than mobile because it has more breathing room.
- Do not make all cards H1/H2; reserve large type for page and hero hierarchy.
- Use Body 2/3 for dense operational metadata, but never for primary status or price.

## Desktop components

### Primary action button

Reference: `docs/shared/assets/ui-elements/primary-cta-button.svg`.

- Use for start/open/resume/connect/pay/top-up.
- Height: `40-48px` in top bars, `52-56px` in hero cards.
- Radius: `12px`.
- Keep label direct and action-oriented.

### Desktop card

Reference: `docs/shared/assets/ui-elements/glass-product-card.svg`.

- Use dark glass fill, white-opacity border, and 20-28px radius.
- Use cards for product status, plan state, diagnostics, and settings groups.
- Cards should have one primary meaning; do not mix unrelated settings and warnings in the same card.

### Status chip

Status chips should be compact but explicit.

| Status | Visual |
| --- | --- |
| Ready | Green or Cloud Teal dot/fill + `Ready` or Vietnamese equivalent |
| Connecting | Teal animated/pulsing cue + `Đang kết nối` |
| Streaming | Cloud Teal active cue + stream metrics |
| Warning | Yellow cue + short label |
| Error | Red cue + recovery action nearby |

### Tables and dense lists

Desktop may use denser tables/lists than mobile.

Rules:

- Use alternating subtle dark surfaces if rows are long.
- Keep row height comfortable, usually `48-64px`.
- Use Body 1/2, not tiny text, for operational rows.
- Put row actions at the far right and keep destructive actions visually secondary.

### Modals and confirmations

Rules:

- Use modals for destructive or high-impact actions: shutdown, restart, disconnect, delete, logout.
- Modal background should preserve dark brand shell with dim overlay.
- Modal title uses H3/H4 Bold.
- Explain consequence in Body 1/2.
- Primary confirm action should match severity: teal for safe confirm, red for destructive confirm.

## Desktop interaction states

Desktop must include pointer and keyboard affordances.

| Interaction | Required treatment |
| --- | --- |
| Hover | Slightly stronger border/fill or teal glow; avoid large movement |
| Focus | Visible outline or ring with Cloud Teal/white contrast |
| Active/pressed | Slightly darker fill and reduced glow |
| Disabled | Lower opacity plus clear reason where needed |
| Loading | Inline spinner/progress and explicit label |
| Drag/resize if present | Clear handles and safe cursor behavior |

## Desktop responsive behavior

Desktop design should degrade gracefully toward tablet/mobile.

- Sidebar can collapse to an icon rail on medium widths.
- Right-side metric column can stack below the main card.
- Top bar actions can move into page header/card actions.
- Tables can become cards when width is constrained.
- At mobile widths, switch to the mobile design document's navigation and layout rules.

## Desktop visual hierarchy

A strong desktop Thinkmay screen reads in this order:

1. Current app area/page title.
2. Current cloud PC/session state.
3. Primary action.
4. Metrics/warnings that affect the session.
5. Secondary tools and settings.

If metrics, warnings, or navigation compete with the launch/resume action, reduce their emphasis.

## Desktop accessibility

- Support keyboard navigation and visible focus states.
- Keep text contrast high on dark backgrounds.
- Do not encode status only with color.
- Keep controls large enough for pointer and touchpad users.
- Ensure modal focus is trapped and return focus after close.
- Avoid tiny operational text for latency, payment, or session status.

## Desktop handoff checklist

For each desktop screen, designers should provide:

- Screen name and purpose.
- Desktop breakpoint and minimum supported width.
- Sidebar state: full, compact, hidden.
- Top bar content and primary action.
- Main grid layout and responsive behavior.
- Empty/loading/error/warning states.
- Component variants used.
- Typography rows used.
- Color tokens used.
- Icons/assets required.
- Hover/focus/active states.
- Confirmation modal behavior for destructive actions.
- Vietnamese copy and localization variants if needed.

For developers, implementation should:

- Treat Figma as source of truth when existing implementation disagrees.
- Map colors and typography to shared design tokens.
- Build reusable shell/card/button/status components.
- Avoid one-off hardcoded colors or arbitrary spacing.
- Implement desktop keyboard and pointer states, not only mobile/touch states.

## Related design material

- `docs/product/design/thinkmay_design_language.md`
- `docs/product/design/thinkmay_mobile_design.md`
- `docs/shared/assets/ui-elements/desktop-app-shell.svg`
- `docs/shared/assets/ui-elements/primary-cta-button.svg`
- `docs/shared/assets/ui-elements/glass-product-card.svg`
- `docs/shared/assets/ui-elements/typography-scale.svg`
