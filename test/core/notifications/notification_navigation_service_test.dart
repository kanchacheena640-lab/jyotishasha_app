import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/notifications/notification_navigation_service.dart';

Widget _page(String label) {
  return Builder(
    builder: (context) {
      final extra = GoRouterState.of(context).extra;
      final destination = extra is NotificationDispatchDestination
          ? extra
          : null;
      final suffix = destination?.eventId ?? destination?.route ?? '';
      return Scaffold(body: Text('$label${suffix.isEmpty ? '' : ':$suffix'}'));
    },
  );
}

/// A router whose Nth call to `go('/dashboard')` throws, so tests can
/// reproduce exactly the failure mode BUG-010B identified — [GoRouter.go]
/// is synchronous and can throw before a drain's `while` loop ever starts.
/// Uses the `.routingConfig` constructor because the default `GoRouter(...)`
/// constructor is a `factory`, which can't be called via `super(...)`.
class _FlakyDashboardRouter extends GoRouter {
  _FlakyDashboardRouter({
    required List<RouteBase> routes,
    required String initialLocation,
  }) : super.routingConfig(
         routingConfig: ValueNotifier(RoutingConfig(routes: routes)),
         initialLocation: initialLocation,
       );

  int dashboardGoCount = 0;
  int failOnAttemptNumber = -1;

  @override
  void go(String location, {Object? extra}) {
    if (location == '/dashboard') {
      dashboardGoCount++;
      if (dashboardGoCount == failOnAttemptNumber) {
        throw Exception('simulated go(/dashboard) failure');
      }
    }
    super.go(location, extra: extra);
  }
}

GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => _page('SPLASH')),
      GoRoute(path: '/dashboard', builder: (_, __) => _page('DASHBOARD')),
      GoRoute(path: '/event', builder: (_, __) => _page('EVENT')),
      // N1 — content-only destination (type not in the AstroEvent-backed
      // set: Alerts/Dasha/unknown — see N1.1's _astroEventBackedTypes).
      GoRoute(
        path: '/notification-detail',
        builder: (_, __) => _page('DETAIL'),
      ),
      // N3 — Personalized Planetary Transit destination.
      GoRoute(
        path: '/transit-article',
        builder: (_, __) => _page('TRANSIT'),
      ),
      GoRoute(path: '/other', builder: (_, __) => _page('OTHER')),
    ],
  );
}

void main() {
  testWidgets(
    'a destination opened before the router reaches /dashboard is queued, '
    'not navigated immediately',
    (tester) async {
      final router = _buildRouter(initialLocation: '/splash');
      final service = NotificationNavigationService(router: router)..start();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('SPLASH'), findsOneWidget);

      // type: 'event' deliberately — this test is about QUEUEING mechanics,
      // not N1.1's type-based routing decision, so it uses a destination
      // that resolves to /event exactly as before N1.1.
      service.openDestination(
        const NotificationDispatchDestination(type: 'event', eventId: '1'),
      );
      await tester.pumpAndSettle();

      // Still on splash — nothing navigated yet, no race against runApp().
      expect(find.text('SPLASH'), findsOneWidget);
      expect(find.textContaining('EVENT'), findsNothing);

      // App reaches Dashboard through its own normal splash/auth flow.
      router.go('/dashboard');
      await tester.pumpAndSettle();

      // Queued destination is drained automatically, exactly once.
      expect(find.text('EVENT:1'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches.length, 2);
    },
  );

  testWidgets(
    'when already on /dashboard, opening a destination immediately produces '
    '[dashboard, destination]',
    (tester) async {
      final router = _buildRouter(initialLocation: '/dashboard');
      final service = NotificationNavigationService(router: router)..start();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('DASHBOARD'), findsOneWidget);

      service.openDestination(
        const NotificationDispatchDestination(type: 'event', eventId: '2'),
      );
      await tester.pumpAndSettle();

      expect(find.text('EVENT:2'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches.length, 2);
    },
  );

  testWidgets(
    'a destination with an explicit route navigates there instead of the '
    'default /event fallback',
    (tester) async {
      final router = _buildRouter(initialLocation: '/dashboard');
      final service = NotificationNavigationService(router: router)..start();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      service.openDestination(
        const NotificationDispatchDestination(route: '/other'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('OTHER'), findsOneWidget);
    },
  );

  testWidgets(
    'a warm tap resets an unrelated screen back to dashboard before drilling '
    'into the destination',
    (tester) async {
      final router = _buildRouter(initialLocation: '/dashboard');
      final service = NotificationNavigationService(router: router)..start();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/other');
      await tester.pumpAndSettle();
      expect(find.textContaining('OTHER'), findsOneWidget);

      service.openDestination(
        const NotificationDispatchDestination(type: 'event', eventId: '3'),
      );
      await tester.pumpAndSettle();

      expect(find.text('EVENT:3'), findsOneWidget);
      // /other was discarded — stack is exactly [dashboard, event].
      expect(router.routerDelegate.currentConfiguration.matches.length, 2);
    },
  );

  testWidgets('multiple destinations opened before the router is ready are all '
      'drained, in order, once it settles', (tester) async {
    final router = _buildRouter(initialLocation: '/splash');
    final service = NotificationNavigationService(router: router)..start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    service.openDestination(
      const NotificationDispatchDestination(eventId: 'first'),
    );
    service.openDestination(
      const NotificationDispatchDestination(route: '/other'),
    );
    await tester.pumpAndSettle();

    router.go('/dashboard');
    await tester.pumpAndSettle();

    // Last one drained ends up on top.
    expect(find.textContaining('OTHER'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.matches.length, 3);
  });

  testWidgets(
    'calling start() while already on /dashboard immediately marks the '
    'router ready, without waiting for a further change event',
    (tester) async {
      final router = _buildRouter(initialLocation: '/dashboard');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final service = NotificationNavigationService(router: router)..start();

      service.openDestination(
        const NotificationDispatchDestination(type: 'event', eventId: '4'),
      );
      await tester.pumpAndSettle();

      expect(find.text('EVENT:4'), findsOneWidget);
    },
  );

  testWidgets(
    'if go(/dashboard) throws mid-drain, the queued destination is preserved '
    '(not lost, not marked ready) and successfully drains on the next '
    'opportunity instead of being permanently stuck',
    (tester) async {
      final router = _FlakyDashboardRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(path: '/splash', builder: (_, __) => _page('SPLASH')),
          GoRoute(path: '/dashboard', builder: (_, __) => _page('DASHBOARD')),
          GoRoute(path: '/event', builder: (_, __) => _page('EVENT')),
        ],
      );
      final service = NotificationNavigationService(router: router)..start();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      service.openDestination(
        const NotificationDispatchDestination(type: 'event', eventId: '6'),
      );
      await tester.pumpAndSettle();

      // Arm the failure for the SECOND go('/dashboard') call: the first is
      // this test's own "app reaches dashboard" transition (must succeed so
      // the router genuinely settles there); the second is the service's
      // own reentrant _resetToDashboard() retry triggered by that settle —
      // exactly the call BUG-010B identified as unguarded.
      router.failOnAttemptNumber = 2;
      router.go('/dashboard');
      await tester.pumpAndSettle();

      // The drain attempt failed: still on Dashboard (the outer go()
      // succeeded), but the destination was never pushed, and the queue
      // was NOT thrown away.
      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.textContaining('EVENT'), findsNothing);

      // The next opportunity (any further router change) gets another
      // chance — no longer armed to fail, so this one succeeds. GoRouter
      // dedupes a go() call to the location it's already on, so leave and
      // come back rather than re-issuing an identical, silently-ignored
      // go('/dashboard').
      router.go('/splash');
      await tester.pumpAndSettle();
      router.go('/dashboard');
      await tester.pumpAndSettle();

      expect(find.text('EVENT:6'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches.length, 2);
    },
  );

  group('N1.1 — routing decision is based on `type`, not eventId shape', () {
    testWidgets(
      'a known AstroEvent-backed type (event/panchang/panchak) with '
      'a valid numeric eventId resolves to /event',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        service.openDestination(
          const NotificationDispatchDestination(
            type: 'panchak',
            eventId: '482',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('EVENT:482'), findsOneWidget);
      },
    );

    testWidgets(
      'a known AstroEvent-backed type with a malformed/non-numeric eventId '
      'STILL resolves to /event (type is authoritative) — the malformed id '
      'is EventDispatcherPage\'s own concern to fail safely on '
      '(int.tryParse == null -> "No event data available", no repository '
      'call), never this routing decision\'s',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        service.openDestination(
          const NotificationDispatchDestination(
            type: 'event',
            eventId: 'not-a-number',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('EVENT:not-a-number'), findsOneWidget);
      },
    );

    testWidgets(
      'a future/unrecognized type with a NUMERIC-LOOKING eventId must NOT '
      'accidentally resolve to /event — this is exactly the failure mode '
      'N1.1 removes: routing must never infer "this is an AstroEvent" from '
      'eventId shape alone',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        service.openDestination(
          const NotificationDispatchDestination(
            type: 'some_future_type',
            eventId: '999',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DETAIL:999'), findsOneWidget);
        expect(find.textContaining('EVENT:'), findsNothing);
      },
    );

    testWidgets(
      'a Personalized Alert semantic eventId resolves to /notification-detail, '
      'never /event',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        service.openDestination(
          const NotificationDispatchDestination(
            type: 'alert',
            eventId: 'mood_positive',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DETAIL:mood_positive'), findsOneWidget);
        expect(find.textContaining('EVENT:'), findsNothing);
      },
    );

    testWidgets(
      'a Dasha composite eventId resolves to /notification-detail, never /event',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        service.openDestination(
          const NotificationDispatchDestination(
            type: 'dasha',
            eventId: 'dasha_42_Venus_Moon',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DETAIL:dasha_42_Venus_Moon'), findsOneWidget);
        expect(find.textContaining('EVENT:'), findsNothing);
      },
    );

    testWidgets(
      'a dasha_pre composite eventId resolves to /notification-detail',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        service.openDestination(
          const NotificationDispatchDestination(
            type: 'dasha_pre',
            eventId: 'dasha_pre_42_Venus_Moon',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DETAIL:dasha_pre_42_Venus_Moon'), findsOneWidget);
      },
    );

    testWidgets('a missing eventId (unknown/malformed payload) fails safe to '
        '/notification-detail rather than the misleading /event dead end', (
      tester,
    ) async {
      final router = _buildRouter(initialLocation: '/dashboard');
      final service = NotificationNavigationService(router: router)..start();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      service.openDestination(
        const NotificationDispatchDestination(type: 'some_unknown_future_type'),
      );
      await tester.pumpAndSettle();

      expect(find.text('DETAIL'), findsOneWidget);
      expect(find.textContaining('EVENT'), findsNothing);
    });

    testWidgets('an explicit route still wins over the type-based decision, '
        'exactly as before N1.1', (tester) async {
      final router = _buildRouter(initialLocation: '/dashboard');
      final service = NotificationNavigationService(router: router)..start();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      service.openDestination(
        const NotificationDispatchDestination(
          type: 'alert',
          eventId: 'mood_positive',
          route: '/other',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('OTHER'), findsOneWidget);
    });
  });

  group('N3 — Personalized Planetary Transit routes to /transit-article', () {
    testWidgets(
      'type: "transit" resolves to /transit-article, never /event',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        service.openDestination(
          const NotificationDispatchDestination(
            type: 'transit',
            eventId: '482',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('TRANSIT:482'), findsOneWidget);
        expect(find.textContaining('EVENT:'), findsNothing);
      },
    );

    testWidgets(
      'push and Bell entry points resolve type: "transit" identically '
      '(same NotificationDispatcher._build path, same routing decision)',
      (tester) async {
        final router = _buildRouter(initialLocation: '/dashboard');
        final service = NotificationNavigationService(router: router)..start();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        final fromBell = NotificationDispatcher.fromNotificationCenterItem({
          'title': 'Jupiter Transit Tomorrow: 10th House',
          'body': 'Jupiter moves into your 10th House tomorrow.',
          'data': {
            'type': 'transit',
            'event_id': '482',
            'planet': 'Jupiter',
            'house': '10',
            'language': 'en',
            'url': 'https://www.jyotishasha.com/planet-in-house/jupiter-in-10th-house',
          },
        });

        service.openDestination(fromBell);
        await tester.pumpAndSettle();

        expect(find.text('TRANSIT:482'), findsOneWidget);
      },
    );
  });
}
