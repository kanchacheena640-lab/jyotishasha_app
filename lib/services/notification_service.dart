import 'package:firebase_auth/firebase_auth.dart';
import 'package:jyotishasha_app/core/repositories/implementations/backend_notification_repository.dart';
import 'package:jyotishasha_app/core/repositories/notification_repository.dart';

import '../core/models/notifications/notification_contracts.dart';
import 'backend_auth_service.dart';

class NotificationService {
  NotificationService({NotificationRepository? notificationRepository})
    : _notificationRepository =
          notificationRepository ?? _buildDefaultRepository() {
    _sharedRepository = _notificationRepository;
  }

  final NotificationRepository _notificationRepository;

  static NotificationRepository _sharedRepository = _buildDefaultRepository();

  static NotificationRepository get _repository => _sharedRepository;

  static NotificationRepository _buildDefaultRepository() {
    return BackendNotificationRepository(
      backendTokenProvider: _requireBackendToken,
      idTokenProvider: _requireIdToken,
    );
  }

  static Future<String> _requireBackendToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('USER NULL');
    }

    final token = await BackendAuthService.getBackendToken(user.uid);
    if (token == null) {
      throw StateError('TOKEN NULL');
    }

    return token;
  }

  static Future<String> _requireIdToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw StateError('JWT TOKEN NULL');
    }

    return token;
  }

  // N5: FirebaseAuth.instance itself (not just `.currentUser`) throws
  // when no Firebase app has been initialized -- this app's headless
  // widget-test environment, never real production (Firebase is always
  // initialized there). Treated identically to "not signed in", matching
  // the exact precedent already established for
  // HttpPremiumAiReportRepository's own _requireBackendToken().
  static User? _currentUserOrNull() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  static Future<int> getUnreadCount() async {
    final user = _currentUserOrNull();
    if (user == null) {
      print("❌ USER NULL");
      return 0;
    }

    final token = await BackendAuthService.getBackendToken(user.uid);
    if (token == null) {
      print("❌ TOKEN NULL");
      return 0;
    }

    try {
      final response = await _repository.getUnreadCount();
      return response.unreadCount ?? 0;
    } catch (e) {
      print("❌ Unread count error: $e");
      return 0;
    }
  }

  static Future<List> getNotifications() async {
    final user = _currentUserOrNull();
    if (user == null) {
      return [];
    }

    final token = await BackendAuthService.getBackendToken(user.uid);
    if (token == null) {
      return [];
    }

    try {
      final response = await _repository.getNotifications();
      return response.notifications
              ?.map((item) => item.toJson())
              .toList(growable: false) ??
          [];
    } catch (e) {
      print("❌ Get notifications error: $e");
      return [];
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    final user = _currentUserOrNull();
    if (user == null) {
      return;
    }

    final token = await BackendAuthService.getBackendToken(user.uid);
    if (token == null) {
      return;
    }

    try {
      await _repository.markAsRead(
        MarkNotificationReadRequest(notificationId: notificationId),
      );
    } catch (e) {
      print("❌ Mark as read error: $e");
    }
  }
}
