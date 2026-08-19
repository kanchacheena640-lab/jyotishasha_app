// lib/services/report_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Report Purchase CANCELED Recovery Dead-End fix: `sendReportRequest()`
/// used to collapse every non-200 response to a bare `false`, so a
/// caller could not tell "this token can never succeed (Google
/// canceled it)" apart from "transient failure, safe to retry". This
/// carries the backend's new structured `error_code` (additive field
/// on `/api/reports/google/confirm`'s existing failure JSON) through
/// unchanged when the backend hasn't sent one, so old behavior is
/// preserved exactly for every failure this class doesn't recognize.
class ReportConfirmResult {
  const ReportConfirmResult({required this.success, this.errorCode});
  final bool success;
  final String? errorCode;
}

class ReportService {
  static const String _baseUrl = "https://jyotishasha-backend.onrender.com";

  // P0 — Flutter Google Play Report Purchase Integration: report
  // purchases now go through Google Play, verified server-side via
  // POST /api/reports/google/confirm (GooglePlayProvider.verify_product_
  // purchase(), purposed REPORT_PURCHASE) instead of the Razorpay-shaped
  // /webhook the Website still uses unchanged. Same PaymentService ->
  // OrderService -> report-generation pipeline either way -- only the
  // entry point and its required fields differ.
  Future<ReportConfirmResult> sendReportRequest({
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
        return const ReportConfirmResult(success: false);
      }

      // 🔒 HARD GUARD — /api/reports/google/confirm requires both of
      // these to verify the purchase at all; fail fast instead of
      // sending a request the backend can only reject.
      if (purchaseToken.isEmpty) {
        print("❌ REPORT SERVICE ERROR: purchaseToken is empty");
        return const ReportConfirmResult(success: false);
      }
      if (productId == null || productId.isEmpty) {
        print("❌ REPORT SERVICE ERROR: productId is empty");
        return const ReportConfirmResult(success: false);
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

      if (res.statusCode == 200) {
        return const ReportConfirmResult(success: true);
      }

      // Best-effort parse of the failure body for the new structured
      // `error_code` field -- absent/unparseable body just means no
      // classification, identical to today's plain-`false` behavior.
      String? errorCode;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final code = decoded['error_code'];
          if (code is String && code.isNotEmpty) errorCode = code;
        }
      } catch (_) {
        // Non-JSON or empty body -- leave errorCode null.
      }

      return ReportConfirmResult(success: false, errorCode: errorCode);
    } catch (e) {
      print("❌ ReportService exception: $e");
      return const ReportConfirmResult(success: false);
    }
  }
}
