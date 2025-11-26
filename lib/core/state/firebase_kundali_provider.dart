// lib/core/state/firebase_kundali_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:flutter/material.dart';

BuildContext? globalKundaliContext;

class FirebaseKundaliProvider extends ChangeNotifier {
  Map<String, dynamic>? kundaliData;
  Map<String, dynamic>? profileData;
  bool isLoading = false;
  String? errorMessage;

  // ---------------------------------------------------------
  // DOB FIXER
  // ---------------------------------------------------------
  String _fixDob(dynamic rawDob) {
    if (rawDob == null) return "";

    final dob = rawDob.toString().trim();
    print("🧩 [DOB] Raw: $dob");

    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(dob)) {
      print("✅ DOB already ISO");
      return dob;
    }

    final parts = dob.split("-");
    if (parts.length == 3) {
      final fixed = "${parts[2]}-${parts[1]}-${parts[0]}";
      print("🔁 DOB fixed → $fixed");
      return fixed;
    }

    print("⚠️ DOB format unknown");
    return dob;
  }

  // ---------------------------------------------------------
  // MAIN FUNCTION
  // ---------------------------------------------------------
  Future<void> loadFromFirebaseProfile() async {
    print("--------------------------------------------------");
    print("🔮 FirebaseKundaliProvider → START");
    print("--------------------------------------------------");

    try {
      isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No Firebase user");
        return;
      }

      // LOAD USER ROOT DOC
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final activeId = userDoc.data()?["activeProfileId"];
      print("🟣 Active ID = $activeId");

      if (activeId == null) {
        print("❌ No active profile found");
        return;
      }

      // LOAD PROFILE DOC
      final profileDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("profiles")
          .doc(activeId)
          .get();

      print("📄 Profile exists → ${profileDoc.exists}");
      print("📄 ProfileData → ${profileDoc.data()}");

      if (!profileDoc.exists) {
        print("❌ Profile missing");
        return;
      }

      profileData = profileDoc.data();

      // Extract Values
      final name = profileData?["name"];
      final dob = _fixDob(profileData?["dob"]);
      final tob = profileData?["tob"];
      final pob = profileData?["pob"];
      final lat = profileData?["lat"];
      final lng = profileData?["lng"];

      final selectedLang = (profileData?["language"] ?? "en")
          .toString()
          .toLowerCase()
          .substring(0, 2);

      print("🌐 User Language from Firebase = $selectedLang");

      // BACKEND CALL PAYLOAD
      final payload = {
        "name": name,
        "dob": dob,
        "tob": tob,
        "place_name": pob,
        "lat": lat,
        "lng": lng,
        "timezone": profileData?["timezone"] ?? "+05:30",
        "ayanamsa": profileData?["ayanamsa"] ?? "Lahiri",
        "language": selectedLang,
      };

      print("🌐 Sending to backend:");
      print(jsonEncode(payload));

      // BACKEND CALL
      final url = Uri.parse(
        "https://jyotishasha-backend.onrender.com/api/full-kundali-modern",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("🌐 Response → ${response.statusCode}");

      if (response.statusCode != 200) {
        print("❌ Backend error");
        print(response.body);
        return;
      }

      kundaliData = jsonDecode(response.body);
      print("✅ Kundali Loaded, keys:");
      print(kundaliData?.keys);

      // ---------------------------------------------
      // LANGUAGE SYNC (ONLY FROM FIREBASE)
      // ---------------------------------------------
      try {
        final profileLang = (profileData?["language"] ?? "en")
            .toString()
            .toLowerCase()
            .substring(0, 2);

        print("🌐 Applying Firebase Profile language → $profileLang");

        if (globalKundaliContext != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            globalKundaliContext!.read<LanguageProvider>().setLanguage(
              profileLang,
            );
          });
        }
      } catch (e) {
        print("❌ Firebase language sync error → $e");
      }
    } catch (e) {
      print("❌ Exception → $e");
    }

    isLoading = false;
    notifyListeners();

    print("🎯 FINAL → ${kundaliData != null ? "Kundali Loaded" : "NULL"}");
    print("--------------------------------------------------");
  }

  Future<void> refresh() async => await loadFromFirebaseProfile();

  void clear() {
    kundaliData = null;
    profileData = null;
    errorMessage = null;
    notifyListeners();
  }
}
