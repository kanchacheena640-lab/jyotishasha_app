import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('LoginPage characterization', () {
    // P0 -- Recover authenticated users with incomplete birth profiles:
    // LoginPage used to decide Dashboard vs. birth-detail setup purely
    // from Firestore `profiles/default` doc existence -- an independent
    // source of truth from SplashPage's (then-nonexistent) check, which
    // let a user whose backend AppUser profile was incomplete reach
    // Dashboard on a fresh Google sign-in. It now uses the SAME backend
    // completeness source of truth SplashPage uses.
    //
    // TODO(ESR-001): Drive this as widget behavior once AuthService and
    // ProfileCompletenessService can be supplied deterministically to
    // LoginPage (see the matching TODO on SplashPage's own
    // characterization test).
    test(
      'resolves backend profile completeness after Google sign-in, '
      'not Firestore doc existence',
      () {
        final source = readProjectSource(
          'lib/features/login/login_page.dart',
        );

        expect(
          source,
          isNot(contains("collection('profiles')")),
          reason:
              'must no longer decide navigation from the Firestore '
              'profiles/default doc',
        );
        expect(
          source,
          contains(
            "import '../../services/profile_completeness_service.dart';",
          ),
        );

        expectMarkersInOrder(source, const [
          'final user = await auth.signInWithGoogle();',
          'if (!mounted || user == null) return;',
          'final result = await ProfileCompletenessService.checkCompleteness();',
          'if (!mounted) return;',
          'if (result.checkFailed) {',
          'if (result.isComplete) {',
          "context.go('/dashboard');",
          "context.go('/birth');",
        ]);
      },
    );

    test(
      'shows an inline error and does not navigate when the '
      'completeness check fails',
      () {
        final source = normalizeWhitespace(
          readProjectSource('lib/features/login/login_page.dart'),
        );

        expect(source, contains('if (result.checkFailed) {'));
        expect(source, contains('ScaffoldMessenger.of(context).showSnackBar('));
        // The checkFailed branch must return before either context.go()
        // call -- i.e. it must not navigate anywhere.
        final checkFailedIndex = source.indexOf('if (result.checkFailed) {');
        final returnIndex = source.indexOf('return;', checkFailedIndex);
        final dashboardIndex = source.indexOf(
          "context.go('/dashboard');",
          checkFailedIndex,
        );
        expect(returnIndex, greaterThan(checkFailedIndex));
        expect(
          returnIndex,
          lessThan(dashboardIndex),
          reason:
              'the checkFailed branch must return before the dashboard '
              'navigation that follows it',
        );
      },
    );
  });

  // =====================================================================
  // Phase 5D.3 -- login_completed producer. Same structural-
  // characterization technique as the group above, for the same reason
  // (AuthService/ProfileCompletenessService can't yet be supplied
  // deterministically to LoginPage -- see the TODO above). Facade-level
  // behavior (exact event shape, no-guard double-call, failure isolation)
  // is proven separately in test/core/analytics/activity_events_test.dart
  // and test/services/activity_event_client_test.dart, which this file's
  // own seam-placement proof relies on being correct.
  group('login_completed producer (Phase 5D.3)', () {
    test(
      'B/C/D/F/G/L/M: the login_completed call sits after the null-user '
      'guard, BEFORE both SessionStartProducer and the completeness/'
      'navigation flow -- so it depends on neither, and remains a '
      'separate call from session_start',
      () {
        final source = readProjectSource(
          'lib/features/login/login_page.dart',
        );

        expectMarkersInOrder(source, const [
          'final user = await auth.signInWithGoogle();',
          'if (!mounted || user == null) return;',
          "ActivityEvents.loginCompleted(method: 'google');",
          "SessionStartProducer.attemptOnce(entryPoint: 'login');",
          'final result = await ProfileCompletenessService.checkCompleteness();',
          "context.go('/dashboard');",
          "context.go('/birth');",
        ]);
      },
    );

    test(
      'D: the call is NOT awaited -- fire-and-forget, matching every '
      'other Phase 5B/5C producer call site in this same function',
      () {
        final source = readProjectSource(
          'lib/features/login/login_page.dart',
        );
        expect(
          source,
          isNot(contains("await ActivityEvents.loginCompleted(")),
        );
      },
    );

    test(
      'J/K: no once-per-process (or any other) guard wraps the '
      'login_completed call -- it is reached unconditionally once past '
      'the null-user early-return, unlike SessionStartProducer.attemptOnce '
      'which owns its own separate, unrelated guard',
      () {
        final source = readProjectSource(
          'lib/features/login/login_page.dart',
        );
        final callIndex = source.indexOf(
          "ActivityEvents.loginCompleted(method: 'google');",
        );
        expect(callIndex, greaterThanOrEqualTo(0));

        // Nothing between the null-user guard and the call introduces a
        // second conditional/guard around it.
        final guardIndex = source.indexOf(
          'if (!mounted || user == null) return;',
        );
        final between = source.substring(
          guardIndex + 'if (!mounted || user == null) return;'.length,
          callIndex,
        );
        expect(
          between,
          isNot(contains('if (')),
          reason:
              'no conditional may sit between the null-user guard and the '
              'login_completed call -- it must be unconditional',
        );

        // No login-specific attempted-flag/persistence mechanism exists
        // anywhere in this file.
        expect(source, isNot(contains('SharedPreferences')));
        expect(source, isNot(contains('_loginCompletedAttempted')));
        expect(source, isNot(contains('_attempted')));
      },
    );

    test(
      'N: no signup_completed reference exists anywhere in this file -- '
      'Flutter never emits it (backend-owned, Phase 5D.1)',
      () {
        final source = readProjectSource(
          'lib/features/login/login_page.dart',
        );
        expect(source, isNot(contains('signup_completed')));
        expect(source, isNot(contains('signupCompleted')));
      },
    );

    test(
      '10: Facebook login is not instrumented -- no reachable UI call '
      'site exists for it in this file (Phase 5D audit: dead code, not '
      'revived here)',
      () {
        final source = readProjectSource(
          'lib/features/login/login_page.dart',
        );
        expect(source, isNot(contains('signInWithFacebook')));
        expect(source, isNot(contains("method: 'facebook'")));
      },
    );

    test(
      'E: SplashPage never references login_completed -- cold-start '
      'restored-session recognition must never emit it',
      () {
        final source = readProjectSource(
          'lib/features/splash/splash_page.dart',
        );
        expect(source, isNot(contains('login_completed')));
        expect(source, isNot(contains('loginCompleted')));
        expect(source, isNot(contains('ActivityEvents.login')));
      },
    );

    test(
      "4: BackendAuthService's /api/auth/token exchange never emits "
      'login_completed -- it is a routine JWT-acquisition helper, not '
      'the interactive-login seam',
      () {
        final source = readProjectSource(
          'lib/services/backend_auth_service.dart',
        );
        expect(source, isNot(contains('login_completed')));
        expect(source, isNot(contains('loginCompleted')));
      },
    );
  });
}
