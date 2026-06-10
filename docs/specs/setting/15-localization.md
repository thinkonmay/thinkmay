# 15 — Localization (i18n)

## Tổng quan

Hai ngôn ngữ: **Tiếng Việt** (mặc định) và **English**.

Website: `next-intl` với `[locale]` segment.

---

## Trạng thái API

> Tổng hợp: [API-COVERAGE.md](../API-COVERAGE.md)

| Trạng thái | Chi tiết |
|------------|----------|
| 🔴 **Chưa** | `language_settings_cubit` — danh sách locale cứng; `changeLanguage` chỉ đổi state local, chưa persist `LoadSetting` / `UpdateSetting` |

**Chưa hoàn thiện** — cần nối setting API hoặc SharedPreferences + `main.dart` locale.

---

## Mobile

| Item | Path |
|------|------|
| ARB sources | `lib/l10n/app_en.arb`, `app_vi.arb` |
| Generated | `lib/utils/generated/app_localizations.dart` |
| Language UI | `language_settings_screen.dart` |
| Cubit | `language_settings_cubit.dart` — list locale, persist |

### main.dart setup

```dart
MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: // from user setting
)
```

### Usage in widgets

```dart
AppLocalizations.of(context)!.someKey
```

### Thêm string mới

1. Sửa `.arb` files
2. `flutter gen-l10n` hoặc `flutter pub get`

---

## Website — đối chiếu

| Mobile | Website |
|--------|---------|
| ARB + gen-l10n | JSON messages + `useTranslations('Namespace')` |
| Language settings page | `/setting/(application)/language` |
| Default vi | `[locale]` default in middleware |
| No URL locale | Mobile không có `/vi/` prefix |

**Render:** Cả hai resolve string tại build(context) — không ảnh hưởng streaming protocol.

---

## Liên kết

- [08-settings](08-settings-configuration.md)
