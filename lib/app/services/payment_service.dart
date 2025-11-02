import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  static final _razorpay = Razorpay();

  static Future<void> startPayment({
    required BuildContext context,
    required Map<String, dynamic> report,
    required Map<String, dynamic> form,
  }) async {
    try {
      // 1️⃣ Backend call → create Razorpay order
      final response = await http.post(
        Uri.parse("https://jyotishasha.pythonanywhere.com/api/razorpay-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"product": report['slug']}),
      );

      if (response.statusCode != 200) throw Exception("Order create failed");
      final data = jsonDecode(response.body);

      // 2️⃣ Razorpay options
      var options = {
        'key': 'rzp_live_xxxxxxxxx', // replace with your key
        'amount': data['amount'] * 100,
        'currency': 'INR',
        'name': 'Jyotishasha',
        'description': report['title'],
        'order_id': data['order_id'],
      };

      // 3️⃣ Open Razorpay
      _razorpay.open(options);

      // 4️⃣ On success — save order to backend / Firestore
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
        PaymentSuccessResponse r,
      ) async {
        await http.post(
          Uri.parse("https://jyotishasha.pythonanywhere.com/webhook"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            ...form,
            "product": report['slug'],
            "order_id": r.orderId,
            "payment_id": r.paymentId,
          }),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "✅ Payment successful! Report will appear in your library.",
              ),
            ),
          );
          Navigator.pushNamed(context, '/my-reports');
        }
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Payment failed. Please try again.")),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
