import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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

class _TransitAlertWidgetState extends State<TransitAlertWidget> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.83);

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      if ((page - _currentPage).abs() > 0.01) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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

    final sortedPlanets = [...p.allPlanets];

    sortedPlanets.sort((a, b) {
      try {
        final da = DateTime.parse(a["next_change"] ?? "");
        final db = DateTime.parse(b["next_change"] ?? "");

        return da.compareTo(db);
      } catch (_) {
        return 0;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.22),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const RotatingEarth(),
              ),

              const SizedBox(width: 10),
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
          height: 210,
          child: PageView.builder(
            controller: _pageController,
            padEnds: true,

            itemCount: sortedPlanets.length,
            itemBuilder: (context, index) {
              final planet = sortedPlanets[index];

              double diff = (_currentPage - index).abs();

              /// 🔥 SCALE (smooth)
              double scale = 1 - (diff * 0.08);
              if (scale < 0.90) scale = 0.90;

              /// 🔥 OPACITY
              double opacity = 1 - (diff * 0.5);
              if (opacity < 0.65) opacity = 0.65;

              /// 🔥 NO BLUR
              double blur = 0;

              /// 🔥 PARALLAX (slight shift)
              double translateX = diff * 12;

              return Transform.translate(
                offset: Offset(translateX, 0),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: blur,
                        sigmaY: blur,
                      ),
                      child: _buildPlanetCard(context, planet, p, profileP, t),
                    ),
                  ),
                ),
              );
            },
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
      11: "ग्यारहवें",
      12: "बारहवें",
    };

    int lagnaNum = rashiMap[lagna] ?? 1;
    int planetRashiNum = planet["rashi_number"] ?? 1;
    int house = (planetRashiNum - lagnaNum + 12) % 12 + 1;

    String houseName = t.localeName.startsWith("hi")
        ? houseHindi[house] ?? house.toString()
        : house.toString();

    String nextDate = planet["next_change"] ?? "";

    try {
      final parsedDate = DateTime.parse(nextDate);
      nextDate =
          "${parsedDate.day.toString().padLeft(2, '0')}-"
          "${parsedDate.month.toString().padLeft(2, '0')}-"
          "${parsedDate.year}";
    } catch (e) {
      // fallback (agar already formatted ho)
    }

    String planetName = planet["name"];
    String rashiName = planet["rashi"];

    if (t.localeName.startsWith("hi")) {
      planetName = planetHindi[planetName] ?? planetName;
      rashiName = rashiHindi[rashiName] ?? rashiName;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
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
        child: Builder(
          builder: (context) {
            final base = planetColor(planet["name"]);

            return Container(
              width: MediaQuery.of(context).size.width * 0.78,
              margin: const EdgeInsets.only(right: 12, top: 6, bottom: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [base.withOpacity(0.9), base.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: planet["motion"] == "Retrograde"
                        ? Colors.red.withOpacity(0.45)
                        : base.withOpacity(0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔥 TOP ROW
                  Row(
                    children: [
                      FloatingPlanet(planet["name"]),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          planetName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: planet["motion"] == "Retrograde"
                              ? Colors.red.withOpacity(0.9)
                              : Colors.green.withOpacity(0.9),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              planet["motion"] == "Retrograde"
                                  ? Icons.sync
                                  : Icons.arrow_upward,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              planet["motion"],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// 🔥 MAIN LINE
                  Text(
                    t.localeName.startsWith("hi")
                        ? "$planetName $rashiName में आपके $houseName भाव पर प्रभाव।"
                        : "$planetName in $rashiName is impacting your $house house.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 🔥 CTA
                  Text(
                    t.localeName.startsWith("hi")
                        ? "अपना पूरा फल देखें →"
                        : "Your Free Prediction →",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// 🔥 NEXT LINE (RIGHT)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.localeName.startsWith("hi")
                            ? "अगला: $nextDate"
                            : "Next: $nextDate",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 🔥 FLOATING PLANET (TOP LEVEL WIDGET)
class FloatingPlanet extends StatefulWidget {
  final String planet;
  const FloatingPlanet(this.planet, {super.key});

  @override
  State<FloatingPlanet> createState() => _FloatingPlanetState();
}

class _FloatingPlanetState extends State<FloatingPlanet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnim = Tween(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = "assets/planets/${widget.planet.toLowerCase()}.webp";

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.transparent,
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: 44,
              height: 44,
              errorBuilder: (_, __, ___) {
                return const Icon(Icons.circle, color: Colors.white, size: 20);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔥 PLANET COLOR HELPER (TOP LEVEL FUNCTION)
Color planetColor(String name) {
  switch (name.toLowerCase()) {
    case 'sun':
      return const Color(0xFFF59E0B);
    case 'moon':
      return const Color(0xFF6366F1);
    case 'mars':
      return const Color(0xFFEF4444);
    case 'mercury':
      return const Color(0xFF10B981);
    case 'jupiter':
      return const Color(0xFFF59E0B);
    case 'venus':
      return const Color(0xFFEC4899);
    case 'saturn':
      return const Color(0xFF475569);
    case 'rahu':
      return const Color(0xFF111827);
    case 'ketu':
      return const Color(0xFF92400E);
    default:
      return const Color(0xFF7C3AED);
  }
}
