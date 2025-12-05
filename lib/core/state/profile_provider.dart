// lib/core/state/profile_provider.dart

import 'package:flutter/material.dart';
import 'package:jyotishasha_app/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  Map<String, dynamic>? activeProfile;
  List<Map<String, dynamic>> otherProfiles = [];

  bool isLoading = false;
  bool isSwitching = false;

  /// ⭐ NEW → Track Active Profile ID
  String? activeProfileId;

  /// ⭐ Getter for EditPage (easy access)
  String? get activeId => activeProfileId;

  // ---------------------------------------------------
  // LOAD ALL PROFILES
  // ---------------------------------------------------
  Future<void> loadProfiles() async {
    isLoading = true;
    notifyListeners();

    final list = await _service.getProfiles();

    // ⭐ AUTO-ACTIVATE IF ONLY ONE PROFILE EXISTS
    if (list.length == 1) {
      final only = list.first;

      if (only["isActive"] != true) {
        // Make single profile active automatically
        await _service.setActiveProfile(only["id"]);
        return loadProfiles(); // reload after update
      }
    }

    if (list.isEmpty) {
      activeProfile = null;
      otherProfiles = [];
      activeProfileId = null;
    } else {
      // active profile
      activeProfile = list.firstWhere(
        (p) => p["isActive"] == true,
        orElse: () => {
          "id": "",
          "name": "",
          "dob": "",
          "tob": "",
          "pob": "",
          "lat": 0.0,
          "lng": 0.0,
          "gender": "",
          "language": "en",
          "isActive": true,
        },
      );

      // ⭐ FIX → Save active ID
      activeProfileId = activeProfile?["id"];

      // other profiles
      otherProfiles = list.where((p) => p["isActive"] != true).toList();
    }

    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------
  // ADD NEW PROFILE
  // ---------------------------------------------------
  Future<String?> addProfile(Map<String, dynamic> data) async {
    final id = await _service.addProfile(data);
    await loadProfiles();
    return id;
  }

  // ---------------------------------------------------
  // UPDATE PROFILE
  // ---------------------------------------------------
  Future<bool> updateProfile(String id, Map<String, dynamic> data) async {
    final ok = await _service.updateProfile(id, data);
    await loadProfiles();
    return ok;
  }

  // ---------------------------------------------------
  // DELETE PROFILE
  // ---------------------------------------------------
  Future<bool> deleteProfile(String id) async {
    final ok = await _service.deleteProfile(id);
    await loadProfiles();
    return ok;
  }

  // ---------------------------------------------------
  // SET ACTIVE PROFILE
  // ---------------------------------------------------
  Future<void> setActiveProfile(String id) async {
    await _service.setActiveProfile(id);
    await loadProfiles();
  }

  // ---------------------------------------------------
  // SWITCH ACTIVE PROFILE (with loader)
  // ---------------------------------------------------
  Future<void> setActive(String profileId) async {
    try {
      isSwitching = true;
      notifyListeners();

      await _service.setActiveProfile(profileId);
      await loadProfiles();
    } finally {
      isSwitching = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------
  // REMOVE PROFILE
  // ---------------------------------------------------
  Future<void> removeProfile(String id) async {
    await _service.deleteProfile(id);
    await loadProfiles();
  }
}
