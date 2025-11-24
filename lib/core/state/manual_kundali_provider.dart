import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ManualKundaliProvider with ChangeNotifier {
  Map<String, dynamic>? kundali;
  bool isLoading = false;
  String? error;

  static const String apiUrl =
      "https://jyotishasha-backend.onrender.com/api/full-kundali-modern";

  Future<bool> generateKundali({
    required String name,
    required String dob,
    required String tob,
    required String place,
    required double lat,
    required double lng,
    String language = "en",
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final payload = {
        "name": name,
        "dob": dob,
        "tob": tob,
        "place": place,
        "lat": lat,
        "lng": lng,
        "language": language,
      };

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        kundali = jsonDecode(res.body);

        // ⭐ INSERT PROFILE NODE (REQUIRED FOR UI)
        kundali!["profile"] = {
          "name": name,
          "dob": dob,
          "tob": tob,
          "pob": place,
          "place": place,
        };

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = "Server Error: ${res.statusCode}";
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  void reset() {
    kundali = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
