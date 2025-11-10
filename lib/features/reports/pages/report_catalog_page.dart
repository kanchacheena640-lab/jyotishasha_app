import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_checkout_page.dart';

class ReportCatalogPage extends StatefulWidget {
  const ReportCatalogPage({super.key});

  @override
  State<ReportCatalogPage> createState() => _ReportCatalogPageState();
}

class _ReportCatalogPageState extends State<ReportCatalogPage> {
  List<dynamic> reports = [];
  bool loading = true;
  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      final data = await rootBundle.loadString('assets/data/reports.json');
      setState(() {
        reports = jsonDecode(data);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading JSON: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEFF5),
      appBar: AppBar(
        title: const Text("Personal Astrology Reports"),
        centerTitle: true,
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : Column(
              children: [
                // 🔮 Category Filter Chips
                SizedBox(
                  height: 55,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: _buildCategoryChips(),
                  ),
                ),

                // 📄 Report Cards List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports().length,
                    itemBuilder: (context, index) {
                      final r = _filteredReports()[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF5F8), Color(0xFFFCEFF9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _showReportDetails(context, r);
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                                child: Image.asset(
                                  r["image"],
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r["title"],
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF4A148C),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        r["description"],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "₹${r["price"]}",
                                            style: GoogleFonts.montserrat(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF7C3AED),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF7C3AED,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            onPressed: () {
                                              _showReportDetails(context, r);
                                            },
                                            child: const Text(
                                              "Buy Now",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // 🔮 Category Chips builder
  List<Widget> _buildCategoryChips() {
    final categories = [
      "All",
      ...{...reports.map((r) => r["category"]).toSet()},
    ];

    return categories.map((cat) {
      final isSelected = selectedCategory == cat;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(
            cat,
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.white : const Color(0xFF7C3AED),
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: isSelected,
          selectedColor: const Color(0xFF7C3AED),
          backgroundColor: Colors.white,
          onSelected: (_) {
            setState(() {
              selectedCategory = cat;
            });
          },
        ),
      );
    }).toList();
  }

  // 🎯 Filter reports by category
  List<dynamic> _filteredReports() {
    if (selectedCategory == "All") return reports;
    return reports
        .where(
          (r) => r["category"].toString().toLowerCase().contains(
            selectedCategory.toLowerCase(),
          ),
        )
        .toList();
  }

  // 🪶 Show full details in bottom sheet
  void _showReportDetails(BuildContext context, dynamic report) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 550),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼️ Image on top
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.asset(
                        report["image"],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report["title"],
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A148C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            report["fullDescription"],
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReportCheckoutPage(report: report),
                                  ),
                                );
                              },
                              child: Text(
                                "Buy Now ₹${report["price"]}",
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        );
      },
    );
  }
}
