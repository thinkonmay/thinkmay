# 14 — Onboarding & Welcome

## Overview

App introduction and virtual control tutorial before/during remote usage.

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md) — **⚪ No API needed** (tutorial / marketing UI).

---

## Mobile

### Welcome

| File | `lib/presentation/screen/welcome/welcome_screen.dart` |
|------|--------------------------------------------------------|
| Route | `/welcome` |
| Cubit | None — static marketing |
| Flow | CTA → Login or Sign up |

Shown after splash if not logged in.

### Onboarding virtual

| File | `lib/presentation/screen/onboarding_virtual/onboarding_virtual_screen.dart` |
|------|-------------------------------------------------------------------------------|
| Cubit | None — local enum `OnboardingStep` |
| Steps | Widgets: `welcome_step`, `mouse_click_left_step`, `scroll_page_step`, `enable_assistive_control_step`, … |

**Purpose:** Teach remote gestures:
- Move virtual mouse
- Left/right click
- Scroll
- Enable assistive touch / control panel

**Render:** `PageView` + illustration; does not call `ThinkmayClient`.

### Website — comparison

| Mobile | Website |
|--------|---------|
| Onboarding virtual | `nextstepjs` tour — `useTourGuide` in `GetStarted` |
| Welcome | Marketing `(e-commerce)/page.tsx` |
| In-remote tutorial | — | `startNextStep()` on remote page mount |

Website tour attaches to dashboard/remote; mobile uses separate screen before streaming.

---

## Links

- [06-virtual-controls](../remote/06-virtual-controls-sidepane.md)
- [03-navigation](../home/03-navigation-home-shell.md)
