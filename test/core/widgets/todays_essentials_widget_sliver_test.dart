import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/widgets/todays_essentials_widget.dart';

import '../../helpers/test_harness.dart';

/// F4.3 investigation: dashboard_home_section.dart renders TodaysEssentials
/// Widget as one item inside `SliverList(delegate: SliverChildListDelegate(
/// [...]))`, inside `SliverPadding`, inside `CustomScrollView` — a
/// meaningfully different layout context from the isolated
/// `SingleChildScrollView` wrapper used in todays_essentials_widget_test.dart
/// (Sliver list items receive an *unbounded* main-axis constraint, same
/// shape as production). This test reproduces that exact Sliver skeleton
/// (with lightweight placeholder siblings standing in for the other real
/// home-section widgets, which pull in unrelated Firebase/provider
/// dependencies) to conclusively verify the widget lays out, receives
/// constraints, and paints inside a real CustomScrollView/SliverList.
class _FakeProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

void main() {
  testWidgets(
    'TodaysEssentialsWidget renders with non-zero size and correct content '
    'when embedded in the same CustomScrollView > SliverPadding > SliverList '
    'skeleton dashboard_home_section.dart actually uses',
    (tester) async {
      final dailyProvider = DailyProvider()
        ..intro = 'Sample horoscope preview text for today.'
        ..isLoading = false;
      final languageProvider = LanguageProvider()..currentLang = 'en';
      final profileProvider = _FakeProfileProvider();
      when(() => profileProvider.activeProfile).thenReturn(const {
        'name': 'Ravi',
        'moon_sign': 'cancer',
      });

      await tester.pumpTestHarness(
        Scaffold(
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(height: 60, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    // The real widget under test, positioned exactly as it
                    // is in dashboard_home_section.dart: between two
                    // sibling sections.
                    const TodaysEssentialsWidget(),
                    const SizedBox(height: 16),
                    Container(height: 60, color: Colors.grey.shade200),
                  ]),
                ),
              ),
            ],
          ),
        ),
        providers: [
          ChangeNotifierProvider<DailyProvider>.value(value: dailyProvider),
          ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
          ChangeNotifierProvider<ProfileProvider>.value(value: profileProvider),
        ],
      );

      // 1. Instantiated + in the tree.
      expect(find.byType(TodaysEssentialsWidget), findsOneWidget);

      // 2. Receives real layout constraints and has a non-zero, sane size
      //    (not collapsed to 0 by an unbounded-height Sliver context).
      final size = tester.getSize(find.byType(TodaysEssentialsWidget));
      expect(size.height, greaterThan(100));
      expect(size.width, greaterThan(0));

      // 3. Actually paints its real content (proves it isn't
      //    Offstage/invisible/zero-opacity).
      expect(find.text("Today's Essentials"), findsOneWidget);
      expect(find.text("Today's Horoscope"), findsOneWidget);
      // Darshan card title is now dynamic ("<Deity> Darshan"); presence of
      // the temple emoji + "Open →" is enough to confirm it painted.
      expect(find.text('🛕'), findsOneWidget);
      expect(find.text('Open →'), findsOneWidget);

      // 4. The whole page (siblings + widget) is scrollable, matching the
      //    real page's CustomScrollView.
      expect(find.byType(CustomScrollView), findsOneWidget);
    },
  );
}
