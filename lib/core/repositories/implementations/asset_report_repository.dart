import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../../services/report_service.dart';
import '../../models/reports/report_contracts.dart';
import '../report_repository.dart';

final class AssetReportRepository implements ReportRepository {
  AssetReportRepository({AssetBundle? bundle, ReportService? reportService})
    : _bundle = bundle ?? rootBundle,
      _reportService = reportService ?? ReportService();

  final AssetBundle _bundle;
  final ReportService _reportService;

  @override
  Future<List<ReportCatalogItem>> getCatalog({required String language}) async {
    final english = _decodeList(
      await _bundle.loadString('assets/data/reports.json'),
    );
    if (language.toLowerCase() == 'hi') {
      try {
        final hindi = _decodeList(
          await _bundle.loadString('assets/data/reports_hi.json'),
        );
        for (
          var index = 0;
          index < math.min(english.length, hindi.length);
          index++
        ) {
          final localized = hindi[index];
          for (final key in const [
            'title_hi',
            'description_hi',
            'short_description_hi',
            'fullDescription_hi',
            'category_hi',
          ]) {
            if (localized[key] != null) english[index][key] = localized[key];
          }
        }
      } catch (_) {
        // Preserve the current English-catalog fallback.
      }
    }
    return english.map(ReportCatalogItem.fromJson).toList(growable: false);
  }

  @override
  Future<ReportGenerationOutcome> requestReport(
    ReportGenerationRequest request,
  ) async {
    final result = await _send(request, const {});
    return ReportGenerationOutcome(
      success: result.success,
      errorCode: result.errorCode,
    );
  }

  @override
  Future<ReportGenerationOutcome> requestRelationshipReport(
    RelationshipReportRequest request,
  ) async {
    final report = request.report ?? const ReportGenerationRequest();
    final result = await _send(report, {
      'boy_is_user': request.boyIsUser,
      'partner': request.partner?.toJson(),
    });
    return ReportGenerationOutcome(
      success: result.success,
      errorCode: result.errorCode,
    );
  }

  Future<ReportConfirmResult> _send(
    ReportGenerationRequest request,
    Map<String, dynamic> additionalFields,
  ) => _reportService.sendReportRequest(
    name: request.name ?? '',
    email: request.email ?? '',
    birthDetails: {
      'product': request.product,
      'dob': request.birthDetails?.dateOfBirth,
      'tob': request.birthDetails?.timeOfBirth,
      'pob': request.birthDetails?.placeOfBirth,
      'latitude': request.birthDetails?.latitude,
      'longitude': request.birthDetails?.longitude,
      'phone': request.phone,
      'language': request.language,
      'user_id': request.userId,
      ...additionalFields,
    },
    purchaseToken: request.purchaseToken ?? '',
    productId: request.productId,
    orderId: request.orderId,
  );

  static List<Map<String, dynamic>> _decodeList(String source) =>
      (jsonDecode(source) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
}
