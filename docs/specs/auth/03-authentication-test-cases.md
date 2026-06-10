# 03 — Authentication test cases

Bộ test case cho toàn bộ phạm vi [02-authentication.md](./02-authentication.md): luồng đăng nhập/đăng ký PocketBase, bootstrap Splash, **P2** (logout có chọn lọc, route guard, `AuthErrorLocalizer`, reset session).

> **Nguồn sự thật code:** `lib/data/storage/user/user_storage.dart`, `lib/data/use_case/user/logout_use_case_impl.dart`, `lib/presentation/router/route_paths.dart`, `lib/presentation/router/app_router.dart`, `lib/utils/api/auth_error_localizer.dart`, các `*_cubit.dart` auth.

---

## Cách đọc tài liệu

| Cột | Ý nghĩa |
|-----|---------|
| **ID** | Mã test duy nhất (`AUTH-xxx`) |
| **Loại** | `Unit` = `flutter test`; `Manual` = QA trên thiết bị/emulator; `Integration` = cần PocketBase / email thật |
| **Ưu tiên** | P0 bắt buộc trước release; P1 quan trọng; P2 polish / edge case |

**Chạy test tự động (phần Unit):**

```powershell
cd d:/thinkmay/mobile
flutter test test/auth/
```

---

## Ma trận traceability — không bỏ sót tính năng

Mỗi hàng phải có ít nhất một test ID **Pass** trước khi coi tính năng hoàn tất.

| # | Tính năng / hành vi | Spec § | Test IDs |
|---|---------------------|--------|----------|
| 1 | Splash: chưa có session → Welcome | Splash restore | AUTH-001, AUTH-002 |
| 2 | Splash: restore token + server URL + authRefresh + preload → Home | Splash restore | AUTH-003–AUTH-007 |
| 3 | Login email/password + lưu prefs + register User + preload → Home | Login flow | AUTH-010–AUTH-014 |
| 4 | ~~Login: chọn server/domain~~ → đã bỏ UI, chỉ còn lưu routing URL mặc định | Server selection — removed | AUTH-015–AUTH-016 (REMOVED), AUTH-160 |
| 5 | Login Google OAuth | Login / OAuth | AUTH-017–AUTH-019 |
| 6 | Login OTP: request → nhập OTP → Home | Login OTP | AUTH-020–AUTH-027 |
| 7 | Sign up: validation form | Sign up | AUTH-030–AUTH-037 |
| 8 | Sign up: PB create → auto-login → verification → Home | Sign up | AUTH-038–AUTH-041 |
| 9 | Sign up Google | Sign up | AUTH-042 |
| 10 | Sign up: create OK, auto-login fail → success screen | Sign up | AUTH-043 |
| 11 | Forgot password: gửi email reset | Forgot password | AUTH-050–AUTH-052 |
| 12 | Reset password: deep link token + confirm | Enter new password | AUTH-053–AUTH-058 |
| 13 | Email verification: resend từ app | Email verification | AUTH-060–AUTH-061 |
| 14 | Email verification: deep link confirm | Confirm verification | AUTH-062–AUTH-065 |
| 15 | Logout: xóa **chỉ** key auth, giữ server URL & prefs khác | Session P2 | AUTH-070–AUTH-075 |
| 16 | Logout: PB `authStore.clear` | Session P2 | AUTH-076 |
| 17 | Logout: `unregisterCurrentUser` + `GlobalCubit.clearSession` | Session P2 | AUTH-077–AUTH-079 |
| 18 | Logout UI: Setting → Welcome | Session P2 | AUTH-080 |
| 19 | Route guard: app chưa init → Splash | Route guard | AUTH-090–AUTH-091 |
| 20 | Route guard: guest + route protected → Login | Route guard | AUTH-092–AUTH-094 |
| 21 | Route guard: guest + route public → không redirect | Route guard | AUTH-095–AUTH-098 |
| 22 | Route guard: đã login → vào protected bình thường | Route guard | AUTH-099 |
| 23 | `AuthErrorLocalizer`: map lỗi PB → l10n | Error UI P2 | AUTH-100–AUTH-115 |
| 24 | Dialog lỗi dùng localizer trên từng màn auth | Error UI P2 | AUTH-116–AUTH-122 |
| 25 | Change password (đã đăng nhập) | Profile | AUTH-130–AUTH-132 |
| 26 | Update profile (đã đăng nhập) | Profile | AUTH-133–AUTH-134 |
| 27 | Session keys: save/load user, token, server URL | Session persistence | AUTH-140–AUTH-142 |
| 28 | OAuth scheme / callback (cấu hình) | OAuth | AUTH-150–AUTH-151 |
| 29 | Keyboard avoidance trên Login / Sign-up (pattern fixed-bottom-actions) | UI gap H1/H2 | AUTH-170–AUTH-176 |

---

## A. Bootstrap & Splash (`SplashCubit.checkIsLoggedIn`)

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-001 | Manual | P0 | Cài mới / xóa app; chưa từng login | Mở app | Splash animation → `/welcome` |
| AUTH-002 | Unit/Manual | P0 | SharedPreferences không có user JSON | Gọi `checkIsLoggedIn()` | `false`; `AppRouter.isAppInitialized == true` |
| AUTH-003 | Integration | P0 | Đã login trước đó; token còn hạn | Kill app → mở lại | Splash → `/home`; dashboard có dữ liệu preload |
| AUTH-004 | Integration | P1 | Có user + token + `SERVER_URL_KEY` custom | Cold start | `BaseUrlProvider` dùng URL đã lưu (không fallback mặc định nếu key có giá trị) |
| AUTH-005 | Integration | P1 | Có user + token; **không** có server URL | Cold start | Fallback `Endpoint.baseUrl`; vẫn restore session nếu PB OK |
| AUTH-006 | Integration | P1 | Token hết hạn nhưng refresh OK | Cold start | `authRefresh` cập nhật token + storage + `registerCurrentUser` |
| AUTH-007 | Integration | P1 | Token invalid / refresh fail | Cold start | Không vào Home; `FetchUser` fail → Welcome (hoặc guest flow) |
| AUTH-008 | Manual | P2 | User JSON corrupt trong prefs | Cold start | Không crash; coi như chưa login |

---

## B. Login email / password (`LoginCubit`)

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-010 | Integration | P0 | Tài khoản hợp lệ | Nhập email/password → Sign In | Loading → `/home`; không dialog lỗi |
| AUTH-011 | Integration | P0 | — | Sau login thành công | `AUTHENTICATED_*` keys có giá trị; `getIt.isRegistered<User>()` |
| AUTH-012 | Integration | P0 | — | Sau login | `GlobalCubit.state.fetched == true`; có subscriptions/workerInfo (nếu API OK) |
| AUTH-013 | Integration | P0 | Sai mật khẩu | Login | Dialog **Sign In Failed**; message = `authErrorInvalidCredentials` (VI/EN theo locale app) |
| AUTH-014 | Manual | P1 | Email không tồn tại | Login | Dialog lỗi; 404/user not found → `authErrorUserNotFound` hoặc message PB |
| ~~AUTH-015~~ | — | — | ~~RPC domains trả ≥2 server~~ | ~~Mở Login~~ | **REMOVED** — UI server selection đã bỏ. Login luôn dùng `Endpoint.baseUrl`. Thay bằng AUTH-160. |
| ~~AUTH-016~~ | — | — | ~~Đổi server trên Login~~ | ~~Login thành công~~ | **REMOVED** — không còn UI đổi server ở Login. Thay đổi routing server giờ qua Profile → Select server. |
| AUTH-017 | Integration | P1 | Google account đã liên kết PB | Tap **Sign in with Google** | OAuth flow → `/home`; user + token lưu |
| AUTH-018 | Manual | P2 | User hủy OAuth | Tap Google → cancel | Quay Login; không crash; không register User |
| AUTH-019 | Manual | P2 | Link **Sign in with email OTP** | Tap | Navigate `/login-otp` |

---

## C. Login OTP (`LoginOtpCubit`)

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-020 | Integration | P0 | Email có tài khoản | Nhập email → submit | Chuyển bước OTP; countdown resend ~120s |
| AUTH-021 | Integration | P0 | Đã có OTP từ email | Nhập 6 số → verify | `/home`; session lưu |
| AUTH-022 | Manual | P1 | Email invalid format | Submit ở bước email | Không gọi API (silent / không loading vô hạn) |
| AUTH-023 | Integration | P1 | OTP sai | Verify | Dialog lỗi qua `AuthErrorLocalizer` |
| AUTH-024 | Manual | P1 | Đang countdown | Nút resend disabled | Không gửi lại OTP |
| AUTH-025 | Integration | P1 | Hết countdown | Tap resend | Gửi OTP mới; reset timer |
| AUTH-026 | Manual | P2 | Bước OTP | **Prefer password?** | Quay bước email / login password |
| AUTH-027 | Manual | P2 | OTP < 6 ký tự | Submit | Không gọi verify |

---

## D. Sign up (`SignUpCubit`)

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-030 | Unit/Manual | P0 | — | Name trống | `signUpErrorNameRequired` |
| AUTH-031 | Unit/Manual | P0 | — | Email trống | `signUpErrorEmailRequired` |
| AUTH-032 | Unit/Manual | P1 | — | Email có chữ HOA | `signUpErrorEmailNoCapital` |
| AUTH-033 | Unit/Manual | P1 | — | Email sai format | `signUpErrorInvalidFormatEmailDialogMessage` |
| AUTH-034 | Unit/Manual | P1 | — | Phone không hợp lệ (có nhập) | `signUpErrorPhoneInvalid` |
| AUTH-035 | Unit/Manual | P0 | — | Password < 8 | `signUpErrorPasswordTooShort` |
| AUTH-036 | Unit/Manual | P0 | — | Password ≠ confirm | `signUpErrorPasswordMismatch` |
| AUTH-037 | Manual | P1 | Phone để trống | Sign up hợp lệ khác | Pass validation |
| AUTH-038 | Integration | P0 | Email chưa dùng | Sign up đầy đủ | Auto-login → `/home`; email verification gửi |
| AUTH-039 | Integration | P1 | Email đã tồn tại | Sign up | Dialog; `authErrorAccountExists` (nếu PB trả unique) |
| AUTH-040 | Integration | P1 | PB 5xx khi create | Sign up | Navigate `/sign-up-error` |
| AUTH-041 | Manual | P1 | — | Sau sign-up thành công | User trong GetIt; preload xong |
| AUTH-042 | Integration | P1 | — | Continue with Google | `/home` (không qua màn success) |
| AUTH-043 | Integration | P2 | Create OK; login fail (vd. chưa verify policy) | Sign up | `/sign-up-success` (login tay) |

---

## E. Forgot & reset password

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-050 | Integration | P0 | Email tồn tại | Forgot password → submit | Success UI / không dialog lỗi |
| AUTH-051 | Integration | P1 | Email không tồn tại | Submit | Dialog lỗi (`AuthErrorLocalizer.rawMessage`) |
| AUTH-052 | Manual | P1 | — | Mở Forgot từ Login | Màn hình mở thẳng, không yêu cầu chọn domain (đã bỏ `ForgotPasswordParam`) |
| AUTH-053 | Integration | P0 | Link email `thinkmay://confirm-reset-password?token=` | Mở deep link | Màn enter new password với token |
| AUTH-054 | Manual | P0 | Token hợp lệ | Nhập password mới + confirm → submit | `/enter-new-password-success` |
| AUTH-055 | Unit/Manual | P1 | Token rỗng | Submit | `authErrorInvalidResetToken` (localizer) |
| AUTH-056 | Unit/Manual | P1 | Password < 8 | Submit | `signUpErrorPasswordTooShort` |
| AUTH-057 | Unit/Manual | P1 | Password mismatch | Submit | `signUpErrorPasswordMismatch` |
| AUTH-058 | Integration | P1 | Token expired | Submit | Dialog lỗi PB → localizer hoặc raw message |

---

## F. Email verification

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-060 | Integration | P1 | Đang login; email chưa verify | Màn `/email-verification` → Resend | API `requestVerification` OK |
| AUTH-061 | Manual | P2 | Resend cooldown | Tap resend liên tục | Tuân countdown UI |
| AUTH-062 | Integration | P0 | Link `thinkmay://confirm-verification?token=` | Mở deep link | Auto confirm |
| AUTH-063 | Integration | P1 | Token hợp lệ | Confirm success | Reload user → `/home` |
| AUTH-064 | Unit/Manual | P1 | Token rỗng / invalid | Mở `/confirm-verification` | `authErrorInvalidVerificationToken` |
| AUTH-065 | Integration | P1 | Token expired | Confirm | Dialog lỗi |

---

## G. Logout & session P2

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-070 | Unit | P0 | Prefs có auth keys + `SERVER_URL_KEY` + `thinkmay_mobile_control` | `UserStorage.logout()` | Chỉ `AUTHENTICATED_*` bị remove |
| AUTH-071 | Unit | P0 | — | Sau logout | `SERVER_URL_KEY` và sidepane key **còn** |
| AUTH-072 | Unit | P0 | — | Sau logout | `PocketBase.authStore` empty |
| AUTH-073 | Integration | P0 | Đang login | Setting → Logout | `/welcome` |
| AUTH-074 | Manual | P0 | Sau logout | Thử deep link `/home` | Redirect `/login` (guard) |
| AUTH-075 | Manual | P1 | Sau logout | Reopen Login | `SERVER_URL_KEY` còn nguyên (kiểm tra qua Profile sau khi login lại); Login UI không hiển thị bất kỳ control nào liên quan server. |
| AUTH-076 | Unit | P0 | Mock PB authStore có token | `LogoutUseCase` | `authStore.clear()` được gọi |
| AUTH-077 | Unit | P0 | User registered trong GetIt | `LogoutUseCase` | `getIt.isRegistered<User>() == false` |
| AUTH-078 | Unit | P0 | GlobalCubit đã preload | `LogoutUseCase` | `fetched == false`; subscriptions/worker rỗng |
| AUTH-079 | Manual | P1 | Logout fail (mock throw) | Logout | Ở lại Setting; User vẫn registered |
| AUTH-080 | Manual | P1 | — | Logout thành công | Không flash data dashboard cũ trên Welcome/Login |

---

## H. Route guard (`AppRouter` + `RoutePaths.requiresAuthentication`)

**Allowlist công khai (guest OK):**  
`/splash`, `/welcome`, `/login`, `/login-otp`, `/sign-up`, `/sign-up-success`, `/sign-up-error`, `/forgot-password`, `/enter-new-password`, `/enter-new-password-success`, `/confirm-reset-password`, `/confirm-verification`, `/email-verification`, `/terms`, `/network-check`

**Protected (cần `User` trong GetIt):** mọi route còn lại trong `RoutePaths` — gồm `/home`, `/dashboard`, `/profile`, `/setting`, `/remote-screen`, `/change-password`, `/update-profile`, `/deposit`, `/explore`, `/store`, `/payment`, `/subscription`, `/advanced-settings`, `/language-settings`, `/check-keyboard`, `/gamepad-test`, … (xem unit test `route_paths_test.dart`).

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-090 | Unit | P0 | `isAppInitialized == false` | Navigate `/login` | Redirect `/splash` |
| AUTH-091 | Manual | P0 | Cold start | Deep link `/home` trước splash xong | Về splash trước |
| AUTH-092 | Unit | P0 | Init xong; no User | `requiresAuthentication('/home')` | `true` |
| AUTH-093 | Unit | P0 | Init xong; no User | Mỗi protected path | `requiresAuthentication == true` |
| AUTH-094 | Manual | P0 | Guest sau splash | `context.go('/setting')` | Redirect `/login` |
| AUTH-095 | Unit | P0 | Init xong; no User | Mỗi public path | `requiresAuthentication == false` |
| AUTH-096 | Manual | P0 | Guest | Mở `/login`, `/sign-up`, `/terms` | Không redirect |
| AUTH-097 | Unit | P1 | — | `/confirm-verification?token=abc` | Path normalize; vẫn public |
| AUTH-098 | Unit | P2 | — | `/login/` (trailing slash) | Coi như `/login`; public |
| AUTH-099 | Manual | P0 | Đã login | Navigate `/home`, `/setting`, `/remote-screen` | Không redirect login |

---

## I. Auth error localization (`AuthErrorLocalizer`)

| ID | Loại | Ưu tiên | Input (message / code) | Expected (EN key) |
|----|------|---------|------------------------|-------------------|
| AUTH-100 | Unit | P0 | `Invalid login credentials` / 401 | `authErrorInvalidCredentials` |
| AUTH-101 | Unit | P0 | `Failed to authenticate` / 403 | `authErrorInvalidCredentials` |
| AUTH-102 | Unit | P1 | `Too many requests` / 429 | `authErrorTooManyAttempts` |
| AUTH-103 | Unit | P1 | `rate limit exceeded` / 0 | `authErrorTooManyAttempts` |
| AUTH-104 | Unit | P1 | `The requested record wasn't found` / 404 | `authErrorUserNotFound` |
| AUTH-105 | Unit | P1 | `email already registered` / 400 | `authErrorAccountExists` |
| AUTH-106 | Unit | P1 | `unique constraint failed` / 0 | `authErrorAccountExists` |
| AUTH-107 | Unit | P0 | `Invalid verification token.` | `authErrorInvalidVerificationToken` |
| AUTH-108 | Unit | P0 | `Invalid reset token. Please request a new password reset.` | `authErrorInvalidResetToken` |
| AUTH-109 | Unit | P0 | `Password must be at least 8 characters.` | `signUpErrorPasswordTooShort` |
| AUTH-110 | Unit | P0 | `Passwords do not match.` | `signUpErrorPasswordMismatch` |
| AUTH-111 | Unit | P1 | `Custom server validation error` / 400 | Giữ nguyên chuỗi server |
| AUTH-112 | Unit | P1 | ` ` / 0 | `authErrorGeneric` |
| AUTH-113 | Unit | P1 | Locale `vi` | Chuỗi tiếng Việt tương ứng |
| AUTH-114 | Unit | P1 | Locale `en` | Chuỗi tiếng Anh tương ứng |
| AUTH-115 | Unit | P2 | Message mixed case `INVALID LOGIN CREDENTIALS` | Vẫn map credentials (contains check) |

### Dialog wiring (Manual smoke)

| ID | Màn hình | Trigger lỗi | Expected |
|----|----------|---------------|----------|
| AUTH-116 | Login | Sai password | Dialog title `loginLoginErrorDialogTitle`; body qua localizer |
| AUTH-117 | Login OTP | OTP sai |同上 |
| AUTH-118 | Sign up | Email trùng |同上 |
| AUTH-119 | Forgot password | Email lỗi | `AuthErrorLocalizer.rawMessage` |
| AUTH-120 | Enter new password | Token invalid | Localized reset token message |
| AUTH-121 | Confirm verification | Token invalid | Localized verification message |
| AUTH-122 | Email verification | Resend fail | Localizer trên dialog |

---

## J. Tài khoản đã đăng nhập (profile)

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-130 | Integration | P1 | Logged in | Change password → submit | Success screen; login lại được với pass mới |
| AUTH-131 | Manual | P2 | Guest | Deep link `/change-password` | Redirect `/login` |
| AUTH-132 | Integration | P2 | Wrong old password | Change password | Dialog / error |
| AUTH-133 | Integration | P1 | Logged in | Update profile (name/avatar) | Success; profile refresh |
| AUTH-134 | Manual | P2 | Guest | `/update-profile` | Redirect `/login` |

---

## K. Session persistence keys

| ID | Loại | Ưu tiên | Key | Expected |
|----|------|---------|-----|----------|
| AUTH-140 | Unit/Integration | P0 | `AUTHENTICATED_USER_EMAIL_KEY` | JSON user sau login |
| AUTH-141 | Unit/Integration | P0 | `AUTHENTICATED_TOKEN_KEY` | PB token sau login |
| AUTH-142 | Integration | P1 | `SERVER_URL_KEY` | Set tự động về `Endpoint.baseUrl` sau `LoginCubit.init()`; **survive logout**. Là **routing server** cho WebRTC, KHÔNG ảnh hưởng PocketBase auth host. |

---

## L. OAuth / deep link (cấu hình)

| ID | Loại | Ưu tiên | Steps | Expected |
|----|------|---------|-------|----------|
| AUTH-150 | Manual | P1 | Google login trên Android/iOS | App resume; session OK |
| AUTH-151 | Manual | P2 | So sánh scheme `thinkmay://` với PocketBase admin redirect URLs | Reset + verify + OAuth callback khớp |

---

## L2. Server selection — post-removal (AUTH-160+)

UI dropdown chọn server đã bỏ khỏi Login (xem [02-authentication.md § Server selection — removed](./02-authentication.md#server-selection--removed)). Test giữ key này hoạt động đúng:

| ID | Loại | Ưu tiên | Steps | Expected |
|----|------|---------|-------|----------|
| AUTH-160 | Manual | P0 | Mở Login (cài mới) | Không có dropdown server / divider "Hoặc — server —" / list domain. Chỉ có email/password/forgot/Sign In/Google/OTP. |
| AUTH-161 | Manual | P0 | Sau `LoginCubit.init()` (1 frame) | `SERVER_URL_KEY` = `Endpoint.baseUrl`. Kiểm tra: `flutter logs` hoặc Profile → Select server hiển thị `saigon2`. |
| AUTH-162 | Manual | P1 | Profile → Select server → đổi sang domain khác → quay lại Dashboard → bật Remote | WebRTC URL parse từ domain mới (xem `SessionServiceImpl.parseRequest`); PocketBase auth vẫn dùng `saigon2`. |
| AUTH-163 | Manual | P1 | Logout sau khi đổi server ở Profile | `SERVER_URL_KEY` giữ domain đã chọn (không reset về `saigon2`); user phải login lại từ `saigon2`. |
| AUTH-164 | Unit | P1 | `BaseUrlProvider.getCurrentBaseUrl()` | Luôn `Endpoint.baseUrl`, bất kể giá trị `SERVER_URL_KEY`. |
| AUTH-165 | Unit | P1 | `BaseUrlProvider.updateBaseUrl(custom)` | `SERVER_URL_KEY` = custom; `getIt<PocketBase>().baseURL` reset về `Endpoint.baseUrl` (qua `_ensurePocketBaseOnSaigon2`). |

---

## L3. UI / keyboard handling — auth screens (AUTH-170+)

Pattern tài liệu hoá trong [`skills/flutter-form-fixed-bottom-actions/SKILL.md`](../../skills/flutter-form-fixed-bottom-actions/SKILL.md). Áp dụng cho `login_screen.dart` và `sign_up_screen.dart`.

| ID | Loại | Ưu tiên | Preconditions | Steps | Expected |
|----|------|---------|---------------|-------|----------|
| AUTH-170 | Manual | P0 | Login idle, keyboard đóng | Quan sát toàn màn hình | Không có mảng đen ở đáy; background image phủ tới mép dưới; cụm "Đăng nhập / Hoặc / Google / OTP" dock sát đáy màn hình. |
| AUTH-171 | Manual | P0 | Login | Tap field "Email" | Field scroll lên dock sát mép keyboard (default 20px padding); không jitter / double-scroll; logo có thể bị che bởi field nhưng không có lỗi layout. |
| AUTH-172 | Manual | P0 | Login | Tap field "Mật khẩu" | Field dock sát keyboard; cụm 3 button (Đăng nhập / Google / OTP) **không** nhảy lên theo keyboard, vẫn ở đáy màn hình (bị keyboard che — đúng intent). |
| AUTH-173 | Manual | P0 | Login | Drag scroll view xuống | Keyboard dismiss (`keyboardDismissBehavior.onDrag`); layout trở về trạng thái idle, button không bị offset. |
| AUTH-174 | Manual | P0 | Login | Tap background ngoài field | Keyboard dismiss qua `GestureDetector(onTap: unfocus)`. |
| AUTH-175 | Manual | P0 | Sign-up, keyboard đóng | Quan sát | Tương tự AUTH-170: không gap đen, cụm "Tiếp tục / Hoặc / Google" dock đáy. |
| AUTH-176 | Manual | P0 | Sign-up | Tap lần lượt 5 field từ trên xuống | Mỗi field dock sát keyboard khi focus; field cuối ("Nhập lại mật khẩu") không bị che bởi keyboard; cụm button không bounce. |

---

## M. Gaps regression tests

Đối chiếu mục **「Gaps & rủi ro đã biết」** trong [02-authentication.md](./02-authentication.md). ✅ = đã fix + có test xanh; ⏳ = chưa fix / accepted risk.

| ID | Trạng thái | Gap | Loại | Test cụ thể |
|----|-----------|-----|------|-------------|
| GAP-A1 | ✅ | Logout fail giữa chừng | Unit | `test/auth/logout_use_case_test.dart` — "unregisters user even when repository.logout throws" |
| GAP-A2 | ✅ | Prefs remove fail | Unit | Đã wrap `try/finally` ở `UserStorageImpl.logout()`; verify qua `user_storage_logout_test.dart` (AUTH-070/071/072 vẫn pass với code mới) |
| GAP-A3 | ✅ | Data → presentation violation | Code review | `LogoutUseCaseImpl` không còn import `GlobalCubit`; `clearSession` được gọi trong `SettingCubit.logout` + `ProfileCubit.logout` |
| GAP-A4 | ✅ | SettingCubit.logout không emit error | Unit/Manual | `SettingCubit.logout` giờ trả `false` + emit `SettingErrorState` khi fail (manual smoke trên Setting screen) |
| GAP-B1 | ⏳ | Public allowlist hard-code | Accepted | Mỗi PR thêm route mới phải review allowlist |
| GAP-B2 | ✅ | Token expired vẫn vào protected | Integration | Code: `app_router.dart` check `authStore.isValid`. Test integration: gán JWT exp = quá khứ, mở `/home` → redirect `/login` |
| GAP-B3 | ⏳ | Query escape edge case | — | Test cơ bản đã pass (AUTH-097/098); URL-encoded chưa cover |
| GAP-C1 | ✅ | Exact string fragile | Unit | `auth_error_localizer_test.dart` group "AuthErrorCode dispatch (GAP-C1)" |
| GAP-C2 | ✅ | Passthrough English trên VI | Unit | `auth_error_localizer_test.dart` "passthrough suppressed for English text in VI locale" + "Vietnamese server message kept" |
| GAP-C3 | ✅ | `contains('user')` false positive | Unit | `auth_error_localizer_test.dart` group "user-not-found tightening" |
| GAP-D1 | ✅ | Network error → mất session | Unit | `splash_cubit.dart:_fetchUser` phân biệt 401/403 vs khác. Manual: tắt mạng → Splash giữ session nếu `authRefresh` đã thành công |
| GAP-D2 | ⏳ | Splash không timeout | Accepted | Animation che 3s; chấp nhận tạm |
| GAP-D3 | ✅ | User JSON corrupt | Unit | `test/auth/user_storage_get_test.dart` "clears corrupt JSON and throws" |
| GAP-E1 | 🟡 | Thiếu cubit test | Tracking | Có `LogoutUseCaseImpl`; Login/SignUp/LoginOtp/Splash cubit tests vẫn cần thêm |
| GAP-E2 | ⏳ | Router widget test | Tracking | Pure function `requiresAuthentication` đã cover; widget redirect chưa |
| GAP-E3 | ⏳ | Deep link URL escape | Tracking | Chấp nhận tạm — GoRouter tự decode |
| GAP-F1 | ⏳ | Deep link handler chưa cấu hình | Manual | Cần product decision + native config (Android intent / iOS URL types) |
| GAP-F2 | ⏳ | OAuth `urlCallback` chưa custom | Manual | Cần test trên thiết bị thật |
| GAP-G2 | ⏳ | Cubit khác giữ data user cũ | Manual | Cần manual smoke A→B logout/login |
| GAP-H1 | ✅ | Keyboard che field / button nhảy theo keyboard | Manual | AUTH-170–AUTH-176 trên Login + Sign-up. Pattern: skill `flutter-form-fixed-bottom-actions`. |
| GAP-H2 | ✅ | Custom focus listener trong `TmTextField` đè built-in EditableText scroll | Code review | `lib/presentation/components/tm_text_field.dart` không còn `_alignFieldWithKeyboardTop` / `_scheduleScrollAboveKeyboard`; chỉ giữ `FocusNode` cho UI state. |
| GAP-H3 | ⏳ | SafeArea (notch / home indicator) chưa wrap trên auth screens | Manual | Accepted risk — vertical padding 32.h ở bottom actions đủ trên đa số iPhone. Nếu fix: làm theo verification checklist trong skill, không revert lại pattern Stack/SizedBox.expand. |

---

## Mapping test tự động ↔ ID

| File test | Cover IDs |
|-----------|-----------|
| `test/auth/route_paths_test.dart` | AUTH-092, AUTH-093, AUTH-095, AUTH-097, AUTH-098 |
| `test/auth/auth_error_localizer_test.dart` | AUTH-100–AUTH-115, GAP-C1, GAP-C2, GAP-C3 |
| `test/auth/user_storage_logout_test.dart` | AUTH-070–AUTH-072, GAP-A2 |
| `test/auth/user_storage_get_test.dart` | GAP-D3 |
| `test/auth/logout_use_case_test.dart` | GAP-A1 |

Tổng: **85 unit test xanh** (`flutter test test/auth/`). Các ID còn lại: **Manual** hoặc **Integration**.

---

## Checklist QA trước release (auth)

- [ ] AUTH-001, AUTH-003, AUTH-010, AUTH-021, AUTH-038, AUTH-050, AUTH-054, AUTH-062
- [ ] AUTH-070–AUTH-074, AUTH-077, AUTH-090, AUTH-094, AUTH-096, AUTH-099
- [ ] AUTH-100, AUTH-107–AUTH-110, AUTH-116–AUTH-119
- [ ] AUTH-160, AUTH-161 (server selection removed sanity)
- [ ] AUTH-170–AUTH-176 (keyboard handling Login + Sign-up trên thiết bị thật / simulator)
- [ ] `flutter test test/auth/` — all green
- [ ] Triage `GAP-*` — quyết định fix / accept risk trước release lớn

---

## Liên kết

- [02-authentication.md](./02-authentication.md) — mô tả tính năng
- [../API-COVERAGE.md](../API-COVERAGE.md) — trạng thái tích hợp API
- [../01-app-bootstrap-global-state.md](../01-app-bootstrap-global-state.md) — Splash / GlobalCubit
- [Skill: flutter-form-fixed-bottom-actions](../../skills/flutter-form-fixed-bottom-actions/SKILL.md) — pattern UI auth screens (Login / Sign-up)
