import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:jyotishasha_app/app/features/reports/pages/report_viewer_page.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🧾 Example purchased reports (replace later with Firestore/Backend data)
    final List<Map<String, dynamic>> purchasedReports = [
      {
        'title': 'Career Report',
        'purchaseDate': DateTime.now().subtract(const Duration(days: 2)),
        'pdfUrl': 'https://example.com/report_career.pdf', // backend PDF link
      },
      {
        'title': 'Marriage Compatibility',
        'purchaseDate': DateTime.now().subtract(const Duration(days: 8)),
        'pdfUrl': 'https://example.com/report_marriage.pdf', // expired one
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: Colors.deepPurple,
      ),
      body: purchasedReports.isEmpty
          ? const Center(child: Text('No purchased reports yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: purchasedReports.length,
              itemBuilder: (context, index) {
                final report = purchasedReports[index];
                final purchaseDate = report['purchaseDate'] as DateTime;
                final expiryDate = purchaseDate.add(const Duration(days: 7));
                final isExpired = DateTime.now().isAfter(expiryDate);

                return _PurchasedReportCard(
                  title: report['title'],
                  pdfUrl: report['pdfUrl'],
                  purchaseDate: purchaseDate,
                  expiryDate: expiryDate,
                  isExpired: isExpired,
                );
              },
            ),
    );
  }
}

class _PurchasedReportCard extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final bool isExpired;

  const _PurchasedReportCard({
    required this.title,
    required this.pdfUrl,
    required this.purchaseDate,
    required this.expiryDate,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final remainingDays = expiryDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧭 Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),

            // 📅 Date Info
            Text(
              'Purchased on: ${dateFormat.format(purchaseDate)}',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
            Text(
              'Expires on: ${dateFormat.format(expiryDate)}',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),

            const SizedBox(height: 12),

            // ⏳ Expiry or Remaining
            if (isExpired)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Expired',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Valid for ${remainingDays + 1} day(s)',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            const SizedBox(height: 16),

            // 🔘 Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isExpired
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReportViewerPage(pdfUrl: pdfUrl),
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isExpired
                        ? null
                        : () {
                            Share.share(
                              'Here is my purchased report: $title\n$pdfUrl',
                              subject: 'Jyotishasha Report - $title',
                            );
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
