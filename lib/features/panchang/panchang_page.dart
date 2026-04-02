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
    Future.microtask(() {
      final lang = context.read<LanguageProvider>().currentLang;
      context.read<PanchangProvider>().loadPanchang(lang: lang);
    });
  }

  // -------------------------------------------------------------------------
  // ⭐ GOOGLE PLACES — AUTOCOMPLETE (REST)
  // -------------------------------------------------------------------------
  Future<List<Map<String, String>>> fetchAutocomplete(String input) async {
    if (input.trim().length < 3) return [];
    return await LocationService.fetchAutocomplete(input);
  }

  // -------------------------------------------------------------------------
  // ⭐ GOOGLE PLACES — GET LAT/LNG (REST)
  // -------------------------------------------------------------------------
  Future<Map<String, double>> fetchLatLng(String placeId) async {
    final res = await LocationService.fetchPlaceDetail(placeId);
    if (res == null) {
      throw Exception("Place details not found");
    }
    return {"lat": res["lat"] as double, "lng": res["lng"] as double};
  }

  // -------------------------------------------------------------------------
  // ⭐ Change Location Handler (with TIMEZONE)
  // -------------------------------------------------------------------------
  Future<void> _changeLocation(double lat, double lng, String name) async {
    final lang = context.read<LanguageProvider>().currentLang;
    final p = context.read<PanchangProvider>();

    // ⭐ AUTO TIMEZONE
    final timezone = await LocationService.fetchTimeZone(lat, lng);

    setState(() => locationName = name);

    p.fetchPanchang(lat: lat, lng: lng, lang: lang);
  }

  // -------------------------------------------------------------------------
  // ⭐ Place Picker Dialog (REST)
  // -------------------------------------------------------------------------
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
                      final data = await fetchAutocomplete(value);
                      setStateSB(() {
                        suggestions = data;
                        loadingSuggestions = false;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  if (loadingSuggestions) const LinearProgressIndicator(),

                  // ⭐ FIX: Proper height + ListView visible
                  if (suggestions.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final s = suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(s["description"]!),
                            onTap: () async {
                              _searchController.text = s["description"]!;
                              final coords = await fetchLatLng(s["place_id"]!);

                              Navigator.pop(context);

                              _changeLocation(
                                coords["lat"]!,
                                coords["lng"]!,
                                s["description"]!,
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

  // -------------------------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final p = context.watch<PanchangProvider>();
    final d = p.fullPanchang;
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

      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : d == null
          ? _buildError()
          : _buildContent(d),
    );
  }

  Widget _buildError() {
    final t = AppLocalizations.of(context)!;
    return Center(child: Text(t.loadingError));
  }

  // -------------------------------------------------------------------------
  // MAIN CONTENT UI
  // -------------------------------------------------------------------------
  Widget _buildContent(Map<String, dynamic> d) {
    final t = AppLocalizations.of(context)!;

    final formattedDate = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.parse(d['date']));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE + LOCATION
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

          // SUNRISE + SUNSET
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
                  _infoTile(t.panchang_sunrise, d['sunrise']),
                  _infoTile(t.panchang_sunset, d['sunset']),
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

          _dataRow(
            t.panchang_tithi,
            "${d['tithi']?['name']} (${d['tithi']?['paksha']})",
          ),
          _dataRow(
            t.panchang_nakshatra,
            "${d['nakshatra']?['name']} (Pada ${d['nakshatra']?['pada']})",
          ),
          _dataRow(t.panchang_yoga, d['yoga']?['name']),
          _dataRow(t.panchang_karana, d['karan']?['name']),
          _dataRow(t.panchang_vaar, d['weekday']),
          _dataRow(t.panchang_panchak, d['panchak']?['message']),

          const SizedBox(height: 24),

          Text(
            t.panchang_highlights,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          _highlight(
            t.panchang_abhijit,
            "${d['abhijit_muhurta']?['start']} – ${d['abhijit_muhurta']?['end']}",
          ),
          _highlight(
            t.panchang_rahu,
            "${d['rahu_kaal']?['start']} – ${d['rahu_kaal']?['end']}",
          ),
          if (d['brahma_muhurta'] != null)
            _highlight(
              "Brahma Muhurta",
              "${d['brahma_muhurta']['start']} – ${d['brahma_muhurta']['end']}",
            ),

          const SizedBox(height: 32),
          if (d['chaughadiya'] != null) ...[
            const SizedBox(height: 24),
            const Text(
              "Chaughadiya (Day)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            GridView.count(
              crossAxisCount: 2,
              childAspectRatio:
                  2.6, // 🔥 height control (try 2.4–2.8 if needed)
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: (d['chaughadiya']['day'] as List)
                  .map((c) => _chaughadiyaCard(c))
                  .toList(),
            ),

            const SizedBox(height: 20),
            const Text(
              "Chaughadiya (Night)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            GridView.count(
              crossAxisCount: 2,
              childAspectRatio:
                  2.6, // 🔥 height control (try 2.4–2.8 if needed)
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: (d['chaughadiya']['night'] as List)
                  .map((c) => _chaughadiyaCard(c))
                  .toList(),
            ),
          ],
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
          AppFooterFeedbackWidget(),
        ],
      ),
    );
  }

  Widget _dataRow(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              v ?? '--',
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
          color: AppColors.primary.withOpacity(0.9),
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
  final isShubh = c['nature_en'] == 'shubh';

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isShubh ? Colors.green.shade50 : Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isShubh ? Colors.green : Colors.red,
        width: 0.8,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, // 🔥 vertical compact
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          c['name'],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          "${c['start']} – ${c['end']}",
          style: TextStyle(
            fontSize: 14.5, // 🔥 time prominent
            fontWeight: FontWeight.w700,
            color: isShubh ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
      ],
    ),
  );
}
