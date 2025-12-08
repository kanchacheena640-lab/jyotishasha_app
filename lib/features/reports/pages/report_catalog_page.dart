// lib/features/reports/pages/report_catalog_page.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

// CHECKOUT PAGE IMPORT (IMPORTANT)
import 'package:jyotishasha_app/features/reports/pages/report_checkout_page.dart';

class ReportCatalogPage extends StatefulWidget {
  const ReportCatalogPage({super.key});

  @override
  State<ReportCatalogPage> createState() => _ReportCatalogPageState();
}

class _ReportCatalogPageState extends State<ReportCatalogPage> {
  List<dynamic> reports = [];
  bool loading = true;

  /// Category: all / Finance / Marriage / Love / Transit / Self
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // ------------------------------------------------------------
  // LOAD REPORT JSON
  // ------------------------------------------------------------
  Future<void> _loadReports() async {
    try {
      setState(() => loading = true);

      final enData = await rootBundle.loadString("assets/data/reports.json");
      final List<dynamic> enList = jsonDecode(enData);

      try {
        final hiData = await rootBundle.loadString(
          "assets/data/reports_hi.json",
        );
        final List<dynamic> hiList = jsonDecode(hiData);

        final len = math.min(enList.length, hiList.length);

        for (int i = 0; i < len; i++) {
          final en = enList[i] as Map<String, dynamic>;
          final hi = hiList[i] as Map<String, dynamic>;

          if (hi["title_hi"] != null) en["title_hi"] = hi["title_hi"];
          if (hi["description_hi"] != null) {
            en["description_hi"] = hi["description_hi"];
          }
          if (hi["fullDescription_hi"] != null) {
            en["fullDescription_hi"] = hi["fullDescription_hi"];
          }
          if (hi["category_hi"] != null) en["category_hi"] = hi["category_hi"];

          en["id"] = (en["slug"] ?? "").toString().trim().toLowerCase();
        }
      } catch (_) {
        debugPrint("⚠️ reports_hi.json missing");
      }

      setState(() {
        reports = enList;
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ ERROR loading reports: $e");
      setState(() => loading = false);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
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
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : Column(
              children: [
                // Category chips
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

                // Report list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReports().length,
                    itemBuilder: (context, i) {
                      final r = _filteredReports()[i];

                      final String title =
                          (lang == "hi"
                                  ? r["title_hi"] ?? r["title"]
                                  : r["title"])
                              .toString();

                      final String desc =
                          (lang == "hi"
                                  ? r["description_hi"] ?? r["description"]
                                  : r["description"])
                              .toString();

                      return _buildReportCard(r, title, desc, t, lang);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------
  // CATEGORY CHIPS
  // ------------------------------------------------------------
  List<Widget> _buildCategoryChips(AppLocalizations t) {
    final lang = context.read<LanguageProvider>().currentLang;

    final Set<String> categories = {
      for (final r in reports)
        lang == "hi"
            ? (r["category_hi"] ?? r["category"] ?? "")
            : (r["category"] ?? ""),
    };

    return [
      _chip(t.reports_category_all, "all"),
      ...categories.map((c) => _chip(c, c)),
    ];
  }

  Widget _chip(String label, String value) {
    final selected = selectedCategory == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF7C3AED),
          ),
        ),
        selected: selected,
        selectedColor: const Color(0xFF7C3AED),
        backgroundColor: Colors.white,
        onSelected: (_) => setState(() => selectedCategory = value),
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTER LOGIC
  // ------------------------------------------------------------
  List<dynamic> _filteredReports() {
    if (selectedCategory == "all") return reports;

    return reports.where((r) {
      final en = (r["category"] ?? "").toString().toLowerCase();
      final hi = (r["category_hi"] ?? "").toString().toLowerCase();
      final sel = selectedCategory.toLowerCase();
      return en == sel || hi == sel;
    }).toList();
  }

  // ------------------------------------------------------------
  // REPORT CARD
  // ------------------------------------------------------------
  Widget _buildReportCard(
    dynamic r,
    String title,
    String desc,
    AppLocalizations t,
    String lang,
  ) {
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final rootCtx = Navigator.of(context, rootNavigator: true).context;
          _showReportDetails(rootCtx, r, lang, t);
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
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${t.reports_price_prefix}${r["price"]}",
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF7C3AED),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () =>
                              _showReportDetails(context, r, lang, t),
                          child: Text(
                            t.reports_buy_now,
                            style: const TextStyle(color: Colors.white),
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
  }

  // ------------------------------------------------------------
  // POPUP + CHECKOUT
  // ------------------------------------------------------------
  void _showReportDetails(
    BuildContext context,
    dynamic r,
    String lang,
    AppLocalizations t,
  ) {
    final String title = (lang == "hi"
        ? r["title_hi"] ?? r["title"]
        : r["title"]);
    final String desc =
        (lang == "hi"
                ? r["fullDescription_hi"] ?? r["fullDescription"]
                : r["fullDescription"])
            .toString();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (c, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      ),
      pageBuilder: (c, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(c).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 580),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: Image.asset(
                        r["image"],
                        width: double.infinity,
                        height: 170,
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
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // BUY NOW BUTTON (FINAL PATCH)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                // Proper dialog close
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();

                                final profile =
                                    context
                                        .read<ProfileProvider>()
                                        .activeProfile ??
                                    {};

                                // Safe navigation post-frame
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReportCheckoutPage(
                                        selectedReport: r,
                                        initialProfile: profile,
                                      ),
                                    ),
                                  );
                                });
                              },
                              child: Text(
                                "${t.reports_buy_now} ${t.reports_price_prefix}${r["price"]}",
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
