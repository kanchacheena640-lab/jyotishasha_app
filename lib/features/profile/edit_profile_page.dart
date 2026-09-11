// lib/features/profile/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/services/location_service.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _tobCtrl;
  late TextEditingController _pobCtrl;

  double _lat = 0.0;
  double _lng = 0.0;

  String _selectedLanguage = "en";

  /// REST autocomplete
  List<Map<String, String>> _suggestions = [];
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();

    // -------------------------
    // INITIAL FILL
    // -------------------------
    _nameCtrl = TextEditingController(text: widget.profile["name"] ?? "");
    _dobCtrl = TextEditingController(text: widget.profile["dob"] ?? "");
    _tobCtrl = TextEditingController(text: widget.profile["tob"] ?? "");
    _pobCtrl = TextEditingController(text: widget.profile["pob"] ?? "");

    _lat = (widget.profile["lat"] ?? 0.0).toDouble();
    _lng = (widget.profile["lng"] ?? 0.0).toDouble();

    final lang = widget.profile["language"]?.toString().toLowerCase();
    _selectedLanguage = (lang == "hi") ? "hi" : "en";
  }

  // Neutral historical default -- same convention as
  // birth_detail_page.dart's own _pickDateCupertino(), so both DOB-
  // collecting flows fail toward the same safe value when there's no
  // usable existing DOB. Deliberately never DateTime.now(): Jyotishasha
  // supports genuine newborn/recent birth charts, so "today" cannot be
  // used as a stand-in for "nothing picked yet".
  static final DateTime _neutralDefaultDob = DateTime(2000);

  // Parses the pre-filled/previously-picked DOB text back into a
  // DateTime for the picker's initialDate. Tolerant of both shapes this
  // field can currently hold -- "YYYY-MM-DD" (as written by
  // birth_detail_page.dart's initial profile save) and "DD-MM-YYYY" (as
  // written by this screen's own _pickDate() below); reconciling that
  // pre-existing format inconsistency is a separate concern, out of
  // scope here -- this parser only needs to not crash or silently
  // misread whichever shape is actually present. Falls back to the
  // neutral default for anything empty/unparseable/outside the
  // picker's own [1900, today] bounds.
  DateTime _existingDobOrDefault() {
    final text = _dobCtrl.text.trim();
    if (text.isEmpty) return _neutralDefaultDob;

    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text);
    final dmy = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(text);

    int? year, month, day;
    if (iso != null) {
      year = int.tryParse(iso.group(1)!);
      month = int.tryParse(iso.group(2)!);
      day = int.tryParse(iso.group(3)!);
    } else if (dmy != null) {
      day = int.tryParse(dmy.group(1)!);
      month = int.tryParse(dmy.group(2)!);
      year = int.tryParse(dmy.group(3)!);
    }
    if (year == null || month == null || day == null) return _neutralDefaultDob;

    DateTime parsed;
    try {
      parsed = DateTime(year, month, day);
    } catch (_) {
      return _neutralDefaultDob;
    }
    final now = DateTime.now();
    if (parsed.isBefore(DateTime(1900)) || parsed.isAfter(now)) {
      return _neutralDefaultDob;
    }
    return parsed;
  }

  // -----------------------------------------------------------
  // DATE PICKER
  // -----------------------------------------------------------
  //
  // DATA-INTEGRITY FIX: previously always initialized to
  // DateTime.now(), so a user who opened this picker and tapped OK
  // without changing anything would silently overwrite a correct
  // existing DOB with today's date. Now initializes from the existing
  // DOB when one is present/parseable, else the same neutral
  // historical default birth_detail_page.dart uses -- confirming
  // without touching the wheel now always preserves what was already
  // there (or requires an actual pick when there wasn't one).
  Future<void> _pickDate() async {
    final initial = _existingDobOrDefault();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _dobCtrl.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

  // -----------------------------------------------------------
  // TIME PICKER
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // AUTOCOMPLETE (REST)
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // HANDLE SELECTED PLACE
  // -----------------------------------------------------------
  Future<void> _selectPlace(Map<String, String> p) async {
    _pobCtrl.text = p["description"] ?? "";
    FocusScope.of(context).unfocus();

    final details = await LocationService.fetchPlaceDetail(p["place_id"]!);

    if (details != null) {
      setState(() {
        _lat = (details["lat"] as num).toDouble();
        _lng = (details["lng"] as num).toDouble();
        _suggestions = [];
      });
    }
  }

  // -----------------------------------------------------------
  // SAVE CHANGES
  // -----------------------------------------------------------
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProfileProvider>();
    final activeId = provider.activeProfileId;

    if (activeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No active profile")));
      return;
    }

    final updated = {
      "name": _nameCtrl.text.trim(),
      "dob": _dobCtrl.text.trim(),
      "tob": _tobCtrl.text.trim(),
      "pob": _pobCtrl.text.trim(),
      "lat": _lat,
      "lng": _lng,
      "language": _selectedLanguage,
    };

    final ok = await provider.updateProfile(activeId, updated);

    if (!mounted) return;

    if (ok) {
      provider.notifyListeners();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated ✨")));

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update ❌")));
    }
  }

  // -----------------------------------------------------------
  // DELETE PROFILE
  // -----------------------------------------------------------
  Future<void> _deleteProfile() async {
    final provider = context.read<ProfileProvider>();
    final id = provider.activeProfileId;

    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Profile?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await provider.deleteProfile(id);

    if (ok && mounted) Navigator.pop(context, true);
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: KeyboardDismissOnTap(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ------------------ NAME ------------------
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                ),

                const SizedBox(height: 12),

                // ------------------ DOB -------------------
                TextFormField(
                  controller: _dobCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 12),

                // ------------------ TOB -------------------
                TextFormField(
                  controller: _tobCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Time of Birth",
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  onTap: _pickTime,
                ),

                const SizedBox(height: 12),

                // ------------------ PLACE FIELD -------------------
                TextFormField(
                  controller: _pobCtrl,
                  decoration: const InputDecoration(
                    labelText: "Place of Birth",
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  onChanged: _searchPlace,
                ),

                if (_loadingSuggestions) const LinearProgressIndicator(),

                if (_suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
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

                const SizedBox(height: 12),

                // ------------------ LANGUAGE -------------------
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: const InputDecoration(labelText: "Language"),
                  items: const [
                    DropdownMenuItem(value: "en", child: Text("English")),
                    DropdownMenuItem(value: "hi", child: Text("Hindi")),
                  ],
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),

                const SizedBox(height: 24),

                // ------------------ SAVE BUTTON -------------------
                ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                TextButton.icon(
                  onPressed: _deleteProfile,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    "Delete Profile",
                    style: TextStyle(color: Colors.red),
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
