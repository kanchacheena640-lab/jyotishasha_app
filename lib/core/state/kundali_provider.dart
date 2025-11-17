import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jyotishasha_app/core/models/kundali_model.dart';

class KundaliProvider extends ChangeNotifier {
  KundaliModel? kundali;
  Map<String, dynamic>? kundaliData; // 🌕 Full Kundali JSON cache
  Map<String, dynamic>? activeProfile; // 🔥 Firestore birth-profile cache

  bool isLoading = false;
  String? errorMessage;

  // ===========================================================
  // 🔥 INTERNAL FUNCTION — single API caller (DON’T DUPLICATE)
  // ===========================================================
  Future<Map<String, dynamic>?> _callFullKundaliAPI(
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = Uri.parse(
        "https://jyotishasha-backend.onrender.com/api/full-kundali-modern",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        errorMessage = "Failed: ${response.statusCode}";
        return null;
      }

      kundali = KundaliModel.fromRawJson(response.body);
      kundaliData = jsonDecode(response.body);

      return kundaliData;
    } catch (e) {
      errorMessage = "API Error: $e";
      return null;
    }
  }

  // ===========================================================
  // 1) 🚀 BOOTSTRAP PROFILE — saves profile to Firestore
  // ===========================================================
  Future<Map<String, dynamic>?> bootstrapUserProfile({
    required String name,
    required String dob,
    required String tob,
    required String pob,
    required double lat,
    required double lng,
    String language = "en",
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        errorMessage = "No Firebase user logged in";
        return null;
      }

      final url = Uri.parse(
        "https://jyotishasha-backend.onrender.com/api/user/bootstrap",
      );

      final payload = {
        "name": name,
        "email": user.email,
        "dob": dob,
        "tob": tob,
        "pob": pob,
        "lat": lat,
        "lng": lng,
        "lang": language,
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        errorMessage = "Bootstrap failed (${response.statusCode})";
        return null;
      }

      final data = jsonDecode(response.body);

      // Provided fields
      final lagna = data["lagna"];
      final moonSign = data["moon_sign"];
      final nakshatra = data["nakshatra"];
      final backendProfileId = data["profileId"];

      // Save to Firestore
      final fs = FirebaseFirestore.instance;

      await fs.collection("users").doc(user.uid).set({
        "email": user.email,
        "name": name,
        "activeProfileId": "default",
        "lastLogin": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await fs
          .collection("users")
          .doc(user.uid)
          .collection("profiles")
          .doc("default")
          .set({
            "name": name,
            "dob": dob,
            "tob": tob,
            "pob": pob,
            "lat": lat,
            "lng": lng,
            "language": language,
            "lagna": lagna,
            "moon_sign": moonSign,
            "nakshatra": nakshatra,
            "backendProfileId": backendProfileId,
            "updatedAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return data;
    } catch (e) {
      errorMessage = "Bootstrap error: $e";
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================
  // 2) 🌐 PUBLIC METHOD: Manual Input → API → Full Kundali
  // ===========================================================
  Future<Map<String, dynamic>?> loadFromManualInput({
    required String name,
    required String dob,
    required String tob,
    required String pob,
    required double lat,
    required double lng,
    String language = "en",
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final payload = {
      "name": name,
      "dob": dob,
      "tob": tob,
      "place_name": pob,
      "lat": lat,
      "lng": lng,
      "timezone": "+05:30",
      "language": language,
      "ayanamsa": "Lahiri",
    };

    final data = await _callFullKundaliAPI(payload);

    isLoading = false;
    notifyListeners();
    return data;
  }

  // ===========================================================
  // 3) 🌕 PUBLIC METHOD: Active Profile → API → Full Kundali
  // ===========================================================
  Future<void> loadFromActiveProfile() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        errorMessage = "No user logged in";
        return;
      }

      // Load profile info
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final activeProfileId = userDoc.data()?["activeProfileId"];
      if (activeProfileId == null) {
        errorMessage = "No active profile found";
        return;
      }

      final profileSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("profiles")
          .doc(activeProfileId)
          .get();

      if (!profileSnap.exists) {
        errorMessage = "Profile not found";
        return;
      }

      activeProfile = profileSnap.data();

      // Call API with profile details
      await loadFromManualInput(
        name: activeProfile?["name"] ?? "",
        dob: activeProfile?["dob"] ?? "",
        tob: activeProfile?["tob"] ?? "",
        pob: activeProfile?["pob"] ?? "",
        lat: activeProfile?["lat"]?.toDouble() ?? 26.8467,
        lng: activeProfile?["lng"]?.toDouble() ?? 80.9462,
        language: activeProfile?["language"] ?? "en",
      );
    } catch (e) {
      errorMessage = "Error loading profile: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================
  // 4) CLEAR DATA
  // ===========================================================
  void clearKundali() {
    kundali = null;
    kundaliData = null;
    activeProfile = null;
    errorMessage = null;
    notifyListeners();
  }
}
