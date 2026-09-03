import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/analytics/session_start_producer.dart';
import '../../core/analytics/install_attribution_producer.dart';
import '../../core/constants/app_colors.dart';
import '../../services/profile_completeness_service.dart';
import '../../services/app_version_gate_service.dart';
import '../update_required/update_required_page.dart';
import '../update_required/soft_update_dialog.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // P0 -- Recover authenticated users with incomplete birth profiles:
  // when the completeness check itself fails (network/backend issue),
  // this becomes true and the splash screen shows an inline retry
  // state instead of guessing. `false` (the default) keeps today's
  // exact loading-spinner appearance for every other case.
  bool _showRetry = false;

  // Ask Now Security + Force Update task, Part D -- set only when a
  // valid backend response explicitly established this build is
  // unsupported (AppVersionGateService's own fail-open contract means
  // every other outcome, including any failure, leaves this null and
  // the existing flow below proceeds completely unchanged).
  AppVersionGateResult? _blockingUpdate;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (mounted && _showRetry) {
      setState(() => _showRetry = false);
    }

    // Reusable App Update System -- runs FIRST, before the splash
    // animation delay and before any auth/profile check, so a
    // FORCE-state build is never allowed to reach /login or /dashboard
    // even briefly. Fail-open (AppVersionGateService's own contract):
    // any network/parse failure resolves to AppUpdateStatus.none here,
    // so this never adds a blocking step to the normal startup path.
    final gate = await AppVersionGateService.checkForUpdate();
    if (!mounted) return;

    switch (gate.status) {
      case AppUpdateStatus.force:
        setState(() => _blockingUpdate = gate);
        return; // Never proceeds into login/dashboard/birth routing below.
      case AppUpdateStatus.soft:
        // Non-blocking: shown once, then the normal startup flow below
        // continues regardless of which button (or dismissal path) the
        // user took -- there is nothing to block here.
        await showSoftUpdatePrompt(
          context,
          storeUrl: gate.storeUrl,
          operatorMessage: gate.message,
        );
        if (!mounted) return;
        break;
      case AppUpdateStatus.none:
        break;
    }

    // 🔹 Short delay for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // 🌙 New or logged-out user → Onboarding / Login
        Future.microtask(() {
          if (!mounted) return;
          context.go('/login');
        });
        return;
      }

      // Phase 5B -- a real, already-authenticated Firebase user is
      // present at this exact point (the `user == null` branch above
      // already returned). This is the "returning user cold start" seam:
      // fire-and-forget, at most once per process (SessionStartProducer's
      // own in-memory guard) -- never awaited, never allowed to affect
      // the navigation decision below in any way.
      SessionStartProducer.attemptOnce(entryPoint: 'cold_start');

      // Task 5A -- FIRST SAFE AUTHENTICATED OPPORTUNITY (restored-session
      // case): a real authenticated Firebase user is present at this
      // exact point (the `user == null` branch above already returned),
      // which is exactly what "first authenticated opportunity" must
      // cover beyond just a fresh interactive login -- a user whose
      // session was restored on a later cold start, who never touched
      // LoginPage this run, must still get a chance to have any captured
      // install attribution recorded. Fire-and-forget, at most a no-op
      // if already recorded or already attempted with nothing to send
      // (InstallAttributionProducer's own idempotent guard), never
      // allowed to affect the profile-completeness check/navigation
      // below.
      InstallAttributionProducer.attemptOnce();

      // 🌞 Firebase session present -- resolve backend profile
      // completeness before deciding Dashboard vs. birth-detail setup.
      // This is the SAME source of truth LoginPage's fresh-sign-in
      // path now uses, so a persisted-session relaunch and a fresh
      // login never disagree about the same user.
      final result = await ProfileCompletenessService.checkCompleteness();

      if (!mounted) return;

      if (result.checkFailed) {
        // Network/backend failure: do NOT classify as incomplete (that
        // would force a genuinely complete user through destructive
        // re-onboarding on a transient blip), and do NOT silently
        // proceed to Dashboard either (that discards the whole point
        // of this check). Show an explicit retry state instead.
        setState(() => _showRetry = true);
        return;
      }

      Future.microtask(() {
        if (!mounted) return;
        if (result.isComplete) {
          context.go('/dashboard');
        } else {
          // Authenticated but the backend AppUser profile is missing
          // required birth fields -- send them to complete it, exactly
          // like a brand-new user would go through BirthDetailPage.
          context.go('/birth');
        }
      });
    } catch (e) {
      debugPrint('🔥 Splash navigation error: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockingUpdate = _blockingUpdate;
    if (blockingUpdate != null) {
      return UpdateRequiredPage(
        storeUrl: blockingUpdate.storeUrl,
        operatorMessage: blockingUpdate.message,
      );
    }

    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Jyotishasha",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your Personalized Path to the Stars",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 50),
              if (_showRetry) ...[
                Text(
                  "Couldn't reach the server. Check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkAuthAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text("Retry"),
                ),
              ] else
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.2,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
