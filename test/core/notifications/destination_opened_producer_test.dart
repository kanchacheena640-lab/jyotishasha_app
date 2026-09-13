import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/notifications/destination_opened_producer.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

class _FakeIdentityPort implements CurrentUserIdentityPort {
  const _FakeIdentityPort();
  @override
  String? get currentFirebaseUid => 'test-uid';
}

/// N6 -- DestinationOpenedProducer. Mirrors
/// notification_opened_producer_test.dart's own convention exactly: a
/// fully test-controlled ActivityEventClient, no real Firebase/backend.
void main() {
  late List<http.Request> captured;

  ActivityEventClient client({int statusCode = 201}) {
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response('{"status":"written","event_id":"x"}', statusCode);
    });
    return ActivityEventClient(
      httpClient: mockClient,
      identityPort: const _FakeIdentityPort(),
      tokenProvider: (firebaseUid, {client}) async => 'fake-token',
    );
  }

  setUp(() {
    captured = <http.Request>[];
  });

  test('emit() sends the canonical destination_opened event name', () async {
    const destination = NotificationDispatchDestination(
      type: 'admin_campaign',
      route: '/reports',
      payload: {'campaign_id': 'c1', 'notification_id': 'e1', 'slot': 'general'},
    );
    await DestinationOpenedProducer.emit(destination, client: client());
    expect(captured, hasLength(1));
    final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
    expect(body['event_name'], 'destination_opened');
    expect(body['notification_context'], {
      'notification_id': 'e1',
      'campaign_id': 'c1',
      'slot': 'general',
    });
  });

  test('never emits notification_clicked/push_clicked/notification_tapped or any near-duplicate name', () async {
    const destination = NotificationDispatchDestination(
      type: 'admin_campaign',
      route: '/asknow',
      payload: {'campaign_id': 'c1'},
    );
    await DestinationOpenedProducer.emit(destination, client: client());
    final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
    expect(body['event_name'], isNot(anyOf(
      'notification_clicked', 'push_clicked', 'bell_clicked', 'notification_tapped',
    )));
  });

  group('maybeEmitForDeepLink gating', () {
    test('fires for a Campaign C destination that resolved to a real deep-link route', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        route: '/kundali/overview',
        payload: {'campaign_id': 'c1'},
      );
      DestinationOpenedProducer.maybeEmitForDeepLink(destination, client: client());
      await Future<void>.delayed(Duration.zero);
      expect(captured, hasLength(1));
    });

    test('never fires for NONE (route null)', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        route: null,
        payload: {'campaign_id': 'c1'},
      );
      DestinationOpenedProducer.maybeEmitForDeepLink(destination, client: client());
      await Future<void>.delayed(Duration.zero);
      expect(captured, isEmpty);
    });

    test('never fires for a WEB_URL destination (route is /campaign-web, not a deep-link route)', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        route: '/campaign-web',
        payload: {'campaign_id': 'c1', 'url': 'https://jyotishasha.com/x'},
      );
      DestinationOpenedProducer.maybeEmitForDeepLink(destination, client: client());
      await Future<void>.delayed(Duration.zero);
      expect(captured, isEmpty);
    });

    test('never fires for a non-Campaign-C destination (A/B), even with a resolvable-looking route', () async {
      const destination = NotificationDispatchDestination(
        type: 'transit',
        route: '/transit-article',
        payload: {'notification_id': '1'},
      );
      DestinationOpenedProducer.maybeEmitForDeepLink(destination, client: client());
      await Future<void>.delayed(Duration.zero);
      expect(captured, isEmpty);
    });

    test('never fires for an unsupported/invalid target that fell back (route null)', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        route: null,
        payload: {'campaign_id': 'c1', 'action_target': 'NOT_REAL'},
      );
      DestinationOpenedProducer.maybeEmitForDeepLink(destination, client: client());
      await Future<void>.delayed(Duration.zero);
      expect(captured, isEmpty);
    });
  });

  test('analytics failure never throws', () async {
    const destination = NotificationDispatchDestination(
      type: 'admin_campaign',
      route: '/profile',
      payload: {'campaign_id': 'c1'},
    );
    await expectLater(
      DestinationOpenedProducer.emit(destination, client: client(statusCode: 500)),
      completes,
    );
  });

  group('Campaign C Analytics Hardening -- idempotency key', () {
    test('emit() attaches a deterministic idempotency_key derived from notification_id', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        route: '/reports',
        payload: {'campaign_id': 'c1', 'notification_id': 'exec-123', 'slot': 'general'},
      );
      await DestinationOpenedProducer.emit(destination, client: client());
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['idempotency_key'], 'destination_opened_exec-123');
    });

    test('re-dispatching the SAME destination produces the IDENTICAL idempotency_key '
        '(what lets a duplicate maybeEmitForDeepLink call collapse server-side)', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        route: '/kundali/overview',
        payload: {'campaign_id': 'c1', 'notification_id': 'exec-123'},
      );
      final c = client();
      await DestinationOpenedProducer.emit(destination, client: c);
      await DestinationOpenedProducer.emit(destination, client: c);
      expect(captured, hasLength(2));
      final key1 = (jsonDecode(captured[0].body) as Map<String, dynamic>)['idempotency_key'];
      final key2 = (jsonDecode(captured[1].body) as Map<String, dynamic>)['idempotency_key'];
      expect(key1, key2);
    });

    test('a DIFFERENT notification_id produces a DIFFERENT idempotency_key '
        '(a different campaign notification remains independently countable)', () async {
      const destinationA = NotificationDispatchDestination(
        type: 'admin_campaign',
        payload: {'campaign_id': 'c1', 'notification_id': 'exec-A'},
      );
      const destinationB = NotificationDispatchDestination(
        type: 'admin_campaign',
        payload: {'campaign_id': 'c1', 'notification_id': 'exec-B'},
      );
      final c = client();
      await DestinationOpenedProducer.emit(destinationA, client: c);
      await DestinationOpenedProducer.emit(destinationB, client: c);
      final keyA = (jsonDecode(captured[0].body) as Map<String, dynamic>)['idempotency_key'];
      final keyB = (jsonDecode(captured[1].body) as Map<String, dynamic>)['idempotency_key'];
      expect(keyA, isNot(keyB));
    });

    test('no notification_id in the payload -> no idempotency_key sent (event still recorded)', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        payload: {'campaign_id': 'c1'},
      );
      await DestinationOpenedProducer.emit(destination, client: client());
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body.containsKey('idempotency_key'), isFalse);
    });

    test('the idempotency_key never contains a colon or any character outside '
        '[A-Za-z0-9_-] (the backend\'s own idempotency_key charset contract)', () async {
      const destination = NotificationDispatchDestination(
        type: 'admin_campaign',
        payload: {'campaign_id': 'c1', 'notification_id': '3f9a2b1c-aaaa-bbbb-cccc-111122223333'},
      );
      await DestinationOpenedProducer.emit(destination, client: client());
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      final key = body['idempotency_key'] as String;
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(key), isTrue);
    });
  });
}
