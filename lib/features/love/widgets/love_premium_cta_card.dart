import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/reports/pages/report_payment_page.dart';
import '../providers/love_provider.dart';

class LovePremiumCtaCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const LovePremiumCtaCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile ?? const {};

    final lang = profile['language'] ?? 'en';

    final title = lang == 'hi'
        ? 'इस रिश्ते को गहराई से समझना चाहते हैं?'
        : 'Want deeper clarity about this relationship?';

    final subtitle = lang == 'hi'
        ? 'शादी की संभावना, स्थिरता, समय और उपाय।'
        : 'Marriage chances, long-term stability, timing & remedies.';

    final buttonText = lang == 'hi' ? 'रिपोर्ट देखें' : 'View Report';

    final price = report['price'] ?? 299;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹$price',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: profile.isEmpty
                      ? null
                      : () {
                          final payload = context.read<LoveProvider>().payload;
                          if (payload == null) return; // 🔒 safety

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportPaymentPage(
                                selectedReport: report,
                                formData: {"love_payload": payload},
                              ),
                            ),
                          );
                        },

                  child: Text(buttonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
