import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jyotishasha_app/features/kundali/kundali_detail_page.dart';
import 'package:http/http.dart' as http;

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

  // ⭐ AUTOCOMPLETE STATE
  List<Map<String, String>> suggestions = [];
  bool pobLoading = false;

  // 🔥 Convert DD-MM-YYYY to YYYY-MM-DD
  String convertDob(String ddmmyyyy) {
    final parts = ddmmyyyy.split("-");
    return "${parts[2]}-${parts[1]}-${parts[0]}";
  }

  // ⭐ Pick Date
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: DateTime(1990),
    );

    if (date != null) {
      dobCtrl.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

  // ⭐ Pick Time
  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );

    if (time != null) {
      tobCtrl.text = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  // ⭐ REST API – Autocomplete
  Future<List<Map<String, String>>> fetchAutocomplete(String input) async {
    if (input.length < 3) return [];

    final key = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$input&components=country:in&key=$key";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["status"] != "OK") return [];

    return (data["predictions"] as List)
        .map<Map<String, String>>(
          (p) => {
            "description": p["description"].toString(),
            "place_id": p["place_id"].toString(),
          },
        )
        .toList();
  }

  // ⭐ REST API – Geocode lat/lng
  Future<void> fetchLatLng(String placeId) async {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?placeid=$placeId&key=$key";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    final loc = data["result"]["geometry"]["location"];
    lat = loc["lat"];
    lng = loc["lng"];
  }

  // ⭐ Submit
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
              style: const TextStyle(
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

            // ⭐ REST AUTOCOMPLETE FIELD
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.only(left: 4, right: 4),
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
              child: Column(
                children: [
                  TextFormField(
                    controller: pobCtrl,
                    decoration: const InputDecoration(
                      labelText: "Place of Birth",
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) async {
                      if (value.length < 3) {
                        setState(() => suggestions = []);
                        return;
                      }

                      setState(() => pobLoading = true);
                      final data = await fetchAutocomplete(value);
                      setState(() {
                        suggestions = data;
                        pobLoading = false;
                      });
                    },
                    validator: (v) => v!.isEmpty ? "Choose Place" : null,
                  ),

                  if (pobLoading) const LinearProgressIndicator(),

                  if (suggestions.isNotEmpty)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView(
                        children: suggestions.map((s) {
                          return ListTile(
                            title: Text(s["description"]!),
                            onTap: () async {
                              pobCtrl.text = s["description"]!;
                              suggestions = [];
                              FocusScope.of(context).unfocus();
                              await fetchLatLng(s["place_id"]!);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
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
                      style: const TextStyle(
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
