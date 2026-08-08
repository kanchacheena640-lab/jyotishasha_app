import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/widgets/trending_questions_widget.dart';

import '../../helpers/test_harness.dart';

void main() {
  Future<void> pumpWidget(WidgetTester tester, {String lang = 'en'}) async {
    final languageProvider = LanguageProvider()..currentLang = lang;

    await tester.pumpTestHarness(
      const Scaffold(body: TrendingQuestionsWidget()),
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ],
    );
  }

  testWidgets(
    'shows the heading, subtitle, and exactly one "Ask Now →" CTA in '
    'English — no FREE QUESTION label, no pill (F5.7)',
    (tester) async {
      await pumpWidget(tester);

      expect(find.text('Question in mind..'), findsOneWidget);
      expect(find.text('One free question every day.'), findsOneWidget);
      expect(find.text('Ask Now →'), findsOneWidget);

      // Old copy from earlier iterations must be gone.
      expect(find.text('FREE QUESTION'), findsNothing);
      expect(find.text("Don't move with doubt."), findsNothing);
      expect(find.text('Daily 1 Question Free.'), findsNothing);
      expect(find.textContaining('Free Question Available'), findsNothing);
      expect(find.text('✨ Ask Anything'), findsNothing);
    },
  );

  testWidgets(
    'the avatar/person illustration is removed entirely (F5.4)',
    (tester) async {
      await pumpWidget(tester);

      expect(find.byIcon(Icons.person_rounded), findsNothing);
      expect(find.text('?'), findsNothing);
    },
  );

  testWidgets('the banner is 82dp tall (F5.6)', (tester) async {
    await pumpWidget(tester);

    final size = tester.getSize(find.byType(TrendingQuestionsWidget));
    expect(size.height, 82);
  });

  testWidgets('renders Hindi copy', (tester) async {
    await pumpWidget(tester, lang: 'hi');

    expect(find.text('मन में कोई सवाल..'), findsOneWidget);
    expect(find.text('हर दिन एक सवाल मुफ़्त।'), findsOneWidget);
    expect(find.text('अभी पूछें →'), findsOneWidget);
  });

  testWidgets(
    'the whole card is a single tap target (one GestureDetector covering '
    'both the heading and the "Ask Now →" button)',
    (tester) async {
      // AskNowChatPage (the navigation destination) touches
      // FirebaseAuth.instance directly in its own initState, unrelated to
      // this widget and unavailable in this test environment — so this
      // verifies the tap-target wiring structurally instead of completing
      // a full navigation, consistent with this suite's existing pattern
      // for other Firebase-backed destinations.
      await pumpWidget(tester);

      expect(find.byType(GestureDetector), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.text('Ask Now →'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.text('Question in mind..'),
        ),
        findsOneWidget,
      );
    },
  );
}
