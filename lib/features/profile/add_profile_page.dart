import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/services/location_service.dart';

class AddProfilePage extends StatefulWidget {
  const AddProfilePage({super.key});

  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _tobCtrl = TextEditingController();
  final TextEditingController _pobCtrl = TextEditingController();

  double? _lat;
  double? _lng;
  String? _timezone;

  String _selectedGender = "Male";
  String _selectedLanguage = "English";

  // -------------------------------------------------------
  // DATE PICKER
  // -------------------------------------------------------
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _dobCtrl.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

  // -------------------------------------------------------
  // TIME PICKER
  // -------------------------------------------------------
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      _tobCtrl.text =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  // -------------------------------------------------------
  // REST GOOGLE PLACES AUTOCOMPLETE
  // -------------------------------------------------------
  List<Map<String, String>> _suggestions = [];
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
        _suggestions = (data["predictions"] as List).map<Map<String, String>>((
          p,
        ) {
          return {"description": p["description"], "place_id": p["place_id"]};
        }).toList();
      } else {
        _suggestions = [];
      }
    } catch (e) {
      _suggestions = [];
    }

    setState(() => _loadingSuggestions = false);
  }

  // -------------------------------------------------------
  // PLACE DETAILS → LAT/LNG + TIMEZONE
  // -------------------------------------------------------
  Future<void> _selectPlace(Map<String, String> p) async {
    _pobCtrl.text = p["description"]!;
    FocusScope.of(context).unfocus();

    final details = await LocationService.fetchPlaceDetail(p["place_id"]!);

    if (details != null) {
      _lat = details["lat"];
      _lng = details["lng"];

      // ⭐ Auto timezone
      _timezone = await LocationService.fetchTimeZone(_lat!, _lng!);
    }

    setState(() => _suggestions = []);
  }

  // -------------------------------------------------------
  // SAVE PROFILE
  // -------------------------------------------------------
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid place")),
      );
      return;
    }

    final provider = context.read<ProfileProvider>();

    final data = {
      "name": _nameCtrl.text.trim(),
      "dob": _dobCtrl.text.trim(),
      "tob": _tobCtrl.text.trim(),
      "pob": _pobCtrl.text.trim(),
      "lat": _lat!,
      "lng": _lng!,
      "timezone": _timezone ?? "Asia/Kolkata",
      "gender": _selectedGender,
      "language": _selectedLanguage,
      "createdAt": DateTime.now().toIso8601String(),
    };

    final id = await provider.addProfile(data);

    if (id != null) {
      if (provider.activeProfileId == null) {
        await provider.setActiveProfile(id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile created")));

      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Failed to save profile")));
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: KeyboardDismissOnTap(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 16),

                // DOB
                TextFormField(
                  controller: _dobCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Select DOB" : null,
                ),
                const SizedBox(height: 16),

                // TOB
                TextFormField(
                  controller: _tobCtrl,
                  readOnly: true,
                  onTap: _pickTime,
                  decoration: const InputDecoration(
                    labelText: "Time of Birth",
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Select TOB" : null,
                ),
                const SizedBox(height: 16),

                // PLACE FIELD
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _pobCtrl,
                        onChanged: _onPlaceSearch,
                        decoration: const InputDecoration(
                          labelText: "Place of Birth",
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Enter place"
                            : null,
                      ),

                      if (_loadingSuggestions) const LinearProgressIndicator(),

                      if (_suggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            itemCount: _suggestions.length,
                            itemBuilder: (_, i) {
                              final s = _suggestions[i];
                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(s["description"]!),
                                onTap: () => _selectPlace(s),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // GENDER
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                    DropdownMenuItem(value: "Other", child: Text("Other")),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v!),
                  decoration: const InputDecoration(labelText: "Gender"),
                ),
                const SizedBox(height: 16),

                // LANGUAGE
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: "English", child: Text("English")),
                    DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                  ],
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                  decoration: const InputDecoration(labelText: "Language"),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text("Save Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 28,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
