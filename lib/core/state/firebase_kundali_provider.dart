// lib/core/state/firebase_kundali_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class FirebaseKundaliProvider extends ChangeNotifier {
  Map<String, dynamic>? kundaliData; // final backend kundali
  Map<String, dynamic>? profileData; // firebase profile data
  bool isLoading = false;
  String? errorMessage;

  /// 🔧 DOB FORMAT FIXER
  /// - If "1985-01-14" → keep as is
  /// - If "14-01-1985" → convert to "1985-01-14"
  String _fixDob(dynamic rawDob) {
    if (rawDob == null) return "";

    final dob = rawDob.toString().trim();
    print("🧩 Raw DOB from Firestore: $dob");

    final isoRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoRegex.hasMatch(dob)) {
      print("✅ DOB looks ISO already → $dob");
      return dob; // already correct
    }

    final parts = dob.split("-");
    if (parts.length == 3) {
      final fixed = "${parts[2]}-${parts[1]}-${parts[0]}";
      print("🔁 DOB converted → $fixed");
      return fixed;
    }

    print("⚠️ DOB format unknown, sending as-is");
    return dob;
  }

  /// 🔥 MAIN FUNCTION → Firebase Profile + Backend Kundali
  Future<void> loadFromFirebaseProfile() async {
    print("--------------------------------------------------");
    print("🔮 FirebaseKundaliProvider → loadFromFirebaseProfile()");
    print("--------------------------------------------------");

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ User not logged in");
        errorMessage = "User not logged in";
        kundaliData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      // -------------------------------------------
      // 🔥 STEP 1 — LOAD ACTIVE PROFILE ID
      // -------------------------------------------
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final activeId = userDoc.data()?["activeProfileId"];
      print("🟣 ACTIVE PROFILE ID = $activeId");

      if (activeId == null) {
        print("❌ No active profile selected");
        errorMessage = "No active profile selected";
        kundaliData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      // -------------------------------------------
      // 🔥 STEP 2 — LOAD ACTIVE PROFILE DATA
      // -------------------------------------------
      final profileDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("profiles")
          .doc(activeId)
          .get();

      print("📄 Profile Exists? ${profileDoc.exists}");
      print("📄 Profile Data: ${profileDoc.data()}");

      if (!profileDoc.exists) {
        print("❌ Profile not found");
        errorMessage = "Profile not found";
        kundaliData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      profileData = profileDoc.data();

      final name = profileData?["name"];
      final rawDob = profileData?["dob"];
      final fixedDob = _fixDob(rawDob);
      final tob = profileData?["tob"];
      final pob = profileData?["pob"];
      final lat = profileData?["lat"];
      final lng = profileData?["lng"];

      if (name == null || fixedDob.isEmpty || tob == null || pob == null) {
        print("❌ Incomplete profile → name/dob/tob/pob missing");
        errorMessage = "Incomplete profile";
        kundaliData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      // -------------------------------------------
      // 🔥 STEP 3 — CALL BACKEND KUNDALI API
      // -------------------------------------------
      final url = Uri.parse(
        "https://jyotishasha-backend.onrender.com/api/full-kundali-modern",
      );

      final payload = {
        "name": name,
        "dob": fixedDob, // ✅ ALWAYS YYYY-MM-DD
        "tob": tob,
        "place_name": pob,
        "lat": lat,
        "lng": lng,
        "timezone": profileData?["timezone"] ?? "+05:30",
        "ayanamsa": profileData?["ayanamsa"] ?? "Lahiri",
        "language":
            (profileData?["language"] ?? "en")
                .toString()
                .toLowerCase()
                .startsWith("e")
            ? "en"
            : "hi",
      };

      print("🌐 Sending Payload to backend:");
      print(jsonEncode(payload));

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("🌐 Status Code: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("❌ Backend error → ${response.body}");
        errorMessage = "Backend error: ${response.statusCode}";
        kundaliData = null;
      } else {
        kundaliData = jsonDecode(response.body);
        print("✅ Kundali Loaded Successfully");
        if (kDebugMode) {
          print("🟢 Kundali keys: ${kundaliData?.keys}");
        }
      }
    } catch (e) {
      print("❌ Exception: $e");
      errorMessage = e.toString();
      kundaliData = null;
    }

    isLoading = false;
    notifyListeners();
    print("🎯 FINAL kundaliData: ${kundaliData != null ? "Loaded" : "NULL"}");
    print("--------------------------------------------------");
  }

  Future<void> refresh() async {
    await loadFromFirebaseProfile();
  }

  void clear() {
    kundaliData = null;
    profileData = null;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}
