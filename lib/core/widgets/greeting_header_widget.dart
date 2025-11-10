import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class GreetingHeaderWidget extends StatefulWidget {
  final String? userName;

  const GreetingHeaderWidget({super.key, this.userName});

  @override
  State<GreetingHeaderWidget> createState() => _GreetingHeaderWidgetState();
}

class _GreetingHeaderWidgetState extends State<GreetingHeaderWidget> {
  String displayName = "Friend";
  String? moonRashi; // from full-kundali-modern
  String? abhijitTime;
  String? rahukaalTime;
  String remedyText =
      "🪔 Loading today’s remedy..."; // placeholder (future logic)

  @override
  void initState() {
    super.initState();

    if (widget.userName != null && widget.userName!.trim().isNotEmpty) {
      displayName = widget.userName!;
    }

    // 🔮 Fetch both APIs
    _fetchKundaliData(); // sets moonRashi
    _fetchPanchangData(); // sets abhijitTime & rahukaalTime
    _loadRemedy();
  }

  // 🌙 Fetch Moon Rashi
  Future<void> _fetchKundaliData() async {
    try {
      final url = Uri.parse(
        "https://jyotishasha-backend.onrender.com/api/full-kundali-modern",
      );

      // TODO: Replace this dummy data with actual user info
      final payload = {
        "name": "Ravi",
        "dob": "1985-03-31",
        "tob": "19:45",
        "pob": "Lucknow",
      };

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          moonRashi = data["moon_rashi"];
        });
      } else {
        debugPrint("⚠️ Kundali API failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Kundali fetch error: $e");
    }
  }

  // 🌞 Panchang: Abhijit Muhurta + Rahukaal
  Future<void> _fetchPanchangData() async {
    try {
      final res = await http.get(
        Uri.parse("https://jyotishasha-backend.onrender.com/api/panchang"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final selected = data["selected_date"];

        final abhijit = selected["abhijit_muhurta"];
        final rahu = selected["rahu_kaal"];

        setState(() {
          abhijitTime = "${abhijit['start']} – ${abhijit['end']}";
          rahukaalTime = "${rahu['start']} – ${rahu['end']}";
        });
      }
    } catch (e) {
      debugPrint("⚠️ Panchang fetch error: $e");
    }
  }

  // 🪔 Remedy placeholder
  Future<void> _loadRemedy() async {
    setState(() {
      remedyText =
          "🪔 Offer water to the Sun at sunrise — brings clarity and confidence.";
    });
  }

  // ♈ Map moon_rashi → zodiac asset
  String _zodiacAssetForRashi(String? rashi) {
    if (rashi == null || rashi.isEmpty) return 'assets/zodiac/leo.png';
    final key = rashi.toLowerCase();
    return 'assets/zodiac/$key.png';
  }

  @override
  Widget build(BuildContext context) {
    final zodiacAsset = _zodiacAssetForRashi(moonRashi);

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
                        text: "Good Morning, ",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      TextSpan(
                        text: "$displayName 🌞",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      if (moonRashi != null) ...[
                        const TextSpan(text: "  "),
                        TextSpan(
                          text: "(${moonRashi!} Rashi)",
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
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

          // 🪔 Daily Remedy
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.deepPurple.shade100, width: 1),
            ),
            child: Text(
              remedyText,
              style: GoogleFonts.montserrat(
                fontSize: 14.5,
                color: Colors.deepPurple.shade800,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 📅 Time Alert
          Text(
            "Today's Time Alert",
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _timeTile("🕒 Time to Do", abhijitTime ?? "--:--"),
              _timeTile("🌑 Time to Hold", rahukaalTime ?? "--:--"),
            ],
          ),
        ],
      ),
    );
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
