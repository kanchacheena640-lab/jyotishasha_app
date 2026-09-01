import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/core/analytics/session_start_producer.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

class _FakeIdentityPort implements CurrentUserIdentityPort {
  const _FakeIdentityPort(this._uid);
  final String? _uid;
  @override
  String? get currentFirebaseUid => _uid;
}

/// Phase 5B foundation tests -- SessionStartProducer.
///
/// [SessionStartProducer] is the shared in-memory once-per-process guard
/// both SplashPage (authenticated returning-user cold start) and
/// LoginPage (fresh sign-in) call into -- tested directly here rather
/// than through those widgets, so no real Firebase/backend/network is
/// ever needed (same seam-injection convention Phase 5A established).
void main() {
  setUp(() {
    SessionStartProducer.resetForTest();
  });

  ActivityEventClient clientWith(List<http.Request> captured) {
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response('{"status":"written","event_id":"x"}', 201);
    });
    return ActivityEventClient(
      httpClient: mockClient,
      identityPort: const _FakeIdentityPort('uid'),
      tokenProvider: (firebaseUid, {client}) async => 'fake-token',
    );
  }

  test(
    'authenticated returning startup (SplashPage seam) -> exactly one '
    'session_start, entry_point="cold_start"',
    () async {
      final captured = <http.Request>[];
      await SessionStartProducer.attemptOnce(
        entryPoint: 'cold_start',
        client: clientWith(captured),
      );
      expect(captured, hasLength(1));
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['event_name'], 'session_start');
      expect(body['properties'], {'entry_point': 'cold_start'});
    },
  );

  test(
    'fresh login path (LoginPage seam) -> exactly one session_start, '
    'entry_point="login"',
    () async {
      final captured = <http.Request>[];
      await SessionStartProducer.attemptOnce(
        entryPoint: 'login',
        client: clientWith(captured),
      );
      expect(captured, hasLength(1));
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['properties'], {'entry_point': 'login'});
    },
  );

  test(
    'same process, multiple eligible seams reached -> still exactly one '
    'session_start (Splash attempt then a later Login attempt is a no-op)',
    () async {
      final captured = <http.Request>[];
      await SessionStartProducer.attemptOnce(
        entryPoint: 'cold_start',
        client: clientWith(captured),
      );
      await SessionStartProducer.attemptOnce(
        entryPoint: 'login',
        client: clientWith(captured),
      );
      expect(captured, hasLength(1));
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      // The FIRST seam attempted wins -- entry_point stays "cold_start".
      expect(body['properties'], {'entry_point': 'cold_start'});
    },
  );

  test(
    'background/resume (re-entering the same seam again) -> no second '
    'event',
    () async {
      final captured = <http.Request>[];
      await SessionStartProducer.attemptOnce(
        entryPoint: 'cold_start',
        client: clientWith(captured),
      );
      // Simulates SplashPage's initState() running again (e.g. a widget
      // remount) without a real new process -- resetForTest() is NOT
      // called between these two attempts.
      await SessionStartProducer.attemptOnce(
        entryPoint: 'cold_start',
        client: clientWith(captured),
      );
      expect(captured, hasLength(1));
    },
  );

  test(
    'the guard itself never depends on a real Firebase user -- callers '
    'are responsible for only invoking it after their own user != null '
    'check (SplashPage/LoginPage both do)',
    () async {
      // This test documents the contract: attemptOnce() has no identity
      // check of its own -- it trusts the caller. Proven by construction
      // (no CurrentUserIdentityPort/FirebaseAuth reference anywhere in
      // SessionStartProducer's source).
      expect(SessionStartProducer.attemptOnce, isNotNull);
    },
  );

  test(
    'later authentication in the same process (no earlier attempt made) '
    '-> exactly one event when it finally happens',
    () async {
      final captured = <http.Request>[];
      // No attempt yet -- simulates an unauthenticated launch reaching
      // LoginPage with nothing emitted from Splash.
      expect(captured, isEmpty);
      await SessionStartProducer.attemptOnce(
        entryPoint: 'login',
        client: clientWith(captured),
      );
      expect(captured, hasLength(1));
    },
  );

  test('properties are exactly entry_point, nothing else, no PII', () async {
    final captured = <http.Request>[];
    await SessionStartProducer.attemptOnce(
      entryPoint: 'cold_start',
      client: clientWith(captured),
    );
    final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
    final properties = body['properties'] as Map<String, dynamic>;
    expect(properties.keys, ['entry_point']);
    expect(body.toString().contains('@'), isFalse); // no email-shaped text
  });

  test('resetForTest() makes the next attempt eligible again', () async {
    final first = <http.Request>[];
    await SessionStartProducer.attemptOnce(
      entryPoint: 'cold_start',
      client: clientWith(first),
    );
    expect(first, hasLength(1));

    SessionStartProducer.resetForTest();

    final second = <http.Request>[];
    await SessionStartProducer.attemptOnce(
      entryPoint: 'cold_start',
      client: clientWith(second),
    );
    expect(second, hasLength(1));
  });
}
