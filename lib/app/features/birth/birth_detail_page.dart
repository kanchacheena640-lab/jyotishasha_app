import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:jyotishasha_app/app/routes/app_routes.dart';

class BirthDetailPage extends StatefulWidget {
  const BirthDetailPage({super.key});

  @override
  State<BirthDetailPage> createState() => _BirthDetailPageState();
}

class _BirthDetailPageState extends State<BirthDetailPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _placeController = TextEditingController();

  double? _lat;
  double? _lng;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // 📅 Pick Date
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dobController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  // ⏰ Pick Time
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // 💾 Save Details
  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Time of Birth')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final location = tz.getLocation('Asia/Kolkata');
      final tzName = location.name;
      final tzOffsetMinutes = location.currentTimeZone.offset ~/ 60000;

      await db.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
        'tob':
            '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
        'birthPlace': _placeController.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'tzName': tzName,
        'tzOffsetMinutes': tzOffsetMinutes,
        'hasBirthDetails': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      debugPrint("⚠️ Firestore save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save details. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    debugPrint("🔍 Loaded Google API Key: $apiKey");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Birth Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 👤 Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter name'
                      : null,
                ),
                const SizedBox(height: 16),

                // 📅 Date of Birth
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Select DOB' : null,
                ),
                const SizedBox(height: 16),

                // ⏰ Time of Birth
                ListTile(
                  title: Text(
                    selectedTime == null
                        ? 'Select Time of Birth'
                        : 'Time of Birth: ${selectedTime!.format(context)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 8),

                // 📍 Place of Birth
                GooglePlaceAutoCompleteTextField(
                  textEditingController: _placeController,
                  googleAPIKey: apiKey,
                  inputDecoration: const InputDecoration(
                    labelText: 'Place of Birth',
                    border: OutlineInputBorder(),
                  ),
                  debounceTime: 400,
                  countries: const ["in"],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    try {
                      final double? lat = prediction.lat != null
                          ? double.tryParse(prediction.lat!)
                          : null;
                      final double? lng = prediction.lng != null
                          ? double.tryParse(prediction.lng!)
                          : null;
                      setState(() {
                        _lat = lat;
                        _lng = lng;
                      });
                    } catch (e) {
                      debugPrint("⚠️ LatLng parsing error: $e");
                    }
                  },
                  itemClick: (Prediction prediction) {
                    _placeController.text = prediction.description ?? '';
                    _placeController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _placeController.text.length),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Validation hint
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '* All fields are required',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),

                const SizedBox(height: 24),

                // Continue Button
                ElevatedButton.icon(
                  onPressed: _saveDetails,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  label: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
