import 'package:flutter/material.dart';

class PanchangPage extends StatelessWidget {
  const PanchangPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Panchang Data
    final Map<String, String> panchangData = {
      "tithi": "Dwitiya",
      "nakshatra": "Rohini",
      "yoga": "Siddha",
      "karan": "Bava",
      "sunrise": "06:27 AM",
      "sunset": "05:43 PM",
    };

    final bool isEmpty = panchangData.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Panchang"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isEmpty
          ? const Center(
              child: Text(
                "No Panchang data available 📿",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8F6FB), Color(0xFFEDE7F6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🪔 Daily Panchang Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List of details
                  ...panchangData.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text("View Monthly Panchang"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Monthly Panchang feature coming soon 🗓️",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
