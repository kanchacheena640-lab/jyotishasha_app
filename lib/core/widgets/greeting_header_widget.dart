import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class GreetingHeaderWidget extends StatelessWidget {
  final DailyProvider daily;

  const GreetingHeaderWidget({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseKundaliProvider>();
    final kundali = firebase.kundaliData ?? {};
    final panchang = context.watch<PanchangProvider>();
    final dailyProvider = context.watch<DailyProvider>();
    final t = AppLocalizations.of(context)!;

    final displayName = kundali["profile"]?["name"] ?? t.greetFriend;
    final birthRashi = kundali["rashi"] ?? "";
    final zodiacAsset = _zodiacAssetForRashi(birthRashi);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌙 Rashi Icon + Greeting
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.deepPurple.shade200,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(zodiacAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${t.greetNamaste} ",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      TextSpan(
                        text: "$displayName 🙏",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      if (birthRashi.isNotEmpty) ...[
                        const TextSpan(text: " "),
                        TextSpan(
                          text: "($birthRashi Rashi)",
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            color: Colors.deepPurple.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 🪔 Daily Lines
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.deepPurple.shade100, width: 1),
            ),
            child: dailyProvider.isLoading
                ? Text(
                    t.dailyLoading,
                    style: GoogleFonts.montserrat(
                      fontSize: 14.5,
                      color: Colors.deepPurple.shade800,
                      height: 1.5,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dailyProvider.aspectLine != null &&
                          dailyProvider.aspectLine!.trim().isNotEmpty)
                        Text(
                          dailyProvider.aspectLine!,
                          style: GoogleFonts.montserrat(
                            fontSize: 14.5,
                            color: Colors.deepPurple.shade800,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        t.dailyRemedy,
                        style: GoogleFonts.montserrat(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dailyProvider.remedyLine ?? "—",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.deepPurple.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 18),

          // 📅 Time Alert
          Text(
            t.panchangTimeAlert,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 8),

          panchang.isLoading
              ? Text(
                  t.panchangCalcLoading,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.deepPurple.shade500,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _timeTile(
                      "🕒 ${t.timeToDo}",
                      "${panchang.abhijitStart} – ${panchang.abhijitEnd}",
                    ),
                    _timeTile(
                      "🌑 ${t.timeToHold}",
                      "${panchang.rahukaalStart} – ${panchang.rahukaalEnd}",
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ♈ Rashi → image asset
  String _zodiacAssetForRashi(String? rashi) {
    if (rashi == null || rashi.isEmpty) return 'assets/zodiac/leo.png';
    return 'assets/zodiac/${rashi.toLowerCase()}.png';
  }

  Widget _timeTile(String title, String time) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.deepPurple.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                color: Colors.deepPurple.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
