import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/widgets/app_footer_feedback_widget.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';

const String kGoogleApiKey = "YOUR_GOOGLE_API_KEY";

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
      final panchang = context.read<PanchangProvider>();
      panchang.loadPanchang();
    });
  }

  void _changeLocation(double lat, double lng, String name) {
    final p = context.read<PanchangProvider>();
    setState(() => locationName = name);
    p.fetchPanchang(lat: lat, lng: lng);
  }

  void _openPlacePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Location"),
        content: KeyboardDismissOnTap(
          child: GooglePlaceAutoCompleteTextField(
            textEditingController: _searchController,
            googleAPIKey: kGoogleApiKey,
            debounceTime: 800,
            countries: const ["in"],
            isLatLngRequired: true,
            getPlaceDetailWithLatLng: (Prediction p) {
              final lat = double.tryParse(p.lat ?? '') ?? 26.8467;
              final lng = double.tryParse(p.lng ?? '') ?? 80.9462;
              Navigator.pop(context);
              _changeLocation(lat, lng, p.description ?? "Selected Place");
            },
            itemClick: (Prediction p) {
              _searchController.text = p.description ?? "";
            },
            itemBuilder: (context, index, Prediction p) {
              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(p.description ?? ""),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PanchangProvider>();
    final d = provider.fullPanchang;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: Text(
          "Today's Panchang",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : d == null
          ? _buildError()
          : _buildContent(d),
    );
  }

  Widget _buildError() {
    return Center(child: Text("⚠️ Unable to load Panchang data"));
  }

  Widget _buildContent(Map<String, dynamic> d) {
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
                label: const Text("Change"),
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
                  _infoTile("Sunrise", d['sunrise']),
                  _infoTile("Sunset", d['sunset']),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "Main Panchang Elements",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),
          _dataRow(
            "Tithi",
            "${d['tithi']?['name']} (${d['tithi']?['paksha']})",
          ),
          _dataRow(
            "Nakshatra",
            "${d['nakshatra']?['name']} (Pada ${d['nakshatra']?['pada']})",
          ),
          _dataRow("Yoga", d['yoga']?['name']),
          _dataRow("Karana", d['karan']?['name']),
          _dataRow("Vaar", d['weekday']),
          _dataRow("Panchak", d['panchak']?['message']),

          const SizedBox(height: 24),

          Text(
            "Highlights",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          _highlight(
            "Abhijit Muhurta",
            "${d['abhijit_muhurta']?['start']} – ${d['abhijit_muhurta']?['end']}",
          ),
          _highlight(
            "Rahu Kaal",
            "${d['rahu_kaal']?['start']} – "
                "${d['rahu_kaal']?['end']}",
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              "✨ Data synced from Jyotishasha API ✨",
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 20),
          AppFooterFeedbackWidget(),
        ],
      ),
    );
  }

  Widget _dataRow(String k, String? v) => Padding(
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

  Widget _highlight(String title, String value) => Card(
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
