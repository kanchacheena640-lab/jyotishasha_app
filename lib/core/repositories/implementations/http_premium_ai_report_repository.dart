import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/services/backend_auth_service.dart';

import '../../models/premium_reports/premium_ai_report_contracts.dart';
import '../premium_ai_report_repository.dart';

/// Same auth/networking pattern as [SubscriptionProvider] — reuses
/// [BackendAuthService.getBackendToken] (no new auth mechanism) and the
/// same backend base URL every other repository in this app already
/// hardcodes.
final class HttpPremiumAiReportRepository implements PremiumAiReportRepository {
  HttpPremiumAiReportRepository({http.Client? client})
    : _client = client ?? http.Client();

  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';
  final http.Client _client;

  @override
  Future<PremiumAiReportResult> getReport({
    required String segment,
    required String reportType,
    required String language,
  }) async {
    final token = await _requireBackendToken();
    if (token == null) {
      return PremiumAiReportResult.failure(errorCode: 'auth_failed');
    }

    final uri = Uri.parse('$_baseUrl/api/premium-report').replace(
      queryParameters: {
        'segment': segment,
        'report_type': reportType,
        'language': language,
      },
    );

    try {
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Backend's own error contract verbatim
        // (`modules/premium_report/exceptions.py`): `{"error": code,
        // "message": text}`.
        return PremiumAiReportResult.failure(
          errorCode: body['error']?.toString() ?? 'internal_error',
          errorMessage: body['message']?.toString(),
        );
      }

      final content = body['content'];
      return PremiumAiReportResult.success(
        content is String ? content : jsonEncode(content),
      );
    } catch (e) {
      return PremiumAiReportResult.failure(
        errorCode: 'network_error',
        errorMessage: e.toString(),
      );
    }
  }

  Future<String?> _requireBackendToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return BackendAuthService.getBackendToken(user.uid);
  }
}
