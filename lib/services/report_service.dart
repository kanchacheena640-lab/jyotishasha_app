// lib/services/report_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportService {
  static const String _baseUrl = "https://jyotishasha-backend.onrender.com";

  Future<bool> sendReportRequest({
    required String name,
    required String email,
    required Map<String, dynamic> birthDetails,
    required String purchaseToken,
  }) async {
    try {
      final product = birthDetails["product"]?.toString().trim();

      // 🔒 HARD GUARD — PRODUCT MUST EXIST
      if (product == null || product.isEmpty) {
        print("❌ REPORT SERVICE ERROR: product is empty");
        print("BirthDetails => $birthDetails");
        return false;
      }

      final payload = {
        "name": name,
        "email": email,
        "phone": birthDetails["phone"] ?? "",
        "product": product,

        // 👤 user details
        "dob": birthDetails["dob"],
        "tob": birthDetails["tob"],
        "pob": birthDetails["pob"],
        "latitude": birthDetails["latitude"],
        "longitude": birthDetails["longitude"],

        // ❤️ relationship support (only when present)
        if (birthDetails["boy_is_user"] != null)
          "boy_is_user": birthDetails["boy_is_user"],

        if (birthDetails["partner"] != null) "partner": birthDetails["partner"],

        "language": birthDetails["language"] ?? "en",
      };

      // 🔍 DEBUG (TEMP)
      print("📤 FINAL WEBHOOK PAYLOAD => $payload");

      final res = await http.post(
        Uri.parse("$_baseUrl/webhook"),
        headers: const {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("❌ ReportService exception: $e");
      return false;
    }
  }
}
