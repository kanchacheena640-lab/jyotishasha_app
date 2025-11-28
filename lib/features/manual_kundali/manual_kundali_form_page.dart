import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_result_page.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';

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

  bool _submitting = false;

  String selectedLanguage = "English";

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

  String _convertDobToIso(String ddmmyyyy) {
    final p = ddmmyyyy.split("-");
    return "${p[2]}-${p[1]}-${p[0]}";
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid place")),
      );
      return;
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

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      // ⭐ ADD THIS WRAPPER
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
                  child: GooglePlaceAutoCompleteTextField(
                    textEditingController: placeController,
                    googleAPIKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                    inputDecoration: const InputDecoration(
                      labelText: "Place of Birth",
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Colors.deepPurple,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    debounceTime: 300,
                    countries: const ["in"],
                    isLatLngRequired: true,
                    getPlaceDetailWithLatLng: (Prediction p) async {
                      if (p.lat != null && p.lng != null) {
                        latitude = double.tryParse(p.lat!);
                        longitude = double.tryParse(p.lng!);
                      } else {
                        final locs = await locationFromAddress(p.description!);
                        latitude = locs.first.latitude;
                        longitude = locs.first.longitude;
                      }
                    },
                    itemClick: (Prediction p) {
                      placeController.text = p.description ?? "";
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),

                // ⭐ LANGUAGE DROPDOWN
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
                    onChanged: (val) => setState(() {
                      selectedLanguage = val!;
                    }),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
