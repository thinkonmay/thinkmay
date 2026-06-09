# 13 — Banners & Marketing

## Overview

Display promotional / event banners — fetch from API, navigate on tap.

Website: banners on `/play` SSR + carousel component.

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md) — **✅ Complete** (`FetchBannerUseCase`).

---

## Mobile

| File | Path |
|------|------|
| UI | `lib/presentation/screen/banner/banner_screen.dart` |
| Cubit | `banner_cubit.dart` |
| Use case | `FetchBannerUseCase` |
| ViewModel | `banner_view_model.dart`, `banner_item_view_model.dart` |

### Flow

1. `init()` → `FetchBannerUseCase`
2. Loading → Primary / Error
3. `BannerViewModel.items` — image URL, title, deep link action
4. Tap → `context.push` corresponding route (store, payment, external)

### Route

`/banner` — standalone, not in bottom nav.

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| `FetchBannerUseCase` | SSR `FetchBanners` in `play/page.tsx` |
| Full screen list | Carousel embedded in play dashboard |
| State | Cubit | Server props → client carousel |

**Website render:** Next.js Image optimization, autoplay slider.

**Mobile render:** `PageView` / horizontal list + cached images.

---

## Links

- [12-explore-games](../explore/12-explore-games-store.md)
- [14-onboarding](../welcome/14-onboarding-welcome.md)
