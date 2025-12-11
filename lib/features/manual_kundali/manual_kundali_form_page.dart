import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_result_page.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';

class ManualKundaliFormPage extends StatefulWidget {
  const ManualKundaliFormPage({super.key});

  @override
  State<ManualKundaliFormPage> createState() => _ManualKundaliFormPageState();
}

class _ManualKundaliFormPageState extends State<ManualKundaliFormPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final tobController = TextEditingController();
  final placeController = TextEditingController();

  double? latitude;
  double? longitude;
  String? timezone;

  bool _submitting = false;

  String selectedLanguage = "English";

  // ---------------------------------------------------------------
  // DATE PICKER
  // ---------------------------------------------------------------
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      dobController.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

  // ---------------------------------------------------------------
  // TIME PICKER
  // ---------------------------------------------------------------
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );

    if (time != null) {
      tobController.text =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  // ---------------------------------------------------------------
  // Convert DD-MM-YYYY → YYYY-MM-DD
  // ---------------------------------------------------------------
  String _convertDobToIso(String ddmmyyyy) {
    final p = ddmmyyyy.split("-");
    return "${p[2]}-${p[1]}-${p[0]}";
  }

  // ---------------------------------------------------------------
  // TEXT FIELD BUILDER
  // ---------------------------------------------------------------
  Widget _tf({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        validator: (v) =>
            v == null || v.trim().isEmpty ? "Required field" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // GOOGLE PLACES AUTOCOMPLETE (REST)
  // ---------------------------------------------------------------
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;

  Future<void> _onPlaceSearch(String input) async {
    if (input.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _loadingSuggestions = true);

    final key = dotenv.env["GOOGLE_MAPS_API_KEY"]!;
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$input&components=country:in&key=$key";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["status"] == "OK") {
        setState(() {
          _suggestions = (data["predictions"] as List)
              .map(
                (p) => {
                  "description": p["description"],
                  "place_id": p["place_id"],
                },
              )
              .toList();
        });
      }
    } catch (_) {}

    setState(() => _loadingSuggestions = false);
  }

  // ---------------------------------------------------------------
  // FETCH TIMEZONE BY LAT & LNG
  // ---------------------------------------------------------------
  Future<void> _fetchTimezone() async {
    if (latitude == null || longitude == null) return;

    final key = dotenv.env["GOOGLE_MAPS_API_KEY"]!;
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final url =
        "https://maps.googleapis.com/maps/api/timezone/json"
        "?location=$latitude,$longitude&timestamp=$ts&key=$key";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      print("📡 TIMEZONE API RESPONSE: $data");

      // ❗ ONLY set if Google returns correct zone
      if (data["timeZoneId"] != null && data["status"] == "OK") {
        timezone = data["timeZoneId"];
      } else {
        timezone = null; // so submit will fail and you know it’s broken
      }
    } catch (e) {
      print("❌ TIMEZONE ERROR: $e");
      timezone = null;
    }
  }

  // ---------------------------------------------------------------
  // GET LAT/LNG FROM PLACE DETAILS
  // ---------------------------------------------------------------
  Future<void> _selectPlaceSuggestion(Map<String, dynamic> p) async {
    final key = dotenv.env["GOOGLE_MAPS_API_KEY"]!;
    final placeId = p["place_id"];

    final url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeId&key=$key";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["status"] == "OK") {
        final loc = data["result"]["geometry"]["location"];

        latitude = (loc["lat"] as num).toDouble();
        longitude = (loc["lng"] as num).toDouble();

        await _fetchTimezone(); // ← ADD TIMEZONE

        setState(() {
          placeController.text = p["description"];
          _suggestions = [];
        });
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------
  // SUBMIT → Backend Call
  // ---------------------------------------------------------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid place")),
      );
      return;
    }

    if (timezone == null) {
      await _fetchTimezone();
      if (timezone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Timezone error. Try again.")),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    final provider = context.read<ManualKundaliProvider>();

    final ok = await provider.generateKundali(
      name: nameController.text.trim(),
      dob: _convertDobToIso(dobController.text.trim()),
      tob: tobController.text.trim(),
      place: placeController.text.trim(),
      lat: latitude!,
      lng: longitude!,
      timezone: timezone!, // ⭐ ADDED
      language: selectedLanguage == "English" ? "en" : "hi",
    );

    setState(() => _submitting = false);

    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error ?? "Failed")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManualKundaliResultPage()),
    );
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Manual Kundali",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tf(
                  controller: nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                ),

                _tf(
                  controller: dobController,
                  label: "Date of Birth (DD-MM-YYYY)",
                  icon: Icons.cake_outlined,
                  readOnly: true,
                  onTap: _pickDate,
                ),

                _tf(
                  controller: tobController,
                  label: "Time of Birth (HH:MM)",
                  icon: Icons.access_time,
                  readOnly: true,
                  onTap: _pickTime,
                ),

                // ----------------------------- PLACE SEARCH -----------------------------
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: placeController,
                        onChanged: _onPlaceSearch,
                        decoration: const InputDecoration(
                          labelText: "Place of Birth",
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: Colors.deepPurple,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Required field"
                            : null,
                      ),

                      if (_loadingSuggestions) const LinearProgressIndicator(),

                      if (_suggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final item = _suggestions[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.deepPurple,
                                ),
                                title: Text(item["description"]),
                                onTap: () => _selectPlaceSuggestion(item),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // LANGUAGE DROPDOWN
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: "Preferred Language",
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.language,
                        color: Colors.deepPurple,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "English",
                        child: Text("English"),
                      ),
                      DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                    ],
                    onChanged: (val) => setState(() => selectedLanguage = val!),
                  ),
                ),

                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          "Generate Kundali",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const SizedBox(height: 20),
                const Center(child: BannerAdWidget()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
