// lib/features/panchang/panchang_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:jyotishasha_app/core/widgets/global_share_button.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/services/location_service.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';

class PanchangPage extends StatefulWidget {
  const PanchangPage({super.key});

  @override
  State<PanchangPage> createState() => _PanchangPageState();
}

class _PanchangPageState extends State<PanchangPage> {
  String locationName = "Lucknow, India";
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> suggestions = [];
  bool loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<LanguageProvider>().currentLang;
      context.read<PanchangProvider>().loadPanchang(lang: lang);
    });
  }

  Future<void> _changeLocation(double lat, double lng, String name) async {
    final lang = context.read<LanguageProvider>().currentLang;
    final p = context.read<PanchangProvider>();

    setState(() => locationName = name);
    await p.loadPanchang(lat: lat, lng: lng, lang: lang);
  }

  void _openPlacePickerDialog() {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(t.changeLocationTitle),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: "Search location",
                    ),
                    onChanged: (value) async {
                      if (value.length < 3) {
                        setStateSB(() => suggestions = []);
                        return;
                      }

                      setStateSB(() => loadingSuggestions = true);

                      final data = await LocationService.fetchAutocomplete(
                        value,
                      );

                      setStateSB(() {
                        suggestions = data;
                        loadingSuggestions = false;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  if (loadingSuggestions) const LinearProgressIndicator(),

                  if (suggestions.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final s = suggestions[index];

                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(s["description"] ?? ""),

                            onTap: () async {
                              final coords =
                                  await LocationService.fetchPlaceDetail(
                                    s["place_id"] ?? "",
                                  );

                              if (!mounted) return;

                              // ✅ SAFE NULL CHECK (MAIN FIX)
                              if (coords == null ||
                                  coords["lat"] == null ||
                                  coords["lng"] == null) {
                                return;
                              }

                              Navigator.pop(context);

                              _changeLocation(
                                coords["lat"] as double,
                                coords["lng"] as double,
                                s["description"] ?? "Unknown",
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: Text(
          t.panchang,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [GlobalShareButton(currentPage: "panchang")],
      ),

      // ✅ ONLY THIS PART WATCHES PROVIDER
      body: Consumer<PanchangProvider>(
        builder: (context, p, _) {
          if (p.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (p.hasError || p.fullPanchang == null) {
            return _buildError(p, t);
          }

          return _buildContent(p, t);
        },
      ),
    );
  }

  Widget _buildError(PanchangProvider p, AppLocalizations t) {
    final message = p.errorMessage ?? t.loadingError;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildContent(PanchangProvider p, AppLocalizations t) {
    final d = p.fullPanchang!;

    final dateStr =
        d['date']?.toString() ??
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final formattedDate = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.parse(dateStr));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "📍 $locationName",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _openPlacePickerDialog,
                icon: const Icon(Icons.location_on_outlined),
                label: Text(t.change),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 2,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile(t.panchang_sunrise, p.sunrise),
                  _infoTile(t.panchang_sunset, p.sunset),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            t.panchang_elements,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          _dataRow(t.panchang_tithi, "${p.tithiName} (${p.tithiPaksha})"),
          _dataRow(
            t.panchang_nakshatra,
            "${p.nakshatra} (Pada ${d['nakshatra']?['pada']?.toString() ?? '--'})",
          ),
          _dataRow(t.panchang_yoga, p.yoga),
          _dataRow(t.panchang_karana, p.karan),
          _dataRow(t.panchang_vaar, p.weekday),
          _dataRow(t.panchang_panchak, p.panchakMessage),

          const SizedBox(height: 24),

          Text(
            t.panchang_highlights,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          _highlight(
            t.panchang_abhijit ?? "Abhijit Muhurta",
            "${p.abhijitStart} – ${p.abhijitEnd}",
          ),
          _highlight(
            t.panchang_rahu ?? "Rahu Kaal",
            "${p.rahukaalStart} – ${p.rahukaalEnd}",
          ),
          _highlight(
            "Brahma Muhurta",
            "${d['brahma_muhurta']?['start'] ?? '--'} – ${d['brahma_muhurta']?['end'] ?? '--'}",
          ),

          const SizedBox(height: 32),

          if (p.chaughadiyaDay.isNotEmpty) ...[
            const Text(
              "Chaughadiya (Day)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: p.chaughadiyaDay
                  .map((c) => _chaughadiyaCard(c))
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),

          if (p.chaughadiyaNight.isNotEmpty) ...[
            const Text(
              "Chaughadiya (Night)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: p.chaughadiyaNight
                  .map((c) => _chaughadiyaCard(c))
                  .toList(),
            ),
          ],

          const SizedBox(height: 30),
          Center(
            child: Text(
              t.dataSyncedText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const BannerAdWidget(),
          const SizedBox(height: 20),
          const AppFooterFeedbackWidget(),
        ],
      ),
    );
  }

  Widget _dataRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlight(String title, String value) {
    return Card(
      elevation: 1,
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.star_border_outlined,
          color: AppColors.primary.withValues(alpha: 0.9),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

Widget _chaughadiyaCard(Map<String, dynamic> c) {
  final isShubh = (c['nature_en'] ?? c['nature'] ?? '') == 'shubh';

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: isShubh ? Colors.green.shade50 : Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isShubh ? Colors.green : Colors.red,
        width: 0.8,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          "${c['start'] ?? ''} – ${c['end'] ?? ''}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isShubh ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
      ],
    ),
  );
}
