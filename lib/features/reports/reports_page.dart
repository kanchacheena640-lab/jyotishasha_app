import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        "title": "Love Marriage Report",
        "desc": "Know about your love & life partner destiny.",
      },
      {
        "title": "Marriage Problem Report",
        "desc": "Find causes & remedies for conflicts in marriage.",
      },
      {
        "title": "Financial Status Report",
        "desc": "Discover your wealth and money potential.",
      },
      {
        "title": "Career Report",
        "desc": "Find the right career path and growth period.",
      },
      {
        "title": "Government Job Chances",
        "desc": "Check yogas supporting government job.",
      },
      {
        "title": "Foreign Travel Report",
        "desc": "Explore your abroad travel possibilities.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Astrology Reports"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: reports.isEmpty
          ? const Center(
              child: Text(
                "No reports available yet ⚡",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8F6FB), Color(0xFFEDE7F6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView.builder(
                itemCount: reports.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report["title"]!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report["desc"]!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Proceed to purchase (Coming Soon)",
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("Buy @ ₹49"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
