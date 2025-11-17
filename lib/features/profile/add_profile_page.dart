import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  double _lat = 0.0;
  double _lng = 0.0;

  String _selectedGender = 'Male';
  String _selectedLanguage = 'English';

  // 🗓️ Date picker
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _dobCtrl.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

  // 🕒 Time picker
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final formattedTime =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      _tobCtrl.text = formattedTime;
    }
  }

  // 💾 Save profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pobCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Place of Birth")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    final profileData = {
      "name": _nameCtrl.text.trim(),
      "dob": _dobCtrl.text.trim(),
      "tob": _tobCtrl.text.trim(),
      "pob": _pobCtrl.text.trim(),
      "lat": _lat,
      "lng": _lng,
      "gender": _selectedGender,
      "language": _selectedLanguage,
      "isActive": false,
      "createdAt": FieldValue.serverTimestamp(),
    };

    try {
      // 🔹 Reference to user's profile subcollection
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final profilesSnap = await userRef.collection('profiles').get();

      // 🔹 If no profiles exist, make this the active one
      profileData['isActive'] = profilesSnap.docs.isEmpty;

      // 🔹 Save profile
      await userRef.collection('profiles').add(profileData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile saved successfully")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error saving profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 👤 Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 12),

              // 📅 DOB
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
                validator: (v) => v!.isEmpty ? "Select DOB" : null,
              ),
              const SizedBox(height: 12),

              // 🕒 TOB
              TextFormField(
                controller: _tobCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Time of Birth",
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: _pickTime,
                validator: (v) => v!.isEmpty ? "Select TOB" : null,
              ),
              const SizedBox(height: 12),

              // 📍 Autocomplete for Place of Birth
              GooglePlaceAutoCompleteTextField(
                textEditingController: _pobCtrl,
                googleAPIKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                inputDecoration: const InputDecoration(
                  labelText: "Place of Birth",
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                debounceTime: 800,
                countries: const ["in"],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  setState(() {
                    _pobCtrl.text = prediction.description ?? "";
                    _lat =
                        double.tryParse(prediction.lat?.toString() ?? "0") ??
                        0.0;
                    _lng =
                        double.tryParse(prediction.lng?.toString() ?? "0") ??
                        0.0;
                  });
                },
                itemClick: (Prediction prediction) {
                  _pobCtrl.text = prediction.description ?? "";
                },
                itemBuilder: (context, index, Prediction prediction) {
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(prediction.description ?? ""),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 👩 Gender
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v!),
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              const SizedBox(height: 12),

              // 🌐 Language
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                ],
                onChanged: (v) => setState(() => _selectedLanguage = v!),
                decoration: const InputDecoration(labelText: "Language"),
              ),
              const SizedBox(height: 24),

              // 💾 Save Button
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Save Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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
    );
  }
}
