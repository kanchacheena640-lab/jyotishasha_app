// lib/services/report_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportService {
  static const String _baseUrl = "https://jyotishasha-backend.onrender.com";

  // P0 — Flutter Google Play Report Purchase Integration: report
  // purchases now go through Google Play, verified server-side via
  // POST /api/reports/google/confirm (GooglePlayProvider.verify_product_
  // purchase(), purposed REPORT_PURCHASE) instead of the Razorpay-shaped
  // /webhook the Website still uses unchanged. Same PaymentService ->
  // OrderService -> report-generation pipeline either way -- only the
  // entry point and its required fields differ.
  Future<bool> sendReportRequest({
    required String name,
    required String email,
    required Map<String, dynamic> birthDetails,
    required String purchaseToken,
    String? productId,
    String? orderId,
  }) async {
    try {
      final product = birthDetails["product"]?.toString().trim();

      // 🔒 HARD GUARD — PRODUCT MUST EXIST
      if (product == null || product.isEmpty) {
        print("❌ REPORT SERVICE ERROR: product is empty");
        print("BirthDetails => $birthDetails");
        return false;
      }

      // 🔒 HARD GUARD — /api/reports/google/confirm requires both of
      // these to verify the purchase at all; fail fast instead of
      // sending a request the backend can only reject.
      if (purchaseToken.isEmpty) {
        print("❌ REPORT SERVICE ERROR: purchaseToken is empty");
        return false;
      }
      if (productId == null || productId.isEmpty) {
        print("❌ REPORT SERVICE ERROR: productId is empty");
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

        // 🔐 Google Play One-Time Product Verification fields
        "purchase_token": purchaseToken,
        "product_id": productId,
        if (orderId != null && orderId.isNotEmpty) "order_id": orderId,
      };

      // 🔍 DEBUG (TEMP)
      print("📤 FINAL GOOGLE PLAY REPORT CONFIRM PAYLOAD => $payload");

      final res = await http.post(
        Uri.parse("$_baseUrl/api/reports/google/confirm"),
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
