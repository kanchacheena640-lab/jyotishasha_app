import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

class RazorpayService {
  Razorpay? _razorpay;

  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
  }) {
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
  }

  void dispose() {
    _razorpay?.clear();
  }

  Future<void> startPayment({
    required BuildContext context,
    required String productId,
    required String customerName,
    required String customerEmail,
  }) async {
    // 1) Backend se order banwao
    final res = await http.post(
      Uri.parse("https://jyotishasha-backend.onrender.com/api/razorpay-order"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"product": productId, "create_order": true}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data["order_id"] == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Payment failed")));
      return;
    }

    // 2) Razorpay options
    final options = {
      "key": "RAZORPAY_KEY_ID", // TODO: replace with your key
      "amount": data["amount"],
      "currency": "INR",
      "name": "Jyotishasha",
      "order_id": data["order_id"],
      "prefill": {"name": customerName, "email": customerEmail},
    };

    _razorpay!.open(options);
  }
}
