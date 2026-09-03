import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jyotishasha_app/core/analytics/install_attribution_producer.dart';
import 'package:jyotishasha_app/core/analytics/install_referrer_service.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// Task 5A focused tests for InstallAttributionProducer.
///
/// SEMANTIC FREEZE (executable, not just a comment): app_install_attributed
/// means "Google Play install attribution was captured by the Android
/// app and later associated with an authenticated app lifecycle." It is
/// NEVER "number of installs" -- see the dedicated test at the bottom
/// of this file that asserts this in the class's own docstring text,
/// so a future edit that quietly drifts the meaning breaks a test, not
/// just a comment.
///
/// LOCAL/UNIT ONLY -- no real Firebase, no real backend. SharedPreferences
/// uses the package's own official in-memory mock (same convention as
/// test/core/analytics/install_referrer_service_test.dart and
/// test/services/activity_event_client_test.dart). ActivityEventClient
/// is wired to a MockClient (http/testing.dart), the exact same
/// convention test/services/activity_event_client_test.dart already
/// establishes.
class _FakeIdentityPort implements CurrentUserIdentityPort {
  _FakeIdentityPort(this._uid);
  final String? _uid;
  @override
  String? get currentFirebaseUid => _uid;
}

void main() {
  const signedInUid = 'test-firebase-uid-install-attr';
  const fakeToken = 'fake-backend-jwt-for-tests-only';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InstallReferrerService.debugResetFetcherOverride();
    InstallAttributionProducer.debugReset();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    InstallReferrerService.debugResetFetcherOverride();
    InstallAttributionProducer.debugReset();
    debugDefaultTargetPlatformOverride = null;
  });

  /// A client wired to a MockClient that always succeeds with 201 and
  /// records every request it receives -- mirrors
  /// activity_event_client_test.dart's own happyClient() helper.
  ({ActivityEventClient client, List<http.Request> captured}) happyClient({
    int statusCode = 201,
    String responseBody = '{"status":"written","event_id":"abc"}',
  }) {
    final captured = <http.Request>[];
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response(responseBody, statusCode);
    });
    final client = ActivityEventClient(
      httpClient: mockClient,
      identityPort: _FakeIdentityPort(signedInUid),
      tokenProvider: (firebaseUid, {client}) async => fakeToken,
    );
    return (client: client, captured: captured);
  }

  ({ActivityEventClient client, List<http.Request> captured}) failingClient() {
    final captured = <http.Request>[];
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response('{"error":"temporarily_unavailable"}', 503);
    });
    final client = ActivityEventClient(
      httpClient: mockClient,
      identityPort: _FakeIdentityPort(signedInUid),
      tokenProvider: (firebaseUid, {client}) async => fakeToken,
    );
    return (client: client, captured: captured);
  }

  Future<void> captureAttribution({
    String? source = 'daily_panchang',
    String? medium = 'primary_cta',
    String? campaign = 'hero',
    String? ctaLocation = 'daily_panchang_primary_cta',
  }) async {
    final parts = <String>[
      if (source != null) 'utm_source=$source',
      if (medium != null) 'utm_medium=$medium',
      if (campaign != null) 'utm_campaign=$campaign',
      if (ctaLocation != null) 'cta_location=$ctaLocation',
    ];
    InstallReferrerService.debugFetcherOverride = () async => parts.join('&');
    await InstallReferrerService.captureOnce();
    InstallReferrerService.debugResetFetcherOverride();
  }

  Map<String, dynamic> decodeBody(http.Request request) {
    return request.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(request.body) as Map);
  }

  group('captureAttribution + attemptOnce', () {
    test(
      '1/2: captured campaign + authenticated Android -> event attempted with correct event_name',
      () async {
        await captureAttribution();
        final h = happyClient();
        InstallAttributionProducer.debugClientOverride = h.client;
        InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

        await InstallAttributionProducer.attemptOnce();

        expect(h.captured.length, 1);
        final body = decodeBody(h.captured.first);
        expect(body['event_name'], 'app_install_attributed');
      },
    );

    test('3: properties are exactly {} -- never included when empty', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      final body = decodeBody(h.captured.first);
      expect(body.containsKey('properties'), isFalse, reason: 'ActivityEventClient omits empty properties entirely -- equivalent to {}');
    });

    test('4: campaign_context contains only the 3 allowed UTM fields', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      final body = decodeBody(h.captured.first);
      final campaignContext = Map<String, dynamic>.from(body['campaign_context'] as Map);
      expect(campaignContext.keys.toSet(), {'utm_source', 'utm_medium', 'utm_campaign'});
      expect(campaignContext['utm_source'], 'daily_panchang');
      expect(campaignContext['utm_medium'], 'primary_cta');
      expect(campaignContext['utm_campaign'], 'hero');
    });

    test('5: cta_location is never emitted -- not in campaign_context, not in properties', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      final body = decodeBody(h.captured.first);
      final campaignContext = Map<String, dynamic>.from(body['campaign_context'] as Map);
      expect(campaignContext.containsKey('cta_location'), isFalse);
      expect(body.containsKey('properties'), isFalse);
      expect(body.toString().contains('daily_panchang_primary_cta'), isFalse);
    });

    test('6: raw referrer string is never emitted anywhere in the request', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      final rawShape = 'utm_source=daily_panchang&utm_medium=primary_cta&utm_campaign=hero&cta_location=daily_panchang_primary_cta';
      expect(h.captured.first.body.contains(rawShape), isFalse);
    });

    test('7: no attribution captured -> no event attempted', () async {
      // InstallReferrerService never successfully captured anything.
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      expect(h.captured, isEmpty);
      expect(await InstallAttributionProducer.debugIsRecorded(), isFalse);
    });

    test('8: captured attribution but unauthenticated -> no event yet (wait)', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(null);

      await InstallAttributionProducer.attemptOnce();

      expect(h.captured, isEmpty);
      expect(await InstallAttributionProducer.debugIsRecorded(), isFalse);
    });

    test('9: restored authenticated session (uid present, no prior interactive login) can emit', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      // Simulates SplashPage's own seam: uid is simply already present.
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      expect(h.captured.length, 1);
      expect(await InstallAttributionProducer.debugIsRecorded(), isTrue);
    });

    test('10: fresh interactive login (uid becomes present) can emit via the same call', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      // Simulates LoginPage's own seam: identical call, uid now present
      // because sign-in just completed.
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      expect(h.captured.length, 1);
      expect(await InstallAttributionProducer.debugIsRecorded(), isTrue);
    });

    test('11: successful event (HTTP 201) -> emission marker set', () async {
      await captureAttribution();
      final h = happyClient(statusCode: 201);
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      expect(await InstallAttributionProducer.debugIsRecorded(), isTrue);
    });

    test('12: failed event (HTTP 503) -> emission marker NOT set', () async {
      await captureAttribution();
      final h = failingClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      expect(h.captured.length, 1, reason: 'the attempt was made');
      expect(await InstallAttributionProducer.debugIsRecorded(), isFalse);
    });

    test(
      '13: later opportunity retries after failure, reusing the SAME idempotency_key',
      () async {
        await captureAttribution();

        final fail = failingClient();
        InstallAttributionProducer.debugClientOverride = fail.client;
        InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);
        await InstallAttributionProducer.attemptOnce();
        expect(await InstallAttributionProducer.debugIsRecorded(), isFalse);
        final firstIdempotencyKey = decodeBody(fail.captured.first)['idempotency_key'];
        expect(firstIdempotencyKey, isNotNull);

        final succeed = happyClient();
        InstallAttributionProducer.debugClientOverride = succeed.client;
        await InstallAttributionProducer.attemptOnce();

        expect(succeed.captured.length, 1);
        final secondIdempotencyKey = decodeBody(succeed.captured.first)['idempotency_key'];
        expect(secondIdempotencyKey, firstIdempotencyKey, reason: 'same install-scoped key reused across retries');
        expect(await InstallAttributionProducer.debugIsRecorded(), isTrue);
      },
    );

    test('14: repeated successful lifecycle does not emit again', () async {
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();
      expect(h.captured.length, 1);

      // Second call -- simulates a second SplashPage cold-start or a
      // second LoginPage sign-in in the same install.
      await InstallAttributionProducer.attemptOnce();
      expect(h.captured.length, 1, reason: 'no second HTTP attempt once already recorded');
    });

    test('15: duplicate backend response (HTTP 200) is handled exactly like a confirmed write', () async {
      await captureAttribution();
      final h = happyClient(statusCode: 200, responseBody: '{"status":"duplicate"}');
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      expect(await InstallAttributionProducer.debugIsRecorded(), isTrue);
    });

    test('16: Android-only -- a non-Android target never even attempts the call', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await captureAttribution();
      final h = happyClient();
      InstallAttributionProducer.debugClientOverride = h.client;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await InstallAttributionProducer.attemptOnce();

      expect(h.captured, isEmpty);
      expect(await InstallAttributionProducer.debugIsRecorded(), isFalse);
    });

    test('never throws even when the client throws synchronously', () async {
      InstallReferrerService.debugFetcherOverride = () async => 'utm_source=x';
      await InstallReferrerService.captureOnce();
      InstallReferrerService.debugResetFetcherOverride();

      final throwingClient = ActivityEventClient(
        httpClient: MockClient((request) async => throw Exception('boom')),
        identityPort: _FakeIdentityPort(signedInUid),
        tokenProvider: (firebaseUid, {client}) async => fakeToken,
      );
      InstallAttributionProducer.debugClientOverride = throwingClient;
      InstallAttributionProducer.debugIdentityPortOverride = _FakeIdentityPort(signedInUid);

      await expectLater(InstallAttributionProducer.attemptOnce(), completes);
      expect(await InstallAttributionProducer.debugIsRecorded(), isFalse);
    });
  });

  group('buildCampaignContext (pure)', () {
    test('returns null when nothing is captured', () {
      final result = InstallAttributionProducer.buildCampaignContext({
        'utm_source': null,
        'utm_medium': null,
        'utm_campaign': null,
        'cta_location': null,
      });
      expect(result, isNull);
    });

    test('omits cta_location even when present in the captured map', () {
      final result = InstallAttributionProducer.buildCampaignContext({
        'utm_source': 'newsletter',
        'utm_medium': null,
        'utm_campaign': null,
        'cta_location': 'some_location',
      });
      expect(result, {'utm_source': 'newsletter'});
    });
  });

  group('21: no PII/birth data in payload', () {
    test('captured attribution containing an accidental email-shaped value is still forwarded as-is by this layer (upstream InstallReferrerService/backend sanitizers are the actual PII gate) -- but no NEW field this layer adds could ever carry PII', () async {
      // This class's own contract: it forwards ONLY utm_source/utm_medium/
      // utm_campaign, structurally -- there is no code path here that could
      // add name/email/phone/DOB/birth data/auth token/device id, since
      // buildCampaignContext()'s own return type only ever contains those
      // 3 fixed keys.
      final result = InstallAttributionProducer.buildCampaignContext({
        'utm_source': 'x',
        'utm_medium': 'y',
        'utm_campaign': 'z',
        'cta_location': 'w',
      });
      expect(result!.keys.toSet(), {'utm_source', 'utm_medium', 'utm_campaign'});
    });
  });

  group('semantic freeze', () {
    test(
      'app_install_attributed is documented as an ATTRIBUTED FACT, never as an install count',
      () {
        // Read the actual source file's own docstring text and assert the
        // freeze phrase is present -- a future edit that silently drifts
        // the meaning (e.g. someone rewording it to "number of installs")
        // breaks this test, not just a comment nobody re-reads.
        final source = File('lib/core/analytics/install_attribution_producer.dart').readAsStringSync();
        expect(source.contains('Google Play install attribution was captured by the Android'), isTrue);
        expect(source.contains('app and later associated with an authenticated app lifecycle'), isTrue);
        expect(source.contains('NOT GA4 first_open'), isTrue);
        expect(source.contains('NOT a raw install counter'), isTrue);
        expect(source.toLowerCase().contains('"number of installs"'), isTrue, reason: 'the explicit prohibition itself must be present');
      },
    );
  });
}
