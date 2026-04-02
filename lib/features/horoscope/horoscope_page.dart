import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/monthly_provider.dart';
import 'package:jyotishasha_app/core/state/yearly_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/widgets/horoscope_card_widget.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/core/widgets/global_share_button.dart';
import 'package:share_plus/share_plus.dart';

class HoroscopePage extends StatefulWidget {
  final int initialTab;
  const HoroscopePage({super.key, this.initialTab = 0});

  @override
  State<HoroscopePage> createState() => _HoroscopePageState();
}

class _HoroscopePageState extends State<HoroscopePage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        _loadByTab(tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadByTab(tabController.index);
    });
  }

  String? _normalizeSign(String? sign) {
    if (sign == null || sign.isEmpty) return null;

    final map = {
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

    final key = sign.toLowerCase().trim();
    return map[key];
  }

  void _loadByTab(int index) {
    final profile = context.read<ProfileProvider>();

    final rawSign = profile.activeProfile?['moon_sign'];
    final sign = _normalizeSign(rawSign);

    final lang = Localizations.localeOf(context).languageCode;

    if (sign == null) return;

    if (index == 0) {
      context.read<DailyProvider>().fetchDaily(sign: sign, lang: lang);
    } else if (index == 1) {
      context.read<MonthlyProvider>().fetchMonthly(sign: sign, lang: lang);
    } else if (index == 2) {
      context.read<YearlyProvider>().fetchYearly(
        sign: sign,
        year: DateTime.now().year,
        lang: lang,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          t.yourHoroscope,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: const [GlobalShareButton(currentPage: "horoscope")],
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: t.today),
            Tab(text: t.monthly),
            Tab(text: t.yearly),
          ],
        ),
      ),

      body: TabBarView(
        controller: tabController,
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: HoroscopeCardWidget(period: HoroscopePeriod.today),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: HoroscopeCardWidget(period: HoroscopePeriod.monthly),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: HoroscopeCardWidget(period: HoroscopePeriod.yearly),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text("Share"),
                  onPressed: () {
                    const text =
                        "Your personalized horoscope is ready 🔮\n"
                        "Get daily, monthly & yearly predictions.\n\n"
                        "Download Jyotishasha App:\n"
                        "https://play.google.com/store/apps/details?id=com.jyotishasha.app";

                    Share.share(text);
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.favorite, size: 18, color: Colors.red),
                  label: const Text("Compatibility"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                  ),
                  onPressed: () {
                    context.go('/astrology');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
