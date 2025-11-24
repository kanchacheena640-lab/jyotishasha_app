import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';

class BirthDetailPage extends StatefulWidget {
  const BirthDetailPage({super.key});

  @override
  State<BirthDetailPage> createState() => _BirthDetailPageState();
}

class _BirthDetailPageState extends State<BirthDetailPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final tobCtrl = TextEditingController();
  final pobCtrl = TextEditingController();
  String selectedLang = 'English';
  bool _isSaving = false;

  double? latitude;
  double? longitude;

  /// 🔹 Convert DD-MM-YYYY → YYYY-MM-DD
  String _convertDob(String ddmmyyyy) {
    final parts = ddmmyyyy.split("-");
    return "${parts[2]}-${parts[1]}-${parts[0]}";
  }

  /// 🔹 Date Picker
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      dobCtrl.text =
          "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    }
  }

  /// 🔹 Time Picker
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      tobCtrl.text = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

  /// 🔥 FINAL SAVE FLOW:
  /// 1) Validate form
  /// 2) Call Backend → /api/user/bootstrap
  /// 3) Save to Firestore
  /// 4) Go to Dashboard
  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final provider = context.read<KundaliProvider>();

      // Step 1 — collect user input
      final name = nameCtrl.text.trim();
      final dob = _convertDob(dobCtrl.text.trim());
      final tob = tobCtrl.text.trim();
      final pob = pobCtrl.text.trim();
      final lat = latitude ?? 26.8467;
      final lng = longitude ?? 80.9462;
      final language = selectedLang == "English" ? "en" : "hi";

      // Step 2 — backend bootstrap
      final result = await provider.bootstrapUserProfile(
        name: name,
        dob: dob,
        tob: tob,
        pob: pob,
        lat: lat,
        lng: lng,
        language: language,
      );

      if (result == null || result["ok"] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? "Bootstrap failed")),
        );
        return;
      }

      // Step 3 — Save to Firestore
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      const profileId = "default";

      await userRef.set({
        "activeProfileId": profileId,
        "updatedAt": DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await userRef.collection("profiles").doc(profileId).set({
        "name": name,
        "dob": dob,
        "tob": tob,
        "pob": pob,
        "lat": lat,
        "lng": lng,
        "language": language,
        "lagna": result["lagna"],
        "moon_sign": result["moon_sign"],
        "nakshatra": result["nakshatra"],
        "backendProfileId": result["profileId"],
        "profile_complete": true,
        "createdAt": DateTime.now().toIso8601String(),
        "updatedAt": DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // Step 4 — move to Dashboard
      context.go('/dashboard');
    } catch (e) {
      debugPrint("❌ Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            "Enter Birth Details",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF5F8),
                  Color(0xFFFCEFF9),
                  Color(0xFFFEEFF5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Tell us about yourself 🌞",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Name
                  _buildTextField(
                    controller: nameCtrl,
                    label: "Full Name",
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty
                        ? "Please enter your name"
                        : null,
                  ),

                  // DOB
                  _buildTextField(
                    controller: dobCtrl,
                    label: "Date of Birth (DD-MM-YYYY)",
                    icon: Icons.cake_outlined,
                    readOnly: true,
                    onTap: _pickDate,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Please enter your DOB" : null,
                  ),

                  // TOB
                  _buildTextField(
                    controller: tobCtrl,
                    label: "Time of Birth (HH:MM)",
                    icon: Icons.access_time,
                    readOnly: true,
                    onTap: _pickTime,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Please enter your TOB" : null,
                  ),

                  // POB
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GooglePlaceAutoCompleteTextField(
                      textEditingController: pobCtrl,
                      googleAPIKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                      inputDecoration: const InputDecoration(
                        labelText: "Place of Birth",
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      debounceTime: 400,
                      countries: const ["in"],
                      isLatLngRequired: true,
                      getPlaceDetailWithLatLng: (Prediction prediction) async {
                        if (prediction.lat != null && prediction.lng != null) {
                          latitude = double.tryParse(prediction.lat!);
                          longitude = double.tryParse(prediction.lng!);
                        } else {
                          final locations = await locationFromAddress(
                            prediction.description!,
                          );
                          if (locations.isNotEmpty) {
                            latitude = locations.first.latitude;
                            longitude = locations.first.longitude;
                          }
                        }
                      },
                      itemClick: (Prediction prediction) {
                        pobCtrl.text = prediction.description ?? "";
                        FocusScope.of(context).unfocus();
                      },
                      itemBuilder: (context, index, Prediction prediction) {
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                          title: Text(prediction.description ?? ""),
                        );
                      },
                    ),
                  ),

                  // Language dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedLang,
                      decoration: const InputDecoration(
                        labelText: "Preferred Language",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.language),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text("English"),
                        ),
                        DropdownMenuItem(value: 'Hindi', child: Text("Hindi")),
                      ],
                      onChanged: (val) => setState(() => selectedLang = val!),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Continue Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Continue",
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onTap: onTap,
        readOnly: readOnly,
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
