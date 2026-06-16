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
}
