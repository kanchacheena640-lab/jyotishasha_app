import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges a single, narrow native action: cancelling the already-displayed
/// Morning Panchang system notification by its Android notification tag.
///
/// This never displays, builds, or creates anything — no local notification,
/// no notification channel. It only ever asks native Android to cancel a
/// notification that already exists (posted by FCM's own auto-display, not
/// by this app). A no-op for every message except the backend's data-only
/// `dismiss_panchang` signal; every other notification type (festival, vrat,
/// transit, muhurat, or anything else) is completely untouched.
final class PanchangDismissBridge {
  PanchangDismissBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'jyotishasha.app/panchang_notification';

  final MethodChannel _channel;

  /// Call from both `FirebaseMessaging.onMessage` and the background
  /// message handler. Does nothing unless the message carries
  /// `data['action'] == 'dismiss_panchang'`.
  Future<void> maybeDismiss(RemoteMessage message) async {
    final data = message.data;
    if (data['action'] != 'dismiss_panchang') return;

    final tag = data['tag'];
    if (tag is! String || tag.isEmpty) {
      debugPrint(
        '[PanchangDismissBridge] dismiss_panchang received without a tag',
      );
      return;
    }

    try {
      await _channel.invokeMethod<bool>('dismissByTag', {'tag': tag});
    } catch (e) {
      debugPrint('[PanchangDismissBridge] native dismiss failed: $e');
    }
  }
}

/// App-wide singleton, matching the existing top-level singleton pattern
/// already used for `fcmTokenManager`. Safe to use from both the
/// foreground/main isolate and the FCM background isolate — unlike a
/// notification-display service, this class has no dependency on
/// `appRouter`/navigation, just a lightweight platform-channel handle.
final panchangDismissBridge = PanchangDismissBridge();
