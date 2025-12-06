import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_units.dart';

class InterstitialAdButton extends StatefulWidget {
  final VoidCallback? onShown; // Optional callback after ad shows
  final String label; // Button text
  final Color color; // Button color

  const InterstitialAdButton({
    super.key,
    this.onShown,
    this.label = "Show Ad",
    this.color = Colors.deepPurple,
  });

  @override
  State<InterstitialAdButton> createState() => _InterstitialAdButtonState();
}

class _InterstitialAdButtonState extends State<InterstitialAdButton> {
  InterstitialAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: AdUnits.interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
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
        widget.onShown?.call(); // callback
        ad.dispose();
        _loadAd(); // load next ad
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        _loadAd();
      },
    );

    _ad!.show();
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
