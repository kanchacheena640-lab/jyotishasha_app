// lib/features/asknow/chatpack_checkout_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/asknow_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/asknow/chatpack_success_page.dart';
import 'package:jyotishasha_app/core/constants/razorpay_keys.dart';

class ChatPackCheckoutPage extends StatefulWidget {
  const ChatPackCheckoutPage({super.key});

  @override
  State<ChatPackCheckoutPage> createState() => _ChatPackCheckoutPageState();
}

class _ChatPackCheckoutPageState extends State<ChatPackCheckoutPage> {
  late Razorpay _razorpay;

  String email = "";

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ---------------------------------------------------------
  // ⭐ STEP 1 — CREATE ORDER
  // ---------------------------------------------------------
  Future<void> _startPayment() async {
    final profile = context.read<ProfileProvider>().activeProfile ?? {};
    email = profile["email"] ?? "";

    try {
      final res = await http.post(
        Uri.parse(
          "https://jyotishasha-backend.onrender.com/api/razorpay-order",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"product": "chatpack_8", "create_order": true}),
      );

      final data = jsonDecode(res.body);

      if (data["order_id"] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to start payment")),
        );
        return;
      }

      final options = {
        "key": RazorpayKeys.liveKey, // 🔥 yahan ab constant use hoga
        "amount": data["amount"],
        "currency": "INR",
        "name": "Jyotishasha",
        "description": "AskNow ChatPack (8 Questions)",
        "order_id": data["order_id"],
        "prefill": {"email": email, "contact": profile["phone"] ?? ""},
      };

      // 🔥 Small delay for safe context
      Future.delayed(Duration(milliseconds: 200), () {
        _razorpay.open(options);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Payment init failed: $e")));
    }
  }

  // ---------------------------------------------------------
  // ⭐ STEP 2 — PAYMENT SUCCESS
  // ---------------------------------------------------------
  void _onSuccess(PaymentSuccessResponse response) async {
    final profile = context.read<ProfileProvider>().activeProfile ?? {};
    final backendUserId = profile["backend_user_id"];

    try {
      // Backend pe pack activate karo (8 questions)
      if (backendUserId != null) {
        await http.post(
          Uri.parse(
            "https://jyotishasha-backend.onrender.com/api/chatpack/purchase",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": backendUserId, "questions": 8}),
        );
      }

      // Local provider state update (AskNowProvider)
      context.read<AskNowProvider>().markPackActive(tokens: 8);
    } catch (e) {
      // Agar backend call fail bhi ho jaye to user ka flow break na ho
      debugPrint("ChatPack activate error: $e");
    }

    // Success Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ChatPackSuccessPage(email: email)),
    );
  }

  // ---------------------------------------------------------
  // ⭐ STEP 3 — PAYMENT FAILURE
  // ---------------------------------------------------------
  void _onError(PaymentFailureResponse res) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Payment Failed")));
  }

  // ---------------------------------------------------------
  // ⭐ UI SCREEN
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const price = 51;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        title: const Text(
          "ChatPack — 8 Questions",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFEEFF5),

      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AskNow ChatPack",
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A148C),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Get 8 detailed astrology answers.\nLove • Career • Money • Health & more.",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                height: 1.4,
                color: Colors.deepPurple.shade700,
              ),
            ),

            const SizedBox(height: 25),

            _infoCard("Total Questions", "8"),
            const SizedBox(height: 20),
            _infoCard("Price", "₹$price"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Buy Now • ₹$price",
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A148C),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
