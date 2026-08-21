import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('session restoration characterization', () {
    // TODO(ESR-001): Replace these source assertions with executable restored
    // Firebase session cases when the current static SDK boundary is testable.
    test('router and Splash independently read the restored user snapshot', () {
      final router = readProjectSource('lib/app/routes/app_routes.dart');
      final splash = readProjectSource('lib/features/splash/splash_page.dart');

      expect(
        'FirebaseAuth.instance.currentUser'.allMatches(router),
        hasLength(1),
      );
      expect(
        'FirebaseAuth.instance.currentUser'.allMatches(splash),
        hasLength(1),
      );
    });

    // P0 -- Recover authenticated users with incomplete birth profiles:
    // a restored Firebase session no longer goes straight to Dashboard.
    // It now resolves backend profile completeness first (the same
    // check LoginPage's fresh-sign-in path uses) and only proceeds to
    // Dashboard when that check reports the profile complete -- an
    // incomplete profile is sent to BirthDetailPage instead, and a
    // check failure shows an inline retry state (see
    // splash_characterization_test.dart for those branches).
    test(
      'restored Splash session resolves backend profile completeness '
      'before proceeding to dashboard',
      () {
        final splash = readProjectSource(
          'lib/features/splash/splash_page.dart',
        );

        expectMarkersInOrder(splash, const [
          'final user = FirebaseAuth.instance.currentUser;',
          'if (user == null) {',
          "context.go('/login');",
          'final result = await ProfileCompletenessService.checkCompleteness();',
          'if (result.isComplete) {',
          "context.go('/dashboard');",
        ]);
      },
    );

    test('startup routing does not subscribe to session changes', () {
      final startupSources = [
        readProjectSource('lib/main.dart'),
        readProjectSource('lib/app/routes/app_routes.dart'),
        readProjectSource('lib/features/splash/splash_page.dart'),
      ].join('\n');

      expect(startupSources, isNot(contains('authStateChanges(')));
      expect(startupSources, isNot(contains('idTokenChanges(')));
      expect(startupSources, isNot(contains('userChanges(')));
    });
  });
}
