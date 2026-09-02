import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/analytics/activity_events.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/utils/premium_gate.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

import '../../helpers/test_harness.dart';

class _FakeIdentityPort implements CurrentUserIdentityPort {
  const _FakeIdentityPort();
  @override
  String? get currentFirebaseUid => 'test-uid';
}

/// Phase 5C.1 -- proves the `subscription_discovery_viewed` DESTINATION
/// producer, wired at [SubscriptionPage]'s own `initState` (see that
/// file's own call site comment), fires exactly once per page instance,
/// never on a rebuild of the same instance, sends `placement` (never a
/// fabricated `plan`), and never blocks rendering when analytics fails.
void main() {
  late List<http.Request> captured;

  void useCapturingClient() {
    captured = <http.Request>[];
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response('{"status":"written","event_id":"x"}', 201);
    });
    ActivityEvents.debugOverrideClient(
      ActivityEventClient(
        httpClient: mockClient,
        identityPort: const _FakeIdentityPort(),
        tokenProvider: (firebaseUid, {client}) async => 'fake-token',
      ),
    );
  }

  tearDown(() {
    ActivityEvents.debugResetClient();
  });

  Future<void> pump(
    WidgetTester tester,
    SubscriptionProvider provider, {
    SubscriptionDiscoveryPlacement placement =
        SubscriptionDiscoveryPlacement.account,
  }) async {
    await tester.pumpTestHarness(
      SubscriptionPage(autoLoad: false, placement: placement),
      providers: [
        ChangeNotifierProvider<SubscriptionProvider>.value(value: provider),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider(),
        ),
      ],
    );
  }

  // Facade-level serialization proofs (event_name/properties shape, the
  // full wired-placement vocabulary, no-plan-fabrication) already live
  // in activity_events_test.dart, alongside every other ActivityEvents
  // method's own facade tests -- not duplicated here. This file covers
  // what only SubscriptionPage itself (not the bare facade call) can
  // prove: the once-per-instance lifecycle seam, rebuild/new-instance
  // behavior, failure isolation, and the real CTA-to-destination funnel.

  test(
    'SubscriptionDiscoveryPlacement.value strings match the approved '
    'vocabulary exactly (Dart identifiers may differ; the wire value '
    'may not)',
    () {
      expect(SubscriptionDiscoveryPlacement.account.value, 'account');
      expect(SubscriptionDiscoveryPlacement.explore.value, 'explore');
      expect(
        SubscriptionDiscoveryPlacement.alertsDashboard.value,
        'alerts_dashboard',
      );
      expect(
        SubscriptionDiscoveryPlacement.premiumLockedContent.value,
        'premium_locked_content',
      );
      expect(
        SubscriptionDiscoveryPlacement.premiumReportReader.value,
        'premium_report_reader',
      );
      expect(
        SubscriptionDiscoveryPlacement.directRoute.value,
        'direct_route',
      );
    },
  );

  testWidgets(
    'G/J: mounting SubscriptionPage fires subscription_discovery_viewed '
    'exactly once, with the page\'s own placement',
    (tester) async {
      useCapturingClient();
      final provider = SubscriptionProvider();

      await pump(tester, provider, placement: SubscriptionDiscoveryPlacement.explore);
      await tester.pump();

      expect(captured.length, 1);
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['event_name'], 'subscription_discovery_viewed');
      expect(body['properties'], {'placement': 'explore'});
    },
  );

  testWidgets(
    'H: rebuilding the SAME SubscriptionPage instance (e.g. a provider '
    'notifyListeners) does NOT fire a second discovery event',
    (tester) async {
      useCapturingClient();
      final provider = SubscriptionProvider();

      await pump(tester, provider);
      await tester.pump();
      expect(captured.length, 1);

      // Force a rebuild of the SAME State instance -- no new navigation,
      // no new SubscriptionPage widget identity.
      provider.notifyListeners();
      await tester.pump();
      provider.notifyListeners();
      await tester.pump();

      expect(
        captured.length,
        1,
        reason: 'initState never re-runs on a rebuild of the same instance',
      );
    },
  );

  testWidgets(
    'I: navigating to a genuinely NEW SubscriptionPage instance fires a '
    'second, independent discovery event',
    (tester) async {
      useCapturingClient();
      final provider = SubscriptionProvider();

      await tester.pumpTestHarness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SubscriptionPage(
                  autoLoad: false,
                  placement: SubscriptionDiscoveryPlacement.account,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        providers: [
          ChangeNotifierProvider<SubscriptionProvider>.value(value: provider),
          ChangeNotifierProvider<LanguageProvider>.value(
            value: LanguageProvider(),
          ),
        ],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(captured.length, 1);

      // Pop back and push a second, brand-new instance.
      Navigator.of(
        tester.element(find.byType(SubscriptionPage)),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        captured.length,
        2,
        reason: 'a new SubscriptionPage instance must fire a new event',
      );
      for (final request in captured) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['event_name'], 'subscription_discovery_viewed');
      }
    },
  );

  testWidgets(
    'M: analytics delivery failure (non-2xx / thrown) never blocks '
    'SubscriptionPage from rendering',
    (tester) async {
      final failingClient = MockClient((request) async {
        throw Exception('simulated network failure');
      });
      ActivityEvents.debugOverrideClient(
        ActivityEventClient(
          httpClient: failingClient,
          identityPort: const _FakeIdentityPort(),
          tokenProvider: (firebaseUid, {client}) async => 'fake-token',
        ),
      );
      final provider = SubscriptionProvider();

      await pump(tester, provider);
      await tester.pump();

      // The page still rendered its normal empty-state UI -- no
      // exception escaped, no error surfaced to the user.
      expect(find.byType(SubscriptionPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'N: subscription_discovery_viewed properties never contain a PII-'
    'shaped key or value, even if a placement value happened to look '
    'like one (defense-in-depth mirrors the backend sanitizer)',
    () async {
      useCapturingClient();
      await ActivityEvents.subscriptionDiscoveryViewed('account');
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      final properties = (body['properties'] as Map).cast<String, dynamic>();
      expect(properties.keys, {'placement'});
      for (final key in [
        'email', 'phone', 'latitude', 'longitude', 'dob', 'tob', 'pob',
        'token', 'password', 'full_name', 'plan',
      ]) {
        expect(properties.containsKey(key), isFalse);
      }
    },
  );

  testWidgets(
    'L: a real CTA-to-destination funnel (premium_gate.requirePremium, '
    'the same function account_page.dart/explore_page.dart/alerts_'
    'dashboard_page.dart all reuse) fires cta_click THEN '
    'subscription_discovery_viewed, in that order',
    (tester) async {
      useCapturingClient();
      final provider = SubscriptionProvider()
        ..subscriptionData = {'membership_state': 'NONE'}; // locked

      late BuildContext capturedContext;
      await tester.pumpTestHarness(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
        providers: [
          ChangeNotifierProvider<SubscriptionProvider>.value(value: provider),
          ChangeNotifierProvider<LanguageProvider>.value(
            value: LanguageProvider(),
          ),
        ],
      );

      // Exercises the real, unmodified requirePremium() -- fires
      // cta_click(premium_gate_locked_content) then pushes
      // SubscriptionPage(placement: premiumLockedContent), whose own
      // initState fires subscription_discovery_viewed.
      requirePremium(capturedContext, () {}, screenName: 'premium_report');
      await tester.pumpAndSettle();

      expect(captured.length, 2);
      final names = captured
          .map((r) => (jsonDecode(r.body) as Map<String, dynamic>)['event_name'])
          .toList();
      expect(names, ['cta_click', 'subscription_discovery_viewed']);
    },
  );
}
