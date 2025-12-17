// lib/services/report_service.dart
// -------------------------------------------
// Google Play Billing → Backend Report Trigger
// -------------------------------------------

import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportService {
  static const String _baseUrl = "https://jyotishasha-backend.onrender.com";

  /// ✅ Called AFTER Google Play purchase success
  /// ❌ No price, no order_id
  /// ⚠️ purchase_token sent only for future hardening
  Future<bool> sendReportRequest({
    required String name,
    required String email,
    required Map<String, dynamic> birthDetails,
    required String purchaseToken,
  }) async {
    try {
      final payload = {
        "name": name,
        "email": email,
        "product": "report-51", // 🔒 BACKEND EXPECTS THIS
        "dob": birthDetails["dob"],
        "tob": birthDetails["tob"],
        "pob": birthDetails["pob"],
        "latitude": birthDetails["lat"],
        "longitude": birthDetails["lng"],
        "language": birthDetails["language"] ?? "en",

        // future-proof (ignored by backend for now)
        "purchase_token": purchaseToken,
        "platform": "android",
      };

      final res = await http.post(
        Uri.parse("$_baseUrl/api/webhook"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
