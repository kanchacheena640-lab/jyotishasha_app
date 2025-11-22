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
      print("👤 Firebase User: ${user?.uid}");

      if (user == null) {
        print("❌ NO USER LOGGED IN");
        errorMessage = "User not logged in";
        kundaliData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      // =============================
      // 1️⃣ GET PROFILE FROM FIRESTORE
      // =============================
      print("📄 Fetching profile document…");

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("profiles")
          .doc("default")
          .get();

      print("📄 Document exists? ${doc.exists}");
      print("📄 Raw Firebase Profile: ${doc.data()}");

      if (!doc.exists) {
        print("❌ PROFILE NOT FOUND IN FIRESTORE");
        errorMessage = "Profile not found";
        kundaliData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      profileData = doc.data();

      final name = profileData?["name"];
      final dob = profileData?["dob"];
      final tob = profileData?["tob"];
      final pob = profileData?["pob"];
      final lat = profileData?["lat"];
      final lng = profileData?["lng"];

      print("🟣 Extracted Profile:");
      print("   • name: $name");
      print("   • dob: $dob");
      print("   • tob: $tob");
      print("   • pob: $pob");
      print("   • lat: $lat");
      print("   • lng: $lng");

      // profile incomplete
      if (name == null || dob == null || tob == null || pob == null) {
        print("❌ PROFILE INCOMPLETE — stopping");
        errorMessage = "Incomplete profile";
        kundaliData = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      // =============================
      // 2️⃣ CALL BACKEND KUNDALI API
      // =============================
      final url = Uri.parse(
        "https://jyotishasha-backend.onrender.com/api/full-kundali-modern",
      );

      final payload = {
        "name": name,
        "dob": dob,
        "tob": tob,
        "place_name": pob,
        "lat": lat,
        "lng": lng,
        "timezone": profileData?["timezone"] ?? "+05:30",
        "ayanamsa": profileData?["ayanamsa"] ?? "Lahiri",
        "language": profileData?["language"] ?? "en",
      };

      print("🌐 Sending API Payload:");
      print(jsonEncode(payload));

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("🌐 Backend Status Code: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("❌ BACKEND ERROR");
        print("Response body: ${response.body}");
        errorMessage = "Backend error: ${response.statusCode}";
        kundaliData = null;
      } else {
        kundaliData = jsonDecode(response.body);
        print("✅ BACKEND KUNDALI LOADED SUCCESSFULLY");
        print("🟢 Kundali Keys: ${kundaliData?.keys}");
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      errorMessage = e.toString();
      kundaliData = null;
    }

    print("🎯 FINAL kundaliData: ${kundaliData != null ? "Loaded" : "NULL"}");
    print("--------------------------------------------------");

    isLoading = false;
    notifyListeners();
  }

  /// 🔄 Refresh Kundali
  Future<void> refresh() async {
    await loadFromFirebaseProfile();
  }

  /// ❌ Logout Clear
  void clear() {
    kundaliData = null;
    profileData = null;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}
