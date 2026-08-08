import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/features/splash/splash_page.dart';

import '../helpers/source_characterization.dart';
import '../helpers/test_harness.dart';

void main() {
  group('SplashPage characterization', () {
    testWidgets('renders the current non-dismissible splash presentation', (
      tester,
    ) async {
      await tester.pumpTestHarness(const SplashPage());

      expect(find.text('Jyotishasha'), findsOneWidget);
      expect(find.text('Your Personalized Path to the Stars'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);

      await tester.pump(const Duration(milliseconds: 1999));
      expect(find.byType(SplashPage), findsOneWidget);

      // Dispose before the static FirebaseAuth read. Advancing the final
      // millisecond lets the delayed callback observe mounted == false.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
    });

    // TODO(ESR-001): Drive both navigation branches as widget behavior when
    // FirebaseAuth.instance.currentUser can be supplied deterministically.
    test('waits two seconds then checks auth in a microtask', () {
      final source = readProjectSource('lib/features/splash/splash_page.dart');

      expectMarkersInOrder(source, const [
        'await Future.delayed(const Duration(seconds: 2));',
        'if (!mounted) return;',
        'final user = FirebaseAuth.instance.currentUser;',
        'Future.microtask(() {',
        'if (user == null)',
        "context.go('/login');",
        "context.go('/dashboard');",
      ]);
    });

    test('falls back to login when the auth lookup throws', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/features/splash/splash_page.dart'),
      );

      expect(source, contains("catch (e) { debugPrint('"));
      expect(source, contains("if (mounted) context.go('/login');"));
    });
  });
}
