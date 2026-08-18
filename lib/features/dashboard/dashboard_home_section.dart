import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

// Task 4A — the existing, already-proven boundary ProfileService/
// FirestoreProfileRepository already use to read the current Firebase
// user without depending on FirebaseAuth directly (see
// lib/core/identity/). Reused here rather than adding a new one.
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/identity/firebase_current_user_identity_port.dart';

// Widgets
import 'package:jyotishasha_app/core/widgets/greeting_header_widget.dart';
import 'package:jyotishasha_app/core/widgets/transit_alert_widget.dart';

import 'package:jyotishasha_app/core/widgets/chaughadiya_alert_widget.dart';
import 'package:jyotishasha_app/core/widgets/trending_questions_widget.dart';

import 'package:jyotishasha_app/features/muhurth/muhurth_page.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:jyotishasha_app/core/widgets/create_another_kundali_banner.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/widgets/shubh_muhurth_preview_widget.dart';
import 'package:jyotishasha_app/core/widgets/share_strip_widget.dart';
import 'package:jyotishasha_app/core/widgets/todays_essentials_widget.dart';

// State
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';

class DashboardHomeSection extends StatefulWidget {
  const DashboardHomeSection({super.key, CurrentUserIdentityPort? identityPort})
    : _identityPort = identityPort;

  /// Task 4A — injectable seam (defaults to the real, production
  /// `FirebaseCurrentUserIdentityPort` below) so tests can supply a fake
  /// that resolves immediately instead of needing a real signed-in
  /// Firebase user, which this widget-test environment has no way to
  /// provide. Production callers never pass this — the one real
  /// `DashboardHomeSection()` construction site (dashboard_page.dart)
  /// is unchanged.
  final CurrentUserIdentityPort? _identityPort;

  @override
  State<DashboardHomeSection> createState() => _DashboardHomeSectionState();
}

class _DashboardHomeSectionState extends State<DashboardHomeSection>
    with WidgetsBindingObserver {
  late final CurrentUserIdentityPort _identityPort =
      widget._identityPort ?? FirebaseCurrentUserIdentityPort();

  /// Task 4A — a real, cancellable `Timer` (was a bare `Future.delayed`
  /// inside the polling loop below, with no handle to cancel).
  /// Previously, disposing this widget while still waiting for a signed-
  /// in user left the poll running in the background indefinitely
  /// instead of actually stopping — dispose() now cancels it outright.
  Timer? _unreadPollTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Task 4A — deferred to the next frame (matching the same
    // addPostFrameCallback convention GreetingHeaderWidget's own
    // unread-count kickoff already uses), not called synchronously from
    // initState. This was already effectively true before (the original
    // polling loop always awaited a 300ms Future.delayed before its
    // first real check, so NotificationProvider.loadUnreadCount() could
    // never fire during the initial build), but relied on that delay's
    // side effect rather than stating the requirement directly — a
    // resolved-immediately current-user check (as an injected test
    // double can produce) would otherwise call
    // NotificationProvider.loadUnreadCount() synchronously inside this
    // widget's own first build, which Flutter disallows
    // (notifyListeners() cannot mark a provider dirty while the tree is
    // still being built).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _unreadPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
    }
  }

  /// Same "keep trying every 300ms until someone is signed in" contract
  /// as before — same cadence, same eventual
  /// `NotificationProvider.loadUnreadCount()` call. Two lifecycle fixes
  /// on top of the original: (1) the current-user read now goes through
  /// [CurrentUserIdentityPort] (the same boundary `ProfileService`
  /// already uses) instead of `FirebaseAuth.instance` directly, wrapped
  /// defensively — an unexpected error there (e.g. an initialization
  /// race) now means "keep polling" instead of an unhandled exception
  /// escaping this fire-and-forget call, the same failure mode this
  /// method already treated "no user yet" as; (2) the wait between
  /// attempts is a real, cancellable `Timer`, and the loop itself now
  /// checks `mounted` on every iteration, so leaving this screen while
  /// still waiting for a user actually stops the poll instead of leaving
  /// it running forever in the background.
  Future<void> _loadUnreadCount() async {
    String? uid = _currentUidOrNull();

    while (mounted && uid == null) {
      final waited = Completer<void>();
      _unreadPollTimer = Timer(const Duration(milliseconds: 300), () {
        if (!waited.isCompleted) waited.complete();
      });
      await waited.future;
      if (!mounted) return;
      uid = _currentUidOrNull();
    }

    if (!mounted || uid == null) return;

    await context.read<NotificationProvider>().loadUnreadCount();
  }

  String? _currentUidOrNull() {
    try {
      return _identityPort.currentFirebaseUid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onRefresh() async {
    final profile = context.read<ProfileProvider>().activeProfile ?? {};
    final sign = profile["rashi"] ?? profile["sign"];
    final lang = context.read<LanguageProvider>().currentLang;

    await Future.wait([
      if (sign != null)
        context.read<DailyProvider>().fetchDaily(
          sign: sign,
          lang: lang,
          force: true,
        ),
      context.read<TransitProvider>().fetchTransit(),
      _loadUnreadCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: GreetingHeaderWidget()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ChaughadiyaAlertWidget supplies its own 24dp top/
                    // bottom margins (F4.2.3 "Header → Current Timing" /
                    // "Footer → Ask Now" spacing) — no extra gap needed
                    // around it here.
                    const ChaughadiyaAlertWidget(),
                    // Share strip moved here, immediately below Current
                    // Timing and above Today's Essentials (F5.4 flow:
                    // Current Timing → Share → Today's Essentials →
                    // Ask Now).
                    const ShareStripWidget(),
                    const SizedBox(height: 16),
                    const TodaysEssentialsWidget(),
                    const SizedBox(height: 16),
                    const TrendingQuestionsWidget(),
                    const SizedBox(height: 16),
                    const TransitAlertWidget(),
                    const SizedBox(height: 16),
                    ShubhMuhurthPreviewWidget(
                      muhurthList: [
                        {
                          "event": t.localeName == "hi"
                              ? "नामकरण"
                              : "Naamkaran",
                        },
                        {"event": t.localeName == "hi" ? "विवाह" : "Marriage"},
                        {
                          "event": t.localeName == "hi"
                              ? "गृह प्रवेश"
                              : "Griha Pravesh",
                        },
                        {"event": t.localeName == "hi" ? "वाहन" : "Vehicle"},
                        {
                          "event": t.localeName == "hi"
                              ? "संपत्ति"
                              : "Property",
                        },
                        {"event": t.localeName == "hi" ? "सोना" : "Gold"},
                        {"event": t.localeName == "hi" ? "यात्रा" : "Travel"},
                        {
                          "event": t.localeName == "hi"
                              ? "शिशु जन्म"
                              : "Childbirth",
                        },
                      ],
                      // F6.5: Home no longer opens CardsPage — MuhurthPage
                      // is now the sole destination, with the tapped
                      // category preselected.
                      onTapType: (type) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MuhurthPage(initialActivity: type),
                          ),
                        );
                      },
                      onSeeMore: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MuhurthPage(),
                          ),
                        );
                      },
                    ),
                    // F8.8 — relocated from after the Footer (F8.7.3) to
                    // here: Shubh Muhurth → Create Another Kundali →
                    // Feedback/Footer, so the Footer stays the true last
                    // section on Home. Presentation and navigation
                    // unchanged — placement only.
                    const SizedBox(height: 20),
                    const CreateAnotherKundaliBanner(),
                    const SizedBox(height: 16),
                    const Divider(thickness: 0.6, color: Colors.black12),
                    const AppFooterFeedbackWidget(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDayLordCTA(BuildContext context, AppLocalizations t) {
    return GestureDetector(
      onTap: () => context.push('/darshan'),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          "ॐ",
                          style: TextStyle(fontSize: 32, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.darshanInstruction.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.darshanWithMantra,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations t) {
    return Column(
      children: [
        Container(width: 40, height: 2, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          t.footerCopyright,
          style: TextStyle(
            color: Colors.blueGrey[300],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t.footerPrivacyTerms,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]),
        ),
      ],
    );
  }
}
