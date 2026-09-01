import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/analytics/analytics_session_context.dart';

/// Phase 5A foundation tests -- AnalyticsSessionContext.
///
/// Covers required foundation tests #7 ("session_id: valid charset, <=64
/// chars, stable during same session/process") and #8 ("explicit
/// test-only new-session/reset mechanism generates a different session
/// id"). #22 ("session_id is not persisted") is a static code-level fact
/// for this class -- `sessionId` is a plain synchronous getter with no
/// storage API imported or called anywhere in this file, so there is no
/// I/O to read from or write to; verified here indirectly by the getter
/// never needing to be awaited.
final _identifierCharset = RegExp(r'^[A-Za-z0-9_-]+$');

void main() {
  setUp(() {
    // Simulate a fresh process for every test so none of them observe a
    // session_id left over from a previous test in this same run.
    AnalyticsSessionContext.resetForTest();
  });

  test('sessionId matches the required charset [A-Za-z0-9_-]+', () {
    final id = AnalyticsSessionContext.instance.sessionId;
    expect(_identifierCharset.hasMatch(id), isTrue, reason: 'got "$id"');
  });

  test('sessionId is never longer than 64 characters', () {
    final id = AnalyticsSessionContext.instance.sessionId;
    expect(id.length, lessThanOrEqualTo(64));
  });

  test('sessionId contains no PII, Firebase UID, or device identifier', () {
    // There is nothing in AnalyticsSessionContext's generation logic that
    // ever reads a uid/device id/email/phone -- this asserts the id is
    // built purely from a timestamp + Random.secure() bytes by shape:
    // exactly one '-' separator, a base36 time part, a 32-hex-char random
    // part.
    final id = AnalyticsSessionContext.instance.sessionId;
    final parts = id.split('-');
    expect(parts.length, 2);
    expect(RegExp(r'^[0-9a-z]+$').hasMatch(parts[0]), isTrue);
    expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(parts[1]), isTrue);
  });

  test(
    'sessionId is a plain synchronous getter (no await needed) -- '
    'consistent with never reading from persistent storage',
    () {
      // If this getter had to consult SharedPreferences/disk it would
      // have to be a Future<String>; it is not.
      final AnalyticsSessionContext ctx = AnalyticsSessionContext.instance;
      final String id = ctx.sessionId; // would not compile if async
      expect(id, isNotEmpty);
    },
  );

  test(
    'sessionId is stable across repeated access within the same process '
    '(same instance, same value every time)',
    () {
      final ctx = AnalyticsSessionContext.instance;
      final first = ctx.sessionId;
      final second = ctx.sessionId;
      final third = AnalyticsSessionContext.instance.sessionId;
      expect(second, equals(first));
      expect(third, equals(first));
    },
  );

  test(
    'resetForTest() (simulating a new process) produces a different '
    'sessionId than the previous process',
    () {
      final beforeReset = AnalyticsSessionContext.instance.sessionId;
      AnalyticsSessionContext.resetForTest();
      final afterReset = AnalyticsSessionContext.instance.sessionId;
      expect(afterReset, isNot(equals(beforeReset)));
    },
  );
}
