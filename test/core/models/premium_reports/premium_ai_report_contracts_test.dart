import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/models/premium_reports/premium_ai_report_contracts.dart';

void main() {
  group('PremiumAiReportResult', () {
    test('success() carries content and reports isSuccess', () {
      final result = PremiumAiReportResult.success('some report text');

      expect(result.isSuccess, isTrue);
      expect(result.content, 'some report text');
      expect(result.errorCode, isNull);
      expect(result.isEntitlementDenied, isFalse);
    });

    test('failure() with trial_expired is entitlement-denied', () {
      final result = PremiumAiReportResult.failure(
        errorCode: 'trial_expired',
        errorMessage: 'Your trial has ended.',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isEntitlementDenied, isTrue);
    });

    test('failure() with subscription_required is entitlement-denied', () {
      final result = PremiumAiReportResult.failure(
        errorCode: 'subscription_required',
      );

      expect(result.isEntitlementDenied, isTrue);
    });

    test('failure() with an unrelated error code is not entitlement-denied', () {
      final result = PremiumAiReportResult.failure(
        errorCode: 'unknown_segment',
        errorMessage: 'Segment not supported.',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isEntitlementDenied, isFalse);
    });
  });
}
