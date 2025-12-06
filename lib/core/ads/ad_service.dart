// lib/core/ads/ad_service.dart

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

class AdService {
  static bool _initialized = false;

  /// ------------------------------------
  /// INITIALIZE SDK (Call once in main)
  /// ------------------------------------
  static Future<void> initialize() async {
    if (_initialized) return;

    await MobileAds.instance.initialize();
    _initialized = true;

    // Optional: global config
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: <String>[
          'YOUR_TEST_DEVICE_ID', // change if needed
        ],
      ),
    );
  }

  // =========================================================
  //  BANNER AD
  // =========================================================
  static BannerAd loadBanner({
    required Function(BannerAd) onAdLoaded,
    Function? onAdFailed,
  }) {
    BannerAd banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AdIds.bannerTest, // TEST
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (onAdFailed != null) onAdFailed();
        },
      ),
      request: const AdRequest(),
    );

    banner.load();
    return banner;
  }

  // =========================================================
  //  INTERSTITIAL AD
  // =========================================================
  static InterstitialAd? _interstitial;

  static void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitialTest,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  static void showInterstitial() {
    if (_interstitial == null) return;

    _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial(); // Preload next one
      },
    );

    _interstitial!.show();
    _interstitial = null;
  }

  // =========================================================
  //  REWARDED AD
  // =========================================================
  static RewardedAd? _rewarded;

  static void loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewardedTest,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  static void showRewarded({required Function(int rewardAmount) onReward}) {
    if (_rewarded == null) return;

    _rewarded!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded(); // preload next
      },
    );

    _rewarded!.show(
      onUserEarnedReward: (ad, reward) {
        onReward(reward.amount.toInt());
      },
    );

    _rewarded = null;
  }
}
