// D4 -- Delete Account UX on AccountPage. NO REAL DELETION REQUEST IS EVER
// MADE: AccountDeletionRepository is fully faked via mocktail and injected
// through AccountPage's own constructor (mirrors AlertsDashboardPage's
// `repository` param). Firebase/network are never touched by this file.
//
// Full-success (sign-out + navigation) is deliberately NOT driven
// end-to-end here, for the exact same reason account_page_test.dart's own
// Logout suite already documents: `_signOutLocallyAndReturnToLogin` (shared
// by both Logout and a fully successful Delete Account) touches real
// `FirebaseAuth.instance`/`GoogleSignIn()` platform channels with no mock
// registered in this headless environment, and does not reliably resolve
// within a widget-test pump loop.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/account/account_deletion_contracts.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/repositories/account_deletion_repository.dart';
import 'package:jyotishasha_app/core/repositories/billing_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/features/profile/account_page.dart';

import '../../helpers/test_harness.dart';

class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

class _FakeAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

class _FakeBillingRepository implements BillingRepository {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ChatPackProduct?> getProduct(String productId) async => null;

  @override
  Future<void> purchaseConsumable(ChatPackProduct product) async {}

  @override
  Future<void> purchaseSubscription(ChatPackProduct product) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Stream<ReportPurchaseReceipt> watchPurchases() => const Stream.empty();

  @override
  Future<void> completePurchase(ReportPurchaseReceipt receipt) async {}
}

void main() {
  late _FakeProfileProvider profileProvider;
  late SubscriptionProvider subscriptionProvider;
  late _FakeAccountDeletionRepository accountDeletionRepository;

  setUpAll(() {
    registerFallbackValue(
      AccountDeletionResult.failure(status: AccountDeletionStatus.networkError),
    );
  });

  setUp(() {
    profileProvider = _FakeProfileProvider();
    when(() => profileProvider.loadProfiles()).thenAnswer((_) async {});
    when(() => profileProvider.isLoading).thenReturn(false);
    when(() => profileProvider.errorMessage).thenReturn(null);
    when(() => profileProvider.activeProfile).thenReturn({
      "name": "Ravi Kumar",
      "dob": "1990-05-12",
      "pob": "Lucknow",
    });
    when(() => profileProvider.reset()).thenReturn(null);

    subscriptionProvider = SubscriptionProvider(
      billing: _FakeBillingRepository(),
    );

    accountDeletionRepository = _FakeAccountDeletionRepository();
  });

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpTestHarness(
      AccountPage(accountDeletionRepository: accountDeletionRepository),
      locale: locale,
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(
          value: subscriptionProvider,
        ),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider(),
        ),
      ],
    );
  }

  Future<void> openAndConfirmDelete(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Delete Account'));
    await tester.tap(find.text('Delete Account'));
    await tester.pump();
    await tester.tap(find.text('Delete Account').last);
    await tester.pump();
  }

  group('Gate 3 — row + EN/HI copy', () {
    testWidgets('1: Delete Account row renders', (tester) async {
      await pump(tester);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets(
      '2: EN confirmation copy explains permanence, irreversibility, and '
      'that it does NOT cancel Play/App Store subscriptions (21: '
      'subscription warning visible)',
      (tester) async {
        await pump(tester);

        await tester.ensureVisible(find.text('Delete Account'));
        await tester.tap(find.text('Delete Account'));
        await tester.pump();

        expect(find.text('Delete Account?'), findsOneWidget);
        final content = tester
            .widget<Text>(
              find.textContaining('Your account and profile data'),
            )
            .data!;
        expect(content, contains('permanently deleted'));
        expect(content, contains('cannot be undone'));
        expect(content, contains('does not automatically cancel'));
        expect(content, contains('Google Play'));
        expect(content, contains('Apple'));

        verifyNever(() => accountDeletionRepository.deleteAccount());
      },
    );

    testWidgets('3: HI confirmation copy carries the same three warnings', (
      tester,
    ) async {
      await pump(tester, locale: const Locale('hi'));

      await tester.ensureVisible(find.text('अकाउंट डिलीट करें'));
      await tester.tap(find.text('अकाउंट डिलीट करें'));
      await tester.pump();

      expect(find.text('अकाउंट डिलीट करें?'), findsOneWidget);
      final content = tester
          .widget<Text>(find.textContaining('स्थायी रूप से डिलीट'))
          .data!;
      expect(content, contains('पूर्ववत नहीं की जा सकती'));
      expect(content, contains('अपने आप रद्द नहीं होती'));
      expect(content, contains('Google Play'));
      expect(content, contains('Apple'));
    });
  });

  group('Gate 3/6 — confirmation flow + request firing', () {
    testWidgets('4: Cancel -> no request sent', (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => accountDeletionRepository.deleteAccount());
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('5: Confirm -> exactly one deleteAccount() request fires', (
      tester,
    ) async {
      when(() => accountDeletionRepository.deleteAccount()).thenAnswer(
        (_) async =>
            AccountDeletionResult.failure(status: AccountDeletionStatus.serverError),
      );

      await pump(tester);
      await openAndConfirmDelete(tester);
      await tester.pumpAndSettle();

      verify(() => accountDeletionRepository.deleteAccount()).called(1);
    });
  });

  group('Gate 5 — pending cleanup (10, 11)', () {
    testWidgets(
      '10: pendingCleanup is NOT presented as success — no provider reset, '
      'no navigation, distinct "in progress" messaging',
      (tester) async {
        when(() => accountDeletionRepository.deleteAccount()).thenAnswer(
          (_) async => AccountDeletionResult.pendingCleanup(
            alreadyDeleted: false,
            hardDeletedProfileCount: 0,
            anonymizedProfileCount: 1,
            firebaseCleanupStatus: 'pending',
          ),
        );

        await pump(tester);
        await openAndConfirmDelete(tester);
        await tester.pumpAndSettle();

        expect(find.text('Deletion In Progress'), findsOneWidget);
        verifyNever(() => profileProvider.reset());
        // Still on AccountPage -- no navigation occurred.
        expect(find.text('Deletion In Progress'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Account'), findsOneWidget);
      },
    );

    testWidgets(
      '11: pending cleanup preserves retry capability -- the row can be '
      'tapped again and fires a second request',
      (tester) async {
        when(() => accountDeletionRepository.deleteAccount()).thenAnswer(
          (_) async => AccountDeletionResult.pendingCleanup(
            alreadyDeleted: true,
            hardDeletedProfileCount: 0,
            anonymizedProfileCount: 0,
            firebaseCleanupStatus: 'pending',
          ),
        );

        await pump(tester);
        await openAndConfirmDelete(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Retry: row is still present, still tappable, fires again.
        await openAndConfirmDelete(tester);
        await tester.pumpAndSettle();

        verify(() => accountDeletionRepository.deleteAccount()).called(2);
      },
    );
  });

  group('Gate 6 — error/retry behavior (12–16)', () {
    Future<void> expectSafeFailure(
      WidgetTester tester,
      AccountDeletionResult result,
      String expectedSnackbarText,
    ) async {
      when(() => accountDeletionRepository.deleteAccount())
          .thenAnswer((_) async => result);

      await pump(tester);
      await openAndConfirmDelete(tester);
      await tester.pumpAndSettle();

      expect(find.text(expectedSnackbarText), findsOneWidget);
      verifyNever(() => profileProvider.reset());
    }

    testWidgets('12: 401 -> unauthorized, no local state cleared', (
      tester,
    ) async {
      await expectSafeFailure(
        tester,
        AccountDeletionResult.failure(status: AccountDeletionStatus.unauthorized),
        'Identity verification failed. Please sign in again and retry.',
      );
    });

    testWidgets('13: 403 -> forbidden, no local state cleared', (
      tester,
    ) async {
      await expectSafeFailure(
        tester,
        AccountDeletionResult.failure(status: AccountDeletionStatus.forbidden),
        'Identity verification failed. Please sign in again and retry.',
      );
    });

    testWidgets('14: 500 -> serverError, "nothing was deleted" retry-safe copy', (
      tester,
    ) async {
      await expectSafeFailure(
        tester,
        AccountDeletionResult.failure(status: AccountDeletionStatus.serverError),
        "We couldn't delete your account. Nothing was deleted — please try again.",
      );
    });

    testWidgets('15: network failure -> networkError, retry-safe copy', (
      tester,
    ) async {
      await expectSafeFailure(
        tester,
        AccountDeletionResult.failure(status: AccountDeletionStatus.networkError),
        "We couldn't delete your account. Nothing was deleted — please try again.",
      );
    });

    testWidgets('16: malformed response -> malformedResponse, retry-safe copy', (
      tester,
    ) async {
      await expectSafeFailure(
        tester,
        AccountDeletionResult.failure(status: AccountDeletionStatus.malformedResponse),
        "We couldn't delete your account. Nothing was deleted — please try again.",
      );
    });

    testWidgets(
      '17/18/19: authFailed (no Firebase user / token refresh failure / '
      'backend token missing — all normalized to the same safe outcome by '
      'HttpAccountDeletionRepository, see its own unit tests for the three '
      'distinct pre-flight causes) -> safe error, no destructive request '
      'side effect assumed',
      (tester) async {
        await expectSafeFailure(
          tester,
          AccountDeletionResult.failure(status: AccountDeletionStatus.authFailed),
          'Could not verify your session. Please sign in again and retry.',
        );
      },
    );
  });

  group('Gate 6 — double-submission (20)', () {
    testWidgets(
      '20: a second tap while a request is in flight does not fire a '
      'second deleteAccount() call',
      (tester) async {
        final completer = Completer<AccountDeletionResult>();
        when(() => accountDeletionRepository.deleteAccount())
            .thenAnswer((_) => completer.future);

        await pump(tester);
        await openAndConfirmDelete(tester);
        await tester.pump(); // _isDeletingAccount becomes true, request in flight

        // Row is now guarded -- tapping it again must not reopen the
        // confirmation flow / fire a second request.
        await tester.ensureVisible(find.text('Delete Account'));
        await tester.tap(find.text('Delete Account'));
        await tester.pump();

        verify(() => accountDeletionRepository.deleteAccount()).called(1);

        // Resolve with a safe, non-navigating outcome so the test settles
        // cleanly (no pending timers/Firebase calls left dangling).
        completer.complete(
          AccountDeletionResult.failure(status: AccountDeletionStatus.serverError),
        );
        await tester.pumpAndSettle();
      },
    );
  });
}
