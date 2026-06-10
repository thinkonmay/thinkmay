# 13 — Banners & Marketing

## Tổng quan

Hiển thị banner khuyến mãi / sự kiện — fetch từ API, navigate khi tap.

Website: banners trên `/play` SSR + component carousel.

---

## Trạng thái API

> [API-COVERAGE.md](../API-COVERAGE.md) — **✅ Hoàn thiện** (`FetchBannerUseCase`).

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
4. Tap → `context.push` route tương ứng (store, payment, external)

### Route

`/banner` — standalone, không nằm trong bottom nav.

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| `FetchBannerUseCase` | SSR `FetchBanners` trong `play/page.tsx` |
| `FetchPlayBannersUseCase` | Cùng Supabase `banner` — carousel trên Dashboard Home tab |
| Full screen list | Carousel embedded in play dashboard |
| State | Cubit | Server props → client carousel |

**Render website:** Next.js Image optimization, autoplay slider.

**Render mobile:** `PageView` / horizontal list + cached images.

---

## Liên kết

- [12-explore-games](../explore/12-explore-games-store.md)
- [14-onboarding](../welcome/14-onboarding-welcome.md)
