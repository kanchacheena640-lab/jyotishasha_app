import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/features/kundali/kundali_overview_page.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/services/location_service.dart';

/// Task 2 — Self/Other Kundali UX unified the manual ("Other person")
/// Kundali experience into [KundaliOverviewPage] itself (a Self|Other
/// toggle, showing the existing birth-details form inline when no Other
/// Kundali exists yet, and the exact same shared chart/details rendering
/// used for Self once one does — see [ManualKundaliBirthDetailsForm] and
/// [KundaliOverviewPage]'s `useManualProvider` mode).
///
/// Both live "Create Another Kundali" entry points
/// (`_CreateAnotherKundaliSection` in [KundaliOverviewPage],
/// `CreateAnotherKundaliBanner` on Dashboard Home) still push this exact
/// page/type, unchanged — so this class stays the stable navigation
/// target, but now simply opens the unified page already in Other mode
/// instead of a separate, standalone form screen. No new route is
/// registered and no competing Kundali result UI is created: the actual
/// birth-details form now lives in exactly one place,
/// [ManualKundaliBirthDetailsForm], reused here (via
/// [KundaliOverviewPage]) and embedded directly inside
/// [KundaliOverviewPage] when its own toggle is switched to Other.
class ManualKundaliFormPage extends StatelessWidget {
  const ManualKundaliFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const KundaliOverviewPage(
      useManualProvider: true,
      autoLoad: false,
    );
  }
}

/// The existing Other-person birth-details form — Full Name, Date of
/// Birth, Time of Birth, Place of Birth (with the existing Google Places
/// autocomplete + lat/lng/timezone resolution via [LocationService]) —
/// extracted unchanged (same fields, same validation, same location
/// resolution, same [ManualKundaliProvider.generateKundali] call) from
/// the page that used to own it, so it can be shown either standalone
/// (via [ManualKundaliFormPage]) or embedded directly inside
/// [KundaliOverviewPage]'s Other-mode empty state — one implementation,
/// two places it can appear, never two competing forms.
///
/// Localization gap fix (Task 2): this form previously showed English
/// text only, and read the *profile's* saved language (via
/// `ProfileProvider`) purely to inform the backend which language to
/// generate the Kundali in. It now follows the project's existing EN/HI
/// mechanism — [LanguageProvider], the same provider
/// [KundaliOverviewPage] itself already reads — for both the UI copy and
/// the language sent to the backend, and no longer depends on
/// `ProfileProvider` at all.
///
/// On a successful submit, this widget does not navigate anywhere itself
/// — [ManualKundaliProvider.generateKundali] populates
/// [ManualKundaliProvider.kundali] and calls `notifyListeners()`, and the
/// parent [KundaliOverviewPage] (which already watches that provider)
/// reactively swaps this form out for the shared Kundali rendering. This
/// keeps the two source providers ([ManualKundaliProvider]) fully
/// decoupled from any navigation concern.
class ManualKundaliBirthDetailsForm extends StatefulWidget {
  const ManualKundaliBirthDetailsForm({super.key, required this.isHindi});

  final bool isHindi;

  @override
  State<ManualKundaliBirthDetailsForm> createState() =>
      _ManualKundaliBirthDetailsFormState();
}

class _ManualKundaliBirthDetailsFormState
    extends State<ManualKundaliBirthDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final tobController = TextEditingController();
  final placeController = TextEditingController();

  double? latitude;
  double? longitude;
  String? timezone;

  bool _submitting = false;

  bool get _isHindi => widget.isHindi;

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
        validator: (v) => v == null || v.trim().isEmpty
            ? (_isHindi ? "आवश्यक फ़ील्ड" : "Required field")
            : null,
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
    // Task 2 — follows the project's existing EN/HI mechanism
    // (LanguageProvider, the same one KundaliOverviewPage itself reads)
    // instead of the signed-in user's own saved profile language, which
    // has no real relationship to what language a chart generated for
    // someone else should render in.
    final profileLang = context.read<LanguageProvider>().currentLang;

    if (!_formKey.currentState!.validate()) return;

    // BirthDetail jaisa rule: ONLY lat/lng check
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHindi
                ? "कृपया एक मान्य स्थान चुनें"
                : "Please select a valid place",
          ),
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? (_isHindi ? "असफल" : "Failed"),
            ),
          ),
        );
        return;
      }

      // Success — no navigation here. `provider.kundali` is now set and
      // notifyListeners() already fired; the parent KundaliOverviewPage
      // (which watches ManualKundaliProvider) reactively shows the
      // shared Kundali rendering in place of this form.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isHindi = _isHindi;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isHindi ? 'उनका जन्म विवरण दर्ज करें' : "Enter Their Birth Details",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1B2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isHindi
                ? 'अपने परिवार, दोस्तों या किसी और के लिए कुंडली बनाने हेतु विवरण भरें।'
                : 'Fill in the details to generate a Kundali for your '
                      'family, friends or anyone else.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          _tf(
            controller: nameController,
            label: isHindi ? "पूरा नाम" : "Full Name",
            icon: Icons.person_outline,
          ),

          _tf(
            controller: dobController,
            label: isHindi
                ? "जन्म तिथि (DD-MM-YYYY)"
                : "Date of Birth (DD-MM-YYYY)",
            icon: Icons.cake_outlined,
            readOnly: true,
            onTap: _pickDate,
          ),

          _tf(
            controller: tobController,
            label: isHindi ? "जन्म समय (HH:MM)" : "Time of Birth (HH:MM)",
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
                  decoration: InputDecoration(
                    labelText: isHindi ? "जन्म स्थान" : "Place of Birth",
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.deepPurple,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? (isHindi ? "आवश्यक फ़ील्ड" : "Required field")
                      : null,
                ),

                if (_loadingSuggestions) const LinearProgressIndicator(),

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
                          onTap: () =>
                              _selectPlaceSuggestion(item), // 🔑 REQUIRED
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
              isHindi
                  ? 'कुंडली की भाषा आपकी ऐप भाषा के अनुसार होगी। इसे बदलने के लिए '
                        'खाता → भाषा पर जाएं।'
                  : 'The Kundali language follows your app language. '
                        'Change it from Account → Language.',
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
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Text(
                    isHindi ? "कुंडली बनाएं" : "Generate Kundali",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),

          // 🔹 BANNER — kept inline (this widget may be embedded inside
          // another scrollable page, so it is no longer pinned to a
          // screen edge the way it was in the old standalone Scaffold).
          const SizedBox(height: 16),
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
