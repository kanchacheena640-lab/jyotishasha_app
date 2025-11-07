import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';

class HoroscopePage extends StatefulWidget {
  const HoroscopePage({super.key});

  @override
  State<HoroscopePage> createState() => _HoroscopePageState();
}

class _HoroscopePageState extends State<HoroscopePage> {
  Map<String, dynamic>? todayData;
  Map<String, dynamic>? tomorrowData;
  Map<String, dynamic>? weeklyData;
  bool isPremium = false; // 🔒 backend se check hoga
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHoroscope();
  }

  Future<void> _fetchHoroscope() async {
    try {
      final today = await http.post(
        Uri.parse('https://jyotishasha-backend.onrender.com/api/horoscope'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mode": "today"}),
      );

      final tomorrow = await http.post(
        Uri.parse('https://jyotishasha-backend.onrender.com/api/horoscope'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mode": "tomorrow"}),
      );

      final weekly = await http.post(
        Uri.parse('https://jyotishasha-backend.onrender.com/api/horoscope'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mode": "weekly"}),
      );

      setState(() {
        todayData = jsonDecode(today.body);
        tomorrowData = jsonDecode(tomorrow.body);
        weeklyData = jsonDecode(weekly.body);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Horoscope fetch error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Your Horoscope",
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHoroscopeSection("☀️ Today’s Horoscope", todayData, false),
            const SizedBox(height: 16),
            _buildHoroscopeSection(
              "🌙 Tomorrow’s Horoscope",
              tomorrowData,
              !isPremium,
            ),
            const SizedBox(height: 16),
            _buildHoroscopeSection(
              "🔭 Weekly Horoscope",
              weeklyData,
              !isPremium,
            ),
            const SizedBox(height: 24),
            _buildBlogSection(),
            const SizedBox(height: 24),
            _buildComingSoonCard(),
            const SizedBox(height: 24),
            AppFooterFeedbackWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHoroscopeSection(
    String title,
    Map<String, dynamic>? data,
    bool locked,
  ) {
    if (locked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your stars tell your story. While others repeat one horoscope for millions, Jyotishasha unveils the world’s first truly personalized astrology — crafted uniquely for your birth details, your destiny, and your day.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFFBBF24)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Unlock Now 🔓",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (data == null) {
      return const Text("No data available");
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['summary'] ?? '',
              style: GoogleFonts.montserrat(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lucky Color: ${data['color'] ?? '--'}",
                  style: GoogleFonts.montserrat(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Lucky Number: ${data['number'] ?? '--'}",
                  style: GoogleFonts.montserrat(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🪐 Latest Planetary Updates for Libra",
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _blogTile(
          "Mars Transit in Aries — A Power Surge for Libra",
          "This transit activates your 7th house of partnerships.",
        ),
        _blogTile(
          "Venus in Scorpio — Emotional Transformation",
          "Expect emotional changes as Venus moves deeper into Scorpio.",
        ),
      ],
    );
  }

  Widget _blogTile(String title, String summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(
          summary,
          style: GoogleFonts.montserrat(color: Colors.black87),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "📆 Transit Alerts & Panchang Alerts",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Coming Soon...",
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
