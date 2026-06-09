# 02 — Authentication

## Overview

**Login and sign-up use PocketBase** (`users` collection), not Supabase Auth.

- Login: `authWithPassword`
- Login OTP: `requestOTP` + `authWithOTP`
- Sign up: `collection.create` → **auto-login** `authWithPassword` → `requestVerification(email)` → `preload` (same as web `signUpWithEmail` + `loginWithEmail`)
- Google: `authWithOAuth2('google')` on PocketBase

Locally stored token is **PocketBase auth token** (`UserResponse.token`), restored via `PocketBase.authStore.save()` on app open (Splash).

`SupabaseClient` is registered in DI but **does not** participate in auth flow — only used for store/resources (see [18-backend-integration](../18-backend-integration.md)).

Website: `(auth)/login`, `register`, … — `backend/actions/index.ts` (needs separate comparison; web may use different stack).

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md)

| Screen | Status | Actual backend |
|--------|--------|----------------|
| Login | ✅ | PocketBase `authWithPassword` (fixed server `saigon2`, no server dropdown) |
| Login Google | ✅ | PocketBase `authWithOAuth2` |
| Login OTP | ✅ | PocketBase `requestOTP` + `authWithOTP` → preload |
| Sign up | ✅ | PocketBase `create` + auto-login + verification email |
| Change password | ✅ | PocketBase `users` update (`UpdateUserUseCase`) |
| Update profile | ✅ | PocketBase + optional avatar upload |
| Email verification | ✅ | `requestVerification` / resend; `confirmVerification(token)` + deep link |
| Forgot password | ✅ | `requestPasswordReset` (no longer accepts domain parameter) |
| Enter new password | ✅ | `confirmPasswordReset` + deep link token |

**Fixed:** After login / OTP / sign-up: `GlobalCubit.preload()` before entering Home. Splash uses saved server URL + **`authRefresh`** to refresh token.

**Auth screen UI/UX:** Login / Sign-up use keyboard-aware pattern with action cluster fixed at bottom of screen, fields auto-dock near keyboard edge via `EditableText` built-in. Pattern documented in skill `skills/flutter-form-fixed-bottom-actions/SKILL.md` — must read before editing any auth screen or creating new form + bottom actions screen.

**Server/email configuration needed:** reset / verify links in email must point to correct app scheme `thinkmay://…` to open app directly.

---

## Mobile — source files

| Screen | Route | Cubit | Service |
|--------|-------|-------|---------|
| Login | `/login` | `login_cubit.dart` | `authentication_service.dart` |
| Login OTP | `/login-otp` | `login_otp_cubit.dart` | same as above |
| Sign up | `/sign-up` | `sign_up_cubit.dart` | same as above |
| Change password | `/change-password` | `change_password_cubit.dart` | `user_service.dart` |
| Update profile | `/update-profile` | `update_profile_cubit.dart` | `user_service.dart` |

**Auth service:** `lib/data/network/authentication/authentication_service.dart`

---

## Login flow (per code)

**`LoginCubit.init()`**

1. Set default routing server = `Endpoint.baseUrl` (saigon2) via `BaseUrlProvider.updateBaseUrl(...)` + `SaveServerUrlUseCase` (key `SERVER_URL_KEY`).
2. PocketBase auth **always** goes through `Endpoint.baseUrl`. No more domain list fetch / server picker in login UI (see [Server selection — removed](#server-selection--removed)).

**`LoginCubit.login()`**

1. `LoginUseCase` → `PocketBase.collection('users').authWithPassword(email, password)`
2. PocketBase SDK auto-attaches `authStore` (token + record)
3. `SaveUserStorageUseCase(record)`, `SaveSessionTokenUseCase(token)`, `SaveServerUrlUseCase(Endpoint.baseUrl)` (ensure key exists)
4. `registerCurrentUser(record)`
5. `GlobalCubit.preload()` then `LoginSuccessState` → `/home`

**`LoginCubit.loginAction()`** — Google OAuth: same save storage + `registerCurrentUser` + `preload()` → `/home`.

### Server selection on login

`SplashCubit` always runs `GlobalCubit.bootstrap()` — guests get `fetch_domains` during splash (PWA preload on shell). `LoginCubit.init()` reads `GlobalState.domains` for `ServerDomainSwitch` (`pocketBaseNodesOnly: true`). Post-login full preload refreshes user-scoped data. WebRTC routing: network check, remote `RoutingSwitch`, control panel settings.

`BaseUrlProvider` after refactor:

| Method | Returns | Used for |
|---|---|---|
| `getCurrentBaseUrl()` | `Endpoint.baseUrl` (fixed `saigon2`) | PocketBase auth + `/info` + volumes |
| `getRoutingServerUrl()` | URL in `SERVER_URL_KEY` (fallback `Endpoint.baseUrl`) | Build WebRTC URL in `SessionServiceImpl.parseRequest()` |
| `updateBaseUrl(url)` | — | Save `url` as routing server; `_ensurePocketBaseOnSaigon2()` resets `PocketBase` in GetIt to `Endpoint.baseUrl` |

`DomainDto.routingOnly` removed. Server selection logic for streaming is in `Profile/SelectServerSection` (see [09-profile-account](../profile/09-profile-account.md)) — unrelated to login.

---

## Login OTP flow (`LoginOtpCubit` + `/login-otp`)

1. `requestOTP(email)` → save `otpId`, switch to OTP input step
2. `authWithOTP(otpId, otp)` → save user/token + `preload()` → `/home`

## Splash restore (auth-related)

`SplashCubit.checkIsLoggedIn()`:

1. Read user + token from SharedPreferences
2. `BaseUrlProvider` → saved server URL (if any) or fallback `Endpoint.baseUrl`
3. `UpdatePocketBaseAuthStoreUseCase` → `authStore.save(token, record)`
4. `RefreshAuthUseCase` → `auth-refresh` (update token + save storage + `registerCurrentUser`)
5. `FetchUserUseCase` → `PocketBase.collection('users').getList(page: 1)` (verify session)
6. If OK → `GlobalCubit.preload()`

---

## Sign up flow

1. `SignUpUseCase` → `PocketBase.collection('users').create(body: ...)` (includes `name`, optional `phone`, `metadata`)
2. `LoginUseCase` → `authWithPassword` (auto-login same as web)
3. `RequestVerificationUseCase` → send verification email
4. `GlobalCubit.preload()` → `SignUpLoggedInState` → `/home`
5. If step (2) fails (e.g. email not verified) → `/sign-up-success` for manual login

Validation: close to website — standard email (no uppercase), name required, phone optional (regex), password ≥ 8, matches `passwordConfirm`.

---

## Session persistence

| Data | Storage | Notes |
|------|---------|-------|
| User record JSON | SharedPreferences (`authenticatedUserEmailKey`) | `SaveUserStorageUseCase` |
| PB auth token | SharedPreferences (`authenticatedTokenKey`) | `SaveSessionTokenUseCase` |
| Routing server URL | SharedPreferences (`serverUrlKey`) | URL for **WebRTC routing** (see `SessionServiceImpl`). PocketBase auth does not read this key — always uses `Endpoint.baseUrl`. Login defaults to `Endpoint.baseUrl`; profile can change later. **Not** cleared on logout. |

`LogoutUseCase` — only removes auth keys in storage, `PocketBase.authStore.clear()`, `unregisterCurrentUser()`, `GlobalCubit.clearSession()`.

---

## Route guard (GoRouter)

After `AppRouter.isAppInitialized == true`, any route **not** in public allowlist (`RoutePaths` in code) when `getIt` has no `User` redirects to `/login`. Public routes include splash, welcome, login/OTP, sign-up, forgot password / reset / email verification (deep link), terms, network check.

---

## Auth error messages (UI)

Login, OTP, sign-up, forgot password, reset password, email verification screens use `AuthErrorLocalizer` to map common PocketBase errors to localized strings; other errors still show server content if available.

---

## OAuth (Google)

Google login opens external OAuth flow; when returning, PocketBase SDK must receive callback. Ensure **scheme** `thinkmay://` (and Android intent filter / iOS URL types) matches PocketBase server config. Reset/verify deep links already use same scheme; OAuth callback must be configured similarly in PB admin if prod uses custom redirect.

---

## Gaps & known risks

Code review: 2026-05-20. Status update: ✅ = fixed; ⏳ = remaining / accepted risk. Corresponding test IDs in [03-authentication-test-cases.md](./03-authentication-test-cases.md).

### A. Logout / cleanup ordering

| # | Status | Issue | File | Fix / reason |
|---|--------|-------|------|--------------|
| A1 | ✅ | `LogoutUseCaseImpl` skips cleanup when repo logout throws. | `lib/data/use_case/user/logout_use_case_impl.dart` | `unregisterCurrentUser()` runs in `finally`; still returns `Left` for UI handle. |
| A2 | ✅ | `UserStorageImpl.logout()` mismatch when `prefs.remove` fails. | `lib/data/storage/user/user_storage.dart` | `try/finally` around prefs remove; `authStore.clear()` always runs; rethrow prefs error. |
| A3 | ✅ | Data layer depends on `GlobalCubit`. | `logout_use_case_impl.dart` | Remove `GlobalCubit` import; `clearSession()` called from `SettingCubit.logout` / `ProfileCubit.logout` after receiving `Right`. |
| A4 | ✅ | `SettingCubit.logout()` does not emit error. | `setting_cubit.dart` | Emit `SettingErrorState` on logout fail; UI can catch from listener. |

### B. Route guard

| # | Status | Issue | File | Fix / reason |
|---|--------|-------|------|--------------|
| B1 | ⏳ | Public allowlist hard-coded. | `route_paths.dart` | Accepted risk; each new route must be updated manually. Consider annotation on `GoRoute` in later milestone. |
| B2 | ✅ | Expired token still enters protected routes. | `app_router.dart` | Guard checks `PocketBase.authStore.isValid` when `authStore.token` non-empty; if expired → redirect login. |
| B3 | ⏳ | Deep link query string tests incomplete. | `route_paths.dart` | Has test `?token=…` + trailing slash. Edge case `%20` / `+` not covered (low risk because GoRouter normalizes first). |

### C. AuthErrorLocalizer

| # | Status | Issue | File | Fix / reason |
|---|--------|-------|------|--------------|
| C1 | ✅ | Exact string comparison fragile. | `auth_error_localizer.dart`, `tm_exception.dart`, `auth_error_code.dart` | Add `AuthErrorCode` enum; `TmException.code` preferred in localizer. Cubits `SignUpCubit` + `ConfirmVerificationCubit` already set `code`. Legacy sentinel string kept as fallback for `EnterNewPasswordCubit` (state not migrated yet). |
| C2 | ✅ | Passthrough English message on VI locale. | `auth_error_localizer.dart:_passthroughOrGeneric` | Heuristic: VI + ASCII-only English → `authErrorGeneric`; strings with Unicode (Vietnamese) kept as-is. |
| C3 | ✅ | `contains('user')` false positive. | `_looksLikeUserNotFound` | Requires `record` or `email` or phrase `user not found`; `"user input invalid"` no longer maps incorrectly. |

### D. Splash / session restore

| # | Status | Issue | File | Fix / reason |
|---|--------|-------|------|--------------|
| D1 | ✅ | Network error → session lost. | `splash_cubit.dart:_fetchUser` | Distinguish 401/403 (drop session) vs other (keep session if User already registered from `authRefresh`). |
| D2 | ⏳ | Splash has no timeout. | `splash_cubit.dart` | Accepted risk; UI has 3s animation covering most cases. Can add `.timeout()` later. |
| D3 | ✅ | Corrupt user JSON. | `user_storage.dart:getUserStorage` | Catch `FormatException`; log warning; remove bad key; throw generic "No user data found". |

### E. Missing test coverage

| # | Status | Missing | Existing |
|---|--------|---------|----------|
| E1 | 🟡 | Cubit tests for `LoginCubit`, `SignUpCubit`, `LoginOtpCubit`, `SplashCubit`. | Has `LogoutUseCaseImpl` test (`test/auth/logout_use_case_test.dart`); rest pending. |
| E2 | ⏳ | Widget test for `AppRouter.redirect`. | Has pure-function test `RoutePaths.requiresAuthentication`. |
| E3 | ⏳ | Edge: token expired + refresh fail; deep link URL escape. | Token expired handled in code (B2) but no automated widget test yet. |

### F. OAuth deep link

| # | Issue | Proposal |
|---|-------|----------|
| F1 | App **has no handler** for external deep links (no `app_links` / `uni_links` in `pubspec.yaml`). Reset / verify use in-app routes — but if user opens email link when app closed, Android/iOS not configured with intent filter / URL types to map to GoRouter. | Decision: (a) add package + configure Android intent filter (`AndroidManifest.xml`) + iOS URL types (`Info.plist`); (b) or send email with HTTPS link to web then web opens app. |
| F2 | `authWithOAuth2('google')` needs URL launcher for mobile; PB SDK 0.23 uses `urlCallback` to open browser → when user taps Google on app, handler needed. No `urlCallback` configuration seen in code. | Verify on real device; if needed, custom OAuth flow. |

### G. Other

| # | Issue | Proposal |
|---|-------|----------|
| G1 | `UserStorageImpl.logout()` logs at INFO without user ID — privacy OK. No audit trail. | Optional: log timestamp + reason (manual / token-expired / forced). |
| G2 | `unregisterCurrentUser()` only unregisters `User` in GetIt; **does not** reset other Cubits (`DashboardCubit`, `RemoteCubit`, …). If user A logs out then user B logs in immediately → cubit may hold A's data before `preload` overwrites. | Document that login must wait for `preload` before opening Home (already correct); add test to confirm. |
| G3 | `BaseUrlProvider.updateBaseUrl` not called after logout. Correct intent (keep server URL). | Note clearly in spec — already documented. |

### H. UI / keyboard handling

| # | Status | Issue | File | Fix / reason |
|---|--------|-------|------|--------------|
| H1 | ✅ | Field covered by keyboard, or "Sign In" button jumps with keyboard. | `login_screen.dart`, `sign_up_screen.dart` | Pattern: `Scaffold(resizeToAvoidBottomInset: false)` + `SizedBox.expand` + `DecoratedBox` + `Stack(fit: StackFit.expand)` + `Padding(bottom: viewInsets.bottom)` around `SingleChildScrollView`. Field auto-docks near keyboard via default `EditableText.scrollPadding`. Docs: `skills/flutter-form-fixed-bottom-actions/SKILL.md`. |
| H2 | ✅ | Custom `FocusNode` listener / `Scrollable.ensureVisible` in `TmTextField` overrides built-in → jitter, wrong scroll position. | `tm_text_field.dart` | Removed entirely. Component now only keeps `FocusNode` for label/border rebuild. |
| H3 | ⏳ | SafeArea for notch / home indicator not explicitly wrapped on auth screens (tried, caused regression with current pattern — reverted). | `login_screen.dart`, `sign_up_screen.dart` | Accepted risk. Bottom action cluster still has 32.h vertical padding sufficient for newer iPhone home indicator. If full fix needed: retry with control, remeasure `_bottomActionsHeight` after adding SafeArea, run verification checklist in skill. |

---

## Test cases

Full test suite (manual + unit + integration), 28-feature traceability matrix: **[03-authentication-test-cases.md](./03-authentication-test-cases.md)**.

Run auth unit tests:

```powershell
flutter test test/auth/
```

---

## Website — comparison

| Aspect | Website | Mobile |
|--------|---------|--------|
| Login | `loginWithEmail` actions | PocketBase password auth + preload |
| Post-login | `preload()` | `preload()` after login / OTP / sign-up |
| Register | `signUpWithEmail` | PB create + auto-login + `requestVerification` + preload |
| OTP login | `RequestOTP` + `LoginByOTP` | `requestOTP` + `authWithOTP` + preload |
| Email verify | `requestVerification` / `confirmVerification` | Resend from app; confirm via deep link `/confirm-verification?token=` |
| Reset password | `ResetPassword` / `ConfirmPasswordReset` | `requestPasswordReset` / `confirmPasswordReset` + deep link |

---

## Links

- [01-app-bootstrap](../01-app-bootstrap-global-state.md)
- [18-backend-integration](../18-backend-integration.md)
- [Skill: flutter-form-fixed-bottom-actions](../../skills/flutter-form-fixed-bottom-actions/SKILL.md) — UI/keyboard pattern for all auth screens with form + bottom actions.
