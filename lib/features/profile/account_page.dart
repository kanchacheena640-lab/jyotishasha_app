// lib/features/profile/account_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jyotishasha_app/core/messaging/fcm_token_manager.dart';
import 'package:jyotishasha_app/core/models/account/account_deletion_contracts.dart';
import 'package:jyotishasha_app/core/repositories/account_deletion_repository.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_account_deletion_repository.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/utils/trial_countdown.dart';
import 'package:jyotishasha_app/features/profile/edit_profile_page.dart';
import 'package:jyotishasha_app/features/subscription/subscription_page.dart';

/// The single-user "Account" experience replacing the old multi-profile
/// [ProfilePage] on the bottom nav. The multi-profile UI (add/switch/edit/
/// delete other profiles) is intentionally NOT rebuilt here — it still
/// exists in `profile_page.dart` and friends, just no longer reachable from
/// the bottom nav.
///
/// Structure (post-audit finalization): PROFILE / SUBSCRIPTION / SETTINGS
/// / HELP & LEGAL / ACCOUNT. Premium-service discovery (Premium Reports,
/// AI Love Insights, Free Horoscope PDF, Downloads) has been deliberately
/// removed from this screen — that belongs on Explore, not Account — and
/// the four dead "Coming Soon" rows this screen previously carried are
/// gone with it.
///
/// One section from the original target structure is deliberately NOT
/// present, per that same audit's own stop-conditions rather than an
/// oversight:
/// - **Activity/History**: no existing Flutter repository or backend
///   endpoint (`ReportPurchaseProvider`, `AskNowProvider`,
///   `ReportRepository`, `SubscriptionProvider`) exposes a per-user list
///   of past purchases/subscriptions/AskNow transactions — only
///   current/in-flight state. `routes/admin_orders.py` on the backend is
///   admin-scoped, not a self-service history endpoint. Labeling a
///   fabricated or partial list "history" would be worse than omitting
///   it — see this screen's audit trail.
/// - **Appearance (Dark Mode)**: also omitted — see [_showLanguageDialog]'s
///   sibling absence; `app/theme/app_theme.dart` defines only
///   `lightTheme`, `app/app.dart` hardcodes `themeMode: ThemeMode.light`,
///   and 400+ call sites across `lib/` use raw `Color(0xFFxxxxxx)`
///   literals rather than `Theme.of(context).colorScheme` — implementing
///   real Dark Mode would require a broad, regression-risky rewrite of
///   color usage app-wide, which this task's own gate explicitly forbids
///   taking on here. Language switching has no such dependency (a single
///   existing provider, already used this way by [EditProfilePage]) and
///   proceeds independently.
///
/// **Delete Account** (D4) — added under ACCOUNT, below Logout. Backed by
/// the now-locked backend contract (D1–D3, Jyotishasha_Backend:
/// `POST /api/auth/delete-account`) via [HttpAccountDeletionRepository].
/// The backend remains the sole authoritative owner of Firebase Auth/
/// Firestore deletion — this screen never calls
/// `FirebaseAuth.currentUser.delete()` and never touches Firestore.
class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    AccountDeletionRepository? accountDeletionRepository,
  }) : _accountDeletionRepository = accountDeletionRepository;

  /// Injectable purely for tests (mirrors [AlertsDashboardPage]'s own
  /// `repository` param) — production always falls through to the real
  /// [HttpAccountDeletionRepository].
  final AccountDeletionRepository? _accountDeletionRepository;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AccountDeletionRepository _accountDeletionRepository =
      widget._accountDeletionRepository ?? HttpAccountDeletionRepository();

  /// Guards against a double-tap/re-entrant delete request (D4 Gate 6).
  /// Set synchronously before the first `await` in [_performDeleteAccount],
  /// so a second invocation arriving before the network call resolves is
  /// always rejected — Dart's single-threaded event loop makes this
  /// race-safe without any additional locking.
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProfileProvider>().loadProfiles();

      // Same provider may already be populated (e.g. the user already
      // visited SubscriptionPage this session) — avoid an unnecessary
      // duplicate fetch, matching KundaliOverviewPage's identical guard.
      final subscription = context.read<SubscriptionProvider>();
      if (subscription.subscriptionData == null && !subscription.isLoading) {
        subscription.loadSubscriptionInfo();
      }
    });
  }

  /// PROFILE → Edit Profile. Reconnects the existing, previously
  /// orphaned [EditProfilePage] (formerly reachable only through the
  /// dead `/profile` → `ProfilePage` → `ProfileListPage` chain — see
  /// this screen's audit trail) directly with the current active
  /// profile, bypassing the multi-profile UI entirely, consistent with
  /// this screen's own single-user design. [EditProfilePage] calls
  /// `ProfileProvider.updateProfile()`/`deleteProfile()` internally on
  /// save/delete, both of which already call `loadProfiles()` themselves
  /// — Account's own `context.watch<ProfileProvider>()` picks up the
  /// refreshed data reactively the moment that completes, with no extra
  /// fetch needed here.
  void _openEditProfile(Map<String, dynamic>? profile) {
    if (profile == null || profile.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: profile)),
    );
  }

  /// SUBSCRIPTION → Manage Subscription. Always navigates to
  /// [SubscriptionPage], regardless of current status — the only way in,
  /// so an already-subscribed user still has a path back into the
  /// subscription screen. [SubscriptionPage] reloads
  /// `SubscriptionProvider.subscriptionData` on its own mount (`autoLoad`
  /// defaults `true`), and both screens share the same provider
  /// instance, so Account's own subscription card reflects any change
  /// (upgrade, restore, trial activation) reactively once the user
  /// returns — no extra refresh call needed here.
  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
    );
  }

  Future<void> _openExternalUrl(Uri uri, bool isHindi) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('launchUrl returned false');
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isHindi
                ? 'यह पेज नहीं खोला जा सका। कृपया पुनः प्रयास करें।'
                : "This page couldn't be opened. Please try again.",
          ),
        ),
      );
    }
  }

  Future<void> _showLanguageDialog(bool isHindi) async {
    final languageProvider = context.read<LanguageProvider>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isHindi ? 'भाषा चुनें' : 'Choose Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOptionTile(
                label: 'English',
                selected: languageProvider.currentLang == 'en',
                onTap: () {
                  languageProvider.setLanguage('en');
                  Navigator.pop(dialogContext);
                },
              ),
              _LanguageOptionTile(
                label: 'हिन्दी',
                selected: languageProvider.currentLang == 'hi',
                onTap: () {
                  languageProvider.setLanguage('hi');
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ACCOUNT → Logout. Confirmation dialog added (previously none —
  /// logout fired immediately on tap); the existing, already-working
  /// sign-out sequence below is otherwise ported verbatim from the old
  /// ProfilePage, with one hardening: [ProfileProvider.reset]/
  /// [SubscriptionProvider.reset] are now called before navigating away,
  /// so a second account logging into the same long-lived app process
  /// never briefly renders the first account's profile/membership state
  /// before its own fresh load resolves. Global, account-independent
  /// preferences (language, theme) are deliberately left untouched.
  Future<void> _confirmLogout(bool isHindi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isHindi ? 'लॉगआउट करें?' : 'Logout?'),
        content: Text(
          isHindi
              ? 'क्या आप वाकई लॉगआउट करना चाहते हैं?'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              isHindi ? 'लॉगआउट' : 'Logout',
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    await _logout(isHindi);
  }

  Future<void> _logout(bool isHindi) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHindi ? 'सफलतापूर्वक लॉगआउट हो गया' : 'Logout Successfully',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await _signOutLocallyAndReturnToLogin();
  }

  /// Shared local-session teardown — used by [_logout] AND by a fully
  /// successful Delete Account (D4 Gate 5). Only ever calls the
  /// ordinary, non-destructive `signOut()` — never
  /// `FirebaseAuth.currentUser.delete()`. In the delete-account case this
  /// only runs once the backend (D1–D3) has already confirmed the
  /// account, its Firestore data, AND its Firebase Auth user are all
  /// genuinely gone server-side; by that point this local session is
  /// already stale, and this just clears it from the app.
  Future<void> _signOutLocallyAndReturnToLogin() async {
    try {
      await fcmTokenManager.clearOnLogout();
    } catch (_) {}

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;

    // Must run before navigating away — this is the last point this
    // widget is guaranteed still mounted/attached to its providers.
    context.read<ProfileProvider>().reset();
    context.read<SubscriptionProvider>().reset();

    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  /// ACCOUNT → Delete Account. Opens a clear, explicit warning dialog
  /// (D4 Gate 3) — a deliberate second tap on a destructively-styled
  /// button is required, matching [_confirmLogout]'s own established
  /// pattern, never a single accidental tap.
  Future<void> _confirmDeleteAccount(bool isHindi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isHindi ? 'अकाउंट डिलीट करें?' : 'Delete Account?'),
        content: Text(
          isHindi
              ? 'आपका अकाउंट और प्रोफ़ाइल डेटा स्थायी रूप से डिलीट कर दिया जाएगा। यह क्रिया पूर्ववत नहीं की जा सकती।\n\nध्यान दें: अकाउंट डिलीट करने से आपकी सक्रिय Google Play / Apple सदस्यता अपने आप रद्द नहीं होती — कृपया उसे Play Store / App Store से अलग से रद्द करें।'
              : 'Your account and profile data will be permanently deleted. This action cannot be undone.\n\nNote: deleting your Jyotishasha account does not automatically cancel an active Google Play / Apple subscription — please cancel that separately from the Play Store / App Store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              isHindi ? 'अकाउंट डिलीट करें' : 'Delete Account',
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    await _performDeleteAccount(isHindi);
  }

  /// Sends the request via [_accountDeletionRepository] (backend
  /// D1–D3's locked contract) and branches on the typed
  /// [AccountDeletionResult.status] — never on a raw HTTP code here (D4
  /// Gate 2/5/6).
  Future<void> _performDeleteAccount(bool isHindi) async {
    if (_isDeletingAccount) return; // Gate 6 -- double-tap suppression
    setState(() => _isDeletingAccount = true); // row shows a disabled/no-op state until this resolves

    final messenger = ScaffoldMessenger.of(context);

    AccountDeletionResult result;
    try {
      result = await _accountDeletionRepository.deleteAccount();
    } catch (e) {
      // Defensive only -- HttpAccountDeletionRepository itself never
      // throws (every failure path returns a typed failure result), but
      // a future/injected repository implementation is not guaranteed
      // to uphold that. Never assume deletion occurred on an unexpected
      // exception.
      result = AccountDeletionResult.failure(
        status: AccountDeletionStatus.networkError,
        message: e.toString(),
      );
    }

    if (!mounted) return;
    setState(() => _isDeletingAccount = false);

    switch (result.status) {
      case AccountDeletionStatus.success:
        // Gate 5 — FULL SUCCESS: safe to clear local state and leave.
        await _signOutLocallyAndReturnToLogin();
        return;

      case AccountDeletionStatus.pendingCleanup:
        // Gate 5 — PENDING CLEANUP: the backend's DB-side deletion
        // already committed, but Firebase-side cleanup is not yet
        // confirmed complete. Deliberately NOT treated as full success:
        // no provider reset, no sign-out, no navigation — the user's
        // current session is left exactly as-is so the backend's own
        // retry path (re-issuing this same authenticated request,
        // possible for as long as the Firebase Auth user still exists —
        // see D3's own retry design) remains available.
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              isHindi ? 'डिलीशन प्रगति पर है' : 'Deletion In Progress',
            ),
            content: Text(
              isHindi
                  ? 'आपके अकाउंट डेटा को हटाने की प्रक्रिया शुरू हो चुकी है, लेकिन अंतिम सफ़ाई अभी पूरी नहीं हुई है। कृपया थोड़ी देर बाद पुनः प्रयास करें, या ज़रूरत पड़ने पर दोबारा साइन इन करके प्रयास करें।'
                  : "Your account data deletion has started, but final cleanup on our side hasn't finished yet. Please try again shortly — you may need to sign in again to retry.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(isHindi ? 'ठीक है' : 'OK'),
              ),
            ],
          ),
        );
        return;

      case AccountDeletionStatus.unauthorized:
      case AccountDeletionStatus.forbidden:
        // Gate 6 — do not clear local state; explain and allow retry.
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'पहचान सत्यापन विफल रहा। कृपया दोबारा साइन इन करें और पुनः प्रयास करें।'
                  : 'Identity verification failed. Please sign in again and retry.',
            ),
          ),
        );
        return;

      case AccountDeletionStatus.authFailed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'सत्यापन नहीं हो सका। कृपया दोबारा साइन इन करें और पुनः प्रयास करें।'
                  : 'Could not verify your session. Please sign in again and retry.',
            ),
          ),
        );
        return;

      case AccountDeletionStatus.serverError:
      case AccountDeletionStatus.networkError:
      case AccountDeletionStatus.malformedResponse:
        // Gate 6 — never assume deletion occurred; retry-safe UX.
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isHindi
                  ? 'अकाउंट डिलीट नहीं हो सका। कुछ भी डिलीट नहीं हुआ है — कृपया पुनः प्रयास करें।'
                  : "We couldn't delete your account. Nothing was deleted — please try again.",
            ),
          ),
        );
        return;
    }
  }

  static const Map<String, String> _zodiacSlugByKey = {
    'aries': 'aries',
    'taurus': 'taurus',
    'gemini': 'gemini',
    'cancer': 'cancer',
    'leo': 'leo',
    'virgo': 'virgo',
    'libra': 'libra',
    'scorpio': 'scorpio',
    'sagittarius': 'sagittarius',
    'capricorn': 'capricorn',
    'aquarius': 'aquarius',
    'pisces': 'pisces',
    'मेष': 'aries',
    'वृषभ': 'taurus',
    'मिथुन': 'gemini',
    'कर्क': 'cancer',
    'सिंह': 'leo',
    'कन्या': 'virgo',
    'तुला': 'libra',
    'वृश्चिक': 'scorpio',
    'धनु': 'sagittarius',
    'मकर': 'capricorn',
    'कुंभ': 'aquarius',
    'मीन': 'pisces',
  };

  String _zodiacSlug(String? sign) {
    if (sign == null || sign.isEmpty) return 'leo';
    return _zodiacSlugByKey[sign.toLowerCase().trim()] ?? 'leo';
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final provider = context.watch<ProfileProvider>();
    final profile = provider.activeProfile ?? const {};
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    final name = (profile["name"] ?? "").toString().trim();
    final displayName = name.isEmpty ? (isHindi ? "अतिथि" : "Guest") : name;
    final dob = (profile["dob"] ?? "").toString();
    final pob = (profile["pob"] ?? "").toString();
    final moonSign = profile["moon_sign"]?.toString();
    final lagna = profile["lagna"]?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      body: SafeArea(
        child: _buildBody(
          isHindi: isHindi,
          provider: provider,
          profile: profile,
          displayName: displayName,
          dob: dob,
          pob: pob,
          moonSign: moonSign,
          lagna: lagna,
          subscriptionProvider: subscriptionProvider,
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isHindi,
    required ProfileProvider provider,
    required Map<String, dynamic> profile,
    required String displayName,
    required String dob,
    required String pob,
    required String? moonSign,
    required String? lagna,
    required SubscriptionProvider subscriptionProvider,
  }) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Gate 2 — a failed loadProfiles() attempt (ProfileProvider.reset()'s
    // sibling `errorMessage` field) previously left this page spinning
    // forever with no recovery. Now surfaced with a Retry that reuses
    // the exact same loadProfiles() call.
    if (provider.errorMessage != null && profile.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                isHindi
                    ? 'प्रोफ़ाइल लोड करने में समस्या हुई।'
                    : 'Something went wrong loading your profile.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => provider.loadProfiles(),
                child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'अकाउंट' : 'Account',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 18),

          // ---------------- PROFILE ----------------
          _SectionLabel(text: isHindi ? 'प्रोफ़ाइल' : 'PROFILE'),
          const SizedBox(height: 10),
          _buildTopCard(isHindi, displayName, dob, pob, moonSign, lagna),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.edit_outlined,
            title: isHindi ? 'प्रोफ़ाइल संपादित करें' : 'Edit Profile',
            onTap: () => _openEditProfile(provider.activeProfile),
          ),
          const SizedBox(height: 20),

          // ---------------- SUBSCRIPTION ----------------
          _SectionLabel(text: isHindi ? 'सदस्यता' : 'SUBSCRIPTION'),
          const SizedBox(height: 10),
          _buildSubscriptionCard(isHindi, subscriptionProvider),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.workspace_premium_outlined,
            title: isHindi ? 'सदस्यता प्रबंधित करें' : 'Manage Subscription',
            onTap: _openSubscription,
          ),
          const SizedBox(height: 20),

          // ---------------- SETTINGS ----------------
          _SectionLabel(text: isHindi ? 'सेटिंग्स' : 'SETTINGS'),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.language_rounded,
            title: isHindi ? 'भाषा' : 'Language',
            trailingText: context.watch<LanguageProvider>().currentLang == 'hi'
                ? 'हिन्दी'
                : 'English',
            onTap: () => _showLanguageDialog(isHindi),
          ),
          const SizedBox(height: 20),

          // ---------------- HELP & LEGAL ----------------
          _SectionLabel(text: isHindi ? 'सहायता व कानूनी' : 'HELP & LEGAL'),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.help_outline_rounded,
            title: isHindi ? 'सहायता व समर्थन' : 'Help & Support',
            onTap: () => _openExternalUrl(
              Uri.parse('https://www.jyotishasha.com/contact'),
              isHindi,
            ),
          ),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.privacy_tip_outlined,
            title: isHindi ? 'गोपनीयता नीति' : 'Privacy Policy',
            onTap: () => _openExternalUrl(
              Uri.parse('https://www.jyotishasha.com/privacy-policy'),
              isHindi,
            ),
          ),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.description_outlined,
            title: isHindi ? 'नियम व शर्तें' : 'Terms & Conditions',
            onTap: () => _openExternalUrl(
              Uri.parse('https://www.jyotishasha.com/terms'),
              isHindi,
            ),
          ),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.currency_rupee_rounded,
            title: isHindi ? 'रिफंड नीति' : 'Refund Policy',
            onTap: () => _openExternalUrl(
              Uri.parse('https://www.jyotishasha.com/refund-policy'),
              isHindi,
            ),
          ),
          const SizedBox(height: 20),

          // ---------------- ACCOUNT ----------------
          _SectionLabel(text: isHindi ? 'खाता' : 'ACCOUNT'),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.logout_rounded,
            title: isHindi ? 'लॉगआउट' : 'Logout',
            iconColor: const Color(0xFFDC2626),
            titleColor: const Color(0xFFDC2626),
            onTap: () => _confirmLogout(isHindi),
          ),
          const SizedBox(height: 10),
          _AccountActionRow(
            icon: Icons.delete_forever_outlined,
            title: isHindi ? 'अकाउंट डिलीट करें' : 'Delete Account',
            iconColor: const Color(0xFFDC2626),
            titleColor: const Color(0xFFDC2626),
            onTap: _isDeletingAccount
                ? () {}
                : () => _confirmDeleteAccount(isHindi),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(
    bool isHindi,
    String name,
    String dob,
    String pob,
    String? moonSign,
    String? lagna,
  ) {
    final birthDetails = [
      dob,
      pob,
    ].where((s) => s.trim().isNotEmpty).join('  •  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF3F1FF),
                backgroundImage: AssetImage(
                  'assets/zodiac/${_zodiacSlug(moonSign)}.webp',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (birthDetails.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        birthDetails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (moonSign != null || lagna != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (moonSign != null)
                  Expanded(
                    child: _birthDetailChip(
                      isHindi ? 'चंद्र राशि' : 'Moon Sign',
                      moonSign,
                    ),
                  ),
                if (moonSign != null && lagna != null)
                  const SizedBox(width: 10),
                if (lagna != null)
                  Expanded(
                    child: _birthDetailChip(isHindi ? 'लग्न' : 'Lagna', lagna),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _birthDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  /// S5.3, superseded — now reads the SAME `membership_state`/
  /// `remaining_days` fields [SubscriptionPage]/`premium_gate.dart`
  /// already treat as the backend's finalized, single source of truth
  /// (see [SubscriptionProvider]), instead of the retired `plan`/`status`
  /// pair this card previously read on its own. No new business logic —
  /// this only mirrors [SubscriptionPage]'s own state→label mapping in a
  /// compact, single-line form; the full picture (dates, tiers,
  /// Restore Purchases) still lives only on [SubscriptionPage] itself,
  /// reached via "Manage Subscription" directly below this card.
  Widget _buildSubscriptionCard(
    bool isHindi,
    SubscriptionProvider subscriptionProvider,
  ) {
    final data = subscriptionProvider.subscriptionData;
    final state = data?['membership_state']?.toString().toUpperCase();

    String title;
    String? subtitle;
    Color? subtitleColor;

    if (data == null) {
      title = subscriptionProvider.isLoading ? '…' : '-';
    } else if (state == 'TRIAL') {
      title = isHindi ? 'फ्री ट्रायल' : 'FREE TRIAL';
      final remainingDays = data['remaining_days'];
      subtitle = TrialCountdown.label(remainingDays, isHindi);
      subtitleColor = TrialCountdown.colorFor(remainingDays);
    } else if (state == 'ACTIVE' || state == 'GRACE_PERIOD') {
      final rawPlan = data['plan']?.toString().trim();
      title = (rawPlan == null || rawPlan.isEmpty)
          ? (isHindi ? 'सक्रिय' : 'Active')
          : rawPlan;
      if (state == 'GRACE_PERIOD') {
        subtitle = isHindi ? 'ग्रेस पीरियड' : 'Grace Period';
        subtitleColor = const Color(0xFF9A5B00);
      } else {
        final endAt = _formatDate(data['end_at']);
        if (endAt != null) {
          subtitle = isHindi ? '$endAt तक सक्रिय' : 'Renews / active until $endAt';
        }
      }
    } else if (state == 'EXPIRED') {
      title = isHindi ? 'समाप्त' : 'Expired';
      subtitle = isHindi
          ? 'प्रीमियम सुविधाओं के लिए सब्सक्राइब करें'
          : 'Subscribe to unlock premium features';
    } else {
      // NONE, or any unrecognized/missing value — never a fabricated
      // "Free User" default; shows exactly what the backend reported.
      title = isHindi ? 'मुफ़्त' : 'Free';
      subtitle = isHindi ? 'कोई सक्रिय सदस्यता नहीं' : 'No active subscription';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3F1FF),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 18,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'सदस्यता' : 'Subscription',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor ?? const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Same `DD-MM-YYYY` convention [SubscriptionPage]'s own `_formatDate`
  /// uses — presentation-only, mirrors that established formatting, not
  /// a new date-handling implementation.
  String? _formatDate(dynamic raw) {
    final text = raw?.toString();
    if (text == null || text.isEmpty) return null;
    try {
      final parsed = DateTime.parse(text);
      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    } catch (_) {
      return text;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5))
          : null,
      onTap: onTap,
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFF4F46E5),
    this.titleColor = const Color(0xFF111827),
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color titleColor;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDEDF2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Color(0xFFBBBBBB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
