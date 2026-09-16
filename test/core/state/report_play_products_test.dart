import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/constants/report_play_products.dart';

void main() {
  test('relationship report maps to its INR 199 Play product', () {
    expect(
      ReportPlayProducts.forReport('relationship_future_report'),
      'relationship_report199',
    );
  });

  test('standard reports map to reports51', () {
    expect(ReportPlayProducts.forReport('career_report'), 'reports51');
    expect(ReportPlayProducts.forReport('financial_report'), 'reports51');
  });
}
