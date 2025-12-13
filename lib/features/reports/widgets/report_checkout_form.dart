// lib/features/reports/widgets/report_checkout_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:jyotishasha_app/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jyotishasha_app/services/location_service.dart';

class ReportCheckoutForm extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  final Function(Map<String, dynamic>) onFormUpdated;

  const ReportCheckoutForm({
    super.key,
    required this.initialProfile,
    required this.onFormUpdated,
  });

  @override
  State<ReportCheckoutForm> createState() => _ReportCheckoutFormState();
}

class _ReportCheckoutFormState extends State<ReportCheckoutForm> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController tobCtrl;
  late TextEditingController pobCtrl;

  String dob = "";
  String tob = "";
  double? lat;
  double? lng;
  String language = "en";

  // NEW — autocomplete state
  List<Map<String, String>> _suggestions = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();

    Map<String, dynamic> p = {};
    if (widget.initialProfile.isNotEmpty) {
      p = Map<String, dynamic>.from(widget.initialProfile);
    }

    // NAME
    nameCtrl = TextEditingController(text: p["name"]?.toString() ?? "");

    // EMAIL auto from Firebase
    final firebaseEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    emailCtrl = TextEditingController(text: firebaseEmail);

    // POB
    pobCtrl = TextEditingController(text: p["pob"]?.toString() ?? "");

    // DOB
    dob = p["dob"]?.toString() ?? "";
    if (dob.isNotEmpty) {
      try {
        final d = DateTime.parse(dob);
        dobCtrl = TextEditingController(
          text: DateFormat('dd MMM yyyy').format(d),
        );
      } catch (_) {
        dobCtrl = TextEditingController();
      }
    } else {
      dobCtrl = TextEditingController();
    }

    // TOB
    tob = p["tob"]?.toString() ?? "";
    if (tob.isNotEmpty) {
      try {
        final parts = tob.split(":");
        final dt = DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
        tobCtrl = TextEditingController(text: DateFormat('hh:mm a').format(dt));
      } catch (_) {
        tobCtrl = TextEditingController();
      }
    } else {
      tobCtrl = TextEditingController();
    }

    lat = (p["lat"] is num) ? (p["lat"] as num).toDouble() : null;
    lng = (p["lng"] is num) ? (p["lng"] as num).toDouble() : null;

    language = p["language"]?.toString() ?? "en";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParent();
    });
  }

  // Notify parent
  void _notifyParent() {
    widget.onFormUpdated({
      "name": nameCtrl.text,
      "email": emailCtrl.text,
      "dob": dob,
      "tob": tob,
      "pob": pobCtrl.text,
      "lat": lat,
      "lng": lng,
      "language": language,
    });
  }

  // DOB Picker
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dob.isNotEmpty
          ? DateTime.parse(dob)
          : DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: now,
    );

    if (picked != null) {
      dob =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      dobCtrl.text = DateFormat('dd MMM yyyy').format(picked);
      _notifyParent();
    }
  }

  // Time picker
  Future<void> _pickTob() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      tob =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      final dt = DateTime(0, 1, 1, picked.hour, picked.minute);
      tobCtrl.text = DateFormat('hh:mm a').format(dt);
      _notifyParent();
    }
  }

  // -------------------------------
  // GOOGLE PLACES — AUTOCOMPLETE (REST)
  // -------------------------------
  Future<void> _searchPlace(String input) async {
    if (input.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _loadingSuggestions = true);

    final data = await LocationService.fetchAutocomplete(input);

    if (!mounted) return;

    setState(() {
      _suggestions = data;
      _loadingSuggestions = false;
    });
  }

  // -------------------------------
  // SELECT PLACE — GET LAT/LNG
  // -------------------------------
  Future<void> _selectPlace(Map<String, String> p) async {
    pobCtrl.text = p["description"] ?? "";

    FocusScope.of(context).unfocus();

    final details = await LocationService.fetchPlaceDetail(p["place_id"]!);

    if (details != null) {
      setState(() {
        lat = (details["lat"] as num).toDouble();
        lng = (details["lng"] as num).toDouble();
        _suggestions = [];
      });
      _notifyParent();
    }
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ordering for someone else? Update the birth details below.",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.deepPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // NAME
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: t.checkout_name),
          onChanged: (_) => _notifyParent(),
        ),
        const SizedBox(height: 12),

        // EMAIL
        TextFormField(
          controller: emailCtrl,
          decoration: InputDecoration(
            labelText: t.checkout_email,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          onChanged: (_) => _notifyParent(),
        ),
        const SizedBox(height: 20),

        // DOB
        TextFormField(
          controller: dobCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: t.checkout_dob,
            suffixIcon: const Icon(Icons.calendar_today_rounded),
          ),
          onTap: _pickDob,
        ),
        const SizedBox(height: 12),

        // TOB
        TextFormField(
          controller: tobCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: t.checkout_tob,
            suffixIcon: const Icon(Icons.access_time_rounded),
          ),
          onTap: _pickTob,
        ),
        const SizedBox(height: 12),

        // PLACE OF BIRTH (REST GOOGLE PLACES)
        Text(
          t.checkout_pob,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple.shade700,
          ),
        ),
        const SizedBox(height: 6),

        TextFormField(
          controller: pobCtrl,
          decoration: InputDecoration(
            hintText: t.checkout_pob,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _searchPlace,
        ),

        if (_loadingSuggestions) const LinearProgressIndicator(),

        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 230),
            margin: const EdgeInsets.only(top: 4, bottom: 12),
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
                final s = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(s["description"] ?? ""),
                  onTap: () => _selectPlace(s),
                );
              },
            ),
          ),

        const SizedBox(height: 20),

        // LANGUAGE
        DropdownButtonFormField<String>(
          initialValue: language,
          decoration: InputDecoration(labelText: t.checkout_language),
          items: [
            DropdownMenuItem(value: "en", child: Text(t.checkout_language_en)),
            DropdownMenuItem(value: "hi", child: Text(t.checkout_language_hi)),
          ],
          onChanged: (v) {
            language = v ?? "en";
            _notifyParent();
          },
        ),
      ],
    );
  }
}
