import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Reusable App Update System -- backend-controlled, three-state Android
/// update gate. Operators change behavior entirely through
/// PATCH /admin/api/app-version-policy; no Flutter or backend code
/// change is needed for a future release's rollout.
///
/// STATES (installedBuild vs. the backend's minimum_supported_build /
/// latest_build -- both plain integer Android versionCodes, never a
/// semantic-version STRING comparison):
///
///   [AppUpdateStatus.none]  installedBuild >= latest_build
///                           -- fully current, no UI, continue normally.
///   [AppUpdateStatus.soft]  minimum_supported_build <= installedBuild
///                           < latest_build
///                           -- non-blocking "Update Available" prompt;
///                              Later continues into the app.
///   [AppUpdateStatus.force] installedBuild < minimum_supported_build
///                           -- blocking "Update Required"; no bypass.
///
/// CRITICAL SEMANTICS (Safe Deployment Split, Task B -- unchanged from
/// the prior pass, restated here since it's the one invariant every
/// future change to this file must never violate): the sole authority
/// for [AppUpdateStatus.force] is `installedBuild < minimum_supported_build`.
/// `force_update` is never consulted to compute the status -- it is
/// policy/UI-severity metadata an operator may use for messaging, never
/// an independent gate. A build sitting exactly AT minimum_supported_build
/// is always supported (force never fires); a build exactly AT
/// latest_build is always fully current (soft never fires either).
///
/// FAIL-OPEN BY DESIGN: any network/timeout/non-2xx/malformed-JSON/
/// missing-or-non-integer-build-value failure resolves to
/// [AppVersionGateResult.allowed] ([AppUpdateStatus.none]) -- a
/// temporarily unreachable or malformed config response must never lock
/// users out, whether that would have been a soft or a force block.
/// Every failure is still recorded via
/// [FirebaseCrashlytics.instance.recordError] (the same instance
/// `main.dart` already wires up for `FlutterError.onError`), itself
/// guarded by its own try/catch so a Crashlytics-side problem can never
/// defeat the fail-open guarantee this whole catch block exists for.
enum AppUpdateStatus { none, soft, force }

class AppVersionGateResult {
  const AppVersionGateResult({
    required this.status,
    this.storeUrl,
    this.message,
  });

  final AppUpdateStatus status;

  /// Only meaningful when [status] is not [AppUpdateStatus.none].
  final String? storeUrl;

  /// Optional operator-supplied context from the backend
  /// (`AppVersionPolicy.message`) -- shown alongside, never instead of,
  /// each update UI's own static, branded copy.
  final String? message;

  static const AppVersionGateResult allowed = AppVersionGateResult(
    status: AppUpdateStatus.none,
  );
}

class AppVersionGateService {
  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  /// Reusable App Update System -- tracks whether the user already
  /// dismissed a SOFT prompt during the CURRENT app process lifetime
  /// (in-memory only, never persisted -- a fresh process/app restart
  /// always gets a clean check, per spec: "Future app startup may check
  /// again"). Deliberately module-level state, not a Flutter widget's
  /// own State -- SplashPage is only ever mounted once per cold start
  /// today, but this makes "no repeated loop within the same session"
  /// hold even if a future entry point calls checkForUpdate() again
  /// (e.g. on app resume) without requiring every caller to coordinate
  /// this themselves.
  static bool _softUpdateDismissedThisSession = false;

  /// Called when the user taps "Later" on the soft-update prompt.
  static void dismissSoftUpdateForSession() {
    _softUpdateDismissedThisSession = true;
  }

  /// Test-only: this class's dismissal flag is process-static by design
  /// (see [_softUpdateDismissedThisSession]'s own docstring), which
  /// means it otherwise leaks across every `test()` in the same test
  /// file. Never called from production code.
  @visibleForTesting
  static void resetSessionStateForTesting() {
    _softUpdateDismissedThisSession = false;
  }

  /// Fetches the backend's Android version policy and classifies the
  /// installed build into one of the three states. Never throws.
  static Future<AppVersionGateResult> checkForUpdate({
    http.Client? client,
  }) async {
    final ownsClient = client == null;
    final effectiveClient = client ?? http.Client();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedBuild = int.tryParse(packageInfo.buildNumber);
      if (installedBuild == null) {
        // Should never happen on a real Android build (buildNumber is
        // always the numeric versionCode as a string) -- fail open
        // rather than guess.
        return AppVersionGateResult.allowed;
      }

      final res = await effectiveClient
          .get(Uri.parse('$_baseUrl/api/app/version-policy?platform=android'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        // Includes 404 (no policy configured yet) -- fail open, never
        // treat "the server doesn't know" as "you must update."
        return AppVersionGateResult.allowed;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return AppVersionGateResult.allowed;
      }

      final minimumSupportedBuild = decoded['minimum_supported_build'];
      final latestBuild = decoded['latest_build'];
      if (minimumSupportedBuild is! int || latestBuild is! int) {
        // Malformed/missing required value -- never guess a threshold,
        // never partially evaluate with only one of the two present.
        return AppVersionGateResult.allowed;
      }

      final AppUpdateStatus status;
      if (installedBuild < minimumSupportedBuild) {
        status = AppUpdateStatus.force;
      } else if (installedBuild < latestBuild) {
        status = AppUpdateStatus.soft;
      } else {
        status = AppUpdateStatus.none;
      }

      if (status == AppUpdateStatus.none) {
        return AppVersionGateResult.allowed;
      }

      if (status == AppUpdateStatus.soft && _softUpdateDismissedThisSession) {
        // Already shown and dismissed once this session -- never a
        // repeated loop. FORCE is never suppressed this way (there is
        // no dismiss action for it at all).
        return AppVersionGateResult.allowed;
      }

      final storeUrl = decoded['store_url'];
      final message = decoded['message'];
      return AppVersionGateResult(
        status: status,
        storeUrl: storeUrl is String ? storeUrl : null,
        message: message is String ? message : null,
      );
    } catch (e, stack) {
      try {
        unawaited(
          FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'AppVersionGateService.checkForUpdate failed (fail-open)',
            fatal: false,
          ),
        );
      } catch (_) {
        // Swallowed on purpose -- see class docstring.
      }
      return AppVersionGateResult.allowed;
    } finally {
      if (ownsClient) effectiveClient.close();
    }
  }
}
