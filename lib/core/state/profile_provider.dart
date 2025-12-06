// lib/core/state/profile_provider.dart

import 'package:flutter/material.dart';
import 'package:jyotishasha_app/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  Map<String, dynamic>? activeProfile;
  List<Map<String, dynamic>> otherProfiles = [];

  bool isLoading = false;
  bool isSwitching = false;

  /// ⭐ ACTIVE PROFILE ID
  String? activeProfileId;

  String? get activeId => activeProfileId;

  // ---------------------------------------------------
  // LOAD ALL PROFILES
  // ---------------------------------------------------
  Future<void> loadProfiles() async {
    isLoading = true;
    notifyListeners();

    final list = await _service.getProfiles();

    // Auto-activate if only one profile exists
    if (list.length == 1) {
      final only = list.first;
      if (only["isActive"] != true) {
        await _service.setActiveProfile(only["id"]);
        return loadProfiles();
      }
    }

    if (list.isEmpty) {
      activeProfile = null;
      otherProfiles = [];
      activeProfileId = null;
    } else {
      // FIND ACTIVE PROFILE
      activeProfile = list.firstWhere(
        (p) => p["isActive"] == true,
        orElse: () => {},
      );

      // ⭐ FIX → Normalize Backend IDs
      _normalizeBackendIds();

      // SAVE ACTIVE ID
      activeProfileId = activeProfile?["id"];

      // OTHER PROFILES
      otherProfiles = list.where((p) => p["isActive"] != true).toList();
    }

    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------
  // ⭐ NORMALIZE BACKEND IDs (FINAL WORKING VERSION)
  // ---------------------------------------------------
  void _normalizeBackendIds() {
    if (activeProfile == null) return;

    // backend_user_id
    final buid =
        activeProfile!["backend_user_id"] ??
        activeProfile!["backendUserId"] ??
        activeProfile!["backendUserID"];

    activeProfile!["backend_user_id"] = buid;

    // backend_profile_id
    final bpid =
        activeProfile!["backend_profile_id"] ??
        activeProfile!["backendProfileId"] ??
        activeProfile!["backendProfileID"];

    activeProfile!["backend_profile_id"] = bpid;

    // ⭐ Debug print
    print("🔥 Normalized Backend IDs → user=$buid | profile=$bpid");
  }

  // ---------------------------------------------------
  // ADD PROFILE
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
  // DELETE
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
