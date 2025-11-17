import 'package:flutter/material.dart';
import 'package:jyotishasha_app/services/user_bootstrap_service.dart';
import 'package:jyotishasha_app/services/personalized_horoscope_service.dart';

class ProfileProvider extends ChangeNotifier {
  // ---------- USER PROFILE ----------
  String? uid;
  String? name;
  String? lagna;
  String? moonSign;
  String? nakshatra;
  String activeProfileId = "default";

  bool isBootstrapping = false;
  bool isLoadingHoroscope = false;

  // ---------- HOROSCOPE CACHE ----------
  Map<String, dynamic>? today;
  Map<String, dynamic>? tomorrow;
  Map<String, dynamic>? weekly;

  // ---------- BOOTSTRAP FROM BACKEND ----------
  Future<void> bootstrapProfile(Map<String, dynamic> payload) async {
    try {
      isBootstrapping = true;
      notifyListeners();

      final data = await UserBootstrapService().syncProfile(payload);

      uid = payload["uid"];
      name = data["name"];
      lagna = data["lagna"];
      moonSign = data["moon_sign"];
      nakshatra = data["nakshatra"];
      activeProfileId = data["profileId"] ?? "default";

      notifyListeners();
    } catch (e) {
      print("Bootstrap Error: $e");
      rethrow;
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  // ---------- DAILY HOROSCOPE ----------
  Future<void> loadDaily() async {
    try {
      isLoadingHoroscope = true;
      notifyListeners();

      final result = await PersonalizedHoroscopeService().fetchDaily(
        activeProfileId,
      );

      today = result;
      notifyListeners();
    } catch (e) {
      print("Daily Horoscope Error: $e");
    } finally {
      isLoadingHoroscope = false;
      notifyListeners();
    }
  }

  // ---------- TOMORROW HOROSCOPE ----------
  Future<void> loadTomorrow() async {
    try {
      final result = await PersonalizedHoroscopeService().fetchTomorrow(
        activeProfileId,
      );

      tomorrow = result;
      notifyListeners();
    } catch (e) {
      print("Tomorrow Horoscope Error: $e");
    }
  }

  // ---------- WEEKLY HOROSCOPE ----------
  Future<void> loadWeekly() async {
    try {
      final result = await PersonalizedHoroscopeService().fetchWeekly(
        activeProfileId,
      );

      weekly = result;
      notifyListeners();
    } catch (e) {
      print("Weekly Horoscope Error: $e");
    }
  }
}
