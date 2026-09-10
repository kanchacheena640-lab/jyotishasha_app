import 'package:flutter/material.dart';
import 'package:jyotishasha_app/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  int unreadCount = 0;
  bool isLoading = false;

  // ===============================
  // 🔔 LOAD UNREAD COUNT
  // ===============================
  Future<void> loadUnreadCount() async {
    try {
      isLoading = true;
      notifyListeners();

      final count = await NotificationService.getUnreadCount();
      unreadCount = count;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print("❌ Provider error: $e");
    }
  }

  // ===============================
  // 🔁 REFRESH (manual call)
  // ===============================
  Future<void> refresh() async {
    await loadUnreadCount();
  }

  // ===============================
  // ➕ INCREMENT (optional)
  // ===============================
  void increment() {
    unreadCount++;
    notifyListeners();
  }

  // ===============================
  // 🔄 RESET
  // ===============================
  void reset() {
    unreadCount = 0;
    notifyListeners();
  }

  // ===============================
  // ✅ MARK ALL READ (N6 -- presentation only, unified A/B/C)
  // ===============================
  /// Awaits the authoritative backend call before touching local state --
  /// never fakes success. Rethrows on failure so the caller (the Bell UI)
  /// can show its own error handling; `unreadCount` is left completely
  /// unchanged on failure, exactly as before the call.
  Future<void> markAllRead() async {
    await NotificationService.markAllRead();
    await loadUnreadCount();
  }

  // ===============================
  // 🧹 CLEAR ALL (N6 -- presentation only, unified A/B/C)
  // ===============================
  Future<void> clearAll() async {
    await NotificationService.clearAll();
    await loadUnreadCount();
  }

  // ===============================
  // ❌ DISMISS ONE (N6 -- presentation only)
  // ===============================
  Future<void> dismiss(String itemId) async {
    await NotificationService.dismiss(itemId);
    await loadUnreadCount();
  }

  // ===============================
  // ✅ MARK ONE READ (N6 -- presentation only, unified A/B/C)
  // ===============================
  /// Thin pass-through to [NotificationService.markAsRead] -- introduced
  /// solely as a seam (mirroring [dismiss]) so the Bell row-tap handler's
  /// mark-read call is observable in tests without a Firebase-backed
  /// static call. Deliberately does NOT bundle its own [loadUnreadCount]
  /// call the way [dismiss]/[markAllRead]/[clearAll] do -- the row-tap
  /// handler already calls [loadUnreadCount] itself right after this,
  /// exactly as it did when it called [NotificationService.markAsRead]
  /// directly, so this changes zero production call order/count.
  Future<void> markAsRead(String itemId) async {
    await NotificationService.markAsRead(itemId);
  }
}
