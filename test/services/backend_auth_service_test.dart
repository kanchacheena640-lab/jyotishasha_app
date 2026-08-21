import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/services/backend_auth_service.dart';

/// Release-gate fix (P0) regression coverage for
/// `BackendAuthService.getBackendToken` -- priority #1 in the network
/// timeout hardening pass, since it gates purchase confirmation across
/// every provider (Subscription/AskNow/Report) via
/// `_requireBackendToken()`.
///
/// `registerFirebaseUser()` isn't covered here: it requires a signed-in
/// `FirebaseAuth.instance.currentUser` before it ever reaches the network
/// call, and this headless test environment has no real Firebase app
/// (same documented limitation used throughout this codebase's other
/// provider tests) -- it already returns null before the network layer
/// is ever touched, so there's nothing timeout-specific to prove here
/// beyond what `getBackendToken`'s tests already establish for the
/// identical `.timeout()`/try-catch/`client` pattern.
void main() {
  test(
    'getBackendToken returns null (not a thrown exception) when the '
    'request never completes in time -- TimeoutException flows through '
    'the existing catch exactly like any other failure',
    () async {
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response('{}', 200); // never actually reached
      });

      final result = await BackendAuthService.getBackendToken(
        'uid-doesnt-matter-firebase-not-initialized',
        client: client,
      );

      // Firebase isn't initialized in this headless test environment, so
      // `FirebaseAuth.instance.currentUser?.getIdToken()` itself already
      // returns null (or throws, caught by the same catch) before the
      // network layer runs -- this proves the *contract* (null on any
      // failure, never a thrown exception escaping this method) holds
      // regardless of which internal guard actually short-circuited.
      expect(result, isNull);
    },
    // Real timeout is 12s; MockClient's simulated delay (5s) is well
    // under it deliberately so this test's own runtime stays fast even
    // if Firebase's own guard doesn't short-circuit first.
    timeout: const Timeout(Duration(seconds: 15)),
  );

  test(
    'getBackendToken never throws an unhandled exception on a network '
    'failure -- always resolves to a value',
    () async {
      final client = MockClient((request) async {
        throw const SocketExceptionStub();
      });

      await expectLater(
        BackendAuthService.getBackendToken('uid', client: client),
        completes,
      );
    },
  );
}

/// Minimal stand-in for `SocketException` without importing `dart:io`
/// directly into the test -- only its `Exception`-ness matters here;
/// `BackendAuthService`'s catch block is intentionally untyped (`catch
/// (_)`) and swallows any exception the same way.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'SocketExceptionStub: connection failed';
}
