import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/core/analytics/activity_events.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

class _FakeIdentityPort implements CurrentUserIdentityPort {
  const _FakeIdentityPort();
  @override
  String? get currentFirebaseUid => 'test-uid';
}

/// Phase 5B foundation tests -- the ActivityEvents facade every wired
/// producer call site (cta_click / feature_used / report_discovery_viewed
/// / asknow_entry_viewed) goes through. Proves each method builds EXACTLY
/// the frozen properties shape for its event -- this is what every real
/// widget call site (TrendingQuestionsWidget, DashboardPage, KundaliFormPage,
/// ReportCatalogPage, ExplorePage, premium_gate.dart, AccountPage,
/// AlertsDashboardPage, the horoscope/panchang providers, MuhurthPage,
/// AskNowChatPage) relies on -- tested once here rather than re-proven at
/// every call site.
void main() {
  late List<http.Request> captured;

  setUp(() {
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
  });

  tearDown(() {
    ActivityEvents.debugResetClient();
  });

  test('ctaClick sends event_name=cta_click with exactly cta_id/screen_name', () async {
    await ActivityEvents.ctaClick(ctaId: 'home_ask_now_hero', screenName: 'dashboard_home');
    final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
    expect(body['event_name'], 'cta_click');
    expect(body['properties'], {
      'cta_id': 'home_ask_now_hero',
      'screen_name': 'dashboard_home',
    });
  });

  test('featureUsed sends event_name=feature_used with exactly feature_name', () async {
    await ActivityEvents.featureUsed('kundali_generate');
    final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
    expect(body['event_name'], 'feature_used');
    expect(body['properties'], {'feature_name': 'kundali_generate'});
  });

  test(
    'reportDiscoveryViewed sends event_name=report_discovery_viewed with '
    'exactly report_type',
    () async {
      await ActivityEvents.reportDiscoveryViewed('love');
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['event_name'], 'report_discovery_viewed');
      expect(body['properties'], {'report_type': 'love'});
    },
  );

  test(
    'asknowEntryViewed sends event_name=asknow_entry_viewed with NO '
    'properties at all (frozen schema: {})',
    () async {
      await ActivityEvents.asknowEntryViewed();
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['event_name'], 'asknow_entry_viewed');
      expect(body.containsKey('properties'), isFalse);
    },
  );

  test(
    // Phase 5C.1 -- backend schema now allows {plan, placement}; this
    // facade method only ever sends placement (see its own doc comment
    // for why plan is deliberately never fabricated here).
    'subscriptionDiscoveryViewed sends event_name=subscription_discovery_'
    'viewed with exactly {placement} -- never a fabricated plan',
    () async {
      await ActivityEvents.subscriptionDiscoveryViewed('account');
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['event_name'], 'subscription_discovery_viewed');
      expect(body['properties'], {'placement': 'account'});
      expect((body['properties'] as Map).containsKey('plan'), isFalse);
    },
  );

  test('no forbidden field is ever present in any facade call', () async {
    await ActivityEvents.ctaClick(ctaId: 'x', screenName: 'y');
    final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
    for (final key in [
      'event_id', 'recorded_at', 'environment', 'firebase_uid',
      'profile_id', 'correlation_id', 'dedupe_key',
    ]) {
      expect(body.containsKey(key), isFalse);
    }
  });

  // -----------------------------------------------------------------
  // Exact CTA inventory -- every id/screen_name pair Phase 5B actually
  // wired into a real product call site (see the final report's CTA
  // inventory table for the file:line of each).
  // -----------------------------------------------------------------
  const wiredCtas = <String, String>{
    'home_ask_now_hero': 'dashboard_home',
    'bottom_nav_ask_now': 'dashboard',
    'kundali_form_generate': 'kundali_form',
    'report_catalog_buy_now': 'report_catalog',
    'premium_gate_locked_content': 'premium_report',
    'account_page_subscription': 'account',
    'explore_page_subscription': 'explore',
    'alerts_dashboard_subscription': 'alerts_dashboard',
  };

  for (final entry in wiredCtas.entries) {
    test(
      'wired CTA "${entry.key}" on screen "${entry.value}" serializes '
      'exactly as the inventory documents',
      () async {
        await ActivityEvents.ctaClick(
          ctaId: entry.key,
          screenName: entry.value,
        );
        final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
        expect(body['properties'], {
          'cta_id': entry.key,
          'screen_name': entry.value,
        });
      },
    );
  }

  // -----------------------------------------------------------------
  // Exact feature_used inventory
  // -----------------------------------------------------------------
  const wiredFeatures = <String>[
    'kundali_generate',
    'panchang_view',
    'horoscope_daily',
    'horoscope_monthly',
    'horoscope_yearly',
    'transit_view',
    'muhurth_search',
  ];

  for (final featureName in wiredFeatures) {
    test('wired feature_used "$featureName" serializes correctly', () async {
      await ActivityEvents.featureUsed(featureName);
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['properties'], {'feature_name': featureName});
    });
  }

  // -----------------------------------------------------------------
  // Exact report_discovery_viewed report_type vocabulary (AI report hub)
  // -----------------------------------------------------------------
  const wiredReportTypes = <String>['love', 'career', 'finance', 'health', 'family'];

  for (final reportType in wiredReportTypes) {
    test('wired report_discovery_viewed report_type "$reportType"', () async {
      await ActivityEvents.reportDiscoveryViewed(reportType);
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['properties'], {'report_type': reportType});
    });
  }

  // -----------------------------------------------------------------
  // Phase 5C.1 -- exact subscription_discovery_viewed placement
  // vocabulary. Every value SubscriptionPage's own production
  // constructor sites actually send (see that file's
  // SubscriptionDiscoveryPlacement enum for the file:line mapping).
  // -----------------------------------------------------------------
  const wiredPlacements = <String>[
    'account',
    'explore',
    'alerts_dashboard',
    'premium_locked_content',
    'premium_report_reader',
    'direct_route',
  ];

  for (final placement in wiredPlacements) {
    test('wired subscription_discovery_viewed placement "$placement"', () async {
      await ActivityEvents.subscriptionDiscoveryViewed(placement);
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['properties'], {'placement': placement});
    });
  }
}
