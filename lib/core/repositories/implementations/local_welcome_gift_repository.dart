import 'package:shared_preferences/shared_preferences.dart';

import '../welcome_gift_repository.dart';

/// Local-only implementation — a single SharedPreferences flag, the same
/// simple persistence pattern `LanguageProvider` already uses for
/// `app_lang`. This is intentional for this task: the Welcome Gift claim
/// is not yet backed by the backend, so it is only remembered on this
/// device/install.
///
/// TODO(backend): once the backend exposes Welcome Gift status/claim
/// endpoints, add an HTTP-backed `WelcomeGiftRepository` (e.g.
/// `BackendWelcomeGiftRepository`, mirroring `PlayBillingRepository`'s
/// relationship to `BillingRepository`) and construct `WelcomeGiftProvider`
/// with it instead of this class. `WelcomeGiftProvider` and every UI
/// widget only depend on the [WelcomeGiftRepository] interface, so this
/// swap needs no other changes — claimed state would then survive
/// reinstalls and sync across devices instead of living only in
/// SharedPreferences.
final class LocalWelcomeGiftRepository implements WelcomeGiftRepository {
  static const String _claimedKey = 'welcome_gift_claimed';

  @override
  Future<bool> isClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_claimedKey) ?? false;
  }

  @override
  Future<void> markClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claimedKey, true);
  }
}
