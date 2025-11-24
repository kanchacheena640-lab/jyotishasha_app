// lib/core/widgets/kundali_chart_north_widget.dart
import 'package:flutter/material.dart';

class KundaliChartNorthWidget extends StatelessWidget {
  final List<dynamic> planets;
  final String? lagnaSign;
  final double size;

  const KundaliChartNorthWidget({
    super.key,
    required this.planets,
    required this.lagnaSign,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (lagnaSign == null || lagnaSign!.isEmpty) {
      return const SizedBox.shrink();
    }

    final lagnaRashi = _mapSignToNumber(lagnaSign!);
    if (lagnaRashi == null) return const SizedBox.shrink();

    // 1) Group planets by house
    final Map<int, List<String>> housePlanets = {
      for (int i = 1; i <= 12; i++) i: <String>[],
    };

    for (final p in planets) {
      final name = (p["name"] ?? "").toString().trim();
      final h = _toInt(p["house"]);

      if (name.isEmpty) continue;
      if (h == null || h < 1 || h > 12) continue;

      housePlanets[h]!.add(_toAbbr(name));
    }

    // 2) Rashi order
    final rashis = _getRashisByHouse(lagnaRashi);

    // 3) Box coordinates
    const double base = 400;
    const double center = base / 2;

    final Map<int, Offset> centerPos = {
      1: Offset(center, center + 10),
      2: Offset(center - 100, center - 90),
      3: Offset(center - 130, center - 60),
      4: Offset(center - 30, center + 40),
      5: Offset(center - 125, center + 135),
      6: Offset(center - 100, center + 170),
      7: Offset(center, center + 70),
      8: Offset(center + 100, center + 170),
      9: Offset(center + 125, center + 135),
      10: Offset(center + 30, center + 40),
      11: Offset(center + 130, center - 60),
      12: Offset(center + 100, center - 90),
    };

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: LayoutBuilder(
          builder: (context, c) {
            final sx = c.maxWidth / base;
            final sy = c.maxHeight / base;

            Offset scale(Offset o) => Offset(o.dx * sx, o.dy * sy);

            return Stack(
              children: [
                CustomPaint(
                  size: Size(c.maxWidth, c.maxHeight),
                  painter: _KundaliPainter(),
                ),

                ...centerPos.entries.map((e) {
                  final h = e.key;
                  final pos = scale(e.value);

                  return Positioned(
                    left: pos.dx - 30,
                    top: pos.dy - 30,
                    width: 60,
                    child: Column(
                      children: [
                        // ---------- RASHI NUMBER ----------
                        Text(
                          rashis[h - 1].toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // ---------- PLANETS (VERTICAL OR HORIZONTAL) ----------
                        if (housePlanets[h]!.isNotEmpty)
                          Transform.translate(
                            offset: Offset(
                              planetShift(h).dx * sx,
                              planetShift(h).dy * sy,
                            ),

                            child:
                                (
                                // these houses will show vertical stacking
                                [3, 5, 9, 11].contains(h))
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final p in housePlanets[h]!)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 0.1,
                                          ),
                                          child: Text(
                                            p,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : Text(
                                    housePlanets[h]!.join(" "),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  // Planet shifting per house
  Offset planetShift(int h) {
    if ([1].contains(h)) return const Offset(0, -100);
    if ([2, 12].contains(h)) return const Offset(0, -55);
    if ([3, 4, 5].contains(h)) return const Offset(-30, -30);
    if ([7].contains(h)) return const Offset(0, 30);
    if ([6, 8].contains(h)) return const Offset(0, 15);
    if ([9, 11].contains(h)) return const Offset(50, -50);
    if ([10].contains(h)) return const Offset(50, -30);
    return Offset.zero;
  }

  // Helpers
  int? _toInt(dynamic x) {
    if (x is int) return x;
    if (x is num) return x.toInt();
    if (x is String) return int.tryParse(x);
    return null;
  }

  int? _mapSignToNumber(String s) {
    const m = {
      "aries": 1,
      "taurus": 2,
      "gemini": 3,
      "cancer": 4,
      "leo": 5,
      "virgo": 6,
      "libra": 7,
      "scorpio": 8,
      "sagittarius": 9,
      "capricorn": 10,
      "aquarius": 11,
      "pisces": 12,
    };
    return m[s.toLowerCase()];
  }

  List<int> _getRashisByHouse(int lagna) =>
      List.generate(12, (i) => ((lagna - 1 + i) % 12) + 1);

  String _toAbbr(String name) {
    const map = {
      "sun": "Su",
      "moon": "Mo",
      "mars": "Ma",
      "mercury": "Me",
      "jupiter": "Ju",
      "venus": "Ve",
      "saturn": "Sa",
      "rahu": "Ra",
      "ketu": "Ke",
    };
    final key = name.toLowerCase().replaceAll(" ", "");
    return map[key] ?? name.substring(0, 2).toUpperCase();
  }
}

// Frame Painter
class _KundaliPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);

    canvas.drawLine(const Offset(0, 0), Offset(w, h), p);
    canvas.drawLine(Offset(w, 0), Offset(0, h), p);

    final cx = w / 2;
    final cy = h / 2;

    canvas.drawLine(Offset(cx, 0), Offset(0, cy), p);
    canvas.drawLine(Offset(0, cy), Offset(cx, h), p);
    canvas.drawLine(Offset(cx, h), Offset(w, cy), p);
    canvas.drawLine(Offset(w, cy), Offset(cx, 0), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
