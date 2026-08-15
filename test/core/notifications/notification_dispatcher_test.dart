import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';

void main() {
  group('NotificationDispatcher.parse', () {
    test('extracts type, event_id, and route from a well-formed payload', () {
      final message = RemoteMessage(
        data: const {
          'type': 'transit_alert',
          'event_id': '482',
          'planet': 'Saturn',
          'house': '10',
          'route': '/darshan',
        },
      );

      final destination = NotificationDispatcher.parse(message);

      expect(destination.type, 'transit_alert');
      expect(destination.eventId, '482');
      expect(destination.route, '/darshan');
      expect(destination.payload['planet'], 'Saturn');
      expect(destination.payload['house'], '10');
    });

    test('route is null when absent from the payload', () {
      final message = RemoteMessage(
        data: const {'type': 'panchang_reminder', 'event_id': '10'},
      );

      final destination = NotificationDispatcher.parse(message);

      expect(destination.route, isNull);
      expect(destination.type, 'panchang_reminder');
    });

    test('empty data payload fails safe instead of throwing', () {
      const message = RemoteMessage(data: {});

      final destination = NotificationDispatcher.parse(message);

      expect(destination.type, isNull);
      expect(destination.eventId, isNull);
      expect(destination.route, isNull);
      expect(destination.payload, isEmpty);
    });

    test('blank string fields are normalized to null, not empty strings', () {
      final message = RemoteMessage(data: const {'type': '   ', 'route': ''});

      final destination = NotificationDispatcher.parse(message);

      expect(destination.type, isNull);
      expect(destination.route, isNull);
    });

    // N1 — title/body come from RemoteMessage.notification, a different
    // part of the message than `data`.
    test('extracts title/body from RemoteMessage.notification, not data', () {
      final message = RemoteMessage(
        notification: const RemoteNotification(
          title: 'Mood Shift',
          body: 'Your emotional outlook may be shifting today.',
        ),
        data: const {'type': 'alert', 'event_id': 'mood_positive'},
      );

      final destination = NotificationDispatcher.parse(message);

      expect(destination.title, 'Mood Shift');
      expect(destination.body, 'Your emotional outlook may be shifting today.');
      expect(destination.type, 'alert');
      expect(destination.eventId, 'mood_positive');
    });

    test('title/body are null when RemoteMessage.notification is absent', () {
      final message = RemoteMessage(data: const {'type': 'event'});

      final destination = NotificationDispatcher.parse(message);

      expect(destination.title, isNull);
      expect(destination.body, isNull);
    });

    // N1 — Alerts semantic ids and Dasha composite ids must survive parsing
    // as plain, unmangled strings (never coerced toward a number).
    test('preserves a Dasha composite event_id verbatim', () {
      final message = RemoteMessage(
        data: const {
          'type': 'dasha_pre',
          'event_id': 'dasha_pre_42_Venus_Moon',
          'mahadasha': 'Venus',
          'antardasha': 'Moon',
        },
      );

      final destination = NotificationDispatcher.parse(message);

      expect(destination.type, 'dasha_pre');
      expect(destination.eventId, 'dasha_pre_42_Venus_Moon');
      expect(destination.payload['mahadasha'], 'Venus');
      expect(destination.payload['antardasha'], 'Moon');
    });
  });

  group('NotificationDispatcher.fromNotificationCenterItem', () {
    test('extracts the identical fields parse() extracts for FCM, from the '
        'Notification Center backend JSON shape', () {
      final item = {
        'id': 501,
        'title': 'Saturn transit alert',
        'body': 'Saturn is entering your 10th house',
        'is_read': false,
        'data': {
          'type': 'transit_alert',
          'event_id': '482',
          'planet': 'Saturn',
          'house': '10',
          'route': '/darshan',
        },
      };

      final destination = NotificationDispatcher.fromNotificationCenterItem(
        item,
      );

      expect(destination.type, 'transit_alert');
      expect(destination.eventId, '482');
      expect(destination.route, '/darshan');
      expect(destination.payload['planet'], 'Saturn');
      expect(destination.payload['house'], '10');
    });

    test('missing data field fails safe instead of throwing', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem({
        'id': 1,
        'title': 'No data field',
      });

      expect(destination.type, isNull);
      expect(destination.eventId, isNull);
      expect(destination.route, isNull);
      expect(destination.payload, isEmpty);
    });

    test(
      'non-Map item (null, String, List) fails safe instead of throwing',
      () {
        expect(
          NotificationDispatcher.fromNotificationCenterItem(null).payload,
          isEmpty,
        );
        expect(
          NotificationDispatcher.fromNotificationCenterItem(
            'not a map',
          ).payload,
          isEmpty,
        );
        expect(
          NotificationDispatcher.fromNotificationCenterItem([1, 2, 3]).payload,
          isEmpty,
        );
      },
    );

    test('data field that is not a Map fails safe instead of throwing', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem({
        'id': 1,
        'data': 'not-a-map',
      });

      expect(destination.type, isNull);
      expect(destination.payload, isEmpty);
    });

    // N1 — Bell items carry title/body as siblings of `data` (matching
    // AppNotification.toJson()'s shape), not nested inside it.
    test('extracts title/body as siblings of data, not from inside it', () {
      final item = {
        'id': 501,
        'title': 'Financial Signal',
        'body': 'A financial signal is active for you today.',
        'is_read': false,
        'data': {
          'type': 'alert',
          'event_id': 'financial_gain_opportunity',
          'category': 'financial',
          'severity': 'medium',
        },
      };

      final destination = NotificationDispatcher.fromNotificationCenterItem(
        item,
      );

      expect(destination.title, 'Financial Signal');
      expect(destination.body, 'A financial signal is active for you today.');
      expect(destination.type, 'alert');
      expect(destination.eventId, 'financial_gain_opportunity');
      expect(destination.payload['category'], 'financial');
      expect(destination.payload['severity'], 'medium');
    });

    test('missing title/body fields are null, not empty strings', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem({
        'id': 1,
        'data': {'type': 'event', 'event_id': '62'},
      });

      expect(destination.title, isNull);
      expect(destination.body, isNull);
    });
  });
}
