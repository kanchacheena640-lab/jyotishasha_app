import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
// LinkDelegate is a typedef defined in link.dart but not re-exported by
// the package's main barrel file above -- imported directly for that
// one type, needed only to satisfy UrlLauncherPlatform's abstract
// linkDelegate getter (this fake has no Link-widget support to test).
import 'package:url_launcher_platform_interface/link.dart' show LinkDelegate;

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/features/update_required/update_required_page.dart';

/// Ask Now Security + Force Update task, Part H -- coverage for
/// [UpdateRequiredPage]'s blocking contract: no route/back-gesture
/// bypass, "Update Now" opens the correct destination, no account/data
/// action lives on this screen.
class _FakeUrlLauncher extends UrlLauncherPlatform {
  String? lastLaunchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return true;
  }
}

Widget _wrap(Widget child, {bool isHindi = false}) {
  return ChangeNotifierProvider<LanguageProvider>(
    // Sets the field directly rather than calling the async
    // setLanguage() (which persists via SharedPreferences) -- this
    // widget only ever reads `isHindi`, so the synchronous, unmocked
    // path keeps this test free of platform-channel setup it doesn't
    // need.
    create: (_) => LanguageProvider()..currentLang = isHindi ? 'hi' : 'en',
    child: MaterialApp(home: child),
  );
}

void main() {
  late _FakeUrlLauncher fakeLauncher;

  setUp(() {
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  testWidgets('shows the branded Update Required copy and an Update Now button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(
      const UpdateRequiredPage(
        storeUrl: 'https://play.google.com/store/apps/details?id=com.jyotishasha.app',
      ),
    ));

    expect(find.text('Jyotishasha'), findsOneWidget);
    expect(find.text('Update Required'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);
  });

  testWidgets('renders Hindi copy when the language provider is Hindi', (tester) async {
    await tester.pumpWidget(_wrap(
      const UpdateRequiredPage(storeUrl: 'https://example.com'),
      isHindi: true,
    ));

    expect(find.text('अपडेट आवश्यक है'), findsOneWidget);
    expect(find.text('अभी अपडेट करें'), findsOneWidget);
  });

  testWidgets('shows the operator-supplied message as an additional line, never a replacement', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(
      const UpdateRequiredPage(
        storeUrl: 'https://example.com',
        operatorMessage: 'Payment security update required.',
      ),
    ));

    // Both the static branded copy AND the operator message are present.
    expect(find.text('Update Required'), findsOneWidget);
    expect(find.text('Payment security update required.'), findsOneWidget);
  });

  testWidgets('Android back button cannot pop/bypass the blocking screen', (tester) async {
    await tester.pumpWidget(_wrap(
      const UpdateRequiredPage(storeUrl: 'https://example.com'),
    ));

    // Behavioral proof, not a structural widget-tree lookup: MaterialApp
    // itself contributes its own framework-level PopScope in recent
    // Flutter versions (predictive back support), so `find.byType(PopScope)`
    // is ambiguous here -- what actually matters is observable behavior.
    // Simulate the system/Android back gesture -- must be a no-op (the
    // widget tree still shows the same blocking page afterward).
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Update Required'), findsOneWidget);
  });

  testWidgets('Update Now opens the exact store_url the backend supplied', (tester) async {
    const targetUrl = 'https://play.google.com/store/apps/details?id=com.jyotishasha.app';
    await tester.pumpWidget(_wrap(
      const UpdateRequiredPage(storeUrl: targetUrl),
    ));

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.lastLaunchedUrl, targetUrl);
  });

  testWidgets('Update Now falls back to the app Play Store listing when storeUrl is null', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(
      const UpdateRequiredPage(storeUrl: null),
    ));

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.lastLaunchedUrl, contains('com.jyotishasha.app'));
  });

  testWidgets('no logout/account-deletion control exists on this screen', (tester) async {
    await tester.pumpWidget(_wrap(
      const UpdateRequiredPage(storeUrl: 'https://example.com'),
    ));

    expect(find.textContaining('Logout', findRichText: true), findsNothing);
    expect(find.textContaining('Log out', findRichText: true), findsNothing);
    expect(find.textContaining('Delete', findRichText: true), findsNothing);
    // Exactly one interactive control on the whole screen: Update Now.
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
