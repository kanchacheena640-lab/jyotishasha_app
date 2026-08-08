import '../models/reports/report_contracts.dart';

/// Purpose: owns report catalog access and report-generation requests.
///
/// Responsibilities: load typed catalog entries and submit standard or
/// relationship report requests with their current wire-compatible contracts.
///
/// Excluded responsibilities: billing lifecycle, form/UI state, navigation,
/// asset/HTTP implementation details, and Love result presentation.
///
/// Future implementation owner: ESR-003 report repository implementation.
abstract interface class ReportRepository {
  Future<List<ReportCatalogItem>> getCatalog({required String language});

  Future<ReportGenerationOutcome> requestReport(
    ReportGenerationRequest request,
  );

  Future<ReportGenerationOutcome> requestRelationshipReport(
    RelationshipReportRequest request,
  );
}
