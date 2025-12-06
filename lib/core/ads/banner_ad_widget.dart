import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_units.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize size;

  const BannerAdWidget({super.key, this.size = AdSize.banner});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _banner = BannerAd(
      adUnitId: AdUnits.bannerAdUnit,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint("❌ Banner Ad Failed: ${err.message}");
          if (mounted) {
            setState(() => _isLoaded = false);
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prevent UI jump — fixed height even if ad not ready
    final double h = widget.size.height.toDouble();

    if (!_isLoaded || _banner == null) {
      return SizedBox(height: h);
    }

    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: h,
      child: AdWidget(ad: _banner!),
    );
  }
}
