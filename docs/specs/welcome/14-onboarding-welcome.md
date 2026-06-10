# 14 — Onboarding & Welcome

## Tổng quan

Giới thiệu app và hướng dẫn điều khiển ảo trước khi/during sử dụng remote.

---

## Trạng thái API

> [API-COVERAGE.md](../API-COVERAGE.md) — **⚪ Không cần API** (tutorial / marketing UI).

---

## Mobile

### Welcome

| File | `lib/presentation/screen/welcome/welcome_screen.dart` |
|------|--------------------------------------------------------|
| Route | `/welcome` |
| Cubit | Không — static marketing |
| Flow | CTA → Login hoặc Sign up |

Hiển thị sau splash nếu chưa đăng nhập.

### Onboarding virtual

| File | `lib/presentation/screen/onboarding_virtual/onboarding_virtual_screen.dart` |
|------|-------------------------------------------------------------------------------|
| Cubit | Không — local enum `OnboardingStep` |
| Steps | Widgets: `welcome_step`, `mouse_click_left_step`, `scroll_page_step`, `enable_assistive_control_step`, … |

**Mục đích:** Dạy gesture remote:
- Di chuyển chuột ảo
- Click trái/phải
- Scroll
- Bật assistive touch / control panel

**Render:** `PageView` + illustration; không gọi `ThinkmayClient`.

### Website — đối chiếu

| Mobile | Website |
|--------|---------|
| Onboarding virtual | `nextstepjs` tour — `useTourGuide` trong `GetStarted` |
| Welcome | Marketing `(e-commerce)/page.tsx` |
| In-remote tutorial | — | `startNextStep()` on remote page mount |

Website tour gắn với dashboard/remote; mobile tách màn hình riêng trước khi stream.

---

## Liên kết

- [06-virtual-controls](../remote/06-virtual-controls-sidepane.md)
- [03-navigation](../home/03-navigation-home-shell.md)
