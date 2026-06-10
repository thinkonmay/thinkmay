# 02 — Authentication

## Tổng quan

**Đăng nhập và đăng ký dùng PocketBase** (`users` collection), không dùng Supabase Auth.

- Login: `authWithPassword`
- Login OTP: `requestOTP` + `authWithOTP`
- Sign up: `collection.create` → **auto-login** `authWithPassword` → `requestVerification(email)` → `preload` (giống web `signUpWithEmail` + `loginWithEmail`)
- Google: `authWithOAuth2('google')` trên PocketBase

Token lưu local là **PocketBase auth token** (`UserResponse.token`), restore qua `PocketBase.authStore.save()` khi mở app (Splash).

`SupabaseClient` được đăng ký DI nhưng **không** tham gia luồng auth — chỉ dùng cho store/resources (xem [18-backend-integration](../18-backend-integration.md)).

Website: `(auth)/login`, `register`, … — `backend/actions/index.ts` (cần đối chiếu riêng; web có thể khác stack).

---

## Trạng thái API

> [API-COVERAGE.md](../API-COVERAGE.md)

| Màn hình | Trạng thái | Backend thực tế |
|----------|------------|------------------|
| Login | ✅ | PocketBase `authWithPassword` (server cố định `saigon2`, không còn dropdown server) |
| Login Google | ✅ | PocketBase `authWithOAuth2` |
| Login OTP | ✅ | PocketBase `requestOTP` + `authWithOTP` → preload |
| Sign up | ✅ | PocketBase `create` + auto-login + verification email |
| Change password | ✅ | PocketBase `users` update (`UpdateUserUseCase`) |
| Update profile | ✅ | PocketBase + optional avatar upload |
| Email verification | ✅ | `requestVerification` / resend; `confirmVerification(token)` + deep link |
| Forgot password | ✅ | `requestPasswordReset` (không còn nhận tham số domain) |
| Enter new password | ✅ | `confirmPasswordReset` + deep link token |

**Đã fix:** Sau login / OTP / sign-up: `GlobalCubit.preload()` trước khi vào Home. Splash dùng server URL đã lưu + **`authRefresh`** để làm mới token.

**UI/UX auth screens:** Login / Sign-up dùng pattern keyboard-aware với cụm action cố định ở đáy màn hình, field tự dock sát mép bàn phím qua `EditableText` built-in. Pattern tài liệu hoá trong skill `skills/flutter-form-fixed-bottom-actions/SKILL.md` — phải đọc trước khi sửa bất kỳ auth screen nào hoặc tạo screen mới có form + bottom actions.

**Cần cấu hình server/email:** link trong email reset / verify phải trỏ đúng app scheme `thinkmay://…` nếu muốn mở thẳng app.

---

## Mobile — source files

| Màn hình | Route | Cubit | Service |
|----------|-------|-------|---------|
| Login | `/login` | `login_cubit.dart` | `authentication_service.dart` |
| Login OTP | `/login-otp` | `login_otp_cubit.dart` |同上 |
| Sign up | `/sign-up` | `sign_up_cubit.dart` |同上 |
| Change password | `/change-password` | `change_password_cubit.dart` | `user_service.dart` |
| Update profile | `/update-profile` | `update_profile_cubit.dart` | `user_service.dart` |

**Auth service:** `lib/data/network/authentication/authentication_service.dart`

---

## Login flow (theo code)

**`LoginCubit.init()`**

1. Set routing server mặc định = `Endpoint.baseUrl` (saigon2) qua `BaseUrlProvider.updateBaseUrl(...)` + `SaveServerUrlUseCase` (key `SERVER_URL_KEY`).
2. PocketBase auth **luôn** đi qua `Endpoint.baseUrl`. Không còn fetch domain list / hiển thị server picker trong UI login (xem [Server selection — removed](#server-selection--removed)).

**`LoginCubit.login()`**

1. `LoginUseCase` → `PocketBase.collection('users').authWithPassword(email, password)`
2. PocketBase SDK tự gắn `authStore` (token + record)
3. `SaveUserStorageUseCase(record)`, `SaveSessionTokenUseCase(token)`, `SaveServerUrlUseCase(Endpoint.baseUrl)` (đảm bảo key tồn tại)
4. `registerCurrentUser(record)`
5. `GlobalCubit.preload()` rồi `LoginSuccessState` → `/home`

**`LoginCubit.loginAction()`** — Google OAuth: cùng bước lưu storage + `registerCurrentUser` + `preload()` → `/home`.

### Server selection — removed

UI dropdown chọn server đã bỏ khỏi `LoginScreen`; `LoginCubit` không còn phụ thuộc `FetchDomainsUseCase` và `LoginViewModel` không còn các field `availableDomains` / `serverSelected`. Lý do: trên production chỉ `saigon2.thinkmay.net` chạy PocketBase auth, các domain khác là routing-only cho WebRTC streaming → cho user chọn server ở Login chỉ gây nhầm lẫn (chọn sai = login fail).

`BaseUrlProvider` sau refactor:

| Method | Trả về | Dùng cho |
|---|---|---|
| `getCurrentBaseUrl()` | `Endpoint.baseUrl` (cố định `saigon2`) | PocketBase auth + `/info` + volumes |
| `getRoutingServerUrl()` | URL trong `SERVER_URL_KEY` (fallback `Endpoint.baseUrl`) | Build WebRTC URL trong `SessionServiceImpl.parseRequest()` |
| `updateBaseUrl(url)` | — | Lưu `url` làm routing server; `_ensurePocketBaseOnSaigon2()` reset `PocketBase` trong GetIt về `Endpoint.baseUrl` |

`DomainDto.routingOnly` đã xoá. Chọn server routing (WebRTC) qua `/network-check` / Settings — không còn trên profile (xem [09-profile-account](../profile/09-profile-account.md)).

---

## Login OTP flow (`LoginOtpCubit` + `/login-otp`)

1. `requestOTP(email)` → lưu `otpId`, chuyển bước nhập OTP
2. `authWithOTP(otpId, otp)` → lưu user/token + `preload()` → `/home`

## Splash restore (liên quan auth)

`SplashCubit.checkIsLoggedIn()`:

1. Đọc user + token từ SharedPreferences
2. `BaseUrlProvider` → server URL đã lưu (nếu có) hoặc fallback `Endpoint.baseUrl`
3. `UpdatePocketBaseAuthStoreUseCase` → `authStore.save(token, record)`
4. `RefreshAuthUseCase` → `auth-refresh` (cập nhật token + lưu lại storage + `registerCurrentUser`)
5. `FetchUserUseCase` → `PocketBase.collection('users').getList(page: 1)` (kiểm tra session)
6. Nếu OK → `GlobalCubit.preload()`

---

## Sign up flow

1. `SignUpUseCase` → `PocketBase.collection('users').create(body: ...)` (gồm `name`, `phone` tuỳ chọn, `metadata`)
2. `LoginUseCase` → `authWithPassword` (auto-login giống web)
3. `RequestVerificationUseCase` → gửi email xác minh
4. `GlobalCubit.preload()` → `SignUpLoggedInState` → `/home`
5. Nếu bước (2) thất bại (vd. email chưa verify) → `/sign-up-success` để user login tay

Validation: gần website — email chuẩn (không chữ hoa), name bắt buộc, phone tuỳ chọn (regex), mật khẩu ≥ 8, khớp `passwordConfirm`.

---

## Session persistence

| Dữ liệu | Storage | Ghi chú |
|---------|---------|---------|
| User record JSON | SharedPreferences (`authenticatedUserEmailKey`) | `SaveUserStorageUseCase` |
| PB auth token | SharedPreferences (`authenticatedTokenKey`) | `SaveSessionTokenUseCase` |
| Routing server URL | SharedPreferences (`serverUrlKey`) | URL dùng cho **WebRTC routing** (xem `SessionServiceImpl`). PocketBase auth không đọc key này — luôn dùng `Endpoint.baseUrl`. Login mặc định ghi `Endpoint.baseUrl`; profile có thể đổi sau. **Không** bị xóa khi logout. |

`LogoutUseCase` — chỉ xóa các key auth ở storage, `PocketBase.authStore.clear()`, `unregisterCurrentUser()`, `GlobalCubit.clearSession()`.

---

## Route guard (GoRouter)

Sau khi `AppRouter.isAppInitialized == true`, mọi route **không** nằm trong allowlist công khai (`RoutePaths` trong code) mà `getIt` chưa có `User` được redirect về `/login`. Các route không cần đăng nhập gồm splash, welcome, login/OTP, đăng ký, quên mật khẩu / reset / xác minh email (deep link), terms, network check.

---

## Thông báo lỗi auth (UI)

Các màn login, OTP, đăng ký, quên mật khẩu, đặt lại mật khẩu, xác minh email dùng `AuthErrorLocalizer` để map lỗi PocketBase thường gặp sang chuỗi đa ngôn ngữ; lỗi khác vẫn hiển thị nội dung từ server nếu có.

---

## OAuth (Google)

Đăng nhập Google mở luồng OAuth ngoài app; khi quay lại, SDK PocketBase cần nhận callback. Đảm bảo **scheme** `thinkmay://` (và intent filter Android / URL types iOS) khớp cấu hình trên server PocketBase. Deep link reset/verify đã dùng cùng scheme; OAuth callback phải được cấu hình tương ứng trong admin PB nếu prod dùng redirect tùy chỉnh.

---

## Gaps & rủi ro đã biết

Review code: 2026-05-20. Cập nhật trạng thái: ✅ = đã fix; ⏳ = còn lại / accepted risk. Test ID đối ứng trong [03-authentication-test-cases.md](./03-authentication-test-cases.md).

### A. Logout / cleanup ordering

| # | Trạng thái | Vấn đề | File | Giải pháp / lý do |
|---|-----------|--------|------|-------------------|
| A1 | ✅ | `LogoutUseCaseImpl` bỏ qua cleanup khi repo logout throw. | `lib/data/use_case/user/logout_use_case_impl.dart` | `unregisterCurrentUser()` chạy trong `finally`; vẫn trả `Left` cho UI handle. |
| A2 | ✅ | `UserStorageImpl.logout()` mismatch khi `prefs.remove` fail. | `lib/data/storage/user/user_storage.dart` | `try/finally` quanh prefs remove; `authStore.clear()` luôn chạy; rethrow lỗi prefs. |
| A3 | ✅ | Data layer phụ thuộc `GlobalCubit`. | `logout_use_case_impl.dart` | Bỏ import `GlobalCubit`; `clearSession()` được gọi từ `SettingCubit.logout` / `ProfileCubit.logout` sau khi nhận `Right`. |
| A4 | ✅ | `SettingCubit.logout()` không emit error. | `setting_cubit.dart` | Emit `SettingErrorState` khi logout fail; UI có thể bắt từ listener. |

### B. Route guard

| # | Trạng thái | Vấn đề | File | Giải pháp / lý do |
|---|-----------|--------|------|-------------------|
| B1 | ⏳ | Public allowlist hard-code. | `route_paths.dart` | Accepted risk; mỗi route mới phải update tay. Cân nhắc annotation trên `GoRoute` ở milestone sau. |
| B2 | ✅ | Token hết hạn vẫn vào protected. | `app_router.dart` | Guard check `PocketBase.authStore.isValid` khi `authStore.token` không rỗng; nếu hết hạn → redirect login. |
| B3 | ⏳ | Test deep link query string chưa đầy đủ. | `route_paths.dart` | Có test `?token=…` + trailing slash. Edge case `%20` / `+` chưa cover (low risk vì GoRouter normalize trước). |

### C. AuthErrorLocalizer

| # | Trạng thái | Vấn đề | File | Giải pháp / lý do |
|---|-----------|--------|------|-------------------|
| C1 | ✅ | So sánh exact string fragile. | `auth_error_localizer.dart`, `tm_exception.dart`, `auth_error_code.dart` | Thêm enum `AuthErrorCode`; `TmException.code` ưu tiên trong localizer. Cubit `SignUpCubit` + `ConfirmVerificationCubit` đã set `code`. Sentinel string legacy giữ làm fallback cho `EnterNewPasswordCubit` (chưa migrate state). |
| C2 | ✅ | Passthrough English message trên locale VI. | `auth_error_localizer.dart:_passthroughOrGeneric` | Heuristic: VI + ASCII-only English → `authErrorGeneric`; chuỗi có Unicode (tiếng Việt) giữ nguyên. |
| C3 | ✅ | `contains('user')` false positive. | `_looksLikeUserNotFound` | Yêu cầu `record` hoặc `email` hoặc cụm `user not found`; `"user input invalid"` không còn map sai. |

### D. Splash / session restore

| # | Trạng thái | Vấn đề | File | Giải pháp / lý do |
|---|-----------|--------|------|-------------------|
| D1 | ✅ | Network error → mất session. | `splash_cubit.dart:_fetchUser` | Phân biệt 401/403 (drop session) vs khác (giữ session nếu User đã register từ `authRefresh`). |
| D2 | ⏳ | Splash không có timeout. | `splash_cubit.dart` | Accepted risk; UI có animation 3s che đậy phần lớn case. Có thể thêm `.timeout()` về sau. |
| D3 | ✅ | Corrupt user JSON. | `user_storage.dart:getUserStorage` | Catch `FormatException`; log warning; remove key xấu; throw chung "No user data found". |

### E. Test coverage còn thiếu

| # | Trạng thái | Thiếu | Hiện có |
|---|-----------|-------|---------|
| E1 | 🟡 | Cubit test cho `LoginCubit`, `SignUpCubit`, `LoginOtpCubit`, `SplashCubit`. | Đã có `LogoutUseCaseImpl` test (`test/auth/logout_use_case_test.dart`); còn lại pending. |
| E2 | ⏳ | Widget test cho `AppRouter.redirect`. | Có pure-function test `RoutePaths.requiresAuthentication`. |
| E3 | ⏳ | Edge: token expired + refresh fail; deep link URL escape. | Token expired đã được code (B2) nhưng chưa có test widget tự động. |

### F. OAuth deep link

| # | Vấn đề | Đề xuất |
|---|--------|---------|
| F1 | App **chưa có handler** nhận deep link từ ngoài (không thấy `app_links` / `uni_links` trong `pubspec.yaml`). Reset / verify dùng route nội bộ trong app — nhưng nếu user mở link từ email khi app đã đóng, Android/iOS chưa cấu hình intent filter / URL types để map sang GoRouter. | Quyết định: (a) thêm package + cấu hình intent filter Android (`AndroidManifest.xml`) + iOS URL types (`Info.plist`); (b) hoặc gửi email với link HTTPS dẫn về web rồi web mở app. |
| F2 | `authWithOAuth2('google')` cần URL launcher cho mobile; PB SDK 0.23 dùng `urlCallback` để mở browser → khi user tap Google trên app, cần handler. Không thấy code cấu hình `urlCallback`. | Cần verify thực tế trên thiết bị; nếu cần, custom OAuth flow. |

### G. Khác

| # | Vấn đề | Đề xuất |
|---|--------|---------|
| G1 | `UserStorageImpl.logout()` log mức INFO không có user ID — privacy OK. Không có audit trail. | Optional: log thêm timestamp + reason (manual / token-expired / forced). |
| G2 | `unregisterCurrentUser()` chỉ unregister `User` trong GetIt; **không** reset các Cubit khác (`DashboardCubit`, `RemoteCubit`, …). Nếu user A logout rồi user B login ngay → cubit có thể giữ data của A trước khi `preload` ghi đè. | Document rằng login phải chờ `preload` xong trước khi mở Home (đã đúng); thêm test khẳng định. |
| G3 | `BaseUrlProvider.updateBaseUrl` không gọi sau logout. Đúng intent (giữ server URL). | Note rõ trong spec — đã có. |

### H. UI / keyboard handling

| # | Trạng thái | Vấn đề | File | Giải pháp / lý do |
|---|-----------|--------|------|-------------------|
| H1 | ✅ | Field bị bàn phím che, hoặc button "Đăng nhập" nhảy lên theo keyboard. | `login_screen.dart`, `sign_up_screen.dart` | Pattern: `Scaffold(resizeToAvoidBottomInset: false)` + `SizedBox.expand` + `DecoratedBox` + `Stack(fit: StackFit.expand)` + `Padding(bottom: viewInsets.bottom)` quanh `SingleChildScrollView`. Field auto-dock sát keyboard nhờ default `EditableText.scrollPadding`. Tài liệu: `skills/flutter-form-fixed-bottom-actions/SKILL.md`. |
| H2 | ✅ | Custom `FocusNode` listener / `Scrollable.ensureVisible` trong `TmTextField` đè built-in → jitter, scroll sai vị trí. | `tm_text_field.dart` | Bỏ toàn bộ. Component giờ chỉ giữ `FocusNode` cho label/border rebuild. |
| H3 | ⏳ | SafeArea cho notch / home indicator chưa wrap tường minh trên auth screens (đã thử, gây regression với pattern hiện tại — revert). | `login_screen.dart`, `sign_up_screen.dart` | Accepted risk. Cụm bottom action vẫn có vertical padding 32.h đủ tránh home indicator iPhone đời mới ở mức chấp nhận được. Nếu cần fix triệt để: thử lại có kiểm soát, đo lại `_bottomActionsHeight` sau khi thêm SafeArea, chạy verification checklist trong skill. |

---

## Test cases

Bộ test case đầy đủ (manual + unit + integration), ma trận traceability 28 tính năng: **[03-authentication-test-cases.md](./03-authentication-test-cases.md)**.

Chạy unit test auth:

```powershell
flutter test test/auth/
```

---

## Website — đối chiếu

| Khía cạnh | Website | Mobile |
|-----------|---------|--------|
| Login | `loginWithEmail` actions | PocketBase password auth + preload |
| Post-login | `preload()` | `preload()` sau login / OTP / sign-up |
| Register | `signUpWithEmail` | PB create + auto-login + `requestVerification` + preload |
| OTP login | `RequestOTP` + `LoginByOTP` | `requestOTP` + `authWithOTP` + preload |
| Email verify | `requestVerification` / `confirmVerification` | Resend từ app; confirm qua deep link `/confirm-verification?token=` |
| Reset password | `ResetPassword` / `ConfirmPasswordReset` | `requestPasswordReset` / `confirmPasswordReset` + deep link |

---

## Liên kết

- [01-app-bootstrap](../01-app-bootstrap-global-state.md)
- [18-backend-integration](../18-backend-integration.md)
- [Skill: flutter-form-fixed-bottom-actions](../../skills/flutter-form-fixed-bottom-actions/SKILL.md) — pattern UI/keyboard cho mọi auth screen có form + bottom actions.
