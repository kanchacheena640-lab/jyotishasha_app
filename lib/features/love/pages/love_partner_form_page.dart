import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/services/location_service.dart';
import 'package:jyotishasha_app/features/reports/pages/report_payment_page.dart';

import '../providers/love_provider.dart';
import '../enums/love_tool.dart';
import '../pages/love_result_hub_page.dart';

enum Gender { male, female }

class LovePartnerFormPage extends StatefulWidget {
  final LoveTool? tool; // null = report flow

  const LovePartnerFormPage({super.key, this.tool});

  @override
  State<LovePartnerFormPage> createState() => _LovePartnerFormPageState();
}

class _LovePartnerFormPageState extends State<LovePartnerFormPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _dob = '';
  String _tob = '';
  String _pob = '';
  double? _lat;
  double? _lng;
  Gender? _gender;

  bool _submitting = false;

  final _dobController = TextEditingController();
  final _tobController = TextEditingController();
  final _locationController = TextEditingController();

  List<Map<String, String>> _placeSuggestions = [];
  bool _loadingSuggestions = false;

  @override
  void dispose() {
    _dobController.dispose();
    _tobController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ---------------- DATE ----------------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _dob = formatted;
        _dobController.text = formatted;
      });
    }
  }

  // ---------------- TIME ----------------
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        _tob = formatted;
        _tobController.text = formatted;
      });
    }
  }

  // ---------------- PLACES ----------------
  Future<void> _fetchPlaceSuggestions(String input) async {
    if (input.trim().length < 3) {
      setState(() => _placeSuggestions = []);
      return;
    }

    setState(() => _loadingSuggestions = true);
    final results = await LocationService.fetchAutocomplete(input);

    setState(() {
      _loadingSuggestions = false;
      _placeSuggestions = results;
    });
  }

  Future<void> _selectPlace(Map<String, String> place) async {
    final details = await LocationService.fetchPlaceDetail(place["place_id"]!);

    if (details == null) {
      _showError("Unable to fetch place details");
      return;
    }

    setState(() {
      _pob = place["description"]!;
      _locationController.text = _pob;
      _lat = details["lat"];
      _lng = details["lng"];
      _placeSuggestions = [];
    });
  }

  // ---------------- SUBMIT ----------------
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      _showError("Please select place from suggestions");
      return;
    }

    if (_gender == null) {
      _showError("Please select partner gender");
      return;
    }

    final profile = context.read<ProfileProvider>().activeProfile ?? {};
    if (profile.isEmpty) {
      _showError("User profile not found");
      return;
    }

    final bool boyIsUser = _gender == Gender.female;

    final payload = {
      "language": profile["language"] ?? "en",
      "boy_is_user": boyIsUser,
      "user": {
        "name": profile["name"],
        "dob": profile["dob"],
        "tob": profile["tob"],
        "pob": profile["pob"],
        "lat": profile["lat"],
        "lng": profile["lng"],
      },
      "partner": {
        "name": _name,
        "dob": _dob,
        "tob": _tob,
        "pob": _pob,
        "lat": _lat,
        "lng": _lng,
      },
    };

    context.read<LoveProvider>().setPayload(payload);
    setState(() => _submitting = true);

    // ✅ TOOL FLOW
    if (widget.tool != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LoveResultHubPage(tool: widget.tool!, payload: payload),
        ),
      ).then((_) {
        // 👈 user back aaya
        if (!mounted) return;
        setState(() {
          _submitting = false; // 🔥 RESET LOADER
        });
      });
      return;
    }

    // ✅ REPORT FLOW
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPaymentPage(
          selectedReport: {
            "id": "relationship_future_report",
            "title": "Relationship Future Report",
          },
          formData: {"love_payload": payload},
        ),
      ),
    );
  }

  String get _submitButtonText {
    if (widget.tool == null) return "Proceed to Payment";

    switch (widget.tool!) {
      case LoveTool.matchMaking:
        return "Check Compatibility";
      case LoveTool.mangalDosh:
        return "Check Mangal Dosh";
      case LoveTool.truthOrDare:
        return "Reveal Truth or Dare";
      case LoveTool.marriageProbability:
        return "Check Marriage Probability";
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Partner Details",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Partner Name"),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? "Enter partner name" : null,
              onChanged: (v) => _name = v.trim(),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: "Date of Birth",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (_) => _dob.isEmpty ? "Select date of birth" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _tobController,
              readOnly: true,
              onTap: _pickTime,
              decoration: const InputDecoration(
                labelText: "Time of Birth",
                suffixIcon: Icon(Icons.access_time),
              ),
              validator: (_) => _tob.isEmpty ? "Select time of birth" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Place of Birth",
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: _fetchPlaceSuggestions,
            ),

            if (_loadingSuggestions)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: LinearProgressIndicator(),
              ),

            if (_placeSuggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _placeSuggestions.length,
                itemBuilder: (_, i) {
                  final s = _placeSuggestions[i];
                  return ListTile(
                    title: Text(s["description"]!),
                    onTap: () => _selectPlace(s),
                  );
                },
              ),

            const SizedBox(height: 16),

            const Text(
              "Partner Gender",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<Gender>(
                    value: Gender.male,
                    groupValue: _gender,
                    title: const Text("Male"),
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ),
                Expanded(
                  child: RadioListTile<Gender>(
                    value: Gender.female,
                    groupValue: _gender,
                    title: const Text("Female"),
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_submitButtonText),
            ),
          ],
        ),
      ),
    );
  }
}
