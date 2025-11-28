// lib/features/reports/pages/report_catalog_page.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

import 'report_checkout_page.dart';

class ReportCatalogPage extends StatefulWidget {
  const ReportCatalogPage({super.key});

  @override
  State<ReportCatalogPage> createState() => _ReportCatalogPageState();
}

class _ReportCatalogPageState extends State<ReportCatalogPage> {
  List<dynamic> reports = [];
  bool loading = true;

  /// 🔹 Category slug: 'all', 'Finance', 'Self', 'Marriage', 'Transit' etc.
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  /// 🔥 Always load English JSON as base + merge Hindi text if available
  Future<void> _loadReports() async {
    try {
      setState(() => loading = true);

      // 1) Base EN data
      final enData = await rootBundle.loadString('assets/data/reports.json');
      final List<dynamic> enList = jsonDecode(enData);

      // 2) Optional HI overlay (only text fields)
      try {
        final hiData = await rootBundle.loadString(
          'assets/data/reports_hi.json',
        );
        final List<dynamic> hiList = jsonDecode(hiData);

        final len = math.min(enList.length, hiList.length);

        for (int i = 0; i < len; i++) {
          final en = enList[i] as Map<String, dynamic>;
          final hi = hiList[i] as Map<String, dynamic>;

          if (hi['title_hi'] != null) {
            en['title_hi'] = hi['title_hi'];
          }
          if (hi['description_hi'] != null) {
            en['description_hi'] = hi['description_hi'];
          }
          if (hi['fullDescription_hi'] != null) {
            en['fullDescription_hi'] = hi['fullDescription_hi'];
          }
          if (hi['category_hi'] != null) {
            en['category_hi'] = hi['category_hi'];
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not load reports_hi.json: $e');
      }

      setState(() {
        reports = enList;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading reports JSON: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final lang = context.watch<LanguageProvider>().currentLang;

    return Scaffold(
      backgroundColor: const Color(0xFFFEEFF5),
      appBar: AppBar(
        title: Text(t.reports_title),
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
                // 🔹 CATEGORY CHIPS
                SizedBox(
                  height: 55,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: _buildCategoryChips(t),
                  ),
                ),

                // 🔹 REPORT CARDS
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports().length,
                    itemBuilder: (context, index) {
                      final r = _filteredReports()[index];

                      // ✅ Safe String casting
                      final String title =
                          (lang == "hi"
                                  ? (r["title_hi"] ?? r["title"])
                                  : r["title"])
                              .toString();

                      final String desc =
                          (lang == "hi"
                                  ? (r["description_hi"] ?? r["description"])
                                  : r["description"])
                              .toString();

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
                          onTap: () => _showReportDetails(context, r, lang, t),
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
                                        title,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF4A148C),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        desc,
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
                                            "${t.reports_price_prefix}${r["price"]}",
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
                                            onPressed: () => _showReportDetails(
                                              context,
                                              r,
                                              lang,
                                              t,
                                            ),
                                            child: Text(
                                              t.reports_buy_now,
                                              style: const TextStyle(
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

  // 🔹 CATEGORY CHIPS
  List<Widget> _buildCategoryChips(AppLocalizations t) {
    // Unique category slugs from JSON
    final lang = context.read<LanguageProvider>().currentLang;

    final Set<String> categories = {
      for (final r in reports)
        if (lang == "hi")
          (r["category_hi"] ?? r["category"] ?? "").toString()
        else
          (r["category"] ?? "").toString(),
    };

    return [
      // "All" chip
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(
            t.reports_category_all,
            style: GoogleFonts.montserrat(
              color: selectedCategory == 'all'
                  ? Colors.white
                  : const Color(0xFF7C3AED),
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: selectedCategory == 'all',
          selectedColor: const Color(0xFF7C3AED),
          backgroundColor: Colors.white,
          onSelected: (_) {
            setState(() {
              selectedCategory = 'all';
            });
          },
        ),
      ),
      // Category chips from JSON (Finance, Love, Marriage...)
      ...categories.map((cat) {
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
      }),
    ];
  }

  // 🔹 FILTERED REPORTS
  List<dynamic> _filteredReports() {
    if (selectedCategory == 'all') return reports;

    return reports.where((r) {
      final en = (r["category"] ?? "").toString().toLowerCase();
      final hi = (r["category_hi"] ?? "").toString().toLowerCase();
      final sel = selectedCategory.toLowerCase();

      return en == sel || hi == sel;
    }).toList();
  }

  // 🔹 DETAILS POPUP
  void _showReportDetails(
    BuildContext context,
    dynamic report,
    String lang,
    AppLocalizations t,
  ) {
    final String title =
        (lang == "hi"
                ? (report["title_hi"] ?? report["title"])
                : report["title"])
            .toString();

    final String desc =
        (lang == "hi"
                ? (report["fullDescription_hi"] ?? report["fullDescription"])
                : report["fullDescription"])
            .toString();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondary, child) {
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
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4A148C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            desc,
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
                                "${t.reports_buy_now} ${t.reports_price_prefix}${report["price"]}",
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
