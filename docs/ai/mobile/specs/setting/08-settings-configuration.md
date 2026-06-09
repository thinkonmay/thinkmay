# 08 — Settings & Configuration

## Overview

App settings: streaming preferences, app access, resources, domain server, language, advanced streaming.

Website hub: `/setting` with branches `(account)`, `(diagnostic)`, `(other)`.

---

## API status

> Summary: [API-COVERAGE.md](../API-COVERAGE.md)

| Component | Status |
|-----------|--------|
| Setting screen | ✅ `FetchConfiguration`, `LoadSetting`, app access, resources, CRUD setting |
| Advanced settings | 🔴 `advanced_settings_cubit.init()` empty |

See also: [15-localization](./15-localization.md) 🔴, [16-network-domain-diagnostics](./16-network-domain-diagnostics.md) 🟡.

---

## Mobile

### Setting screen

| File | Path |
|------|------|
| UI | `lib/presentation/screen/setting/setting_screen.dart` |
| Cubit | `setting_cubit.dart` |
| State | `setting_state.dart` |

**Use cases → backend (`setting_service.dart`):**

| Use case | Backend |
|----------|---------|
| `FetchConfigurationUseCase` | PB collection `volumes` |
| `FetchStoreByCodeUseCase` | Supabase `stores` |
| `FetchAppAccessUseCase` / update | PB `app_access` |
| `FetchResourcesUseCase` | Supabase `resources` |
| `LoadSetting` / create / update | PB collection `setting` |
| `LogoutUseCase` | PB `authStore.clear` + storage |

**Init flow:**

1. `FetchConfiguration` → volume metadata list
2. `LoadSetting` → user prefs (domain, quality, …)
3. `FetchAppAccess` / `FetchResources` — permissions and additional resources
4. Emit `SettingViewModel` with items for UI list

**Render:** `ListView` of `SettingItemViewModel` — navigate to sub-screens (advanced, language, network).

### Advanced settings

| File | `advanced_settings_screen.dart`, `advanced_settings_cubit.dart` |
|------|---------------------------------------------------------------------|
| State | Reuse `SettingViewModel` |
| Init | **Stub** — `init()` empty |
| Purpose | Bitrate, framerate, HQ, touch mode — intended parity `setting/(other)/advance` |

Calls streaming via `StreamingManager` when user is in remote (if wired).

### Language settings

`language_settings_cubit.dart` — fixed locale list, persist via SharedPreferences / setting API.

### Global configuration consumption

`FetchConfigurationUseCase` also runs in **preload** → `GlobalState.configuration` → Dashboard metadata map.

---

## Website — comparison

| Mobile route | Website route |
|--------------|---------------|
| `/setting` | `/setting` |
| `/advanced-settings` | `/setting/(other)/advance` |
| `/language-settings` | `/setting/(application)/language` |
| `/network-check` | `/setting/(diagnostic)/network` |
| `/check-keyboard` | `/setting/(diagnostic)/keyboard` |
| `/gamepad-test` | `/setting/(diagnostic)/gamepad` |
| — | `/setting/(other)/snapshots` — **mobile does not have** |
| — | `/setting/(other)/assistant` — AI chat |

**Website state:** Settings read/write `user.metadata` + RPC; Redux `remote` slice for streaming prefs.

**Website render:** Form pages with `next-intl`; diagnostic pages test directly via singleton `Thinkmay` helpers.

---

## Setting domain vs worker cluster

`GlobalState.settingDomain` — user-selected domain (affects routing).

Dashboard `isWrongServer` compares `subscription.cluster` with `Endpoint.baseUrl` host.

Website: `WrongDomainState` component guides domain change.

---

## Links

- [15-localization](15-localization.md)
- [16-network-domain-diagnostics](16-network-domain-diagnostics.md)
- [05-remote-streaming](../remote/05-remote-streaming-webrtc.md)
