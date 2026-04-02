import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:jyotishasha_app/features/transit/pages/transit_content_page.dart';
import 'rotating_earth.dart';

class TransitAlertWidget extends StatefulWidget {
  const TransitAlertWidget({super.key});

  @override
  State<TransitAlertWidget> createState() => _TransitAlertWidgetState();
}

class _TransitAlertWidgetState extends State<TransitAlertWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late ScrollController _scrollController;

  bool userTouching = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() async {
    await Future.delayed(const Duration(seconds: 2));

    const double speed = 0.4;

    while (mounted) {
      if (userTouching) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      if (!_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }

      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;

      double next = current + speed;

      if (next >= max) {
        _scrollController.jumpTo(0.1);
      } else {
        await _scrollController.animateTo(
          next,
          duration: const Duration(milliseconds: 40),
          curve: Curves.linear,
        );
      }

      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransitProvider>();
    final profileP = context.watch<ProfileProvider>();
    final t = AppLocalizations.of(context)!;

    if (p.isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (p.allPlanets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              const RotatingEarth(),

              const SizedBox(width: 6),

              Text(
                t.localeName.startsWith("hi")
                    ? "वर्तमान गोचर"
                    : "LIVE TRANSITS",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),

              const SizedBox(width: 8),
            ],
          ),
        ),

        SizedBox(
          height: 190,
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction != ScrollDirection.idle) {
                userTouching = true;
              } else {
                userTouching = false;
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: p.allPlanets.length,
              itemBuilder: (context, index) {
                final planet = p.allPlanets[index];
                return _buildPlanetCard(context, planet, p, profileP, t);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetCard(
    BuildContext context,
    Map<String, dynamic> planet,
    TransitProvider p,
    ProfileProvider profileP,
    AppLocalizations t,
  ) {
    String lagna = profileP.activeProfile?["lagna"] ?? "Aries";

    const rashiMap = {
      "Aries": 1,
      "Taurus": 2,
      "Gemini": 3,
      "Cancer": 4,
      "Leo": 5,
      "Virgo": 6,
      "Libra": 7,
      "Scorpio": 8,
      "Sagittarius": 9,
      "Capricorn": 10,
      "Aquarius": 11,
      "Pisces": 12,
    };

    const planetHindi = {
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

    // English → Hindi Rashi map
    const rashiHindi = {
      "Aries": "मेष",
      "Taurus": "वृषभ",
      "Gemini": "मिथुन",
      "Cancer": "कर्क",
      "Leo": "सिंह",
      "Virgo": "कन्या",
      "Libra": "तुला",
      "Scorpio": "वृश्चिक",
      "Sagittarius": "धनु",
      "Capricorn": "मकर",
      "Aquarius": "कुंभ",
      "Pisces": "मीन",
    };

    // Hindi house names
    const houseHindi = {
      1: "पहले",
      2: "दूसरे",
      3: "तीसरे",
      4: "चौथे",
      5: "पांचवें",
      6: "छठे",
      7: "सातवें",
      8: "आठवें",
      9: "नौवें",
      10: "दसवें",
      11: "11वें",
      12: "12वें",
    };

    int lagnaNum = rashiMap[lagna] ?? 1;
    int planetRashiNum = planet["rashi_number"] ?? 1;

    int house = (planetRashiNum - lagnaNum + 12) % 12 + 1;
    String houseName = house.toString();

    if (t.localeName.startsWith("hi")) {
      houseName = houseHindi[house] ?? house.toString();
    }

    String nextDate = planet["next_change"] ?? "";

    if (nextDate.contains("-")) {
      final parts = nextDate.split("-");
      if (parts.length == 3) {
        nextDate = "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    }

    /// planet name translate
    String planetName = planet["name"];
    // rashi translate
    String rashiName = planet["rashi"];

    if (t.localeName.startsWith("hi")) {
      rashiName = rashiHindi[rashiName] ?? rashiName;
    }

    if (t.localeName.startsWith("hi")) {
      planetName = planetHindi[planetName] ?? planetName;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          final profile = profileP.activeProfile;
          if (profile == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransitContentPage()),
          );

          Future.microtask(() {
            p.fetchTransitContent(
              ascendant: profile["lagna"] ?? "Aries",
              planet: planet["name"],
              lagnaRashi: lagnaNum,
              planetRashi: planetRashiNum,
              lang: t.localeName.substring(0, 2),
            );
          });
        },
        child: Container(
          width: 260,
          margin: const EdgeInsets.only(right: 14, bottom: 10, top: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8F7FF), Color(0xFFFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.deepPurple.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  _getPlanetIcon(planet["name"]),
                  const SizedBox(width: 6),

                  Text(
                    planetName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    t.localeName.startsWith("hi")
                        ? "आप पर प्रभाव"
                        : "Effects on You",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// CURRENT POSITION
              Text(
                t.localeName.startsWith("hi")
                    ? "वर्तमान में $planetName $rashiName राशि में (${planet["degree"]}°)"
                    : "Currently $planetName in $rashiName (${planet["degree"]}°)",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              /// HOUSE INFO
              Text(
                t.localeName.startsWith("hi")
                    ? "आपकी कुंडली में\n$planetName $houseName भाव में गोचर कर रहा है"
                    : "According to your Birth Chart\n$planetName in $house house",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              /// NEXT TRANSIT
              Text(
                t.localeName.startsWith("hi")
                    ? "अगला परिवर्तन : $nextDate"
                    : "Next change : $nextDate",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPlanetIcon(String name) {
    IconData icon;
    Color color;

    switch (name.toLowerCase()) {
      case 'sun':
        icon = Icons.wb_sunny_rounded;
        color = Colors.orange;
        break;

      case 'moon':
        icon = Icons.nightlight_round;
        color = Colors.indigo;
        break;

      case 'mars':
        icon = Icons.local_fire_department_rounded;
        color = Colors.red;
        break;

      case 'mercury':
        icon = Icons.psychology_rounded;
        color = Colors.green;
        break;

      case 'jupiter':
        icon = Icons.auto_awesome_rounded;
        color = Colors.amber;
        break;

      case 'venus':
        icon = Icons.favorite_rounded;
        color = Colors.pink;
        break;

      case 'saturn':
        icon = Icons.hourglass_bottom_rounded;
        color = Colors.blueGrey;
        break;

      case 'rahu':
        icon = Icons.visibility_rounded;
        color = Colors.black87;
        break;

      case 'ketu':
        icon = Icons.settings_input_antenna_rounded;
        color = Colors.brown;
        break;

      default:
        icon = Icons.circle;
        color = Colors.deepPurple;
    }

    return Icon(icon, size: 24, color: color);
  }
}
