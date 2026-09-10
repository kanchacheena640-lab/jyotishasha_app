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

    // P3E -- redirect/navigation defense-in-depth. isNavigationAllowed's
    // rejection of the INITIAL url is safely testable headless (it short-
    // circuits before ever constructing WebViewController, same as the
    // URL-validity tests above); its effect on a SUBSEQUENT navigation
    // request (an actual in-page redirect) is NOT safely testable here for
    // the exact same pre-existing platform-implementation reason this
    // file's own top note documents -- that requires a real
    // NavigationDelegate callback from a constructed WebViewController.
    group('isNavigationAllowed (P3E defense-in-depth)', () {
      testWidgets(
        'default (null) never rejects the initial url -- unchanged '
        'behavior for every existing call site',
        (tester) async {
          // A url this predicate would reject if it were even consulted,
          // proving the default path never calls it at all -- but since a
          // VALID https url would otherwise proceed to construct the
          // (headless-unsupported) WebViewController, this uses an
          // already-invalid url so the test stays inside the same safe
          // "fails before controller construction" zone as every test
          // above; what's being proven is that omitting the parameter
          // compiles and behaves exactly like before (no crash, same
          // error state), not a change in the invalid-url path itself.
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
        },
      );

      testWidgets(
        'a caller-supplied isNavigationAllowed rejecting the initial url '
        'fails closed to the existing error state -- never crashes, never '
        'constructs a WebViewController for a rejected url',
        (tester) async {
          var predicateCalls = 0;
          await tester.pumpTestHarness(
            InAppWebView(
              url: 'https://eviljyotishasha.com/phish',
              isNavigationAllowed: (uri) {
                predicateCalls++;
                return false;
              },
            ),
          );
          await tester.pump();

          expect(predicateCalls, 1);
          expect(
            find.text(
              'Unable to load this page. Please check your connection '
              'and try again later.',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'isNavigationAllowed is never consulted for an already-invalid '
        'url -- the existing scheme check still runs first',
        (tester) async {
          var predicateCalls = 0;
          await tester.pumpTestHarness(
            InAppWebView(
              url: 'javascript:alert(1)',
              isNavigationAllowed: (uri) {
                predicateCalls++;
                return true;
              },
            ),
          );
          await tester.pump();

          expect(predicateCalls, 0);
          expect(
            find.text(
              'Unable to load this page. Please check your connection '
              'and try again later.',
            ),
            findsOneWidget,
          );
        },
      );
    });
  });
}
