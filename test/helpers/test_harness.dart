import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// Minimal application shell shared by widget tests.
///
/// Feature-specific providers, routes, and dependencies should be supplied by
/// the test that needs them; this harness intentionally contains no production
/// behavior.
///
/// [providers], if given, wrap *above* [MaterialApp] — matching how
/// `main.dart`'s `MultiProvider` wraps the real `MaterialApp.router` in
/// production. This matters for any test that pushes a second route (e.g.
/// via `Navigator.push`): a provider placed below `MaterialApp` is scoped to
/// one route's subtree and is invisible to routes pushed afterward, while a
/// provider above `MaterialApp` is visible to every route, exactly like
/// production.
///
/// Localization delegates are always registered (mirroring
/// `lib/app/app.dart`'s real `MaterialApp.router` setup) — any widget under
/// test that calls `AppLocalizations.of(context)!` needs this to be present
/// or that call throws, regardless of whether the test itself cares about
/// localized text.
class TestHarness extends StatelessWidget {
  const TestHarness({
    required this.child,
    this.locale,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.theme,
    this.providers = const <SingleChildWidget>[],
    super.key,
  });

  final Widget child;
  final Locale? locale;
  final List<NavigatorObserver> navigatorObservers;
  final ThemeData? theme;
  final List<SingleChildWidget> providers;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      locale: locale,
      navigatorObservers: navigatorObservers,
      theme: theme,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
    return providers.isEmpty
        ? app
        : MultiProvider(providers: providers, child: app);
  }
}

extension TestHarnessPump on WidgetTester {
  Future<void> pumpTestHarness(
    Widget child, {
    Locale? locale,
    List<NavigatorObserver> navigatorObservers = const <NavigatorObserver>[],
    ThemeData? theme,
    List<SingleChildWidget> providers = const <SingleChildWidget>[],
  }) async {
    await pumpWidget(
      TestHarness(
        locale: locale,
        navigatorObservers: navigatorObservers,
        theme: theme,
        providers: providers,
        child: child,
      ),
    );
    await pump();
  }
}
