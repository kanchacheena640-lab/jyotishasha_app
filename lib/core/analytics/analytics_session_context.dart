import 'dart:math';

import 'package:flutter/foundation.dart';

/// Phase 5A -- minimal process-lifetime session identifier for first-party
/// activity-event delivery (see `ActivityEventClient`).
///
/// Locked scope (Phase 5A design freeze): ONE `session_id` per application
/// PROCESS lifetime.
///   - cold process start -> lazily generated on first access
///   - every event emitted during that process -> the same session_id
///   - background/foreground (`AppLifecycleState` transitions) -> same
///     session_id, this class does not observe lifecycle at all
///   - process death + a new process -> a new session_id (nothing here is
///     persisted, so a fresh Dart isolate has no memory of the old one)
///
/// Deliberately NOT implemented here (out of Phase 5A scope):
///   - 30-minute inactivity/session-timeout semantics
///   - a background timer of any kind
///   - persistence (SharedPreferences, disk, or otherwise)
///   - any visitor/device identity concept
///
/// No actual `session_start` event is produced by this file -- wiring an
/// event producer around this session id is Phase 5B's job.
class AnalyticsSessionContext {
  AnalyticsSessionContext._();

  static AnalyticsSessionContext? _instance;

  /// The single process-lifetime instance every real caller shares.
  static AnalyticsSessionContext get instance =>
      _instance ??= AnalyticsSessionContext._();

  String? _sessionId;

  /// Charset `[A-Za-z0-9_-]`, always <=64 chars, contains no PII, no
  /// Firebase UID, and no device identifier -- a non-sensitive
  /// timestamp-derived prefix (entropy only, not an identity) plus a
  /// `Random.secure()` suffix. Stable for the remainder of this process;
  /// never persisted anywhere.
  String get sessionId => _sessionId ??= _generate();

  static String _generate() {
    final timePart = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = Random.secure();
    final randomPart = List<int>.generate(16, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    // e.g. "8jz3k1qf-a1b2c3d4e5f6a1b2c3d4e5f6a1b2" -- well under the 64
    // char cap (~41 chars total) with room to spare.
    return '$timePart-$randomPart';
  }

  /// Test-only: forces the next [sessionId] access to generate a fresh
  /// value, simulating a new process. Production code never calls this --
  /// it exists purely so a test can prove a new session_id is produced
  /// when the process boundary is simulated.
  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }
}
