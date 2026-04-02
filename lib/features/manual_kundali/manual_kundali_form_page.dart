import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/features/manual_kundali/manual_kundali_result_page.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/services/location_service.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';

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
  // GOOGLE PLACES AUTOCOMPLETE (REST) — FIXED & STABLE
  // ---------------------------------------------------------------
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;

  Future<void> _onPlaceSearch(String input) async {
    if (input.trim().length < 3) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
      return;
    }
    setState(() {
      _loadingSuggestions = true;
    });

    try {
      final data = await LocationService.fetchAutocomplete(input);

      if (!mounted) return;

      setState(() {
        _suggestions = data
            .map(
              (p) => {
                "description": p["description"],
                "place_id": p["place_id"],
              },
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSuggestions = false);
      }
    }
  }

  // ---------------------------------------------------------------
  // GET LAT/LNG FROM PLACE DETAILS
  // ---------------------------------------------------------------
  Future<void> _selectPlaceSuggestion(Map<String, dynamic> p) async {
    FocusScope.of(context).unfocus();

    setState(() => _loadingSuggestions = true);

    final details = await LocationService.fetchPlaceDetail(p["place_id"]);
    if (details == null) {
      setState(() => _loadingSuggestions = false);
      return;
    }

    final lat = (details["lat"] as num).toDouble();
    final lng = (details["lng"] as num).toDouble();

    String? tz;
    try {
      tz = await LocationService.fetchTimeZone(lat, lng);
    } catch (_) {
      tz = "Asia/Kolkata"; // 🔑 FALLBACK (same as Birth logic)
    }

    setState(() {
      placeController.text = p["description"] ?? "";
      latitude = lat;
      longitude = lng;
      timezone = tz ?? "Asia/Kolkata";
      _suggestions = [];
      _loadingSuggestions = false;
    });
  }

  // ---------------------------------------------------------------
  // SUBMIT → Backend Call (FINAL, CLEAN)
  // ---------------------------------------------------------------
  Future<void> _submit() async {
    final raw =
        context
            .read<ProfileProvider>()
            .activeProfile?["language"]
            ?.toString() ??
        "en";
    final profileLang = raw.toLowerCase().startsWith("hi") ? "hi" : "en";

    if (!_formKey.currentState!.validate()) return;

    // BirthDetail jaisa rule: ONLY lat/lng check
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid place")),
      );
      return;
    }

    // 🔑 🔥 EXACT LINE — YAHI ADD KARNA HAI
    timezone ??= "Asia/Kolkata";

    setState(() => _submitting = true);

    try {
      final provider = context.read<ManualKundaliProvider>();

      final ok = await provider.generateKundali(
        name: nameController.text.trim(),
        dob: _convertDobToIso(dobController.text.trim()),
        tob: tobController.text.trim(),
        place: placeController.text.trim(),
        lat: latitude!,
        lng: longitude!,
        timezone: timezone!, // required
        language: profileLang,
      );

      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error ?? "Failed")));
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManualKundaliResultPage()),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final rawLang =
        context
            .watch<ProfileProvider>()
            .activeProfile?["language"]
            ?.toString() ??
        "en";

    final activeLang = rawLang.toLowerCase().startsWith("hi")
        ? "Hindi"
        : "English";
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Manual Kundali",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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

                    // ---------------- PLACE SEARCH ----------------
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
                            readOnly: false, // 🔑 MUST BE FALSE
                            onChanged: (v) {
                              latitude = null;
                              longitude = null;
                              timezone = null;
                              _onPlaceSearch(v); // 🔥 THIS MUST FIRE
                            },
                            decoration: const InputDecoration(
                              labelText: "Place of Birth",
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: Colors.deepPurple,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? "Required field"
                                : null,
                          ),

                          if (_loadingSuggestions)
                            const LinearProgressIndicator(),

                          if (_suggestions.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              margin: const EdgeInsets.only(top: 4),
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
                                    title: Text(item["description"] ?? ""),
                                    onTap: () => _selectPlaceSuggestion(
                                      item,
                                    ), // 🔑 REQUIRED
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "Active language: $activeLang.\n"
                        "Go to Profile → Edit to change your language.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    // ---------------- SUBMIT BUTTON ----------------
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
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Generate Kundali",
                              style: TextStyle(
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

          // 🔹 BANNER FIXED AT BOTTOM (NO TAP BLOCK)
          const SizedBox(height: 60, child: BannerAdWidget()),
        ],
      ),
    );
  }

  // ---------------- DISPOSE ----------------
  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    tobController.dispose();
    placeController.dispose();
    super.dispose();
  }
}
