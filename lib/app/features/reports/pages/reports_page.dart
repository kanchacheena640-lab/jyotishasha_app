import 'package:flutter/material.dart';
import '../data/reports_data.dart';
import '../widgets/report_card.dart';
import 'report_detail_sheet.dart';
import 'report_checkout_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedCategory = "All";

  List<String> get categories {
    final all = reportsData
        .map((r) => r['category'] as String)
        .toSet()
        .toList();
    all.sort();
    return ["All", ...all];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == "All"
        ? reportsData
        : reportsData.where((r) => r['category'] == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Personalized Reports")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((c) {
                  final isSel = c == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: isSel,
                      selectedColor: Colors.deepPurple,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.deepPurple,
                      ),
                      onSelected: (_) => setState(() => selectedCategory = c),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.74,
                ),
                itemBuilder: (_, i) {
                  final r = filtered[i];
                  return ReportCard(
                    title: r['title'],
                    image: r['image'],
                    price: r['price'],
                    description: r['description'],
                    onKnowMore: () async {
                      final action = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => ReportDetailSheet(report: r),
                      );
                      if (action == 'buy' && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportCheckoutPage(report: r),
                          ),
                        );
                      }
                    },
                    onBuyNow: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportCheckoutPage(report: r),
                        ),
                      );
                    },
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
