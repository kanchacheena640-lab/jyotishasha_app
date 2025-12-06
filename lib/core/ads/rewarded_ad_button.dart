import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_units.dart';

class RewardedAdButton extends StatefulWidget {
  final String label;
  final Color color;
  final Function(int rewardAmount) onReward; // callback when reward earned

  const RewardedAdButton({
    super.key,
    required this.onReward,
    this.label = "Watch Ad",
    this.color = Colors.green,
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  RewardedAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: AdUnits.rewardedAdUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          setState(() {});
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void _showAd() {
    if (!_isLoaded || _ad == null) return;

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadAd(); // load next rewarded ad
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        _loadAd();
      },
    );

    _ad!.show(
      onUserEarnedReward: (ad, reward) {
        widget.onReward(reward.amount.toInt()); // FIXED: cast to int
      },
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoaded ? _showAd : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        widget.label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
