// lib/core/state/firebase_kundali_provider.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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

    // dd-mm-yyyy → yyyy-mm-dd
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
  Future<void> loadFromFirebaseProfile(
    BuildContext context, {
    required String lang,
  }) async {
    print("--------------------------------------------------");
    print("🔮 FirebaseKundaliProvider → START");
    print("--------------------------------------------------");

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ No Firebase user");
        return;
      }

      // LOAD ROOT DOC
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

      // ⭐ NEW: fetch backend_user_id from root user doc
      final backendUserId = userDoc.data()?["backend_user_id"];
      profileData = {...profileData!, "backend_user_id": backendUserId};

      final name = profileData?["name"];
      final dob = _fixDob(profileData?["dob"]);
      final tob = profileData?["tob"];
      final pob = profileData?["pob"];
      final lat = profileData?["lat"];
      final lng = profileData?["lng"];

      // language सिर्फ backend को भेजने के लिए
      final selectedLang = lang.toLowerCase().substring(0, 2);

      print("🌐 Language sent by Dashboard = $selectedLang");

      print("🌐 User Language from Firebase = $selectedLang");

      // BACKEND PAYLOAD
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
        errorMessage = response.body;
        return;
      }

      kundaliData = jsonDecode(response.body);

      print("✅ Kundali Loaded, keys:");
      print(kundaliData?.keys);
    } catch (e) {
      print("❌ Exception → $e");
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();

      print("🎯 FINAL → ${kundaliData != null ? "Kundali Loaded" : "NULL"}");
      print("--------------------------------------------------");
    }
  }

  void clear() {
    kundaliData = null;
    profileData = null;
    errorMessage = null;
    notifyListeners();
  }
}
