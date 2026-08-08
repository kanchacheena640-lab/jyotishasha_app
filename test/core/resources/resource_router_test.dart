import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/resources/resource_router.dart';
import 'package:jyotishasha_app/features/events/authority_resource_screen.dart';

import '../../helpers/test_harness.dart';

void main() {
  Future<void> pumpRouterButton(
    WidgetTester tester,
    ResourceDto resource,
  ) async {
    await tester.pumpTestHarness(
      Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => ResourceRouter.open(context, resource),
            child: const Text('Know More'),
          ),
        ),
      ),
    );
  }

  group('ResourceRouter.open', () {
    testWidgets('authority resource opens AuthorityResourceScreen', (
      tester,
    ) async {
      // No `url`: AuthorityResourceScreen now opens a real WebView for a
      // non-null resource.url, and its WebViewController requires a
      // platform implementation flutter test's headless environment
      // doesn't provide (see in_app_webview_test.dart). This test's job is
      // only to verify ResourceRouter dispatches 'authority' to the right
      // widget type — resource.url handling itself is covered separately
      // by authority_resource_screen_test.dart.
      await pumpRouterButton(
        tester,
        const ResourceDto(type: 'authority', id: 'ekadashi/yogini'),
      );

      await tester.tap(find.text('Know More'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthorityResourceScreen), findsOneWidget);
      expect(find.text('Content not available'), findsOneWidget);
    });

    for (final unimplementedType in [
      'video',
      'pdf',
      'tool',
      'community',
      'calculator',
      'ai_insight',
      'something_unknown_from_the_future',
    ]) {
      testWidgets(
        'type "$unimplementedType" shows Not implemented instead of crashing',
        (tester) async {
          await pumpRouterButton(
            tester,
            ResourceDto(type: unimplementedType, id: 'x'),
          );

          await tester.tap(find.text('Know More'));
          await tester.pump();

          expect(find.byType(AuthorityResourceScreen), findsNothing);
          expect(find.text('Not implemented'), findsOneWidget);
        },
      );
    }

    testWidgets('null type shows Not implemented instead of crashing', (
      tester,
    ) async {
      await pumpRouterButton(tester, const ResourceDto());

      await tester.tap(find.text('Know More'));
      await tester.pump();

      expect(find.byType(AuthorityResourceScreen), findsNothing);
      expect(find.text('Not implemented'), findsOneWidget);
    });
  });
}
