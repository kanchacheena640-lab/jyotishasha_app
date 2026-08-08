import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/repositories/welcome_gift_repository.dart';
import 'package:jyotishasha_app/core/state/welcome_gift_provider.dart';

/// Hand-rolled fake — lets [WelcomeGiftProvider]'s own logic (loading,
/// claiming, isClaiming guarding) be tested without touching the real
/// SharedPreferences-backed [LocalWelcomeGiftRepository].
class _FakeWelcomeGiftRepository implements WelcomeGiftRepository {
  bool claimed = false;
  int markClaimedCalls = 0;
  Object? markClaimedError;

  @override
  Future<bool> isClaimed() async => claimed;

  @override
  Future<void> markClaimed() async {
    markClaimedCalls++;
    if (markClaimedError != null) throw markClaimedError!;
    claimed = true;
  }
}

void main() {
  group('WelcomeGiftProvider', () {
    late _FakeWelcomeGiftRepository repository;
    late WelcomeGiftProvider provider;

    setUp(() {
      repository = _FakeWelcomeGiftRepository();
      provider = WelcomeGiftProvider(repository: repository);
    });

    test(
      'starts loading with isClaimed false — never assumes claimed before '
      'the repository has actually answered',
      () {
        expect(provider.isLoading, isTrue);
        expect(provider.isClaimed, isFalse);
      },
    );

    test(
      'loadStatus reflects exactly what the repository reports — never '
      'claimed',
      () async {
        repository.claimed = false;

        await provider.loadStatus();

        expect(provider.isLoading, isFalse);
        expect(provider.isClaimed, isFalse);
      },
    );

    test(
      'loadStatus reflects exactly what the repository reports — already '
      'claimed',
      () async {
        repository.claimed = true;

        await provider.loadStatus();

        expect(provider.isLoading, isFalse);
        expect(provider.isClaimed, isTrue);
      },
    );

    test(
      'claim marks the gift claimed via the repository and never leaves '
      'isClaiming stuck true',
      () async {
        await provider.claim();

        expect(repository.markClaimedCalls, 1);
        expect(provider.isClaimed, isTrue);
        expect(provider.isClaiming, isFalse);
      },
    );

    test(
      'a second claim() call is a no-op while one is already in flight — '
      'never double-claims',
      () async {
        final first = provider.claim();
        final second = provider.claim();

        await Future.wait([first, second]);

        expect(repository.markClaimedCalls, 1);
      },
    );

    test(
      'claim never leaves isClaiming stuck true even if the repository '
      'throws',
      () async {
        repository.markClaimedError = Exception('storage failure');

        await expectLater(provider.claim(), throwsException);

        expect(provider.isClaiming, isFalse);
        expect(provider.isClaimed, isFalse);
      },
    );
  });
}
