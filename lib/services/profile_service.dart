// 🌟 profile_service.dart
// -------------------------------------------
// Temporary placeholder file for Profile backend integration
// -------------------------------------------
// TODO: When backend connects, replace these dummy methods with API calls
//       Example endpoint (future): /api/user/profile or /api/add-profile
// -------------------------------------------

import 'dart:async';

class ProfileService {
  // Simulate network delay
  Future<void> addProfile(Map<String, String> profileData) async {
    await Future.delayed(const Duration(seconds: 1));
    print("🧾 [DEBUG] Profile added: $profileData");
    // TODO: Replace this with actual POST request to backend
  }

  Future<List<Map<String, String>>> fetchProfiles() async {
    await Future.delayed(const Duration(seconds: 1));
    print("🪄 [DEBUG] Fetching profiles from backend...");
    // TODO: Replace this with actual GET request to backend
    return [
      {
        "name": "You (Main Profile)",
        "dob": "15-08-1997",
        "tob": "10:30",
        "pob": "Lucknow",
      },
    ];
  }

  Future<void> deleteProfile(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print("🗑️ [DEBUG] Deleted profile: $name");
    // TODO: Replace with DELETE API
  }
}
