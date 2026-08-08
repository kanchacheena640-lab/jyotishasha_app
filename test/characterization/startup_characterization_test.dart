import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('application startup characterization', () {
    // TODO(ESR-001): Execute main() end-to-end when Firebase, messaging,
    // Crashlytics, and billing can be controlled without changing production.
    test('preserves the current pre-runApp initialization order', () {
      final source = readProjectSource('lib/main.dart');

      expect(source, contains('Future<void> main() async'));
      expectMarkersInOrder(source, const [
        'WidgetsFlutterBinding.ensureInitialized();',
        'HttpOverrides.global =',
        'await Firebase.initializeApp(',
        'FirebaseMessaging.onMessage.listen(',
        'FlutterError.onError =',
        'await PlayBillingStub.init();',
        'runApp(',
      ]);
    });

    test(
      'preserves root MultiProvider composition and eager AskNow startup',
      () {
        final source = readProjectSource('lib/main.dart');

        expect(source, contains('MultiProvider('));
        expect(source, contains('child: const JyotishashaApp()'));

        for (final provider in const [
          'LanguageProvider',
          'ProfileProvider',
          'FirebaseKundaliProvider',
          'KundaliProvider',
          'ManualKundaliProvider',
          'DailyProvider',
          'MonthlyProvider',
          'YearlyProvider',
          'PanchangProvider',
          'TransitProvider',
          'LoveProvider',
          'NotificationProvider',
          'CardsProvider',
          'AskNowProvider',
        ]) {
          expect(source, contains(provider));
        }

        final normalized = normalizeWhitespace(source);
        expect(
          normalized,
          contains(
            'ChangeNotifierProvider( lazy: false, create: (_) { '
            'final p = AskNowProvider(); p.initBilling();',
          ),
        );
      },
    );
  });
}
