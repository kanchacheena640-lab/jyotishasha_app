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

    // TODO(ESR-001): Drive all navigation/retry branches as widget behavior
    // when FirebaseAuth.instance.currentUser and
    // ProfileCompletenessService.checkCompleteness() can be supplied
    // deterministically.
    test(
      'waits two seconds, then for a logged-out user goes straight to '
      'login, and for an authenticated user resolves backend profile '
      'completeness before navigating',
      () {
        final source = readProjectSource('lib/features/splash/splash_page.dart');

        expectMarkersInOrder(source, const [
          'await Future.delayed(const Duration(seconds: 2));',
          'if (!mounted) return;',
          'final user = FirebaseAuth.instance.currentUser;',
          'if (user == null) {',
          'Future.microtask(() {',
          "context.go('/login');",
          // P0 -- Recover authenticated users with incomplete birth
          // profiles: an authenticated user no longer goes straight to
          // '/dashboard'. Backend profile completeness is resolved
          // first, via the SAME source of truth LoginPage now uses.
          'final result = await ProfileCompletenessService.checkCompleteness();',
          'if (result.checkFailed) {',
          'setState(() => _showRetry = true);',
          'if (result.isComplete) {',
          "context.go('/dashboard');",
          "context.go('/birth');",
        ]);
      },
    );

    test('falls back to login when the auth lookup throws', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/features/splash/splash_page.dart'),
      );

      expect(source, contains("catch (e) { debugPrint('"));
      expect(source, contains("if (mounted) context.go('/login');"));
    });

    // P0 -- Recover authenticated users with incomplete birth profiles:
    // a completeness-check failure (network/backend issue) must show an
    // explicit retry state, never silently resolve to either Dashboard
    // or BirthDetailPage.
    test(
      'shows an inline retry control instead of guessing when the '
      'completeness check fails',
      () {
        final source = readProjectSource('lib/features/splash/splash_page.dart');

        expect(
          source,
          contains('bool _showRetry = false;'),
          reason: 'retry state must default to the normal loading UI',
        );
        expectMarkersInOrder(source, const [
          'if (_showRetry) ...[',
          'ElevatedButton(',
          'onPressed: _checkAuthAndNavigate,',
          '"Retry"',
        ]);
      },
    );
  });
}
