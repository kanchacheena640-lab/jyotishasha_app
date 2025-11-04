import 'package:flutter/material.dart';
import '../models/kundali_models.dart';

class KundaliChartWidget extends StatelessWidget {
  final KundaliData data;
  final String? title; // optional heading

  const KundaliChartWidget({super.key, required this.data, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        AspectRatio(
          aspectRatio: 1, // square chart
          child: CustomPaint(
            painter: _NorthIndianPainter(data),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class _NorthIndianPainter extends CustomPainter {
  final KundaliData data;
  _NorthIndianPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF5B21B6) // deep purple
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final w = size.width, h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Outer square
    canvas.drawRect(rect, paint);

    // North-Indian diamond grid (8 diagonals + mid cross)
    final p = Path()
      ..moveTo(w / 2, 0) // top mid
      ..lineTo(w, h / 2) // → right mid
      ..lineTo(w / 2, h) // ↓ bottom mid
      ..lineTo(0, h / 2) // ← left mid
      ..close();
    canvas.drawPath(p, paint);

    // diagonals from corners to corners via center
    canvas.drawLine(Offset(0, 0), Offset(w, h), paint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), paint);

    // mid cross
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), paint);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);

    // House label positions (approx for North-Indian)
    // Map house -> offset (normalized 0..1)
    final positions = <int, Offset>{
      1: Offset(0.52, 0.15),
      2: Offset(0.70, 0.10),
      3: Offset(0.85, 0.24),
      4: Offset(0.86, 0.52),
      5: Offset(0.85, 0.80),
      6: Offset(0.68, 0.89),
      7: Offset(0.48, 0.83),
      8: Offset(0.30, 0.89),
      9: Offset(0.12, 0.80),
      10: Offset(0.10, 0.52),
      11: Offset(0.12, 0.24),
      12: Offset(0.30, 0.10),
    };

    TextPainter textPainter(
      String s, {
      double fs = 11,
      FontWeight fw = FontWeight.w600,
      Color c = Colors.black,
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontSize: fs, fontWeight: fw, color: c),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: w * 0.22);
      return tp;
    }

    // Draw each house: number, sign (short), planets
    for (var house in data.houses) {
      final pos = positions[house.house]!;
      final dx = pos.dx * w;
      final dy = pos.dy * h;

      final houseNum = textPainter(
        house.house.toString(),
        fs: 12,
        fw: FontWeight.w700,
        c: const Color(0xFF5B21B6),
      );
      houseNum.paint(
        canvas,
        Offset(dx - houseNum.width / 2, dy - houseNum.height / 2),
      );

      final signShort = _shortSign(house.sign);
      final signTp = textPainter(
        signShort,
        fs: 10,
        fw: FontWeight.w600,
        c: Colors.grey[800]!,
      );
      signTp.paint(
        canvas,
        Offset(
          dx - signTp.width / 2,
          dy - houseNum.height / 2 - signTp.height - 2,
        ),
      );

      if (house.planets.isNotEmpty) {
        final planets = house.planets.join(' ');
        final plTp = textPainter(
          planets,
          fs: 10,
          fw: FontWeight.w500,
          c: Colors.black87,
        );
        plTp.paint(
          canvas,
          Offset(dx - plTp.width / 2, dy + houseNum.height / 2 + 2),
        );
      }
    }
  }

  String _shortSign(String sign) {
    switch (sign.toLowerCase()) {
      case 'aries':
        return 'Ar';
      case 'taurus':
        return 'Ta';
      case 'gemini':
        return 'Ge';
      case 'cancer':
        return 'Cn';
      case 'leo':
        return 'Le';
      case 'virgo':
        return 'Vi';
      case 'libra':
        return 'Li';
      case 'scorpio':
        return 'Sc';
      case 'sagittarius':
        return 'Sg';
      case 'capricorn':
        return 'Cp';
      case 'aquarius':
        return 'Aq';
      case 'pisces':
        return 'Pi';
      default:
        return sign.substring(0, 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
