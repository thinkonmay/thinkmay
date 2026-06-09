# 15 — Localization (i18n)

## Overview

Two languages: **Vietnamese** (default) and **English**.

Website: `next-intl` with `[locale]` segment.

---

## API status

> Summary: [API-COVERAGE.md](../API-COVERAGE.md)

| Status | Details |
|--------|---------|
| 🔴 **Not done** | `language_settings_cubit` — hardcoded locale list; `changeLanguage` only changes local state, does not persist via `LoadSetting` / `UpdateSetting` |

**Not complete** — needs connection to setting API or SharedPreferences + `main.dart` locale.

---

## Mobile

| Item | Path |
|------|------|
| ARB sources | `lib/l10n/app_en.arb`, `app_vi.arb` |
| Generated | `lib/utils/generated/app_localizations.dart` |
| Language UI | `language_settings_screen.dart` |
| Cubit | `language_settings_cubit.dart` — locale list, persist |

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

### Adding a new string

1. Edit `.arb` files
2. `flutter gen-l10n` or `flutter pub get`

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| ARB + gen-l10n | JSON messages + `useTranslations('Namespace')` |
| Language settings page | `/setting/(application)/language` |
| Default vi | `[locale]` default in middleware |
| No URL locale | Mobile has no `/vi/` prefix |

**Render:** Both resolve strings at build(context) — does not affect streaming protocol.

---

## Links

- [08-settings](08-settings-configuration.md)
