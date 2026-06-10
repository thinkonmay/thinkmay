# 08 — Settings & Configuration

## Tổng quan

Cài đặt app: streaming preferences, app access, resources, domain server, ngôn ngữ, advanced streaming.

Website hub: `/setting` với nhánh `(account)`, `(diagnostic)`, `(other)`.

---

## Trạng thái API

> Tổng hợp: [API-COVERAGE.md](../API-COVERAGE.md)

| Thành phần | Trạng thái |
|------------|------------|
| Setting screen | ✅ `FetchConfiguration`, `LoadSetting`, app access, resources, CRUD setting |
| Advanced settings | 🔴 `advanced_settings_cubit.init()` rỗng |

Xem thêm: [15-localization](./15-localization.md) 🔴, [16-network-domain-diagnostics](./16-network-domain-diagnostics.md) 🟡.

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

**Flow init:**

1. `FetchConfiguration` → volume metadata list
2. `LoadSetting` → user prefs (domain, quality, …)
3. `FetchAppAccess` / `FetchResources` — quyền và tài nguyên bổ sung
4. Emit `SettingViewModel` với items cho UI list

**Render:** `ListView` các `SettingItemViewModel` — navigate sub-screens (advanced, language, network).

**Account edit (`/update-profile`):** avatar (multipart on save), tên, toggle email marketing (`disableEM` = opt-out; UI `enableEmailMarketing = !disableEM`) — parity web `/setting/profile`.

### Advanced settings

| File | `advanced_settings_screen.dart`, `advanced_settings_cubit.dart` |
|------|---------------------------------------------------------------------|
| State | Reuse `SettingViewModel` |
| Init | **Stub** — `init()` empty |
| Mục đích | Bitrate, framerate, HQ, touch mode — intended parity `setting/(other)/advance` |

Gọi streaming qua `StreamingManager` khi user trong remote (nếu wired).

### Language settings

`language_settings_cubit.dart` — danh sách locale cố định, persist qua SharedPreferences / setting API.

### Global configuration consumption

`FetchConfigurationUseCase` cũng chạy trong **preload** → `GlobalState.configuration` → Dashboard metadata map.

---

## Website — đối chiếu

| Mobile route | Website route |
|--------------|---------------|
| `/setting` | `/setting` |
| `/update-profile` | `/setting/profile` (account edit — từ mục "Thông tin cá nhân") |
| `/change-password` | `/setting/password` |
| `/advanced-settings` | `/setting/(other)/advance` |
| `/language-settings` | `/setting/(application)/language` |
| `/network-check` | `/setting/(diagnostic)/network` |
| `/check-keyboard` | `/setting/(diagnostic)/keyboard` |
| `/gamepad-test` | `/setting/(diagnostic)/gamepad` |
| — | `/setting/(other)/snapshots` — **mobile không có** |
| — | `/setting/(other)/assistant` — AI chat |

**State website:** Settings đọc/ghi `user.metadata` + RPC; Redux `remote` slice cho streaming prefs.

**Render website:** Form pages với `next-intl`; diagnostic pages test trực tiếp singleton `Thinkmay` helpers.

---

## Setting domain vs worker cluster

`GlobalState.settingDomain` — domain user chọn (ảnh hưởng routing).

Dashboard `isWrongServer` so sánh `subscription.cluster` với `Endpoint.baseUrl` host.

Website: `WrongDomainState` component hướng dẫn đổi domain.

---

## Liên kết

- [15-localization](15-localization.md)
- [16-network-domain-diagnostics](16-network-domain-diagnostics.md)
- [05-remote-streaming](../remote/05-remote-streaming-webrtc.md)
