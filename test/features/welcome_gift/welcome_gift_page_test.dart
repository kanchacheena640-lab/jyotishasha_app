import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/repositories/welcome_gift_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/state/welcome_gift_provider.dart';
import 'package:jyotishasha_app/features/explore/explore_page.dart';
import 'package:jyotishasha_app/features/welcome_gift/welcome_gift_page.dart';

import '../../helpers/test_harness.dart';

class _FakeWelcomeGiftRepository implements WelcomeGiftRepository {
  bool claimed = false;
  int markClaimedCalls = 0;

  @override
  Future<bool> isClaimed() async => claimed;

  @override
  Future<void> markClaimed() async {
    markClaimedCalls++;
    claimed = true;
  }
}

void main() {
  late _FakeWelcomeGiftRepository repository;
  late WelcomeGiftProvider provider;

  setUp(() {
    repository = _FakeWelcomeGiftRepository();
    provider = WelcomeGiftProvider(repository: repository);
  });

  Future<void> pump(WidgetTester tester, {String lang = 'en'}) async {
    await tester.pumpTestHarness(
      const WelcomeGiftPage(),
      providers: [
        ChangeNotifierProvider<WelcomeGiftProvider>.value(value: provider),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: LanguageProvider()..currentLang = lang,
        ),
        // Claiming navigates to ExplorePage, whose membership strip now
        // reads SubscriptionProvider — required in the tree even though
        // these tests never inspect its content.
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider()..subscriptionData = {
            'active': false,
            'status': 'none',
          },
        ),
      ],
    );
  }

  testWidgets(
    'shows the header, all 5 premium report cards (with the "Premium '
    'Report · Birth Chart Based" caption on each), the membership card, '
    'and the Claim button — no prices, no plans, no marketing copy',
    (tester) async {
      await pump(tester);

      expect(find.text('🎁'), findsOneWidget);
      expect(find.text('Welcome Gift'), findsOneWidget);
      expect(
        find.text('Unlock your personalized astrology experience.'),
        findsOneWidget,
      );
      expect(find.text('PREMIUM REPORTS'), findsOneWidget);

      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('Love Report'), findsOneWidget);
      expect(find.text('💼'), findsOneWidget);
      expect(find.text('Career Report'), findsOneWidget);
      expect(find.text('💰'), findsOneWidget);
      expect(find.text('Finance Report'), findsOneWidget);
      expect(find.text('🌿'), findsOneWidget);
      expect(find.text('Health Report'), findsOneWidget);
      expect(find.text('👨‍👩‍👧'), findsOneWidget);
      expect(find.text('Family Report'), findsOneWidget);
      expect(
        find.text('Premium Report · Birth Chart Based'),
        findsNWidgets(5),
      );

      expect(find.text('7 Days Premium Membership'), findsOneWidget);
      expect(
        find.text('Access current planetary updates for all sections.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Claim Free Access'), findsOneWidget);

      // No pricing/plan/purchase/marketing affordances anywhere on this
      // screen.
      expect(find.textContaining('₹'), findsNothing);
      expect(find.textContaining('Subscribe'), findsNothing);
      expect(find.textContaining('Upgrade'), findsNothing);
    },
  );

  testWidgets('renders Hindi copy for the header, reports and Claim button', (
    tester,
  ) async {
    await pump(tester, lang: 'hi');

    expect(find.text('वेलकम गिफ्ट'), findsOneWidget);
    expect(
      find.text('अपना पर्सनलाइज़्ड ज्योतिष अनुभव अनलॉक करें।'),
      findsOneWidget,
    );
    expect(find.text('प्रेम रिपोर्ट'), findsOneWidget);
    expect(
      find.text('प्रीमियम रिपोर्ट · जन्म कुंडली आधारित'),
      findsNWidgets(5),
    );
    expect(find.text('7 दिनों की प्रीमियम मेंबरशिप'), findsOneWidget);
    expect(
      find.text('सभी सेक्शन के लिए वर्तमान ग्रह अपडेट प्राप्त करें।'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'फ्री एक्सेस पाएं'), findsOneWidget);
  });

  testWidgets(
    'tapping Claim Free Access simulates activation, marks the gift '
    'claimed, and navigates to Explore — no report generation, no '
    'subscription activation, no backend call',
    (tester) async {
      await pump(tester);

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Claim Free Access'),
      );
      await tester.pump();
      // Past the default MaterialPageRoute transition (300ms) so the
      // replaced route is fully removed from the tree.
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.markClaimedCalls, 1);
      expect(provider.isClaimed, isTrue);
      expect(find.byType(ExplorePage), findsOneWidget);
      expect(find.byType(WelcomeGiftPage), findsNothing);
    },
  );

  testWidgets(
    'disables the Claim button and shows a spinner while claiming is in '
    'flight',
    (tester) async {
      provider = WelcomeGiftProvider(repository: repository)..isClaiming = true;

      await pump(tester);

      expect(find.text('Claim Free Access'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    },
  );
}
