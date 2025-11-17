import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jyotishasha_app/features/kundali/kundali_detail_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GetAnyoneHoroscopeCard extends StatefulWidget {
  const GetAnyoneHoroscopeCard({super.key});

  @override
  State<GetAnyoneHoroscopeCard> createState() => _GetAnyoneHoroscopeCardState();
}

class _GetAnyoneHoroscopeCardState extends State<GetAnyoneHoroscopeCard> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final tobCtrl = TextEditingController();
  final pobCtrl = TextEditingController();

  String lang = "en";
  double? lat;
  double? lng;

  bool isLoading = false;

  String convertDob(String ddmmyyyy) {
    final parts = ddmmyyyy.split("-");
    return "${parts[2]}-${parts[1]}-${parts[0]}";
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(1990),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      dobCtrl.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );

    if (time != null) {
      tobCtrl.text = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  /// 🔥 FIXED submit() (Correct Brackets, Catch + Finally Added)
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please choose a valid Place of Birth")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final payload = {
        "name": nameCtrl.text.trim(),
        "dob": convertDob(dobCtrl.text),
        "tob": tobCtrl.text.trim(),
        "pob": pobCtrl.text.trim(),
        "lat": lat,
        "lng": lng,
        "language": lang,
        "timezone": "+05:30",
        "ayanamsa": "Lahiri",
      };

      final response = await http.post(
        Uri.parse(
          "https://jyotishasha-backend.onrender.com/api/full-kundali-modern",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => KundaliDetailPage(data: data)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Get Horoscope of Anyone — Free",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),

            _input(
              controller: nameCtrl,
              label: "Full Name",
              icon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? "Enter name" : null,
            ),

            _input(
              controller: dobCtrl,
              label: "Date of Birth",
              icon: Icons.cake_outlined,
              readOnly: true,
              onTap: pickDate,
              validator: (v) => v!.isEmpty ? "Choose DOB" : null,
            ),

            _input(
              controller: tobCtrl,
              label: "Time of Birth",
              icon: Icons.access_time,
              readOnly: true,
              onTap: pickTime,
              validator: (v) => v!.isEmpty ? "Choose TOB" : null,
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: pobCtrl,
                googleAPIKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                debounceTime: 400,
                countries: const ["in"],
                inputDecoration: const InputDecoration(
                  labelText: "Place of Birth",
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) async {
                  lat = double.tryParse(prediction.lat ?? "");
                  lng = double.tryParse(prediction.lng ?? "");

                  if (lat == null || lng == null) {
                    final loc = await locationFromAddress(
                      prediction.description!,
                    );
                    lat = loc.first.latitude;
                    lng = loc.first.longitude;
                  }
                },
                itemClick: (Prediction p) {
                  pobCtrl.text = p.description!;
                  FocusScope.of(context).unfocus();
                },
              ),
            ),

            DropdownButtonFormField<String>(
              initialValue: lang == "en" ? "English" : "Hindi",
              decoration: InputDecoration(
                labelText: "Preferred Language",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
              ],
              onChanged: (val) {
                lang = val == "English" ? "en" : "hi";
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Get Horoscope",
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(.05), blurRadius: 4),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
