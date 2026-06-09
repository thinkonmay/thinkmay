# 03 — Authentication test cases

Test suite for full scope of [02-authentication.md](./02-authentication.md): PocketBase login/sign-up flows, Splash bootstrap, **P2** (selective logout, route guard, `AuthErrorLocalizer`, session reset).

> **Code source of truth:** `lib/data/storage/user/user_storage.dart`, `lib/data/use_case/user/logout_use_case_impl.dart`, `lib/presentation/router/route_paths.dart`, `lib/presentation/router/app_router.dart`, `lib/utils/api/auth_error_localizer.dart`, auth `*_cubit.dart` files.

---

## How to read this document

| Column | Meaning |
|--------|---------|
| **ID** | Unique test code (`AUTH-xxx`) |
| **Type** | `Unit` = `flutter test`; `Manual` = QA on device/emulator; `Integration` = needs PocketBase / real email |
| **Priority** | P0 required before release; P1 important; P2 polish / edge case |

**Run automated tests (Unit section):**

```powershell
cd d:/thinkmay/mobile
flutter test test/auth/
```

---

## Traceability matrix — no feature gaps

Each row must have at least one test ID **Pass** before feature is considered complete.

| # | Feature / behavior | Spec § | Test IDs |
|---|---------------------|--------|----------|
| 1 | Splash: no session → Welcome | Splash restore | AUTH-001, AUTH-002 |
| 2 | Splash: restore token + server URL + authRefresh + preload → Home | Splash restore | AUTH-003–AUTH-007 |
| 3 | Login email/password + save prefs + register User + preload → Home | Login flow | AUTH-010–AUTH-014 |
| 4 | ~~Login: select server/domain~~ → UI removed, only default routing URL saved | Server selection — removed | AUTH-015–AUTH-016 (REMOVED), AUTH-160 |
| 5 | Login Google OAuth | Login / OAuth | AUTH-017–AUTH-019 |
| 6 | Login OTP: request → enter OTP → Home | Login OTP | AUTH-020–AUTH-027 |
| 7 | Sign up: form validation | Sign up | AUTH-030–AUTH-037 |
| 8 | Sign up: PB create → auto-login → verification → Home | Sign up | AUTH-038–AUTH-041 |
| 9 | Sign up Google | Sign up | AUTH-042 |
| 10 | Sign up: create OK, auto-login fail → success screen | Sign up | AUTH-043 |
| 11 | Forgot password: send reset email | Forgot password | AUTH-050–AUTH-052 |
| 12 | Reset password: deep link token + confirm | Enter new password | AUTH-053–AUTH-058 |
| 13 | Email verification: resend from app | Email verification | AUTH-060–AUTH-061 |
| 14 | Email verification: deep link confirm | Confirm verification | AUTH-062–AUTH-065 |
| 15 | Logout: remove **only** auth keys, keep server URL & other prefs | Session P2 | AUTH-070–AUTH-075 |
| 16 | Logout: PB `authStore.clear` | Session P2 | AUTH-076 |
| 17 | Logout: `unregisterCurrentUser` + `GlobalCubit.clearSession` | Session P2 | AUTH-077–AUTH-079 |
| 18 | Logout UI: Setting → Welcome | Session P2 | AUTH-080 |
| 19 | Route guard: app not init → Splash | Route guard | AUTH-090–AUTH-091 |
| 20 | Route guard: guest + protected route → Login | Route guard | AUTH-092–AUTH-094 |
| 21 | Route guard: guest + public route → no redirect | Route guard | AUTH-095–AUTH-098 |
| 22 | Route guard: logged in → enter protected normally | Route guard | AUTH-099 |
| 23 | `AuthErrorLocalizer`: map PB error → l10n | Error UI P2 | AUTH-100–AUTH-115 |
| 24 | Error dialog uses localizer on each auth screen | Error UI P2 | AUTH-116–AUTH-122 |
| 25 | Change password (logged in) | Profile | AUTH-130–AUTH-132 |
| 26 | Update profile (logged in) | Profile | AUTH-133–AUTH-134 |
| 27 | Session keys: save/load user, token, server URL | Session persistence | AUTH-140–AUTH-142 |
| 28 | OAuth scheme / callback (configuration) | OAuth | AUTH-150–AUTH-151 |
| 29 | Keyboard avoidance on Login / Sign-up (fixed-bottom-actions pattern) | UI gap H1/H2 | AUTH-170–AUTH-176 |

---

## A. Bootstrap & Splash (`SplashCubit.checkIsLoggedIn`)

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-001 | Manual | P0 | Fresh install / cleared app; never logged in | Open app | Splash animation → `/welcome` |
| AUTH-002 | Unit/Manual | P0 | SharedPreferences has no user JSON | Call `checkIsLoggedIn()` | `false`; `AppRouter.isAppInitialized == true` |
| AUTH-003 | Integration | P0 | Previously logged in; token still valid | Kill app → reopen | Splash → `/home`; dashboard has preload data |
| AUTH-004 | Integration | P1 | Has user + token + custom `SERVER_URL_KEY` | Cold start | `BaseUrlProvider` uses saved URL (no default fallback if key has value) |
| AUTH-005 | Integration | P1 | Has user + token; **no** server URL | Cold start | Fallback `Endpoint.baseUrl`; still restore session if PB OK |
| AUTH-006 | Integration | P1 | Token expired but refresh OK | Cold start | `authRefresh` updates token + storage + `registerCurrentUser` |
| AUTH-007 | Integration | P1 | Token invalid / refresh fail | Cold start | Does not enter Home; `FetchUser` fail → Welcome (or guest flow) |
| AUTH-008 | Manual | P2 | Corrupt user JSON in prefs | Cold start | No crash; treat as not logged in |

---

## B. Login email / password (`LoginCubit`)

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-010 | Integration | P0 | Valid account | Enter email/password → Sign In | Loading → `/home`; no error dialog |
| AUTH-011 | Integration | P0 | — | After successful login | `AUTHENTICATED_*` keys have values; `getIt.isRegistered<User>()` |
| AUTH-012 | Integration | P0 | — | After login | `GlobalCubit.state.fetched == true`; has subscriptions/workerInfo (if API OK) |
| AUTH-013 | Integration | P0 | Wrong password | Login | Dialog **Sign In Failed**; message = `authErrorInvalidCredentials` (VI/EN per app locale) |
| AUTH-014 | Manual | P1 | Email does not exist | Login | Error dialog; 404/user not found → `authErrorUserNotFound` or PB message |
| ~~AUTH-015~~ | — | — | ~~RPC domains returns ≥2 servers~~ | ~~Open Login~~ | **REMOVED** — server selection UI removed. Login always uses `Endpoint.baseUrl`. Replaced by AUTH-160. |
| ~~AUTH-016~~ | — | — | ~~Change server on Login~~ | ~~Login success~~ | **REMOVED** — no server change UI on Login. Routing server change now via Profile → Select server. |
| AUTH-017 | Integration | P1 | Google account linked to PB | Tap **Sign in with Google** | OAuth flow → `/home`; user + token saved |
| AUTH-018 | Manual | P2 | User cancels OAuth | Tap Google → cancel | Return to Login; no crash; no User registered |
| AUTH-019 | Manual | P2 | **Sign in with email OTP** link | Tap | Navigate `/login-otp` |

---

## C. Login OTP (`LoginOtpCubit`)

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-020 | Integration | P0 | Email has account | Enter email → submit | Switch to OTP step; resend countdown ~120s |
| AUTH-021 | Integration | P0 | OTP from email | Enter 6 digits → verify | `/home`; session saved |
| AUTH-022 | Manual | P1 | Invalid email format | Submit at email step | No API call (silent / no infinite loading) |
| AUTH-023 | Integration | P1 | Wrong OTP | Verify | Error dialog via `AuthErrorLocalizer` |
| AUTH-024 | Manual | P1 | During countdown | Resend button disabled | Does not resend OTP |
| AUTH-025 | Integration | P1 | Countdown finished | Tap resend | Send new OTP; reset timer |
| AUTH-026 | Manual | P2 | OTP step | **Prefer password?** | Return to email step / password login |
| AUTH-027 | Manual | P2 | OTP < 6 characters | Submit | Does not call verify |

---

## D. Sign up (`SignUpCubit`)

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-030 | Unit/Manual | P0 | — | Empty name | `signUpErrorNameRequired` |
| AUTH-031 | Unit/Manual | P0 | — | Empty email | `signUpErrorEmailRequired` |
| AUTH-032 | Unit/Manual | P1 | — | Email with uppercase | `signUpErrorEmailNoCapital` |
| AUTH-033 | Unit/Manual | P1 | — | Invalid email format | `signUpErrorInvalidFormatEmailDialogMessage` |
| AUTH-034 | Unit/Manual | P1 | — | Invalid phone (if entered) | `signUpErrorPhoneInvalid` |
| AUTH-035 | Unit/Manual | P0 | — | Password < 8 | `signUpErrorPasswordTooShort` |
| AUTH-036 | Unit/Manual | P0 | — | Password ≠ confirm | `signUpErrorPasswordMismatch` |
| AUTH-037 | Manual | P1 | Phone left empty | Otherwise valid sign up | Pass validation |
| AUTH-038 | Integration | P0 | Unused email | Full sign up | Auto-login → `/home`; verification email sent |
| AUTH-039 | Integration | P1 | Email already exists | Sign up | Dialog; `authErrorAccountExists` (if PB returns unique) |
| AUTH-040 | Integration | P1 | PB 5xx on create | Sign up | Navigate `/sign-up-error` |
| AUTH-041 | Manual | P1 | — | After successful sign-up | User in GetIt; preload complete |
| AUTH-042 | Integration | P1 | — | Continue with Google | `/home` (no success screen) |
| AUTH-043 | Integration | P2 | Create OK; login fail (e.g. verify policy) | Sign up | `/sign-up-success` (manual login) |

---

## E. Forgot & reset password

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-050 | Integration | P0 | Email exists | Forgot password → submit | Success UI / no error dialog |
| AUTH-051 | Integration | P1 | Email does not exist | Submit | Error dialog (`AuthErrorLocalizer.rawMessage`) |
| AUTH-052 | Manual | P1 | — | Open Forgot from Login | Screen opens directly, no domain selection required (removed `ForgotPasswordParam`) |
| AUTH-053 | Integration | P0 | Email link `thinkmay://confirm-reset-password?token=` | Open deep link | Enter new password screen with token |
| AUTH-054 | Manual | P0 | Valid token | Enter new password + confirm → submit | `/enter-new-password-success` |
| AUTH-055 | Unit/Manual | P1 | Empty token | Submit | `authErrorInvalidResetToken` (localizer) |
| AUTH-056 | Unit/Manual | P1 | Password < 8 | Submit | `signUpErrorPasswordTooShort` |
| AUTH-057 | Unit/Manual | P1 | Password mismatch | Submit | `signUpErrorPasswordMismatch` |
| AUTH-058 | Integration | P1 | Token expired | Submit | PB error dialog → localizer or raw message |

---

## F. Email verification

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-060 | Integration | P1 | Logged in; email not verified | Screen `/email-verification` → Resend | API `requestVerification` OK |
| AUTH-061 | Manual | P2 | Resend cooldown | Tap resend repeatedly | Follow UI countdown |
| AUTH-062 | Integration | P0 | Link `thinkmay://confirm-verification?token=` | Open deep link | Auto confirm |
| AUTH-063 | Integration | P1 | Valid token | Confirm success | Reload user → `/home` |
| AUTH-064 | Unit/Manual | P1 | Empty / invalid token | Open `/confirm-verification` | `authErrorInvalidVerificationToken` |
| AUTH-065 | Integration | P1 | Token expired | Confirm | Error dialog |

---

## G. Logout & session P2

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-070 | Unit | P0 | Prefs have auth keys + `SERVER_URL_KEY` + `thinkmay_mobile_control` | `UserStorage.logout()` | Only `AUTHENTICATED_*` removed |
| AUTH-071 | Unit | P0 | — | After logout | `SERVER_URL_KEY` and sidepane key **remain** |
| AUTH-072 | Unit | P0 | — | After logout | `PocketBase.authStore` empty |
| AUTH-073 | Integration | P0 | Logged in | Setting → Logout | `/welcome` |
| AUTH-074 | Manual | P0 | After logout | Try deep link `/home` | Redirect `/login` (guard) |
| AUTH-075 | Manual | P1 | After logout | Reopen Login | `SERVER_URL_KEY` unchanged (verify via Profile after re-login); Login UI shows no server-related controls. |
| AUTH-076 | Unit | P0 | Mock PB authStore has token | `LogoutUseCase` | `authStore.clear()` called |
| AUTH-077 | Unit | P0 | User registered in GetIt | `LogoutUseCase` | `getIt.isRegistered<User>() == false` |
| AUTH-078 | Unit | P0 | GlobalCubit preloaded | `LogoutUseCase` | `fetched == false`; subscriptions/worker empty |
| AUTH-079 | Manual | P1 | Logout fail (mock throw) | Logout | Stay on Setting; User still registered |
| AUTH-080 | Manual | P1 | — | Successful logout | No flash of old dashboard data on Welcome/Login |

---

## H. Route guard (`AppRouter` + `RoutePaths.requiresAuthentication`)

**Public allowlist (guest OK):**  
`/splash`, `/welcome`, `/login`, `/login-otp`, `/sign-up`, `/sign-up-success`, `/sign-up-error`, `/forgot-password`, `/enter-new-password`, `/enter-new-password-success`, `/confirm-reset-password`, `/confirm-verification`, `/email-verification`, `/terms`, `/network-check`

**Protected (requires `User` in GetIt):** all remaining routes in `RoutePaths` — including `/home`, `/dashboard`, `/profile`, `/setting`, `/remote-screen`, `/change-password`, `/update-profile`, `/deposit`, `/explore`, `/store`, `/payment`, `/subscription`, `/advanced-settings`, `/language-settings`, `/check-keyboard`, `/gamepad-test`, … (see unit test `route_paths_test.dart`).

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-090 | Unit | P0 | `isAppInitialized == false` | Navigate `/login` | Redirect `/splash` |
| AUTH-091 | Manual | P0 | Cold start | Deep link `/home` before splash done | Go to splash first |
| AUTH-092 | Unit | P0 | Init done; no User | `requiresAuthentication('/home')` | `true` |
| AUTH-093 | Unit | P0 | Init done; no User | Each protected path | `requiresAuthentication == true` |
| AUTH-094 | Manual | P0 | Guest after splash | `context.go('/setting')` | Redirect `/login` |
| AUTH-095 | Unit | P0 | Init done; no User | Each public path | `requiresAuthentication == false` |
| AUTH-096 | Manual | P0 | Guest | Open `/login`, `/sign-up`, `/terms` | No redirect |
| AUTH-097 | Unit | P1 | — | `/confirm-verification?token=abc` | Path normalized; still public |
| AUTH-098 | Unit | P2 | — | `/login/` (trailing slash) | Treated as `/login`; public |
| AUTH-099 | Manual | P0 | Logged in | Navigate `/home`, `/setting`, `/remote-screen` | No redirect to login |

---

## I. Auth error localization (`AuthErrorLocalizer`)

| ID | Type | Priority | Input (message / code) | Expected (EN key) |
|----|------|----------|------------------------|-------------------|
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
| AUTH-111 | Unit | P1 | `Custom server validation error` / 400 | Keep server string as-is |
| AUTH-112 | Unit | P1 | ` ` / 0 | `authErrorGeneric` |
| AUTH-113 | Unit | P1 | Locale `vi` | Corresponding Vietnamese string |
| AUTH-114 | Unit | P1 | Locale `en` | Corresponding English string |
| AUTH-115 | Unit | P2 | Message mixed case `INVALID LOGIN CREDENTIALS` | Still maps credentials (contains check) |

### Dialog wiring (Manual smoke)

| ID | Screen | Error trigger | Expected |
|----|--------|---------------|----------|
| AUTH-116 | Login | Wrong password | Dialog title `loginLoginErrorDialogTitle`; body via localizer |
| AUTH-117 | Login OTP | Wrong OTP | same as above |
| AUTH-118 | Sign up | Duplicate email | same as above |
| AUTH-119 | Forgot password | Email error | `AuthErrorLocalizer.rawMessage` |
| AUTH-120 | Enter new password | Token invalid | Localized reset token message |
| AUTH-121 | Confirm verification | Token invalid | Localized verification message |
| AUTH-122 | Email verification | Resend fail | Localizer on dialog |

---

## J. Logged-in account (profile)

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-130 | Integration | P1 | Logged in | Change password → submit | Success screen; can login with new password |
| AUTH-131 | Manual | P2 | Guest | Deep link `/change-password` | Redirect `/login` |
| AUTH-132 | Integration | P2 | Wrong old password | Change password | Dialog / error |
| AUTH-133 | Integration | P1 | Logged in | Update profile (name/avatar) | Success; profile refresh |
| AUTH-134 | Manual | P2 | Guest | `/update-profile` | Redirect `/login` |

---

## K. Session persistence keys

| ID | Type | Priority | Key | Expected |
|----|------|----------|-----|----------|
| AUTH-140 | Unit/Integration | P0 | `AUTHENTICATED_USER_EMAIL_KEY` | User JSON after login |
| AUTH-141 | Unit/Integration | P0 | `AUTHENTICATED_TOKEN_KEY` | PB token after login |
| AUTH-142 | Integration | P1 | `SERVER_URL_KEY` | Auto-set to `Endpoint.baseUrl` after `LoginCubit.init()`; **survives logout**. Is **routing server** for WebRTC, does NOT affect PocketBase auth host. |

---

## L. OAuth / deep link (configuration)

| ID | Type | Priority | Steps | Expected |
|----|------|----------|-------|----------|
| AUTH-150 | Manual | P1 | Google login on Android/iOS | App resumes; session OK |
| AUTH-151 | Manual | P2 | Compare scheme `thinkmay://` with PocketBase admin redirect URLs | Reset + verify + OAuth callback match |

---

## L2. Server selection — post-removal (AUTH-160+)

Server dropdown removed from Login (see [02-authentication.md § Server selection — removed](./02-authentication.md#server-selection--removed)). Tests in this section verify correct behavior:

| ID | Type | Priority | Steps | Expected |
|----|------|----------|-------|----------|
| AUTH-160 | Manual | P0 | Open Login (fresh install) | No server dropdown / "Or — server —" divider / domain list. Only email/password/forgot/Sign In/Google/OTP. |
| AUTH-161 | Manual | P0 | After `LoginCubit.init()` (1 frame) | `SERVER_URL_KEY` = `Endpoint.baseUrl`. Verify: `flutter logs` or Profile → Select server shows `saigon2`. |
| AUTH-162 | Manual | P1 | Profile → Select server → change to different domain → return to Dashboard → start Remote | WebRTC URL parsed from new domain (see `SessionServiceImpl.parseRequest`); PocketBase auth still uses `saigon2`. |
| AUTH-163 | Manual | P1 | Logout after changing server in Profile | `SERVER_URL_KEY` keeps selected domain (not reset to `saigon2`); user must login again from `saigon2`. |
| AUTH-164 | Unit | P1 | `BaseUrlProvider.getCurrentBaseUrl()` | Always `Endpoint.baseUrl`, regardless of `SERVER_URL_KEY` value. |
| AUTH-165 | Unit | P1 | `BaseUrlProvider.updateBaseUrl(custom)` | `SERVER_URL_KEY` = custom; `getIt<PocketBase>().baseURL` reset to `Endpoint.baseUrl` (via `_ensurePocketBaseOnSaigon2`). |

---

## L3. UI / keyboard handling — auth screens (AUTH-170+)

Pattern documented in [`skills/flutter-form-fixed-bottom-actions/SKILL.md`](../../skills/flutter-form-fixed-bottom-actions/SKILL.md). Applies to `login_screen.dart` and `sign_up_screen.dart`.

| ID | Type | Priority | Preconditions | Steps | Expected |
|----|------|----------|---------------|-------|----------|
| AUTH-170 | Manual | P0 | Login idle, keyboard closed | Observe full screen | No black gap at bottom; background image extends to bottom edge; "Sign In / Or / Google / OTP" cluster docked at screen bottom. |
| AUTH-171 | Manual | P0 | Login | Tap "Email" field | Field scrolls up to dock near keyboard edge (default 20px padding); no jitter / double-scroll; logo may be covered by field but no layout error. |
| AUTH-172 | Manual | P0 | Login | Tap "Password" field | Field docks near keyboard; 3-button cluster (Sign In / Google / OTP) **does not** jump with keyboard, stays at screen bottom (covered by keyboard — correct intent). |
| AUTH-173 | Manual | P0 | Login | Drag scroll view down | Keyboard dismiss (`keyboardDismissBehavior.onDrag`); layout returns to idle state, buttons not offset. |
| AUTH-174 | Manual | P0 | Login | Tap background outside field | Keyboard dismiss via `GestureDetector(onTap: unfocus)`. |
| AUTH-175 | Manual | P0 | Sign-up, keyboard closed | Observe | Same as AUTH-170: no black gap, "Continue / Or / Google" cluster docked at bottom. |
| AUTH-176 | Manual | P0 | Sign-up | Tap each of 5 fields top to bottom | Each field docks near keyboard on focus; last field ("Confirm password") not covered by keyboard; button cluster does not bounce. |

---

## M. Gaps regression tests

Cross-reference **「Gaps & known risks」** section in [02-authentication.md](./02-authentication.md). ✅ = fixed + green test; ⏳ = not fixed / accepted risk.

| ID | Status | Gap | Type | Specific test |
|----|--------|-----|------|---------------|
| GAP-A1 | ✅ | Logout fail mid-way | Unit | `test/auth/logout_use_case_test.dart` — "unregisters user even when repository.logout throws" |
| GAP-A2 | ✅ | Prefs remove fail | Unit | Wrapped `try/finally` in `UserStorageImpl.logout()`; verify via `user_storage_logout_test.dart` (AUTH-070/071/072 still pass with new code) |
| GAP-A3 | ✅ | Data → presentation violation | Code review | `LogoutUseCaseImpl` no longer imports `GlobalCubit`; `clearSession` called in `SettingCubit.logout` + `ProfileCubit.logout` |
| GAP-A4 | ✅ | SettingCubit.logout does not emit error | Unit/Manual | `SettingCubit.logout` now returns `false` + emits `SettingErrorState` on fail (manual smoke on Setting screen) |
| GAP-B1 | ⏳ | Public allowlist hard-coded | Accepted | Each PR adding new route must review allowlist |
| GAP-B2 | ✅ | Expired token still enters protected | Integration | Code: `app_router.dart` checks `authStore.isValid`. Integration test: set JWT exp = past, open `/home` → redirect `/login` |
| GAP-B3 | ⏳ | Query escape edge case | — | Basic tests pass (AUTH-097/098); URL-encoded not covered |
| GAP-C1 | ✅ | Exact string fragile | Unit | `auth_error_localizer_test.dart` group "AuthErrorCode dispatch (GAP-C1)" |
| GAP-C2 | ✅ | Passthrough English on VI | Unit | `auth_error_localizer_test.dart` "passthrough suppressed for English text in VI locale" + "Vietnamese server message kept" |
| GAP-C3 | ✅ | `contains('user')` false positive | Unit | `auth_error_localizer_test.dart` group "user-not-found tightening" |
| GAP-D1 | ✅ | Network error → session lost | Unit | `splash_cubit.dart:_fetchUser` distinguishes 401/403 vs other. Manual: disable network → Splash keeps session if `authRefresh` succeeded |
| GAP-D2 | ⏳ | Splash has no timeout | Accepted | Animation covers 3s; temporarily accepted |
| GAP-D3 | ✅ | User JSON corrupt | Unit | `test/auth/user_storage_get_test.dart` "clears corrupt JSON and throws" |
| GAP-E1 | 🟡 | Missing cubit tests | Tracking | Has `LogoutUseCaseImpl`; Login/SignUp/LoginOtp/Splash cubit tests still needed |
| GAP-E2 | ⏳ | Router widget test | Tracking | Pure function `requiresAuthentication` covered; widget redirect not yet |
| GAP-E3 | ⏳ | Deep link URL escape | Tracking | Temporarily accepted — GoRouter auto-decodes |
| GAP-F1 | ⏳ | Deep link handler not configured | Manual | Needs product decision + native config (Android intent / iOS URL types) |
| GAP-F2 | ⏳ | OAuth `urlCallback` not customized | Manual | Needs test on real device |
| GAP-G2 | ⏳ | Other cubits keep old user data | Manual | Needs manual smoke A→B logout/login |
| GAP-H1 | ✅ | Keyboard covers field / button jumps with keyboard | Manual | AUTH-170–AUTH-176 on Login + Sign-up. Pattern: skill `flutter-form-fixed-bottom-actions`. |
| GAP-H2 | ✅ | Custom focus listener in `TmTextField` overrides built-in EditableText scroll | Code review | `lib/presentation/components/tm_text_field.dart` no longer has `_alignFieldWithKeyboardTop` / `_scheduleScrollAboveKeyboard`; only keeps `FocusNode` for UI state. |
| GAP-H3 | ⏳ | SafeArea (notch / home indicator) not wrapped on auth screens | Manual | Accepted risk — 32.h vertical padding on bottom actions sufficient on most iPhones. If fixing: follow verification checklist in skill, do not revert Stack/SizedBox.expand pattern. |

---

## Automated test ↔ ID mapping

| Test file | Covers IDs |
|-----------|------------|
| `test/auth/route_paths_test.dart` | AUTH-092, AUTH-093, AUTH-095, AUTH-097, AUTH-098 |
| `test/auth/auth_error_localizer_test.dart` | AUTH-100–AUTH-115, GAP-C1, GAP-C2, GAP-C3 |
| `test/auth/user_storage_logout_test.dart` | AUTH-070–AUTH-072, GAP-A2 |
| `test/auth/user_storage_get_test.dart` | GAP-D3 |
| `test/auth/logout_use_case_test.dart` | GAP-A1 |

Total: **85 unit tests green** (`flutter test test/auth/`). Remaining IDs: **Manual** or **Integration**.

---

## Pre-release QA checklist (auth)

- [ ] AUTH-001, AUTH-003, AUTH-010, AUTH-021, AUTH-038, AUTH-050, AUTH-054, AUTH-062
- [ ] AUTH-070–AUTH-074, AUTH-077, AUTH-090, AUTH-094, AUTH-096, AUTH-099
- [ ] AUTH-100, AUTH-107–AUTH-110, AUTH-116–AUTH-119
- [ ] AUTH-160, AUTH-161 (server selection removed sanity)
- [ ] AUTH-170–AUTH-176 (keyboard handling Login + Sign-up on real device / simulator)
- [ ] `flutter test test/auth/` — all green
- [ ] Triage `GAP-*` — decide fix / accept risk before major release

---

## Links

- [02-authentication.md](./02-authentication.md) — feature description
- [../API-COVERAGE.md](../API-COVERAGE.md) — API integration status
- [../01-app-bootstrap-global-state.md](../01-app-bootstrap-global-state.md) — Splash / GlobalCubit
- [Skill: flutter-form-fixed-bottom-actions](../../skills/flutter-form-fixed-bottom-actions/SKILL.md) — UI pattern for auth screens (Login / Sign-up)
