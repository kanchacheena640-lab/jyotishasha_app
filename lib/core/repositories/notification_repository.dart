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

  /// N6 -- presentation-only, unified across A/B/C. No "mark unread"
  /// exists in this interface, by design (N6 v1 contract).
  Future<void> markAllRead();

  /// N6 -- presentation-only removal of every currently-visible item
  /// (both sources). Never implies deletion of operational campaign
  /// history.
  Future<void> clearAll();

  /// N6 -- presentation-only removal of one item, addressed by its exact
  /// backend-supplied composite id (`"ab:<int>"` / `"cc:<uuid>"`).
  Future<void> dismiss(String itemId);

  Future<void> registerDeviceToken(String token);
}
