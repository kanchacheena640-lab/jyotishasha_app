import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/core/ads/ad_units.dart';

class TransitContentPage extends StatefulWidget {
  const TransitContentPage({super.key});

  @override
  State<TransitContentPage> createState() => _TransitContentPageState();
}

class _TransitContentPageState extends State<TransitContentPage> {
  BannerAd? bannerAd;
  bool bannerReady = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: AdUnits.bannerAdUnit,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => bannerReady = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Ad failed: $error");
        },
      ),
    );

    bannerAd!.load();
  }

  /// 👉 STEP 2 FUNCTION — यहीं डालना है
  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not open $url");
    }
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  static const planetHindi = {
    "Sun": "सूर्य",
    "Moon": "चंद्र",
    "Mars": "मंगल",
    "Mercury": "बुध",
    "Jupiter": "गुरु",
    "Venus": "शुक्र",
    "Saturn": "शनि",
    "Rahu": "राहु",
    "Ketu": "केतु",
  };

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransitProvider>();
    final t = AppLocalizations.of(context)!;

    final data = p.contentData;

    String displayPlanet = data?['planet'] ?? "--";

    if (t.localeName.startsWith("hi")) {
      displayPlanet = planetHindi[displayPlanet] ?? displayPlanet;
    }
    String displayRashi = "";
    String displayDegree = "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          "$displayPlanet Transit",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? "$displayPlanet in $displayRashi",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildBadge(displayRashi, displayDegree),

                  const SizedBox(height: 24),

                  /// 🔮 Main Transit Insight (earlier closing snippet)
                  if (data['closing'] != null)
                    _buildClosingBox(data['closing']),

                  const SizedBox(height: 26),

                  if (data['summary'] != null)
                    _buildSummaryBox(data['summary']),

                  const SizedBox(height: 30),

                  if (data['sections'] != null)
                    ...(data['sections'] as List).map(
                      (sec) => _buildSection(sec),
                    ),

                  if (bannerReady)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      width: bannerAd!.size.width.toDouble(),
                      height: bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: bannerAd!),
                    ),
                  if (data['article_url'] != null &&
                      data['article_url'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            _openArticle(data['article_url'].toString());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Read Full Article",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),

                ],
              ),
            ),
    );
  }

  Widget _buildBadge(String rashi, String degree) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$rashi • $degree°",
        style: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          fontStyle: FontStyle.italic,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildSection(dynamic sec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _buildEffectHeading(sec['heading'] ?? ""),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 12),

          if (sec['points'] != null)
            ...(sec['points'] as List).map(
              (pt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.stars, size: 14, color: Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pt,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildEffectHeading(String heading) {
    final map = {
      "Core Personality": "Effect on Personality",
      "Career Direction": "Effect on Career & Direction",
      "Relationship": "Effect on Relationships",
      "Finance Growth": "Effect on Finance & Growth",
      "Health & Mindset": "Effect on Health & Mindset",
    };

    return map[heading] ?? heading;
  }

  Widget _buildClosingBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
