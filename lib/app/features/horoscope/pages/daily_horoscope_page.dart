import 'package:flutter/material.dart';

class DailyHoroscopePage extends StatelessWidget {
  final Map<String, dynamic> horoscopeData;

  const DailyHoroscopePage({super.key, required this.horoscopeData});

  @override
  Widget build(BuildContext context) {
    // 🪐 Backend returns { success: true, result: { message, date, sign } }
    final result = horoscopeData['result'] ?? {};
    final message =
        result['message'] ??
        horoscopeData['summary'] ??
        "No horoscope available right now.";
    final sign = result['sign'] ?? "Your Zodiac";
    final date = result['date'] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
      appBar: AppBar(
        title: const Text("Daily Horoscope"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$sign Horoscope",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "Date: $date",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This content is auto-generated daily based on your birth chart and current planetary transits.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.deepPurple,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
