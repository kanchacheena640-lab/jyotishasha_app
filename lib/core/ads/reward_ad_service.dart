// lib/core/ads/reward_ad_service.dart

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class RewardAdService {
  RewardedAd? _rewardedAd;
  int watchedCount = 0; // 2 ads = 1 reward unlock

  final VoidCallback onRewardCompleted;

  RewardAdService({required this.onRewardCompleted});

  /// LOAD REWARDED AD
  void loadAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // TEST ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint("⭐ Rewarded Ad Loaded");
        },
        onAdFailedToLoad: (err) {
          debugPrint("❌ Rewarded Ad failed: $err");
        },
      ),
    );
  }

  /// SHOW REWARDED AD
  void showAd(BuildContext context) {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ad not ready yet…")));
      loadAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd(); // load next
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        watchedCount++;

        if (watchedCount >= 2) {
          watchedCount = 0;
          onRewardCompleted(); // ⭐ callback → add free question
        }
      },
    );

    _rewardedAd = null;
  }
}
