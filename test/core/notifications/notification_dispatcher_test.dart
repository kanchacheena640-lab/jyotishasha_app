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

  // N6 -- Campaign C (ADMIN_CAMPAIGN). Both on-the-wire shapes are
  // exercised: the Bell's own `campaign_action` (fromNotificationCenterItem)
  // and FCM's flat `action_type`/`action_target`/`action_parameters`
  // (parse), proving both normalize to the identical destination shape.
  group('NotificationDispatcher -- Campaign C (ADMIN_CAMPAIGN)', () {
    Map<String, dynamic> bellItem({
      required String id,
      required Map<String, dynamic> action,
      String? campaignId,
      String? executionId,
      String title = 'Diwali Offer',
      String body = 'Special offer inside',
    }) => {
      'id': id,
      'source': 'ADMIN_CAMPAIGN',
      'title': title,
      'body': body,
      'campaign_action': action,
      if (campaignId != null) 'campaign_id': campaignId,
      if (executionId != null) 'execution_id': executionId,
      'is_read': false,
    };

    RemoteMessage fcmMessage({
      required Map<String, String> action,
      String? campaignId,
      String? executionId,
      String title = 'Diwali Offer',
      String body = 'Special offer inside',
    }) => RemoteMessage(
      notification: RemoteNotification(title: title, body: body),
      data: {
        'contract_version': '1',
        'source': 'ADMIN_CAMPAIGN',
        if (campaignId != null) 'campaign_id': campaignId,
        if (executionId != null) 'execution_id': executionId,
        ...action,
      },
    );

    for (final target in [
      'ASK_NOW',
      'KUNDALI',
      'REPORTS',
      'SUBSCRIPTION',
      'PROFILE',
      'DASHBOARD',
    ]) {
      final expectedRoute = {
        'ASK_NOW': '/asknow',
        'KUNDALI': '/kundali/overview',
        'REPORTS': '/reports',
        'SUBSCRIPTION': '/subscription',
        'PROFILE': '/profile',
        'DASHBOARD': '/dashboard',
      }[target]!;

      test('Bell APP_DEEP_LINK $target resolves to $expectedRoute', () {
        final destination = NotificationDispatcher.fromNotificationCenterItem(
          bellItem(
            id: 'cc:1',
            action: {'type': 'APP_DEEP_LINK', 'target': target, 'parameters': {}},
            campaignId: 'camp-1',
            executionId: 'exec-1',
          ),
        );
        expect(destination.type, NotificationDispatcher.campaignType);
        expect(destination.route, expectedRoute);
        expect(destination.payload['campaign_id'], 'camp-1');
      });

      test('Push APP_DEEP_LINK $target resolves to $expectedRoute', () {
        final destination = NotificationDispatcher.parse(
          fcmMessage(
            action: {'action_type': 'APP_DEEP_LINK', 'action_target': target},
            campaignId: 'camp-1',
            executionId: 'exec-1',
          ),
        );
        expect(destination.type, NotificationDispatcher.campaignType);
        expect(destination.route, expectedRoute);
      });
    }

    test('WEB_URL with a usable url resolves to the campaign-web route and carries the url', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem(
        bellItem(
          id: 'cc:2',
          action: {
            'type': 'WEB_URL',
            'target': 'HTTPS_URL',
            'parameters': {'url': 'https://jyotishasha.com/some/article'},
          },
        ),
      );
      expect(destination.route, '/campaign-web');
      expect(destination.payload['url'], 'https://jyotishasha.com/some/article');
    });

    test('WEB_URL with no url falls back to Notification Detail (route null)', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem(
        bellItem(id: 'cc:3', action: {'type': 'WEB_URL', 'target': 'HTTPS_URL', 'parameters': {}}),
      );
      expect(destination.route, isNull);
    });

    // P3E -- client-side defense-in-depth: an unapproved-domain url must
    // fail closed to Notification Detail EXACTLY like a missing url does
    // today, on BOTH entry points. Prior to this task, the dispatcher
    // only checked "is there a url at all", trusting the backend's own
    // composer-time validation completely; this proves the SECOND,
    // independent client-side check (CampaignUrlPolicy) is actually wired
    // into route resolution, not merely defined and unused.
    test(
      'Bell WEB_URL with an unapproved-domain url fails closed -- never '
      'resolves to the campaign-web route',
      () {
        final destination = NotificationDispatcher.fromNotificationCenterItem(
          bellItem(
            id: 'cc:3b',
            action: {
              'type': 'WEB_URL',
              'target': 'HTTPS_URL',
              'parameters': {'url': 'https://eviljyotishasha.com/phish'},
            },
          ),
        );
        expect(destination.route, isNull);
      },
    );

    test(
      'Push (real FCM) WEB_URL with an unapproved-domain url fails closed '
      '-- never resolves to the campaign-web route',
      () {
        final destination = NotificationDispatcher.parse(
          fcmMessage(
            action: {
              'action_type': 'WEB_URL',
              'action_target': 'HTTPS_URL',
              'action_parameters':
                  '{"url":"https://jyotishasha.com.evil.example/phish"}',
            },
          ),
        );
        expect(destination.route, isNull);
      },
    );

    // P2 -- real FCM `data` is always Map<String, String> on the wire, so a
    // real WEB_URL push's `action_parameters` arrives JSON-ENCODED AS A
    // STRING, never a native Map -- unlike the Bell/API tests immediately
    // above, which exercise fromNotificationCenterItem (a real JSON body,
    // where a nested object already decodes to a Map before this code
    // ever sees it). These tests exercise `parse()` (the actual RemoteMessage
    // / real-push path) with the real wire shape, using the existing
    // `fcmMessage()` helper (`Map<String, String>` data, exactly like a
    // physical device receives).
    group('P2 -- WEB_URL action_parameters as a real-FCM JSON string', () {
      test(
        'valid WEB_URL JSON-string action_parameters resolves to the '
        'campaign-web route and carries the url -- the exact P1 finding',
        () {
          final destination = NotificationDispatcher.parse(
            fcmMessage(
              action: {
                'action_type': 'WEB_URL',
                'action_target': 'HTTPS_URL',
                'action_parameters':
                    '{"url":"https://jyotishasha.com/some/article"}',
              },
            ),
          );
          expect(destination.type, NotificationDispatcher.campaignType);
          expect(destination.route, '/campaign-web');
          expect(
            destination.payload['url'],
            'https://jyotishasha.com/some/article',
          );
        },
      );

      test(
        'a native Map action_parameters (not a String) still works exactly '
        'as before -- existing behavior preserved',
        () {
          final message = RemoteMessage(
            notification: const RemoteNotification(
              title: 'Diwali Offer',
              body: 'Special offer inside',
            ),
            data: {
              'source': 'ADMIN_CAMPAIGN',
              'action_type': 'WEB_URL',
              'action_target': 'HTTPS_URL',
              // Deliberately a real Dart Map, not a String -- proves the
              // pre-existing "already a Map" branch is untouched.
              'action_parameters': {
                'url': 'https://jyotishasha.com/already-a-map',
              },
            },
          );
          final destination = NotificationDispatcher.parse(message);
          expect(destination.route, '/campaign-web');
          expect(
            destination.payload['url'],
            'https://jyotishasha.com/already-a-map',
          );
        },
      );

      test(
        'malformed JSON string fails closed to Notification Detail -- '
        'never throws',
        () {
          final destination = NotificationDispatcher.parse(
            fcmMessage(
              action: {
                'action_type': 'WEB_URL',
                'action_target': 'HTTPS_URL',
                'action_parameters': '{"url": not-valid-json',
              },
            ),
          );
          expect(destination.route, isNull);
          expect(destination.type, NotificationDispatcher.campaignType);
        },
      );

      test(
        'a JSON array (valid JSON, wrong shape) never becomes valid '
        'parameters -- fails closed',
        () {
          final destination = NotificationDispatcher.parse(
            fcmMessage(
              action: {
                'action_type': 'WEB_URL',
                'action_target': 'HTTPS_URL',
                'action_parameters': '["https://jyotishasha.com/article"]',
              },
            ),
          );
          expect(destination.route, isNull);
        },
      );

      test(
        'a JSON scalar (valid JSON, wrong shape) never becomes valid '
        'parameters -- fails closed',
        () {
          final destination = NotificationDispatcher.parse(
            fcmMessage(
              action: {
                'action_type': 'WEB_URL',
                'action_target': 'HTTPS_URL',
                'action_parameters': '"https://jyotishasha.com/article"',
              },
            ),
          );
          expect(destination.route, isNull);
        },
      );

      test(
        'action_parameters missing entirely fails safely -- same as before '
        'this fix',
        () {
          final destination = NotificationDispatcher.parse(
            fcmMessage(
              action: {
                'action_type': 'WEB_URL',
                'action_target': 'HTTPS_URL',
              },
            ),
          );
          expect(destination.route, isNull);
          expect(destination.type, NotificationDispatcher.campaignType);
        },
      );

      test(
        'an empty-string action_parameters fails safely, exactly like an '
        'empty Map does today',
        () {
          final destination = NotificationDispatcher.parse(
            fcmMessage(
              action: {
                'action_type': 'WEB_URL',
                'action_target': 'HTTPS_URL',
                'action_parameters': '',
              },
            ),
          );
          expect(destination.route, isNull);
        },
      );

      test(
        'an unapproved/unsafe destination -- WEB_URL with an empty url '
        'inside otherwise-valid JSON -- remains blocked (an empty string '
        'fails both the presence check and CampaignUrlPolicy.isApproved; '
        'see the dedicated "unapproved-domain url" tests above for the '
        'P3E client-side allowlist check specifically)',
        () {
          final destination = NotificationDispatcher.parse(
            fcmMessage(
              action: {
                'action_type': 'WEB_URL',
                'action_target': 'HTTPS_URL',
                'action_parameters': '{"url":""}',
              },
            ),
          );
          expect(destination.route, isNull);
        },
      );

      test(
        'never throws regardless of action_parameters shape -- parity '
        'check across every malformed/unexpected shape',
        () {
          for (final badParams in [
            '{invalid',
            '["a","b"]',
            '42',
            'null',
            'true',
            '   ',
          ]) {
            expect(
              () => NotificationDispatcher.parse(
                fcmMessage(
                  action: {
                    'action_type': 'WEB_URL',
                    'action_target': 'HTTPS_URL',
                    'action_parameters': badParams,
                  },
                ),
              ),
              returnsNormally,
            );
          }
        },
      );
    });

    test('NONE never resolves to a route -- falls back to Notification Detail', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem(
        bellItem(id: 'cc:4', action: {'type': 'NONE', 'target': null, 'parameters': {}}),
      );
      expect(destination.route, isNull);
      expect(destination.type, NotificationDispatcher.campaignType);
    });

    test('an unsupported/invalid APP_DEEP_LINK target falls back to Notification Detail, never a widened route', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem(
        bellItem(
          id: 'cc:5',
          action: {'type': 'APP_DEEP_LINK', 'target': 'SOMETHING_NOT_IN_THE_REGISTRY', 'parameters': {}},
        ),
      );
      expect(destination.route, isNull);
    });

    test('X1 and X2 -- identical title/body/action but different campaign_id -- remain distinct in payload', () {
      final x1 = NotificationDispatcher.fromNotificationCenterItem(
        bellItem(
          id: 'cc:6',
          action: {'type': 'APP_DEEP_LINK', 'target': 'REPORTS', 'parameters': {}},
          campaignId: 'campaign-x1',
        ),
      );
      final x2 = NotificationDispatcher.fromNotificationCenterItem(
        bellItem(
          id: 'cc:7',
          action: {'type': 'APP_DEEP_LINK', 'target': 'REPORTS', 'parameters': {}},
          campaignId: 'campaign-x2',
        ),
      );
      expect(x1.payload['campaign_id'], 'campaign-x1');
      expect(x2.payload['campaign_id'], 'campaign-x2');
      expect(x1.payload['campaign_id'] == x2.payload['campaign_id'], isFalse);
    });

    test('Hindi/Unicode and long title/body pass through unmodified', () {
      final longBody = 'लंबा संदेश ' * 40;
      final destination = NotificationDispatcher.fromNotificationCenterItem(
        bellItem(
          id: 'cc:8',
          action: {'type': 'NONE', 'target': null, 'parameters': {}},
          title: 'हिन्दी में शीर्षक — Diwali Offer 🎉',
          body: longBody,
        ),
      );
      expect(destination.title, 'हिन्दी में शीर्षक — Diwali Offer 🎉');
      // _stringOrNull trims (an established, existing convention shared
      // by every other field this dispatcher extracts) -- content itself
      // is otherwise passed through byte-for-byte.
      expect(destination.body, longBody.trim());
    });

    test('a malformed campaign_action (not a Map) fails safe, never throws', () {
      final destination = NotificationDispatcher.fromNotificationCenterItem({
        'id': 'cc:9',
        'source': 'ADMIN_CAMPAIGN',
        'title': 't',
        'body': 'b',
        'campaign_action': 'not-a-map',
      });
      expect(destination.route, isNull);
      expect(destination.type, NotificationDispatcher.campaignType);
    });
  });
}
