import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/widgets/in_app_webview.dart';

import '../../helpers/test_harness.dart';

void main() {
  group('InAppWebView', () {
    // NOTE: webview_flutter's WebViewController requires a real platform
    // implementation (WebViewPlatform.instance) that flutter test's headless
    // environment does not provide — attempting to construct one here throws
    // "A platform implementation for `webview_flutter` has not been set."
    // This is a limitation of the plugin in this test environment, not of
    // this widget; it applies equally to the pre-existing BlogReaderPage,
    // which has no test coverage for the same reason. What IS safely
    // testable without a platform implementation is the URL-validation
    // guard below, since an invalid URL never reaches WebViewController
    // construction at all.

    testWidgets(
      'invalid URL shows the graceful error state without ever constructing a controller',
      (tester) async {
        await tester.pumpTestHarness(
          const InAppWebView(url: 'not a valid url'),
        );
        await tester.pump();

        expect(
          find.text(
            'Unable to load this page. Please check your connection '
            'and try again later.',
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'a non-http(s) scheme is treated as invalid and fails gracefully',
      (tester) async {
        await tester.pumpTestHarness(
          const InAppWebView(url: 'javascript:alert(1)'),
        );
        await tester.pump();

        expect(
          find.text(
            'Unable to load this page. Please check your connection '
            'and try again later.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('empty URL fails gracefully instead of crashing', (
      tester,
    ) async {
      await tester.pumpTestHarness(const InAppWebView(url: ''));
      await tester.pump();

      expect(
        find.text(
          'Unable to load this page. Please check your connection '
          'and try again later.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('title is shown in the AppBar', (tester) async {
      await tester.pumpTestHarness(
        const InAppWebView(url: 'not a valid url', title: 'Authority'),
      );
      await tester.pump();

      expect(find.text('Authority'), findsOneWidget);
    });
  });
}
