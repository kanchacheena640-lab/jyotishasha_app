import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/models/alerts/alerts_dashboard_contracts.dart';

void main() {
  group('AlertItem.fromJson (AI-Written Personalized Alert Content addition)', () {
    test('parses "action" when the backend supplies one', () {
      final item = AlertItem.fromJson({
        'alert_id': 1,
        'event_id': 'opportunity_window',
        'title': 'Opportunity Window',
        'message': 'A supportive window is opening for career recognition.',
        'category': 'timing',
        'severity': 'MEDIUM',
        'priority': 'high',
        'valid_from': '2026-08-14',
        'valid_until': '2026-08-16',
        'action': 'Send that proposal or application today.',
      });

      expect(item.action, 'Send that proposal or application today.');
    });

    test('action defaults to null when the backend omits the field entirely '
        '(a plain template-fallback alert)', () {
      final item = AlertItem.fromJson({
        'alert_id': 2,
        'event_id': 'financial_gain_opportunity',
        'title': 'Financial Gain Opportunity',
        'message': 'A financial signal is active for you today.',
        'category': 'financial',
        'severity': 'HIGH',
        'priority': 'high',
        'valid_from': '2026-08-14',
        'valid_until': '2026-08-16',
      });

      expect(item.action, isNull);
    });

    test('every other existing field is unaffected by this addition', () {
      final item = AlertItem.fromJson({
        'alert_id': 3,
        'event_id': 'travel_opportunity',
        'title': 'Travel Opportunity',
        'message': 'A travel-related signal is active for you today.',
        'category': 'travel',
        'severity': 'MEDIUM',
        'priority': 'medium',
        'valid_from': '2026-08-14',
        'valid_until': '2026-08-16',
      });

      expect(item.alertId, 3);
      expect(item.eventId, 'travel_opportunity');
      expect(item.title, 'Travel Opportunity');
      expect(item.category, 'travel');
      expect(item.severity, 'MEDIUM');
      expect(item.priority, 'medium');
      expect(item.validFrom, '2026-08-14');
      expect(item.validUntil, '2026-08-16');
    });
  });
}
