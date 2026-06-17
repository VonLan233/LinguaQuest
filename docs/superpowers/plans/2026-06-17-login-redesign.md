# Login/Register/Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Reskin login, register, and onboarding to a clean centered-minimal ("百词斩-style") layout on warm porcelain, removing the gradient-hero + boxed-form clutter, and add a one-tap demo/guest entry.

**Architecture:** Pure visual reskin of three entry screens using existing Cozy Quest primitives (`MascotImage`, `AppPrimaryButton`, `AppSecondaryButton`, soft `TextFormField`s) — every route, validator, controller, and visible string preserved so the `test/widget_test.dart` auth/onboarding finders (which assert by text + navigation) stay green. One new notifier method `enterDemo()` powers the quick-enter button.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_test. Light mode only.

**Locked decisions:** centered-minimal layout; add 一键体验/游客 quick-enter; scope = login + register + onboarding. Quick-enter label REUSES existing `goalSetupEnterApp` ("进入 LinguaQuest") — translation freeze, no new ARB keys.

---

## Task 1: `enterDemo()` notifier method

**Files:**
- Modify: `lib/core/state/app_controller.dart`
- Test: `test/` (find the app_controller / auth test file, or add a focused one)

The method mirrors the `login()` tail but uses `UserProfile.demo()` directly (no auth repo call), so it works in both mock and API modes.

- [ ] **Step 1: Write a failing test** — pump/construct the controller (follow existing controller-test patterns; mock repos via demo mode), call `enterDemo()`, assert `state.user != null` and `state.user!.uid == 'demo-user'` and `state.isAuthenticated == true`. Run, confirm fails (method undefined).
- [ ] **Step 2: Implement** in `app_controller.dart` (next to `login`):

```dart
Future<bool> enterDemo() async {
  return _run(() async {
    final user = UserProfile.demo();
    final lotteryData = await _loadLotteryData(user);
    state = state.copyWith(
      user: user,
      customWords: await _customWordRepository.list(user.uid),
      lotteryPrizes: lotteryData.prizes,
      userAssets: lotteryData.assets,
      userWords: await _userWordRepository.list(user.uid),
    );
    await _ensureStudyPlan(user);
    await refreshNotifications();
    await refreshRewardTasks();
    unawaited(_scheduleLocalNotifications());
  });
}
```

- [ ] **Step 3:** Run test → pass. `flutter analyze` clean. Full suite green.
- [ ] **Step 4: Commit** — `git add lib/core/state/app_controller.dart test/<file>` → `feat(auth): add enterDemo quick-entry notifier method`. No Co-Authored-By.

---

## Task 2: Login screen — centered minimal + quick-enter

**Files:**
- Modify: `lib/features/auth/login_screen.dart`
- Modify: `test/widget_test.dart` (only if a finder breaks)

Layout (warm porcelain `Scaffold`, NO AppBar, scrollable, centered column with generous spacing):
- `MascotImage(size: ~96)` centered
- "LinguaQuest" wordmark (`Text`, headline, bold) centered
- quiet subtitle: `l10n.authWelcomeBackSubtitle` (secondary text), centered
- email `TextFormField` (`l10n.authEmail`/`authEmailHint`, mail icon, same `_emailValidator`)
- password `TextFormField` (`l10n.authPassword`/`authPasswordHint`, lock icon, obscure, same `_passwordValidator`)
- inline `state.errorMessage` (error color) when present
- `AppPrimaryButton(label: l10n.commonLogin, icon: Icons.login, onPressed: state.isLoading ? null : _submit)` with the existing loading spinner treatment
- `AppSecondaryButton(label: l10n.goalSetupEnterApp, icon: Icons.bolt, onPressed: state.isLoading ? null : _enterDemo)` — the quick-enter
- `TextButton(onPressed: () => context.go('/register'), child: Text(l10n.authRegisterNew))`

Keep `Form`/`_formKey`, controllers, `_submit` (→ `/home`), validators EXACTLY. Add:
```dart
Future<void> _enterDemo() async {
  final ok = await ref.read(appControllerProvider.notifier).enterDemo();
  if (!mounted || !ok) return;
  context.go('/home');
}
```
Remove the `BrandHeroCard` import/usage and the form-wrapping `AppCard` (fields sit directly on porcelain, optionally a single light card — designer's call, keep it clean). Drop unused imports.

- [ ] **Step 1:** Check the widget_test finders for login: there is a test using `find.widgetWithText(AppPrimaryButton, '登录')` (login screen) and the onboarding `find.widgetWithText(AppSecondaryButton, '登录')`. The login CTA stays `AppPrimaryButton` + `commonLogin` ('登录'), so that finder survives. Run the auth/login-related tests first to capture the baseline (green now).
- [ ] **Step 2:** Implement the reskin.
- [ ] **Step 3:** Run `flutter test test/widget_test.dart`; fix any finder that broke by syncing it (preserve text/nav). `flutter analyze` clean. Full suite green.
- [ ] **Step 4: Commit** — `feat(auth): reskin login to centered-minimal with quick-enter`. No Co-Authored-By.

---

## Task 3: Register screen — matching centered minimal

**Files:**
- Modify: `lib/features/auth/register_screen.dart`
- Modify: `test/widget_test.dart` (only if a finder breaks)

Mirror Task 2's layout: centered `MascotImage` + "创建学习档案" (`l10n.authCreateProfile`) + subtitle (`authCreateProfileSubtitle`) + the existing step pill (`authStep1of2`) if present + nickname/email/password fields (same validators) + `AppPrimaryButton(l10n.authContinueToGoal)` → `register()` → `/goal-setup` + `TextButton`(`authHaveAccount` → `/login`). Preserve the post-register SnackBar (`authAccountCreated`) and all controllers/validators/nav. Remove gradient hero/clutter, drop unused imports.

- [ ] **Step 1:** Capture baseline of any register test finders (e.g. `authContinueToGoal`, `authHaveAccount`). 
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Tests green (sync finders if needed). analyze clean. Full suite green.
- [ ] **Step 4: Commit** — `feat(auth): reskin register to match centered-minimal login`. No Co-Authored-By.

---

## Task 4: Onboarding screen — de-cluttered centered

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Modify: `test/widget_test.dart` (only if a finder breaks)

Calmer version: centered `MascotImage` + "LinguaQuest" wordmark + `l10n.onboardingTagline` + the 3 feature rows kept inside ONE light `AppCard` (lighter dividers, more whitespace) + `AppPrimaryButton(l10n.onboardingRegisterButton, → /register)` + `AppSecondaryButton(l10n.commonLogin, → /login)`. Keep the existing feature `_OnboardingStepData`/rows and all l10n keys + nav. The existing test `find.widgetWithText(AppSecondaryButton, '登录')` (onboarding) must stay valid — keep the login button as `AppSecondaryButton` + `commonLogin`. Trim the busy pill row / `SectionHeader` if it reads cluttered, but preserve any string a test asserts (check first).

- [ ] **Step 1:** Capture baseline of onboarding test finders (`onboardingRegisterButton`, `commonLogin` on `AppSecondaryButton`, any tagline/subtitle assertion).
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Tests green. analyze clean. Full suite green.
- [ ] **Step 4: Commit** — `feat(onboarding): de-clutter entry screen to centered-minimal`. No Co-Authored-By.

---

## Task 5: Final review + smoke

- [ ] `flutter analyze` clean; `flutter test` full suite green (report count); `flutter build apk --release` builds.
- [ ] Final code reviewer over the whole diff: spec compliance (centered-minimal, quick-enter works, no new ARB keys, all nav/validators preserved) + quality (no dead imports, consistent across 3 screens, mounted guards on async nav).
- [ ] On-device eyeball is the user's pass (visual feel of the new entry flow).

## Self-review notes
- `enterDemo()` reuses `UserProfile.demo()` + the exact `login()` state tail → consistent auth state; `isAuthenticated` then routes to /home.
- Quick-enter label reuses `goalSetupEnterApp` — zero new translation keys (freeze respected).
- All three screens keep every visible string + route; the integration suite asserts by text+nav, so it remains the safety net. Sync any type-coupled finder in the same commit.
