import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_units.dart';

class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  static void load() {
    if (_isLoading) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: AdUnits.rewardedAdUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoading = false;
          print("🎉 Rewarded Ad Loaded");
        },
        onAdFailedToLoad: (LoadAdError err) {
          print("❌ Failed to load rewarded ad: $err");
          _isLoading = false;

          Future.delayed(const Duration(seconds: 5), () {
            load();
          });
        },
      ),
    );
  }

  /// ⭐ IMPORTANT: We IGNORE `onUserEarnedReward`
  /// Reward will NOT be granted here → Only ad completion will be counted.
  static Future<void> show({
    required Function() onAdCompleted, // <-- renamed
    Function()? onFailed,
  }) async {
    if (_rewardedAd == null) {
      print("⚠ RewardedAd NULL. Loading again…");
      load();
      onFailed?.call();
      return;
    }

    final ad = _rewardedAd;
    _rewardedAd = null;

    ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print("📌 Ad Closed → Mark as completed");
        onAdCompleted(); // <-- THIS triggers "Ad 1/2 completed"

        ad.dispose();
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        print("❌ Failed to show rewarded: $err");
        ad.dispose();
        load();
        onFailed?.call();
      },
    );

    ad.show(
      // IGNORE reward event completely
      onUserEarnedReward: (ad, reward) {
        print("⚠ Ignored Reward Callback: AdMob auto-grant");
      },
    );
  }
}
