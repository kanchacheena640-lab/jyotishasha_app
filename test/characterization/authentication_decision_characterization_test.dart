import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('router authentication decision characterization', () {
    // TODO(ESR-001): Exercise the GoRouter redirect callback directly when the
    // static FirebaseAuth session and analytics observer can be controlled.
    test('reads the Firebase user snapshot for every redirect evaluation', () {
      final source = readProjectSource('lib/app/routes/app_routes.dart');

      expect(
        source,
        contains('final user = FirebaseAuth.instance.currentUser;'),
      );
      expect(source, contains("state.matchedLocation == '/login'"));
      expect(source, contains("state.matchedLocation == '/splash'"));
    });

    test('sends unauthenticated non-entry navigation to login', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/app/routes/app_routes.dart'),
      );

      expect(
        source,
        contains(
          "if (user == null && !goingToLogin && !goingToSplash) { "
          "return '/login'; }",
        ),
      );
    });

    test('allows unauthenticated login and splash navigation to continue', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/app/routes/app_routes.dart'),
      );

      expect(source, contains('!goingToLogin && !goingToSplash'));
      expect(source, contains('return null;'));
    });

    test('sends an authenticated login request to dashboard', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/app/routes/app_routes.dart'),
      );

      expect(
        source,
        contains("if (user != null && goingToLogin) { return '/dashboard'; }"),
      );
    });
  });
}
