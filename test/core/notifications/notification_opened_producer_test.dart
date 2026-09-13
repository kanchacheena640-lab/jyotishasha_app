import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/notifications/destination_opened_producer.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/notifications/notification_opened_producer.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

class _FakeIdentityPort implements CurrentUserIdentityPort {
  const _FakeIdentityPort();
  @override
  String? get currentFirebaseUid => 'test-uid';
}

/// Phase 5B foundation tests -- NotificationOpenedProducer.
///
/// This tests the producer's OWN logic directly (payload -> context
/// extraction, event shape) with a fully test-controlled
/// ActivityEventClient -- no real Firebase/backend/network. The seam
/// contract itself (this is only ever called from handleNotificationTap,
/// which is only reached by onMessageOpenedApp/getInitialMessage, never
/// onMessage) is a structural fact of main.dart verified by code
/// inspection (see the final report), not re-derivable from a unit test
/// of this class alone.
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

  test(
    'a background-tap-shaped destination (onMessageOpenedApp path) -> '
    'exactly one notification_opened',
    () async {
      const destination = NotificationDispatchDestination(
        type: 'festival',
        eventId: '42',
        payload: {'notification_id': '42', 'slot': 'general'},
      );
      await NotificationOpenedProducer.emit(destination, client: client());
      expect(captured, hasLength(1));
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['event_name'], 'notification_opened');
    },
  );

  test(
    'a cold-start-tap-shaped destination (getInitialMessage path) -> '
    'exactly one notification_opened',
    () async {
      const destination = NotificationDispatchDestination(
        type: 'ekadashi',
        payload: {'notification_id': '7'},
      );
      await NotificationOpenedProducer.emit(destination, client: client());
      expect(captured, hasLength(1));
    },
  );

  test(
    'only the three frozen notification_context keys are ever copied out '
    'of the raw payload -- everything else is left behind',
    () async {
      const destination = NotificationDispatchDestination(
        type: 'festival',
        route: '/event',
        title: 'Ganesh Chaturthi',
        body: 'A festival is today',
        payload: {
          'notification_id': '9',
          'campaign_id': 'diwali_2026',
          'slot': 'general',
          'type': 'festival',
          'event_id': '9',
          'route': '/event',
          'planet': 'Jupiter',
        },
      );
      await NotificationOpenedProducer.emit(destination, client: client());
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body.containsKey('properties'), isFalse);
      expect(body['notification_context'], {
        'notification_id': '9',
        'campaign_id': 'diwali_2026',
        'slot': 'general',
      });
      // Title/body/route/raw payload text never leaked anywhere.
      final raw = captured.single.body;
      expect(raw.contains('Ganesh Chaturthi'), isFalse);
      expect(raw.contains('A festival is today'), isFalse);
      expect(raw.contains('Jupiter'), isFalse);
    },
  );

  test(
    'notification_context is omitted entirely when no allowed key is '
    'present in the payload (never invented)',
    () async {
      const destination = NotificationDispatchDestination(
        type: 'transit',
        payload: {'planet': 'Mars', 'house': '7'},
      );
      await NotificationOpenedProducer.emit(destination, client: client());
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body.containsKey('notification_context'), isFalse);
    },
  );

  test('an empty payload (default destination) never throws', () async {
    const destination = NotificationDispatchDestination();
    await expectLater(
      NotificationOpenedProducer.emit(destination, client: client()),
      completes,
    );
    expect(captured, hasLength(1));
  });

  test(
    'analytics failure (e.g. a dropped HTTP status) never throws -- the '
    'caller (handleNotificationTap) is free to call openDestination() '
    'unconditionally right after',
    () async {
      const destination = NotificationDispatchDestination(
        payload: {'notification_id': '1'},
      );
      await expectLater(
        NotificationOpenedProducer.emit(destination, client: client(statusCode: 500)),
        completes,
      );
    },
  );

  test('no title/body/raw payload field name is ever a body key', () async {
    const destination = NotificationDispatchDestination(
      title: 't',
      body: 'b',
      route: '/r',
      payload: {'notification_id': '1'},
    );
    await NotificationOpenedProducer.emit(destination, client: client());
    final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
    for (final key in ['title', 'body', 'route', 'event_id', 'type', 'payload']) {
      expect(body.containsKey(key), isFalse);
      final ctx = body['notification_context'] as Map<String, dynamic>?;
      expect(ctx?.containsKey(key) ?? false, isFalse);
    }
  });

  group('Campaign C Analytics Hardening (P0) -- idempotency key', () {
    test('emit() attaches a deterministic idempotency_key derived from notification_id', () async {
      const destination = NotificationDispatchDestination(
        payload: {'notification_id': 'exec-123', 'campaign_id': 'c1'},
      );
      await NotificationOpenedProducer.emit(destination, client: client());
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['idempotency_key'], 'notification_opened_exec-123');
    });

    test(
      'a re-processed getInitialMessage()/onMessageOpenedApp() dispatch for the SAME '
      'notification (identical destination) produces the IDENTICAL idempotency_key -- '
      'system tray/cold-start duplicate dispatch is safe',
      () async {
        const destination = NotificationDispatchDestination(
          payload: {'notification_id': 'exec-123'},
        );
        final c = client();
        await NotificationOpenedProducer.emit(destination, client: c); // getInitialMessage()
        await NotificationOpenedProducer.emit(destination, client: c); // onMessageOpenedApp()
        expect(captured, hasLength(2));
        final key1 = (jsonDecode(captured[0].body) as Map<String, dynamic>)['idempotency_key'];
        final key2 = (jsonDecode(captured[1].body) as Map<String, dynamic>)['idempotency_key'];
        expect(key1, key2);
      },
    );

    test(
      'a Bell-tap-shaped destination for the SAME Campaign C notification '
      '(fromNotificationCenterItem\'s own execution_id) produces the SAME key a push tap '
      'would -- Bell follows the identical Campaign C identity semantics as the system tray',
      () async {
        const pushDestination = NotificationDispatchDestination(
          type: 'admin_campaign',
          payload: {'notification_id': 'campaign-exec-999', 'campaign_id': 'c1'},
        );
        const bellDestination = NotificationDispatchDestination(
          type: 'admin_campaign',
          payload: {'notification_id': 'campaign-exec-999', 'campaign_id': 'c1'},
        );
        final c = client();
        await NotificationOpenedProducer.emit(pushDestination, client: c);
        await NotificationOpenedProducer.emit(bellDestination, client: c);
        final pushKey = (jsonDecode(captured[0].body) as Map<String, dynamic>)['idempotency_key'];
        final bellKey = (jsonDecode(captured[1].body) as Map<String, dynamic>)['idempotency_key'];
        expect(pushKey, bellKey);
      },
    );

    test('a DIFFERENT campaign notification remains independently countable '
        '(different notification_id -> different idempotency_key)', () async {
      const destinationA = NotificationDispatchDestination(payload: {'notification_id': 'exec-A'});
      const destinationB = NotificationDispatchDestination(payload: {'notification_id': 'exec-B'});
      final c = client();
      await NotificationOpenedProducer.emit(destinationA, client: c);
      await NotificationOpenedProducer.emit(destinationB, client: c);
      final keyA = (jsonDecode(captured[0].body) as Map<String, dynamic>)['idempotency_key'];
      final keyB = (jsonDecode(captured[1].body) as Map<String, dynamic>)['idempotency_key'];
      expect(keyA, isNot(keyB));
    });

    test('no notification_id in the payload -> no idempotency_key sent (event still recorded, '
        'never dropped just because idempotency protection is unavailable)', () async {
      const destination = NotificationDispatchDestination(payload: {'planet': 'Mars'});
      await NotificationOpenedProducer.emit(destination, client: client());
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body.containsKey('idempotency_key'), isFalse);
    });

    test(
      'notification_opened and destination_opened MUST NOT share the same idempotency_key '
      'for the identical notification_id',
      () async {
        const destination = NotificationDispatchDestination(
          type: 'admin_campaign',
          payload: {'notification_id': 'exec-same-777', 'campaign_id': 'c1'},
        );
        final c = client();
        await NotificationOpenedProducer.emit(destination, client: c);
        await DestinationOpenedProducer.emit(destination, client: c);
        final openedKey = (jsonDecode(captured[0].body) as Map<String, dynamic>)['idempotency_key'];
        final destKey = (jsonDecode(captured[1].body) as Map<String, dynamic>)['idempotency_key'];
        expect(openedKey, isNot(destKey));
        expect(openedKey, 'notification_opened_exec-same-777');
        expect(destKey, 'destination_opened_exec-same-777');
      },
    );
  });
}
