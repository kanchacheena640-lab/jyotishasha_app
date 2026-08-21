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
}
