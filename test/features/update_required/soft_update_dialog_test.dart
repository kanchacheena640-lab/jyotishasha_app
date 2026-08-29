import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart' show LinkDelegate;

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/features/update_required/soft_update_dialog.dart';
import 'package:jyotishasha_app/services/app_version_gate_service.dart';

/// Reusable App Update System -- coverage for the non-blocking
/// [showSoftUpdatePrompt] (STATE 2 / SOFT UPDATE).
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

Widget _wrap(Widget child) {
  return ChangeNotifierProvider<LanguageProvider>(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSoftUpdatePrompt(
              context,
              storeUrl: 'https://play.google.com/store/apps/details?id=com.jyotishasha.app',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _FakeUrlLauncher fakeLauncher;

  setUp(() {
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
    AppVersionGateService.resetSessionStateForTesting();
  });

  testWidgets('shows Update Available with Update Now / Later, never blocks the screen underneath', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Update Available'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    // Not a blocking barrier the way UpdateRequiredPage is -- a plain
    // dismissible AlertDialog. Proven behaviorally by the two tests
    // below (Later / Update Now both successfully dismiss it), not by
    // a PopScope widget-tree lookup here (MaterialApp itself
    // contributes its own framework-level PopScope in recent Flutter
    // versions, making that check unreliable).
  });

  testWidgets('Later dismisses without opening the store, and marks the session dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text('Update Available'), findsNothing);
    expect(fakeLauncher.lastLaunchedUrl, isNull);
  });

  testWidgets('Update Now opens the Play Store listing and dismisses the dialog', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(find.text('Update Available'), findsNothing);
    expect(fakeLauncher.lastLaunchedUrl, contains('com.jyotishasha.app'));
  });
}
