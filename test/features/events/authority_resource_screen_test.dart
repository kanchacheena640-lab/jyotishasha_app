import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/widgets/in_app_webview.dart';
import 'package:jyotishasha_app/features/events/authority_resource_screen.dart';

import '../../helpers/test_harness.dart';

void main() {
  group('AuthorityResourceScreen', () {
    testWidgets(
      'shows the empty state instead of a WebView when resource.url is null',
      (tester) async {
        await tester.pumpTestHarness(
          const AuthorityResourceScreen(
            resource: ResourceDto(type: 'authority', id: 'ekadashi/yogini'),
          ),
        );

        expect(find.text('Content not available'), findsOneWidget);
        expect(find.text('This content is not available yet.'), findsOneWidget);
        expect(find.byType(InAppWebView), findsNothing);
      },
    );

    testWidgets(
      'renders Hindi text end to end when the app locale is Hindi — proves '
      'this is not hardcoded English',
      (tester) async {
        await tester.pumpTestHarness(
          const AuthorityResourceScreen(
            resource: ResourceDto(type: 'authority', id: 'ekadashi/yogini'),
          ),
          locale: const Locale('hi'),
        );

        expect(find.text('सामग्री उपलब्ध नहीं है'), findsOneWidget);
        expect(find.text('यह सामग्री अभी उपलब्ध नहीं है।'), findsOneWidget);
        expect(find.text('प्राधिकरण'), findsOneWidget);
        // The English strings must NOT also be present — this is a real
        // locale switch, not both languages rendering at once.
        expect(find.text('Content not available'), findsNothing);
        expect(find.text('Authority'), findsNothing);
      },
    );

    testWidgets(
      'opens the backend-provided URL directly in the generic WebView, unmodified',
      (tester) async {
        // A non-http(s) URL is used deliberately so InAppWebView takes its
        // own "invalid URL" path rather than constructing a real
        // WebViewController, which requires a platform implementation
        // flutter test's headless environment doesn't provide (see
        // in_app_webview_test.dart). This still fully verifies the
        // resource.url value is passed through to InAppWebView untouched —
        // no trimming, no rebuilding, no concatenation.
        const backendUrl = 'not-a-real-scheme://jyotishasha.com/en/ekadashi/yogini';

        await tester.pumpTestHarness(
          const AuthorityResourceScreen(
            resource: ResourceDto(
              type: 'authority',
              id: 'ekadashi/yogini',
              url: backendUrl,
            ),
          ),
        );
        await tester.pump();

        final webView = tester.widget<InAppWebView>(find.byType(InAppWebView));
        expect(webView.url, backendUrl);
        expect(find.text('Content not available'), findsNothing);

        // Reuses InAppWebView's own existing error handling — not
        // duplicated here.
        expect(
          find.text(
            'Unable to load this page. Please check your connection '
            'and try again later.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('back button is present so the user can return', (
      tester,
    ) async {
      await tester.pumpTestHarness(
        Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthorityResourceScreen(
                        resource: ResourceDto(type: 'authority'),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Content not available'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
      expect(find.text('Content not available'), findsNothing);
    });
  });
}
