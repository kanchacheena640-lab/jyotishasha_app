import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

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

  /// Convert DD-MM-YYYY → YYYY-MM-DD
  String _convertDob(String ddmmyyyy) {
    final parts = ddmmyyyy.split("-");
    return "${parts[2]}-${parts[1]}-${parts[0]}";
  }

  // -------------------------------------------------------
  // PREMIUM GLASS PICKER POPUP
  // -------------------------------------------------------
  Widget _glassTopBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 55,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.35)),
          child: Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateCupertino() async {
    DateTime selected = DateTime.now();

    await showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 240),
            scale: 1.0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              height: 330,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _glassTopBar(),
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: DateTime(2000),
                      minimumDate: DateTime(1900),
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (value) => selected = value,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(12),
                        child: const Text("Done"),
                        onPressed: () {
                          dobCtrl.text =
                              "${selected.day.toString().padLeft(2, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.year}";
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickTimeCupertino() async {
    TimeOfDay selected = TimeOfDay.now();

    await showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 240),
            scale: 1.0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _glassTopBar(),
                  SizedBox(
                    height: 180,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      onDateTimeChanged: (value) {
                        selected = TimeOfDay.fromDateTime(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(12),
                        child: const Text("Done"),
                        onPressed: () {
                          tobCtrl.text =
                              "${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}";
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------
  // PREMIUM GOOGLE PLACE FIELD
  // -------------------------------------------------------
  Widget _buildPlaceField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        debounceTime: 400,
        countries: const ["in"],
        isLatLngRequired: true,

        getPlaceDetailWithLatLng: (Prediction prediction) async {
          if (prediction.lat != null && prediction.lng != null) {
            latitude = double.tryParse(prediction.lat!);
            longitude = double.tryParse(prediction.lng!);
          } else {
            final loc = await locationFromAddress(prediction.description!);
            latitude = loc.first.latitude;
            longitude = loc.first.longitude;
          }
        },

        itemClick: (Prediction prediction) {
          pobCtrl.text = prediction.description ?? "";
          FocusScope.of(context).unfocus();
        },

        itemBuilder: (context, index, Prediction p) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.primary),
              title: Text(p.description ?? ""),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------
  // FINAL SAVE FLOW
  // -------------------------------------------------------
  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final provider = context.read<KundaliProvider>();

      final name = nameCtrl.text.trim();
      final dob = _convertDob(dobCtrl.text.trim());
      final tob = tobCtrl.text.trim();
      final pob = pobCtrl.text.trim();
      final lat = latitude ?? 26.8467;
      final lng = longitude ?? 80.9462;

      final language = selectedLang == "English" ? "en" : "hi";

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

      // ⭐ LANGUAGE SYNC
      await context.read<LanguageProvider>().setLanguage(language);

      if (!mounted) return;
      context.go('/dashboard');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
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
            padding: const EdgeInsets.all(20),
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

            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Text(
                    "Tell us about yourself 🌞",
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildField(nameCtrl, "Full Name", Icons.person_outline),

                  _buildField(
                    dobCtrl,
                    "Date of Birth",
                    Icons.cake_outlined,
                    readOnly: true,
                    onTap: _pickDateCupertino,
                  ),

                  _buildField(
                    tobCtrl,
                    "Time of Birth",
                    Icons.access_time,
                    readOnly: true,
                    onTap: _pickTimeCupertino,
                  ),

                  _buildPlaceField(),

                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "English",
                          child: Text("English"),
                        ),
                        DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                      ],
                      onChanged: (v) => setState(() => selectedLang = v!),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // -------------------------------------------------------
                  // PREMIUM CONTINUE BUTTON
                  // -------------------------------------------------------
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        validator: (v) =>
            v == null || v.isEmpty ? "Please fill this field" : null,
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
