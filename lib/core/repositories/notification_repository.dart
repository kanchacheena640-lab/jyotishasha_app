import '../models/notifications/notification_contracts.dart';

/// Purpose: owns notification data and backend messaging registration.
///
/// Responsibilities: retrieve notification lists and unread counts, mark a
/// notification read, and register a device messaging token.
///
/// Excluded responsibilities: foreground event listening, navigation,
/// Firebase SDK access, token acquisition, and presentation state.
///
/// Future implementation owner: ESR-003 notification repository implementation.
abstract interface class NotificationRepository {
  Future<UnreadCountResponse> getUnreadCount();

  Future<NotificationListResponse> getNotifications();

  Future<void> markAsRead(MarkNotificationReadRequest request);

  Future<void> registerDeviceToken(String token);
}
