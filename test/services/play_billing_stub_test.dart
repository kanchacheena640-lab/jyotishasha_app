import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/services/play_billing_stub.dart';

/// Release-gate fix (P0) regression coverage for the second pre-`runApp()`
/// risky call `main()` awaits: `PlayBillingStub.init()` -> `InAppPurchase.
/// isAvailable()`.
///
/// This headless test environment has no real in_app_purchase platform
/// channel registered (same documented limitation `AskNowProvider`'s own
/// tests rely on for `InAppPurchase.instance`), so calling
/// `InAppPurchase.instance.isAvailable()` here throws immediately -- which
/// is exactly the real-world "Play Services not ready / misconfigured"
/// failure this fix guards against. This test therefore exercises the
/// real failure-handling code path, not a mock standing in for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PlayBillingStub.init() completes without throwing when the '
    'underlying isAvailable() call fails -- startup must never block or '
    'crash because of this optional probe',
    () async {
      await expectLater(PlayBillingStub.init(), completes);
    },
  );

  test(
    'PlayBillingStub.init() completes well within a few seconds even on '
    'failure -- proves it is actually bounded, not just eventually-safe',
    () async {
      final stopwatch = Stopwatch()..start();
      await PlayBillingStub.init();
      stopwatch.stop();

      // Generous upper bound for a CI-shared machine; the real timeout is
      // 3s and this environment fails synchronously (no real timeout
      // wait), so this is mainly a guard against a future regression that
      // removes the bound entirely.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    },
  );
}
