/// Authoritative Google Play one-time product policy for paid reports.
abstract final class ReportPlayProducts {
  static const String standard = 'reports51';
  static const String relationship = 'relationship_report199';
  static const String relationshipReportSlug = 'relationship_future_report';

  static String forReport(String reportSlug) =>
      reportSlug == relationshipReportSlug ? relationship : standard;

  static bool isSupported(String productId) =>
      productId == standard || productId == relationship;
}
