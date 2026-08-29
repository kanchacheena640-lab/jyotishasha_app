import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:jyotishasha_app/services/app_version_gate_service.dart';

/// Reusable App Update System -- coverage for [AppVersionGateService]'s
/// three-state classification (none/soft/force), its fail-open
/// contract, and the "no repeated loop" soft-dismiss behavior.
void _mockInstalledBuild(String buildNumber) {
  // Headless test environment has no real platform channel for
  // package_info_plus -- this is its own documented mock-values API,
  // not a workaround. buildNumber is always the numeric versionCode as
  // a string on Android, matched here.
  PackageInfo.setMockInitialValues(
    appName: 'Jyotishasha',
    packageName: 'com.jyotishasha.app',
    version: '1.1.4',
    buildNumber: buildNumber,
    buildSignature: '',
  );
}

http.Client _policyClient({
  required int minimum,
  required int latest,
  bool forceUpdate = false,
  String? message,
}) {
  return MockClient((request) async {
    return http.Response(
      jsonEncode({
        'platform': 'android',
        'minimum_supported_build': minimum,
        'latest_build': latest,
        'force_update': forceUpdate,
        'store_url': 'https://play.google.com/store/apps/details?id=com.jyotishasha.app',
        'message': message,
      }),
      200,
    );
  });
}

void main() {
  setUp(() {
    // AppVersionGateService's soft-dismiss flag is deliberately
    // process-static (see its own docstring) -- reset before every
    // test so one test's dismissal never leaks into the next.
    AppVersionGateService.resetSessionStateForTesting();
  });

  test(
    'A: installed 48 / minimum 48 / latest 48 -> NO UPDATE',
    () async {
      _mockInstalledBuild('48');
      final result = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 48, latest: 48),
      );
      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'B: installed 48 / minimum 48 / latest 49 -> SOFT UPDATE',
    () async {
      _mockInstalledBuild('48');
      final result = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 48, latest: 49),
      );
      expect(result.status, AppUpdateStatus.soft);
      expect(result.storeUrl, contains('com.jyotishasha.app'));
    },
  );

  test(
    'C: installed 48 / minimum 49 / latest 49 -> FORCE UPDATE',
    () async {
      _mockInstalledBuild('48');
      final result = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 49, latest: 49),
      );
      expect(result.status, AppUpdateStatus.force);
      expect(result.storeUrl, contains('com.jyotishasha.app'));
    },
  );

  test(
    'D: installed 49 / minimum 49 / latest 49 -> NO UPDATE (build == minimum stays supported)',
    () async {
      _mockInstalledBuild('49');
      final result = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 49, latest: 49),
      );
      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'E: installed 50 / minimum 49 / latest 49 -> NO UPDATE (ahead of latest is still current)',
    () async {
      _mockInstalledBuild('50');
      final result = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 49, latest: 49),
      );
      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'F: network failure -> FAIL OPEN (none)',
    () async {
      _mockInstalledBuild('48');
      final client = MockClient((request) async {
        throw const _SocketExceptionStub();
      });

      final result = await AppVersionGateService.checkForUpdate(client: client);

      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'G: malformed policy (non-integer minimum_supported_build) -> FAIL OPEN (none)',
    () async {
      _mockInstalledBuild('48');
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'platform': 'android',
            'minimum_supported_build': 'not_a_number',
            'latest_build': 49,
            'force_update': false,
            'store_url': 'https://play.google.com/store/apps/details?id=com.jyotishasha.app',
            'message': null,
          }),
          200,
        );
      });

      final result = await AppVersionGateService.checkForUpdate(client: client);

      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'G2: malformed policy (non-integer latest_build) -> FAIL OPEN (none) -- '
    'both build fields are required, not just minimum_supported_build',
    () async {
      _mockInstalledBuild('48');
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'platform': 'android',
            'minimum_supported_build': 49,
            'latest_build': null,
            'force_update': false,
            'store_url': 'https://play.google.com/store/apps/details?id=com.jyotishasha.app',
            'message': null,
          }),
          200,
        );
      });

      final result = await AppVersionGateService.checkForUpdate(client: client);

      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'force_update=true does NOT self-block a build that already meets the minimum '
    '(Task B invariant, still holds under the three-state model)',
    () async {
      _mockInstalledBuild('49');
      final result = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 49, latest: 49, forceUpdate: true),
      );
      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'fails open on a stalled/never-responding request (timeout)',
    () async {
      _mockInstalledBuild('48');
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 15));
        return http.Response('{}', 200); // never actually reached
      });

      final result = await AppVersionGateService.checkForUpdate(client: client);

      expect(result.status, AppUpdateStatus.none);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'fails open on a non-2xx response (e.g. no policy configured yet)',
    () async {
      _mockInstalledBuild('48');
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'no_policy_configured'}), 404);
      });

      final result = await AppVersionGateService.checkForUpdate(client: client);

      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'fails open on malformed JSON',
    () async {
      _mockInstalledBuild('48');
      final client = MockClient((request) async {
        return http.Response('not valid json {{{', 200);
      });

      final result = await AppVersionGateService.checkForUpdate(client: client);

      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'fails open when the response body is not a JSON object at all',
    () async {
      _mockInstalledBuild('48');
      final client = MockClient((request) async {
        return http.Response(jsonEncode([1, 2, 3]), 200);
      });

      final result = await AppVersionGateService.checkForUpdate(client: client);

      expect(result.status, AppUpdateStatus.none);
    },
  );

  test(
    'dismissSoftUpdateForSession() suppresses the soft prompt for the rest of the process, '
    'never affects a force block',
    () async {
      _mockInstalledBuild('48');

      final before = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 48, latest: 49),
      );
      expect(before.status, AppUpdateStatus.soft);

      AppVersionGateService.dismissSoftUpdateForSession();

      final afterDismiss = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 48, latest: 49),
      );
      expect(afterDismiss.status, AppUpdateStatus.none, reason: 'no repeated loop within the same session');

      // A genuinely below-minimum build must still force-block even
      // after a soft dismissal earlier in the same session.
      final stillForced = await AppVersionGateService.checkForUpdate(
        client: _policyClient(minimum: 49, latest: 49),
      );
      expect(stillForced.status, AppUpdateStatus.force);
    },
  );
}

/// Minimal stand-in for a real network exception -- only its
/// `Exception`-ness matters, matching backend_auth_service_test.dart's
/// identical `SocketExceptionStub` pattern.
class _SocketExceptionStub implements Exception {
  const _SocketExceptionStub();
  @override
  String toString() => '_SocketExceptionStub: connection failed';
}
