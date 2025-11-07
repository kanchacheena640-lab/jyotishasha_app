import 'package:flutter/material.dart';

/// North Indian Kundali Chart (Frontend version of KundaliChartNorth.tsx)
/// Expects:
/// - planets: List from /api/full-kundali (Planets/planets)
/// - lagnaSign: String like "Aries", "Taurus", "Libra" etc.
/// - size: chart box size (default 300)

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

    final lagnaRashi = _mapSignToNumber(lagnaSign!); // 1..12
    if (lagnaRashi == null) {
      return const SizedBox.shrink();
    }

    // Group planets by house (skip Ascendant)
    final Map<int, List<String>> byHouse = {
      for (var i = 1; i <= 12; i++) i: <String>[],
    };

    for (final p in planets) {
      final rawName = (p["planet"] ?? p["name"] ?? "").toString();
      if (rawName.isEmpty) continue;
      if (RegExp(r"ascendant", caseSensitive: false).hasMatch(rawName)) {
        continue; // skip Ascendant (Lagna)
      }

      final h = _toInt(p["house"]);
      if (h == null || h < 1 || h > 12) continue;

      final abbr = _toAbbr(rawName).toUpperCase();
      byHouse[h]!.add(abbr);
    }

    // Rashis per house starting from Lagna (same as TS file)
    final rashis = _getRashisByHouse(lagnaRashi);

    // Normalized positions (x,y as fraction of size)
    const double base = 400;
    const double center = base / 2;

    final Map<int, Offset> houseCenters = {
      1: const Offset(center, 155),
      2: const Offset(center - 100, 80),
      3: const Offset(center - 130, center - 95),
      4: const Offset(center - 40, center),
      5: const Offset(center - 130, center + 95),
      6: const Offset(center - 100, center + 120),
      7: const Offset(center, center + 50),
      8: const Offset(center + 100, center + 120),
      9: const Offset(center + 130, center + 95),
      10: const Offset(center + 40, center),
      11: const Offset(center + 130, center - 95),
      12: const Offset(center + 100, 80),
    };

    // Text shift logic same as TS: minor offsets per house
    Offset _shiftForHouse(int house) {
      if ([1, 2, 12].contains(house)) return const Offset(0, -28);
      if ([3, 4, 5].contains(house)) return const Offset(-30, 0);
      if ([6, 7, 8].contains(house)) return const Offset(0, 30);
      if ([9, 10, 11].contains(house)) return const Offset(30, 0);
      return Offset.zero;
    }

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final scaleX = w / base;
            final scaleY = h / base;

            Offset scale(Offset o) => Offset(o.dx * scaleX, o.dy * scaleY);

            return Stack(
              children: [
                // Frame + lines
                CustomPaint(size: Size(w, h), painter: _KundaliFramePainter()),

                // House labels + planets
                ...houseCenters.entries.map((entry) {
                  final house = entry.key;
                  final basePos = entry.value;
                  final pos = scale(basePos);
                  final rashi = rashis[house - 1];
                  final hp = byHouse[house] ?? [];
                  final shift = _shiftForHouse(house);
                  final shifted = scale(
                    Offset(basePos.dx + shift.dx, basePos.dy + shift.dy),
                  );

                  return Stack(
                    children: [
                      // Rashi number in center
                      Positioned(
                        left: pos.dx - 8,
                        top: pos.dy - 8,
                        child: Text(
                          rashi.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hp.isNotEmpty)
                        Positioned(
                          left: shifted.dx - 30,
                          top: shifted.dy - 10,
                          width: 60,
                          child: Text(
                            hp.join(", "),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- Helpers (same logic as TS) ----------

  int? _toInt(dynamic x) {
    if (x == null) return null;
    if (x is int) return x;
    if (x is String) {
      final n = int.tryParse(x);
      return n;
    }
    if (x is num) return x.toInt();
    return null;
  }

  /// Map Lagna sign text -> rashi number (1 = Aries ... 12 = Pisces)
  int? _mapSignToNumber(String sign) {
    final s = sign.trim().toLowerCase();
    switch (s) {
      case "aries":
      case "mesh":
      case "mesha":
        return 1;
      case "taurus":
      case "vrishabh":
      case "vrishabha":
        return 2;
      case "gemini":
      case "mithun":
      case "mithuna":
        return 3;
      case "cancer":
      case "kark":
      case "karka":
        return 4;
      case "leo":
      case "singh":
      case "simha":
        return 5;
      case "virgo":
      case "kanya":
        return 6;
      case "libra":
      case "tula":
        return 7;
      case "scorpio":
      case "vrishchik":
      case "vrishchika":
        return 8;
      case "sagittarius":
      case "dhanu":
        return 9;
      case "capricorn":
      case "makar":
        return 10;
      case "aquarius":
      case "kumbh":
        return 11;
      case "pisces":
      case "meen":
      case "meena":
        return 12;
      default:
        return null;
    }
  }

  List<int> _getRashisByHouse(int lagnaRashi) {
    final out = <int>[];
    for (int i = 0; i < 12; i++) {
      out.add(((lagnaRashi - 1 + i) % 12) + 1);
    }
    return out;
  }

  String _toAbbr(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return "";
    final key = s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), "");

    const abbr = {
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

    const alt = {
      "surya": "sun",
      "soorya": "sun",
      "ravi": "sun",
      "chandra": "moon",
      "soma": "moon",
      "mangal": "mars",
      "kuja": "mars",
      "budh": "mercury",
      "budha": "mercury",
      "guru": "jupiter",
      "brihaspati": "jupiter",
      "shukra": "venus",
      "shani": "saturn",
      "sani": "saturn",
      "raahu": "rahu",
    };

    final canon = alt[key] ?? key;
    if (abbr.containsKey(canon)) return abbr[canon]!;
    // fallback: 2-letter initials
    return (s[0].toUpperCase()) + (s.length > 1 ? s[1].toLowerCase() : "");
  }
}

class _KundaliFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Outer square
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(rect, paintLine..strokeWidth = 2);

    // Diagonals
    canvas.drawLine(Offset(0, 0), Offset(w, h), paintLine);
    canvas.drawLine(Offset(w, 0), Offset(0, h), paintLine);

    // Diamond ring (mid-lines)
    canvas.drawLine(Offset(cx, 0), Offset(0, cy), paintLine);
    canvas.drawLine(Offset(0, cy), Offset(cx, h), paintLine);
    canvas.drawLine(Offset(cx, h), Offset(w, cy), paintLine);
    canvas.drawLine(Offset(w, cy), Offset(cx, 0), paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
