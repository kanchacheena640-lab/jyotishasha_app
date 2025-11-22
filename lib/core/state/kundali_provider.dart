// lib/core/state/kundali_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class KundaliProvider with ChangeNotifier {
  Map<String, dynamic>? kundaliData;

  bool isLoading = false;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // 🌐 Your backend endpoints
  static const String fullKundaliUrl =
      "https://jyotishasha-backend.onrender.com/api/full-kundali-modern";

  static const String bootstrapUrl =
      "https://jyotishasha-backend.onrender.com/api/user/bootstrap";

  // ---------------------------------------------------------------------------
  // 1) MANUAL KUNDALI → /api/full-kundali-modern
  // ---------------------------------------------------------------------------
  Future<void> fetchManualKundali({
    required String name,
    required String dob, // yyyy-mm-dd
    required String tob, // HH:MM
    required String place,
    required double lat,
    required double lng,
  }) async {
    isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        "name": name,
        "dob": dob,
        "tob": tob,
        "place": place,
        "lat": lat,
        "lng": lng,
      };

      final res = await http.post(
        Uri.parse(fullKundaliUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        kundaliData = jsonDecode(res.body);
      } else {
        _errorMessage = "Server error ${res.statusCode}";
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 2) BOOTSTRAP MAIN USER PROFILE  →  /api/user/bootstrap
  //     (used in BirthDetailPage)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> bootstrapUserProfile({
    required String name,
    required String dob,
    required String tob,
    required String pob,
    required double lat,
    required double lng,
    required String language,
  }) async {
    isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        "name": name,
        "dob": dob,
        "tob": tob,
        "pob": pob,
        "lat": lat,
        "lng": lng,
        "language": language,
      };

      final res = await http.post(
        Uri.parse(bootstrapUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        _errorMessage = "Server error ${res.statusCode}";
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------
  void reset() {
    kundaliData = null;
    _errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}
