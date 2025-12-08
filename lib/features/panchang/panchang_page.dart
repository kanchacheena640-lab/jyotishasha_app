import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/core/widgets/global_share_button.dart';

import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

import 'package:jyotishasha_app/l10n/app_localizations.dart';

class PanchangPage extends StatefulWidget {
  const PanchangPage({super.key});

  @override
  State<PanchangPage> createState() => _PanchangPageState();
}

class _PanchangPageState extends State<PanchangPage> {
  String locationName = "Lucknow, India";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final lang = context.read<LanguageProvider>().currentLang;
      context.read<PanchangProvider>().loadPanchang(lang: lang);
    });
  }

  // 🔄 Change Location
  void _changeLocation(double lat, double lng, String name) {
    final lang = context.read<LanguageProvider>().currentLang;
    final p = context.read<PanchangProvider>();

    setState(() => locationName = name);
    p.fetchPanchang(lat: lat, lng: lng, lang: lang);
  }

  // 🌍 Place Picker Dialog
  void _openPlacePickerDialog() {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.changeLocationTitle),
        content: KeyboardDismissOnTap(
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: _searchController,
            googleAPIKey: "YOUR_GOOGLE_API_KEY",
            debounceTime: 800,
            isLatLngRequired: true,
            countries: const ["in"],
            getPlaceDetailWithLatLng: (Prediction p) {
              final lat = double.tryParse(p.lat ?? '') ?? 26.8467;
              final lng = double.tryParse(p.lng ?? '') ?? 80.9462;

              Navigator.pop(context);
              _changeLocation(lat, lng, p.description ?? t.selectedPlace);
            },
            itemBuilder: (context, index, Prediction p) {
              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(p.description ?? ""),
              );
            },
            itemClick: (Prediction p) {
              _searchController.text = p.description ?? "";
            },
          ),
        ),
      ),
    );
  }

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
          style: GoogleFonts.montserrat(
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

  // ⚠ ERROR UI
  Widget _buildError() {
    final t = AppLocalizations.of(context)!;
    return Center(child: Text(t.loadingError));
  }

  // MAIN PANCHANG BODY UI
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
          // 📅 DATE + LOCATION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "📍 $locationName",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _openPlacePickerDialog,
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: Text(t.change),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 🌞 SURRISE + SUNSET
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

          // MAIN ELEMENTS
          Text(
            t.panchang_elements,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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

          // ⭐ HIGHLIGHTS
          Text(
            t.panchang_highlights,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          _highlight(
            t.panchang_abhijit,
            "${d['abhijit_muhurta']?['start']} – ${d['abhijit_muhurta']?['end']}",
          ),
          _highlight(
            t.panchang_rahu,
            "${d['rahu_kaal']?['start']} – ${d['rahu_kaal']?['end']}",
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              t.dataSyncedText,
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ⭐ GOOGLE BANNER AD (footer ke upar) — CENTER FIX
          Center(
            child: SizedBox(
              width: double.infinity, // Ensures full-width
              child: const BannerAdWidget(),
            ),
          ),

          const SizedBox(height: 20),
          AppFooterFeedbackWidget(),
        ],
      ),
    );
  }

  // ROW TILE
  Widget _dataRow(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              v ?? '--',
              textAlign: TextAlign.end,
              style: GoogleFonts.montserrat(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // STAR HIGHLIGHT
  Widget _highlight(String title, String value) {
    return Card(
      color: AppColors.surface,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.star_border_outlined,
          color: AppColors.primary.withOpacity(0.9),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // INFO TILE
  Widget _infoTile(String title, String value) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
