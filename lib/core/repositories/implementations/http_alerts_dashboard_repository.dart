import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/services/backend_auth_service.dart';

import '../../models/alerts/alerts_dashboard_contracts.dart';
import '../alerts_dashboard_repository.dart';

/// Same auth/networking pattern as
/// [HttpPremiumAiReportRepository]/[SubscriptionProvider] — reuses
/// [BackendAuthService.getBackendToken] (no new auth mechanism) and the
/// same backend base URL every other repository in this app already
/// hardcodes.
final class HttpAlertsDashboardRepository implements AlertsDashboardRepository {
  HttpAlertsDashboardRepository({http.Client? client})
    : _client = client ?? http.Client();

  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';
  final http.Client _client;

  @override
  Future<AlertsDashboardResult> getCurrentAlerts() async {
    final token = await _requireBackendToken();
    if (token == null) {
      return AlertsDashboardResult.failure(status: AlertsDashboardStatus.authFailed);
    }

    final uri = Uri.parse('$_baseUrl/api/alerts/current');

    try {
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final rawAlerts = body['alerts'];
        final alerts = rawAlerts is List
            ? rawAlerts
                  .whereType<Map<String, dynamic>>()
                  .map(AlertItem.fromJson)
                  .toList()
            : <AlertItem>[];
        return AlertsDashboardResult.success(alerts);
      }

      // Backend's own status contract verbatim
      // (`routes/routes_alerts_dashboard.py`): {"status": ..., "message": ...}.
      final status = _statusFromBackend(body['status']?.toString());
      return AlertsDashboardResult.failure(
        status: status,
        message: body['message']?.toString(),
      );
    } catch (e) {
      return AlertsDashboardResult.failure(
        status: AlertsDashboardStatus.networkError,
        message: e.toString(),
      );
    }
  }

  AlertsDashboardStatus _statusFromBackend(String? raw) {
    switch (raw) {
      case 'locked':
        return AlertsDashboardStatus.locked;
      case 'no_profile':
        return AlertsDashboardStatus.noProfile;
      case 'forbidden':
      case 'invalid_request':
        return AlertsDashboardStatus.forbidden;
      default:
        return AlertsDashboardStatus.error;
    }
  }

  Future<String?> _requireBackendToken() async {
    final User? user;
    try {
      // Same defensive pattern as HttpPremiumAiReportRepository -- a
      // headless widget-test navigation path with no injectable fake
      // repository would otherwise throw here instead of surfacing a
      // clean "no token available" failure.
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
    if (user == null) return null;
    return BackendAuthService.getBackendToken(user.uid);
  }
}
