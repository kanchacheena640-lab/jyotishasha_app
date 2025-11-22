import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ManualKundaliProvider with ChangeNotifier {
  Map<String, dynamic>? kundali; // Manual kundali output
  bool isLoading = false;
  String? error;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  static const String apiUrl =
      "https://jyotishasha-backend.onrender.com/api/full-kundali-modern";

  /// ---------------------------------------------------------
  /// 1) Generate Manual Kundali (Always fresh)
  /// ---------------------------------------------------------
  Future<bool> generateKundali({
    required String name,
    required String dob, // yyyy-mm-dd
    required String tob, // HH:MM
    required String place,
    required double lat,
    required double lng,
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
      };

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        kundali = jsonDecode(res.body);
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

  /// ---------------------------------------------------------
  /// 2) Reset (Clear manual chart)
  /// ---------------------------------------------------------
  void reset() {
    kundali = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
