import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jyotishasha_app/core/models/kundali_model.dart';

class KundaliProvider extends ChangeNotifier {
  KundaliModel? kundali;
  Map<String, dynamic>? kundaliData; // 🌕 Full Kundali JSON cache
  bool isLoading = false;
  String? errorMessage;

  /// 🌐 Fetch Kundali from backend and return parsed data
  Future<Map<String, dynamic>?> fetchKundali({
    required String name,
    required String dob,
    required String tob,
    required String pob,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final url = Uri.parse(
        'https://jyotishasha-backend.onrender.com/api/full-kundali-modern',
      );

      final payload = {
        "name": name,
        "dob": dob, // ✅ dd-MM-yyyy format
        "tob": tob,
        "place_name": pob,
        "lat": 26.8467, // 🧭 Default Lucknow (for testing)
        "lng": 80.9462,
        "timezone": "+05:30",
        "language": "en",
        "ayanamsa": "Lahiri",
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        kundali = KundaliModel.fromRawJson(response.body);
        kundaliData = jsonDecode(response.body) as Map<String, dynamic>;
        return kundaliData;
      } else {
        errorMessage = "Failed (Status ${response.statusCode})";
        return null;
      }
    } catch (e) {
      errorMessage = "Error: $e";
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 🧩 Build consistent payload (useful for reusing in tools)
  Map<String, dynamic> buildKundaliPayload(Map<String, dynamic> source) {
    return {
      "name": source["name"] ?? "",
      "dob": source["dob"] ?? "",
      "tob": source["tob"] ?? "",
      "place_name": source["place_name"] ?? source["pob"] ?? "",
      "lat": source["lat"] ?? 26.8467,
      "lng": source["lng"] ?? 80.9462,
      "timezone": source["timezone"] ?? "+05:30",
      "language": source["language"] ?? "en",
      "ayanamsa": source["ayanamsa"] ?? "Lahiri",
    };
  }

  /// 🔁 Clear stored Kundali
  void clearKundali() {
    kundali = null;
    kundaliData = null;
    errorMessage = null;
    notifyListeners();
  }
}
