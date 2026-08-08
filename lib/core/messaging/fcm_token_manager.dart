import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:jyotishasha_app/core/repositories/implementations/backend_notification_repository.dart';
import 'package:jyotishasha_app/core/repositories/implementations/firebase_user_repository.dart';
import 'package:jyotishasha_app/core/repositories/notification_repository.dart';
import 'package:jyotishasha_app/core/repositories/user_repository.dart';
import 'package:jyotishasha_app/services/backend_auth_service.dart';

/// Single source of truth for keeping the backend's stored FCM token in
/// sync with whatever token Firebase currently holds for this device.
///
/// This is a pure application-level service: it has no dependency on any
/// screen or widget being mounted. It starts itself off two triggers —
/// Firebase-issued token rotation (`onTokenRefresh`) and Firebase Auth
/// becoming ready with a signed-in user (`authStateChanges`) — and owns
/// nothing about notification content, dispatch, payloads, or navigation.
/// UI code should never call `getToken()`/upload logic directly, and no UI
/// widget should ever need to trigger a sync itself.
final class FcmTokenManager {
  FcmTokenManager({
    NotificationRepository? notificationRepository,
    UserRepository? userRepository,
    FirebaseMessaging? messaging,
    String? Function()? currentUidProvider,
    Stream<String?>? authStateUidChanges,
    Duration? initialBackoff,
  }) : _notificationRepository =
           notificationRepository ?? _buildDefaultNotificationRepository(),
       _userRepository = userRepository ?? FirebaseUserRepository(),
       _messaging = messaging ?? FirebaseMessaging.instance,
       _currentUidProvider =
           currentUidProvider ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _authStateUidChanges =
           authStateUidChanges ??
           FirebaseAuth.instance.authStateChanges().map((user) => user?.uid),
       _initialBackoff = initialBackoff ?? const Duration(seconds: 2);

  static const String _topic = 'general_0';
  static const int _maxAttempts = 4;

  final NotificationRepository _notificationRepository;
  final UserRepository _userRepository;
  final FirebaseMessaging _messaging;
  final String? Function() _currentUidProvider;
  final Stream<String?> _authStateUidChanges;
  final Duration _initialBackoff;

  StreamSubscription<String>? _refreshSubscription;
  StreamSubscription<String?>? _authStateSubscription;
  bool _started = false;

  /// Starts the manager for the app's full process lifetime. Call once, at
  /// app startup, independent of any particular screen being shown:
  ///   1. Registers the `onTokenRefresh` listener — the primary,
  ///      always-on synchronization mechanism.
  ///   2. Subscribes to Firebase Auth's sign-in state. Every time
  ///      authentication becomes ready with a signed-in user (including a
  ///      session restored on cold start, with no UI ever needing to be
  ///      reached), the current token is uploaded unconditionally. The
  ///      backend upserts, so this is a safe, secondary self-healing pass
  ///      rather than an optimization to be gated.
  void start() {
    if (_started) return;
    _started = true;

    _refreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) {
        debugPrint('[FcmTokenManager] onTokenRefresh fired');
        // Not awaited here (this is a stream callback, not something the
        // caller can meaningfully wait on) — but the sync itself retries
        // internally and always logs its outcome, so it is never silently
        // abandoned.
        unawaited(_syncToken(newToken, reason: 'refresh'));
      },
      onError: (Object error) {
        debugPrint('[FcmTokenManager] onTokenRefresh stream error: $error');
      },
    );

    _authStateSubscription = _authStateUidChanges.listen(
      (uid) {
        if (uid == null) return;
        debugPrint('[FcmTokenManager] authentication ready ($uid)');
        unawaited(_syncCurrentToken(reason: 'auth-ready'));
      },
      onError: (Object error) {
        debugPrint('[FcmTokenManager] authStateChanges stream error: $error');
      },
    );
  }

  /// Fetches whatever token Firebase currently holds for this device and
  /// uploads it unconditionally — no local cache, no compare-before-upload.
  /// A single lightweight, idempotent backend UPSERT on every authenticated
  /// session start is the point: it self-heals any backend record left
  /// stale by a missed refresh, a prior crash mid-upload, or a reinstall.
  Future<void> _syncCurrentToken({required String reason}) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('[FcmTokenManager] permission not granted, skipping $reason sync');
        return;
      }

      final currentToken = await _messaging.getToken();
      if (currentToken == null) {
        debugPrint('[FcmTokenManager] getToken() returned null');
        return;
      }

      await _syncToken(currentToken, reason: reason);
    } catch (e) {
      debugPrint('[FcmTokenManager] $reason sync error: $e');
    }
  }

  /// Logout cleanup: unsubscribes from app-wide topics and deletes the
  /// on-device FCM token, so the next login starts from a verifiably fresh
  /// token rather than one that may already be stale for this backend
  /// account.
  Future<void> clearOnLogout() async {
    try {
      await _messaging.unsubscribeFromTopic(_topic);
    } catch (e) {
      debugPrint('[FcmTokenManager] unsubscribe on logout failed: $e');
    }

    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FcmTokenManager] deleteToken on logout failed: $e');
    }

    debugPrint('[FcmTokenManager] logout cleanup complete');
  }

  Future<void> _syncToken(String token, {required String reason}) async {
    final uid = _currentUidProvider();
    if (uid == null) {
      debugPrint(
        '[FcmTokenManager] no authenticated user, skipping $reason sync',
      );
      return;
    }

    var attempt = 0;
    var delay = _initialBackoff;

    while (true) {
      attempt++;
      try {
        await _messaging.subscribeToTopic(_topic);
        await _notificationRepository.registerDeviceToken(token);
        await _userRepository.updateMessagingToken(
          firebaseUid: uid,
          token: token,
        );
        debugPrint('[FcmTokenManager] $reason sync succeeded (attempt $attempt)');
        return;
      } catch (e) {
        debugPrint('[FcmTokenManager] $reason sync attempt $attempt failed: $e');
        if (attempt >= _maxAttempts) {
          debugPrint(
            '[FcmTokenManager] $reason sync FAILED after $_maxAttempts '
            'attempts — giving up for this trigger; the next onTokenRefresh '
            'or authenticated session start will retry',
          );
          return;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  static NotificationRepository _buildDefaultNotificationRepository() {
    return BackendNotificationRepository(
      backendTokenProvider: _requireBackendToken,
      idTokenProvider: _requireIdToken,
    );
  }

  static Future<String> _requireBackendToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('USER NULL');
    final token = await BackendAuthService.getBackendToken(user.uid);
    if (token == null) throw StateError('TOKEN NULL');
    return token;
  }

  static Future<String> _requireIdToken() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('JWT TOKEN NULL');
    return token;
  }

  /// Stops listening for token refreshes and auth-state changes. Not
  /// currently called anywhere — this manager is intended to live for the
  /// app's full process lifetime, like the other top-level singletons in
  /// `main.dart` — but is provided for completeness/testability.
  void dispose() {
    _refreshSubscription?.cancel();
    _authStateSubscription?.cancel();
  }
}

/// App-wide singleton, matching the existing top-level singleton pattern
/// already used for `analytics` in `lib/main.dart`. There must be exactly
/// one of these for "single source of truth" to actually hold.
final FcmTokenManager fcmTokenManager = FcmTokenManager();
