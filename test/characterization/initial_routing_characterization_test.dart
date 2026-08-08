import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('initial routing characterization', () {
    // TODO(ESR-001): Navigate the real appRouter when its top-level Firebase
    // Analytics observer and FirebaseAuth dependency can be initialized in a
    // deterministic test environment.
    test('starts at splash and redirects the root path to splash', () {
      final source = readProjectSource('lib/app/routes/app_routes.dart');

      expect(source, contains("initialLocation: '/splash'"));
      expect(
        normalizeWhitespace(source),
        contains("GoRoute(path: '/', redirect: (_, __) => '/splash')"),
      );
    });

    test('preserves the registered top-level route set and order', () {
      final source = readProjectSource('lib/app/routes/app_routes.dart');
      final paths = RegExp(
        r"GoRoute\(\s*path:\s*'([^']+)'",
      ).allMatches(source).map((match) => match.group(1)).toList();

      expect(paths, const [
        '/',
        '/splash',
        '/onboarding',
        '/login',
        '/birth',
        '/dashboard',
        '/astrology',
        '/kundali/overview',
        '/reports',
        '/asknow',
        '/profile',
        '/subscription',
        '/darshan',
        '/astrology/detail',
        '/event',
      ]);
      expect(source, contains('Page Not Found'));
    });
  });
}
