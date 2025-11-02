import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/features/reports/models/report_model.dart';
import 'package:jyotishasha_app/app/services/report_service.dart'; // ✅ correct import
import 'dart:io';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  late Future<List<ReportModel>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _fetchUserReports();
  }

  Future<List<ReportModel>> _fetchUserReports() async {
    // 🔹 For now, dummy loader — replace later with Firestore fetch
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<ReportModel>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No purchased reports yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final reports = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final r = reports[i];
              final expired = ReportService.isExpired(r.expiresAt);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${r.language} • ${expired ? "Expired" : "Active"}",
                        style: TextStyle(
                          fontSize: 13,
                          color: expired ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.download_rounded),
                            label: const Text("Download"),
                            onPressed: expired
                                ? null
                                : () => ReportService.downloadReport(
                                    context,
                                    reportId: r.id,
                                    pdfUrl: r.pdfUrl,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.share_rounded),
                            label: const Text("Share"),
                            onPressed:
                                (r.localPath != null &&
                                    File(r.localPath!).existsSync())
                                ? () => ReportService.shareReport(r.localPath!)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
