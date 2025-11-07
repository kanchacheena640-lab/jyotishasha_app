import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jyotishasha_app/core/models/kundali_model.dart';

class KundaliProvider extends ChangeNotifier {
  KundaliModel? kundali;
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

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "dob": dob, // ✅ always dd-mm-yyyy format
          "tob": tob,
          "pob": pob,
        }),
      );

      if (response.statusCode == 200) {
        kundali = KundaliModel.fromRawJson(response.body);
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded; // ✅ return data to AstrologyPage
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

  /// 🔁 Clear Kundali (optional)
  void clearKundali() {
    kundali = null;
    errorMessage = null;
    notifyListeners();
  }
}
