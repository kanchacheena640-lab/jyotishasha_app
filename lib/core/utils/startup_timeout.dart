import 'dart:async';

import 'package:flutter/foundation.dart';

/// Release-gate fix (P0): bounds an optional, non-critical pre-`runApp()`
/// startup operation so a stall or thrown exception in a platform/plugin
/// call can never prevent `runApp()` from ever executing. Only ever used
/// for genuinely optional startup probes whose failure the app can
/// safely continue without (see main.dart's call site) — never wraps
/// [Firebase.initializeApp] itself, which stays a hard startup
/// dependency, and never swallows a programming error anywhere else in
/// the app.
///
/// Extracted out of `main.dart` (rather than kept as a private
/// top-level function there) purely so this exact timeout/catch
/// contract is directly unit-testable — `main()` itself isn't a
/// practical unit-test target.
Future<T?> withStartupTimeout<T>(
  Future<T> Function() operation, {
  String? debugLabel,
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    return await operation().timeout(timeout);
  } catch (e) {
    debugPrint(
      '⚠️ Startup step "${debugLabel ?? 'unnamed'}" failed/timed out '
      '(non-fatal, startup continues): $e',
    );
    return null;
  }
}
