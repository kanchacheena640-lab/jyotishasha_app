import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/notifications/notification_contracts.dart';
import '../notification_repository.dart';

final class BackendNotificationRepository implements NotificationRepository {
  BackendNotificationRepository({
    http.Client? client,
    required Future<String> Function() backendTokenProvider,
    required Future<String> Function() idTokenProvider,
  }) : _client = client ?? http.Client(),
       _backendTokenProvider = backendTokenProvider,
       _idTokenProvider = idTokenProvider;

  static const String _baseUrl = "https://jyotishasha-backend.onrender.com";

  static final Uri _registrationEndpoint = Uri.parse(
    '$_baseUrl/api/users/update-fcm',
  );

  final http.Client _client;
  final Future<String> Function() _backendTokenProvider;
  final Future<String> Function() _idTokenProvider;

  @override
  Future<UnreadCountResponse> getUnreadCount() async {
    final token = await _backendTokenProvider();

    // Release-gate fix (P0): bounds a previously-unbounded request; a
    // TimeoutException propagates to this method's caller exactly like
    // the existing thrown Exceptions below already do.
    final response = await _client
        .get(
          Uri.parse("$_baseUrl/api/user-notifications/unread-count"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Notification API error ${response.statusCode}');
    }

    return UnreadCountResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<NotificationListResponse> getNotifications() async {
    final token = await _backendTokenProvider();

    // Release-gate fix (P0): see getUnreadCount's identical comment above.
    final response = await _client
        .get(
          Uri.parse("$_baseUrl/api/user-notifications"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Notification API error ${response.statusCode}');
    }

    return NotificationListResponse.fromJson(
      jsonDecode(response.body),
    );
  }

  @override
  Future<void> markAsRead(MarkNotificationReadRequest request) async {
    final notificationId = request.notificationId;
    if (notificationId == null) {
      throw ArgumentError.value(notificationId, 'notificationId');
    }

    final token = await _backendTokenProvider();

    // Release-gate fix (P0): see getUnreadCount's identical comment above.
    final response = await _client
        .post(
          Uri.parse("$_baseUrl/api/user-notifications/mark-read"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Notification API error ${response.statusCode}');
    }
  }

  @override
  Future<void> registerDeviceToken(String token) async {
    final idToken = await _idTokenProvider();

    // Release-gate fix (P0): see getUnreadCount's identical comment above
    // -- this call gates FCM token sync, so an unbounded hang here could
    // previously stall whatever awaited registerDeviceToken() forever.
    final response = await _client
        .post(
          _registrationEndpoint,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fcm_token': token}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'FCM registration error ${response.statusCode}: ${response.body}',
      );
    }

    // Defensive body validation: honor an explicit ok/success: false flag
    // if the backend sends one (matching the {"ok": ...} shape already
    // used elsewhere by this backend, e.g. bootstrapProfile). A body that
    // isn't JSON, or has no such flag, doesn't fail the call by itself —
    // the 2xx status code already confirmed the request was accepted, and
    // this endpoint's exact response shape isn't a guaranteed contract.
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final ok = decoded['ok'] ?? decoded['success'];
          if (ok == false) {
            throw Exception(
              'FCM registration rejected by backend: ${response.body}',
            );
          }
        }
      } on FormatException {
        // Non-JSON body — status code already confirmed success.
      }
    }
  }
}
