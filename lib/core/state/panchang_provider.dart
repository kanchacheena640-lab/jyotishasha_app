import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PanchangProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  String? abhijitStart;
  String? abhijitEnd;
  String? rahukaalStart;
  String? rahukaalEnd;

  Future<void> fetchPanchang({
    required double lat,
    required double lng,
    DateTime? date,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final today = (date ?? DateTime.now()).toIso8601String().substring(0, 10);

    final url = Uri.parse(
      "https://jyotishasha-backend.onrender.com/api/panchang",
    );

    final payload = {"date": today, "latitude": lat, "longitude": lng};

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final selected = data["selected_date"] ?? {};

        final abhijit = selected["abhijit_muhurta"] ?? {};
        final rahu = selected["rahu_kaal"] ?? {};

        abhijitStart = abhijit["start"];
        abhijitEnd = abhijit["end"];
        rahukaalStart = rahu["start"];
        rahukaalEnd = rahu["end"];

        isLoading = false;
        notifyListeners();
      } else {
        errorMessage = "Server error: ${res.statusCode}";
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Error: $e";
      isLoading = false;
      notifyListeners();
    }
  }
}
