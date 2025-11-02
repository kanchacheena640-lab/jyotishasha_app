import 'package:flutter/material.dart';

class ReportDetailSheet extends StatelessWidget {
  final Map<String, dynamic> report;
  const ReportDetailSheet({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Text(
            report['title'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            report['description'] ?? '',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "Price: ₹${report['price']}",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'buy'),
                child: const Text("Buy Now"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
