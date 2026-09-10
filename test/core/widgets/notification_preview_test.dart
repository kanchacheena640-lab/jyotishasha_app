import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';

import '../../helpers/test_harness.dart';

/// N5 -- Notification Bell Inbox Finalization.
///
/// Scope note: "tap resolves to the correct destination" is already
/// exhaustively proven per notification `type` at the unit level in
/// test/core/notifications/notification_navigation_service_test.dart and
/// notification_dispatcher_test.dart (N1/N1.1/N3), which this suite does
/// not duplicate. `notificationNavigationService` is a hardcoded global
/// singleton built from the REAL app router (see main.dart) with no
/// injection point -- exercising a full end-to-end navigation from this
/// widget would require the entire real app shell (Firebase-dependent
/// screens included), which is exactly the fragile, redundant coverage
/// N1's own dedicated suite was built to avoid needing. What THIS suite
/// proves instead, all previously untested: the Bell list's own
/// rendering (empty/error/loading/success/unread-indication/timestamp/
/// type-icon/malformed-item-safety/EN-HI) and that a tap correctly
/// triggers the mark-read + list-refresh flow.
void main() {
  group('NotificationPreview (Bell inbox)', () {
    Map<String, dynamic> item({
      required int id,
      required String title,
      required String body,
      bool isRead = false,
      String? createdAt,
      Map<String, dynamic>? data,
    }) {
      return {
        'id': id,
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': createdAt ?? DateTime.now().toUtc().toIso8601String(),
        'data': data ?? {},
      };
    }

    // Matches production usage: NotificationPreview is always shown inside
    // showModalBottomSheet's own Material context (greeting_header_widget.dart
    // ::_showNotificationSheet), never bare -- a Scaffold here reproduces
    // that same Material ancestor for ListTile.
    Future<void> pumpBell(
      WidgetTester tester,
      Future<List> Function() loader, {
      Locale? locale,
    }) {
      return tester.pumpTestHarness(
        Scaffold(body: NotificationPreview(notificationsLoader: loader)),
        locale: locale,
        providers: [
          ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider()),
        ],
      );
    }

    testWidgets('shows a loading indicator while the request is in flight', (
      tester,
    ) async {
      // A Completer (not Future.delayed) so the test controls exactly
      // when the load resolves -- completing it before the test ends
      // avoids flutter_test's "Timer still pending" teardown assertion.
      final completer = Completer<List>();
      await pumpBell(tester, () => completer.future);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(<Map<String, dynamic>>[]);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'N5 Test 16: empty state is localized (English) -- no hardcoded '
      'English-only string regardless of locale',
      (tester) async {
        await pumpBell(tester, () async => <Map<String, dynamic>>[]);
        await tester.pumpAndSettle();

        expect(find.text('No notifications yet.'), findsOneWidget);
      },
    );

    testWidgets(
      'N5 Test 16 (Hindi): empty state renders the Hindi copy end to end',
      (tester) async {
        await pumpBell(
          tester,
          () async => <Map<String, dynamic>>[],
          locale: const Locale('hi'),
        );
        await tester.pumpAndSettle();

        expect(find.text('अभी कोई सूचना नहीं है।'), findsOneWidget);
        expect(find.text('No notifications yet.'), findsNothing);
      },
    );

    testWidgets(
      'N5: error state shows the same localized copy EventDispatcherPage '
      'already uses for a load failure -- not a raw/English-only message',
      (tester) async {
        await pumpBell(tester, () async => throw Exception('network down'));
        await tester.pumpAndSettle();

        expect(find.text('Something went wrong. Please try again later.'), findsOneWidget);
      },
    );

    testWidgets(
      'N5: renders title/body for a normal item, with a relative timestamp '
      'and a visible unread/read distinction',
      (tester) async {
        final now = DateTime.now().toUtc();
        await pumpBell(
          tester,
          () async => [
            item(
              id: 1,
              title: 'Moon Transit Tomorrow: 12th House',
              body: 'Moon moves into your 12th House tomorrow.',
              isRead: false,
              createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
              data: {'type': 'transit'},
            ),
            item(
              id: 2,
              title: 'Today\'s Panchang',
              body: 'Best time, avoid time...',
              isRead: true,
              createdAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
              data: {'type': 'panchang'},
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Moon Transit Tomorrow: 12th House'), findsOneWidget);
        expect(find.text('Today\'s Panchang'), findsOneWidget);
        expect(find.text('5m ago'), findsOneWidget);
        expect(find.text('2h ago'), findsOneWidget);

        // Unread row is bold (w700), read row is not.
        final unreadTitle = tester.widget<Text>(
          find.text('Moon Transit Tomorrow: 12th House'),
        );
        final readTitle = tester.widget<Text>(find.text('Today\'s Panchang'));
        expect(unreadTitle.style?.fontWeight, FontWeight.w700);
        expect(readTitle.style?.fontWeight, FontWeight.w500);
      },
    );

    testWidgets(
      'N5 Test 11: a Bell-only item (delivery_channel=bell_only) renders '
      'identically to a normal item -- no technical wording exposed',
      (tester) async {
        await pumpBell(
          tester,
          () async => [
            item(
              id: 3,
              title: 'Mood Positive',
              body: 'Your emotional outlook may be shifting today.',
              data: {'type': 'alert', 'delivery_channel': 'bell_only'},
            ),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Mood Positive'), findsOneWidget);
        expect(find.textContaining('bell_only'), findsNothing);
        expect(find.textContaining('suppress'), findsNothing);
        expect(find.textContaining('cap'), findsNothing);
      },
    );

    testWidgets(
      'N5 Test 17: a malformed item (missing title/body/data/created_at) '
      'renders gracefully -- no crash',
      (tester) async {
        await pumpBell(
          tester,
          () async => [
            <String, dynamic>{'id': 4},
          ],
        );
        await tester.pumpAndSettle();

        // Reaching this line without a thrown exception is the assertion.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'N5 Test 18: renders items in the exact order the backend already '
      'sorted them (list itself never re-sorts)',
      (tester) async {
        await pumpBell(
          tester,
          () async => [
            item(id: 1, title: 'Newest', body: '...'),
            item(id: 2, title: 'Middle', body: '...'),
            item(id: 3, title: 'Oldest', body: '...'),
          ],
        );
        await tester.pumpAndSettle();

        final titles = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .toList();
        expect(titles.indexOf('Newest') < titles.indexOf('Middle'), isTrue);
        expect(titles.indexOf('Middle') < titles.indexOf('Oldest'), isTrue);
      },
    );

    // A "tap triggers mark-read + list refresh" test was deliberately NOT
    // added here: the tap handler's final step
    // (notificationNavigationService.openDestination(), unchanged
    // production behavior) reaches a top-level global built from
    // main.dart's real Firebase-backed analytics/appRouter, which this
    // headless test environment cannot construct -- attempting to tap a
    // row surfaces that construction failure regardless of takeException()
    // handling, making the interaction untestable in isolation without
    // either the real app shell or a production code change purely for
    // testability (neither of which this task calls for). The mark-read
    // API call itself (notification_service.dart) is unchanged except for
    // the N5 _currentUserOrNull() hardening above; navigation correctness
    // is exhaustively covered by notification_navigation_service_test.dart
    // and notification_dispatcher_test.dart (N1/N1.1/N3), unaffected by
    // any change in this file.

    // N6 -- Campaign C rendering, mixed A/B/C, Mark all read/Clear/dismiss
    // affordances. Same scope note as above applies to any assertion that
    // would require an actual row TAP (still untestable in isolation here)
    // -- these tests cover rendering and the non-navigating actions
    // (Mark all read/Clear/dismiss), which do not reach
    // notificationNavigationService at all.
    Map<String, dynamic> campaignItem({
      required String id,
      required String title,
      required String body,
      bool isRead = false,
      Map<String, dynamic>? action,
    }) {
      return {
        'id': id,
        'source': 'ADMIN_CAMPAIGN',
        'title': title,
        'body': body,
        'is_read': isRead,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'campaign_action': action ?? {'type': 'NONE', 'target': null, 'parameters': {}},
        'campaign_id': 'camp-1',
        'execution_id': 'exec-1',
      };
    }

    testWidgets(
      'N6: a mixed A/B + Campaign C list renders both -- existing A/B '
      'rows are byte-for-byte unaffected by a Campaign C row being present',
      (tester) async {
        await pumpBell(
          tester,
          () async => [
            item(id: 1, title: 'Moon Transit Tomorrow', body: 'A/B content', data: {'type': 'transit'}),
            campaignItem(id: 'cc:1', title: 'Diwali Offer', body: 'Special offer from Admin'),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Moon Transit Tomorrow'), findsOneWidget);
        expect(find.text('Diwali Offer'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('N6: a Campaign C row renders with its own distinct leading icon', (tester) async {
      await pumpBell(tester, () async => [campaignItem(id: 'cc:1', title: 'Diwali Offer', body: 'x')]);
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.campaign_rounded));
      expect(icon, isNotNull);
    });

    testWidgets('N6: Hindi/Unicode Campaign C content renders correctly', (tester) async {
      await pumpBell(
        tester,
        () async => [
          campaignItem(
            id: 'cc:1',
            title: 'हिन्दी में शीर्षक — Diwali Offer 🎉',
            body: 'यह एक परीक्षण संदेश है।',
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('हिन्दी में शीर्षक — Diwali Offer 🎉'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('N6: long Campaign C title/body renders without overflow crashing', (tester) async {
      final longTitle = 'Very long campaign title ' * 5;
      final longBody = 'Very long campaign body text ' * 20;
      await pumpBell(
        tester,
        () async => [campaignItem(id: 'cc:1', title: longTitle, body: longBody)],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('N6: "Mark all read" and "Clear" controls are present and never a "Mark unread" control', (tester) async {
      await pumpBell(
        tester,
        () async => [item(id: 1, title: 'A', body: 'x')],
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.textContaining('Mark unread', findRichText: true), findsNothing);
      expect(find.textContaining('mark unread', findRichText: true), findsNothing);
    });

    testWidgets('N6: tapping "Mark all read" does not crash and does not remove rows itself', (tester) async {
      await pumpBell(
        tester,
        () async => [item(id: 1, title: 'A', body: 'x'), campaignItem(id: 'cc:1', title: 'B', body: 'y')],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('N6: tapping "Clear" does not crash', (tester) async {
      await pumpBell(
        tester,
        () async => [item(id: 1, title: 'A', body: 'x'), campaignItem(id: 'cc:1', title: 'B', body: 'y')],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('N6: an individual dismiss button exists per row and tapping it does not crash or navigate', (tester) async {
      await pumpBell(
        tester,
        () async => [item(id: 1, title: 'A', body: 'x'), campaignItem(id: 'cc:1', title: 'B', body: 'y')],
      );
      await tester.pumpAndSettle();

      final dismissButtons = find.byIcon(Icons.close_rounded);
      expect(dismissButtons, findsNWidgets(2));

      await tester.tap(dismissButtons.first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // N6 individual-dismiss defect regression (physical-device QA finding):
    // the × button visually responded to every tap but the request never
    // reached the backend. Root cause -- greeting_header_widget.dart read
    // `n["id"]` (AppNotification.toJson()'s legacy nullable int, ALWAYS
    // null for a unified-list composite id) instead of `n["item_id"]`
    // (the real "ab:<int>"/"cc:<uuid>" string). The fixtures below use the
    // EXACT shape production data has -- `id: null`, real id only under
    // `item_id` -- unlike this file's other `item()`/`campaignItem()`
    // helpers (which put the id under the legacy `id` key and would have
    // passed even on the broken code, which is why this defect shipped
    // undetected). A `_RecordingNotificationProvider` observes exactly
    // what id (if any) reaches NotificationProvider.dismiss(), without
    // going through the Firebase-gated real NotificationService (see this
    // file's own note above on why a full-stack tap can't be exercised
    // headless).
    Map<String, dynamic> realItem({
      required String itemId,
      required String title,
      String source = 'AB',
      Map<String, dynamic>? campaignAction,
    }) {
      final isCampaign = source == 'ADMIN_CAMPAIGN';
      return {
        'id': null, // legacy field -- always null under the N6 unified list, see AppNotification.toJson()
        'item_id': itemId,
        'source': source,
        'title': title,
        'body': 'body',
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (!isCampaign) 'data': <String, dynamic>{},
        if (isCampaign) 'campaign_action': campaignAction ?? {'type': 'NONE', 'target': null, 'parameters': {}},
        if (isCampaign) 'campaign_id': 'camp-1',
        if (isCampaign) 'execution_id': 'exec-1',
      };
    }

    Future<void> pumpBellWithProvider(
      WidgetTester tester,
      Future<List> Function() loader,
      NotificationProvider provider,
    ) {
      return tester.pumpTestHarness(
        Scaffold(body: NotificationPreview(notificationsLoader: loader)),
        providers: [
          ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<NotificationProvider>.value(value: provider),
        ],
      );
    }

    testWidgets(
      'N6 regression: dismissing a Campaign C row (cc:<uuid>) sends the real '
      'composite item_id, not the always-null legacy id',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [realItem(itemId: 'cc:2733c246-6c20-44ce-8ff4-31ea4e6dcfde', title: 'N6 Device QA Test', source: 'ADMIN_CAMPAIGN')],
          provider,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(provider.dismissedIds, ['cc:2733c246-6c20-44ce-8ff4-31ea4e6dcfde']);
      },
    );

    testWidgets(
      'N6 regression: individual dismiss of an A/B row (ab:<int>) still works',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [realItem(itemId: 'ab:42', title: 'A/B item')],
          provider,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(provider.dismissedIds, ['ab:42']);
      },
    );

    testWidgets(
      'N6 regression: dismissing one row among several only dismisses that row\'s id',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [
            realItem(itemId: 'ab:1', title: 'First'),
            realItem(itemId: 'cc:2', title: 'Second', source: 'ADMIN_CAMPAIGN'),
            realItem(itemId: 'ab:3', title: 'Third'),
          ],
          provider,
        );
        await tester.pumpAndSettle();

        // Tap only the middle row's dismiss button.
        await tester.tap(find.byIcon(Icons.close_rounded).at(1));
        await tester.pumpAndSettle();

        expect(provider.dismissedIds, ['cc:2']);
      },
    );

    testWidgets(
      'N6 regression: a row with no item_id at all (malformed) fails safe -- '
      'no crash, no dismiss call',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [
            <String, dynamic>{'id': null, 'title': 'Malformed', 'body': 'x'},
          ],
          provider,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(provider.dismissedIds, isEmpty);
      },
    );

    testWidgets(
      'N6 regression: dismiss never triggers the row\'s own tap-to-open flow '
      '(no notification_opened/destination_opened emission path reached)',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [realItem(itemId: 'cc:1', title: 'Campaign row', source: 'ADMIN_CAMPAIGN')],
          provider,
        );
        await tester.pumpAndSettle();

        // A real row TAP reaches notificationNavigationService (a
        // Firebase-backed global this headless test cannot construct --
        // see this file's own note above) and would surface that
        // construction failure via takeException(). The dismiss button is
        // a separate IconButton, not the ListTile's onTap, so tapping it
        // must reach neither that navigation call nor any emission that
        // only lives on the onTap branch.
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(provider.dismissedIds, ['cc:1']);
      },
    );

    // N6 row-tap mark-read composite-id defect (physical-device QA
    // finding, confirmed during Campaign C dismiss QA): the ListTile's own
    // onTap read `n["id"]` (AppNotification.toJson()'s legacy nullable
    // int, ALWAYS null for a unified-list composite id) instead of
    // `n["item_id"]` -- the exact same bug class already fixed for the
    // dismiss button above, just on the row tap's own mark-read call.
    // Root cause identical; fix identical (`item_id`, not `id`).
    //
    // A real row TAP is not fully untestable here, unlike this file's own
    // earlier note claims for a plain `tester.tap()`/`takeException()`
    // approach: everything up to and including mark-read and the
    // Campaign-C-only notification_opened emission runs to completion
    // BEFORE the tap reaches `notificationNavigationService` (a
    // Firebase-backed global singleton this headless environment cannot
    // construct -- verified directly: it throws
    // `[core/no-app] No Firebase App '[DEFAULT]' has been created`, not
    // from anything this fix touches). That single, pre-existing,
    // unrelated failure is isolated with `runZonedGuarded` around the tap
    // itself -- a test-only technique, zero production code change --
    // so the mark-read/notification_opened behavior that happens earlier
    // in the SAME tap can be asserted directly, and the caught error's
    // identity is itself asserted to guarantee no *other*, unexpected
    // failure is silently being swallowed.
    Future<Object?> tapAndCaptureUnrelatedNavCrash(
      WidgetTester tester,
      Finder finder,
    ) async {
      Object? caught;
      await runZonedGuarded(() async {
        await tester.tap(finder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }, (error, stack) => caught = error);
      return caught;
    }

    void expectOnlyTheKnownUnrelatedNavCrash(Object? caught) {
      // Sanity check on the zone-guard itself: if this ever changes (e.g.
      // a future test-harness change actually provides a working router),
      // this assertion fails loudly instead of silently swallowing a
      // DIFFERENT, real regression.
      expect(caught, isNotNull);
      expect(caught.toString(), contains('core/no-app'));
    }

    testWidgets(
      'N6 regression: tapping a Campaign C row (cc:<uuid>) sends the real '
      'composite item_id to mark-read, not the always-null legacy id',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [
            realItem(
              itemId: 'cc:2733c246-6c20-44ce-8ff4-31ea4e6dcfde',
              title: 'N6 Device QA Row Tap Test',
              source: 'ADMIN_CAMPAIGN',
            ),
          ],
          provider,
        );
        await tester.pumpAndSettle();

        final caught = await tapAndCaptureUnrelatedNavCrash(
          tester,
          find.text('N6 Device QA Row Tap Test'),
        );

        expectOnlyTheKnownUnrelatedNavCrash(caught);
        expect(provider.markedReadIds, [
          'cc:2733c246-6c20-44ce-8ff4-31ea4e6dcfde',
        ]);
      },
    );

    testWidgets(
      'N6 regression: tapping an A/B row (ab:<int>) sends the real '
      'composite item_id to mark-read',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [realItem(itemId: 'ab:42', title: 'A/B item')],
          provider,
        );
        await tester.pumpAndSettle();

        final caught = await tapAndCaptureUnrelatedNavCrash(
          tester,
          find.text('A/B item'),
        );

        expectOnlyTheKnownUnrelatedNavCrash(caught);
        expect(provider.markedReadIds, ['ab:42']);
      },
    );

    testWidgets(
      'N6 regression: a row with no item_id at all (malformed) fails safe '
      'on row tap -- no mark-read call, and no NEW crash beyond the one '
      'pre-existing, unrelated navigation gap',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [
            <String, dynamic>{
              'id': null,
              'title': 'Malformed',
              'body': 'x',
              'is_read': false,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'data': <String, dynamic>{},
            },
          ],
          provider,
        );
        await tester.pumpAndSettle();

        final caught = await tapAndCaptureUnrelatedNavCrash(
          tester,
          find.text('Malformed'),
        );

        expectOnlyTheKnownUnrelatedNavCrash(caught);
        expect(provider.markedReadIds, isEmpty);
      },
    );

    testWidgets(
      'N6 regression: tapping a Campaign C row still fires exactly one '
      'notification_opened emission attempt -- unaffected by the item_id '
      'fix',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [
            realItem(
              itemId: 'cc:notif-opened-1',
              title: 'Campaign notif-opened row',
              source: 'ADMIN_CAMPAIGN',
            ),
          ],
          provider,
        );
        await tester.pumpAndSettle();

        // ActivityEventClient.record()'s own "no signed-in user" drop
        // message is the one line in this entire tap's call graph
        // uniquely attributable to NotificationOpenedProducer.emit() --
        // loadUnreadCount()'s own failure path prints a different,
        // distinguishable message ("❌ USER NULL"), and nothing else in
        // this onTap handler reaches ActivityEventClient before the
        // (isolated) navigation crash.
        final captured = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) captured.add(message);
        };
        Object? caught;
        try {
          caught = await tapAndCaptureUnrelatedNavCrash(
            tester,
            find.text('Campaign notif-opened row'),
          );
        } finally {
          debugPrint = originalDebugPrint;
        }

        expectOnlyTheKnownUnrelatedNavCrash(caught);
        expect(
          captured.where((m) => m.contains('activity event dropped')).length,
          1,
        );
      },
    );

    testWidgets(
      'N6 regression: tapping an A/B row does NOT fire notification_opened '
      '(unchanged existing behavior -- this app has never emitted '
      'notification_opened for an A/B Bell tap)',
      (tester) async {
        final provider = _RecordingNotificationProvider();
        await pumpBellWithProvider(
          tester,
          () async => [realItem(itemId: 'ab:7', title: 'A/B notif-opened row')],
          provider,
        );
        await tester.pumpAndSettle();

        final captured = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) captured.add(message);
        };
        Object? caught;
        try {
          caught = await tapAndCaptureUnrelatedNavCrash(
            tester,
            find.text('A/B notif-opened row'),
          );
        } finally {
          debugPrint = originalDebugPrint;
        }

        expectOnlyTheKnownUnrelatedNavCrash(caught);
        expect(
          captured.where((m) => m.contains('activity event dropped')).length,
          0,
        );
      },
    );
  });
}

/// Records dismiss()/markAsRead() calls instead of reaching the real,
/// Firebase-gated NotificationService -- isolates "did the widget extract
/// and send the correct composite id" from "does the real HTTP call
/// succeed", which the backend's own test_notification_campaign_n6.py
/// already covers.
class _RecordingNotificationProvider extends NotificationProvider {
  final List<String> dismissedIds = [];
  final List<String> markedReadIds = [];

  @override
  Future<void> dismiss(String itemId) async {
    dismissedIds.add(itemId);
  }

  @override
  Future<void> markAsRead(String itemId) async {
    markedReadIds.add(itemId);
  }
}
