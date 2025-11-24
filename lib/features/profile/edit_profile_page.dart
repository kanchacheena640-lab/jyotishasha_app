import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
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

  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.profile["name"] ?? "");
    _dobCtrl = TextEditingController(text: widget.profile["dob"] ?? "");
    _tobCtrl = TextEditingController(text: widget.profile["tob"] ?? "");
    _pobCtrl = TextEditingController(text: widget.profile["pob"] ?? "");

    _lat = (widget.profile["lat"] ?? 0.0).toDouble();
    _lng = (widget.profile["lng"] ?? 0.0).toDouble();

    final lang = widget.profile["language"]?.toString().toLowerCase();

    if (lang == "hindi" || lang == "hi") {
      _selectedLanguage = "Hindi";
    } else {
      _selectedLanguage = "English"; // default
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _dobCtrl.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = context.read<ProfileProvider>();
    final activeId = profileProvider.activeProfileId;

    // 🛑 SAFETY CHECK — ID MUST NOT BE NULL
    if (activeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active profile selected ❌")),
      );
      return;
    }

    final updatedData = {
      "name": _nameCtrl.text.trim(),
      "dob": _dobCtrl.text.trim(),
      "tob": _tobCtrl.text.trim(),
      "pob": _pobCtrl.text.trim(),
      "lat": _lat,
      "lng": _lng,
      "language": _selectedLanguage,
    };

    final provider = context.read<ProfileProvider>();
    final ok = await provider.updateProfile(activeId, updatedData);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully ✨")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile ❌")),
      );
    }
  }

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
                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 12),

                // DOB
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

                // TOB
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

                // POB AUTOCOMPLETE
                GooglePlaceAutoCompleteTextField(
                  textEditingController: _pobCtrl,
                  googleAPIKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                  inputDecoration: const InputDecoration(
                    labelText: "Place of Birth",
                    border: OutlineInputBorder(),
                  ),
                  debounceTime: 800,
                  countries: const ["in"],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    setState(() {
                      _pobCtrl.text = prediction.description ?? "";
                      _lat = double.tryParse(prediction.lat ?? "0") ?? 0.0;
                      _lng = double.tryParse(prediction.lng ?? "0") ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Language
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(labelText: "Language"),
                  items: const [
                    DropdownMenuItem(value: "English", child: Text("English")),
                    DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                  ],
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),
                const SizedBox(height: 24),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
