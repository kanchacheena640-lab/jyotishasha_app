// lib/features/reports/pages/report_payment_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ReportPaymentPage extends StatefulWidget {
  final Map<String, dynamic> selectedReport;
  final Map<String, dynamic> formData;

  const ReportPaymentPage({
    super.key,
    required this.selectedReport,
    required this.formData,
  });

  @override
  State<ReportPaymentPage> createState() => _ReportPaymentPageState();
}

class _ReportPaymentPageState extends State<ReportPaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.selectedReport;
    final form = widget.formData;

    final dynamic priceRaw = report["price"] ?? 0;
    final double priceDouble = (priceRaw is num)
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw.toString()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Confirm & Pay",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ⭐⭐⭐ Sticky Payment Button ⭐⭐⭐
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _startPayment,
            child: Text(
              "Pay ₹${priceDouble.toStringAsFixed(0)}",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REPORT SUMMARY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report["title"] ?? "",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Price: ₹${priceDouble.toStringAsFixed(0)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // USER SUMMARY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryLine("Name", form["name"]),
                  _summaryLine("Email", form["email"]),
                  _summaryLine("DOB", form["dob"]),
                  _summaryLine("TOB", form["tob"]),
                  _summaryLine("POB", form["pob"]),
                ],
              ),
            ),

            const SizedBox(height: 80), // space above sticky button
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: ${value ?? "-"}",
        style: GoogleFonts.montserrat(fontSize: 14),
      ),
    );
  }

  // PAYMENT LOGIC
  void _startPayment() {
    final report = widget.selectedReport;
    final form = widget.formData;

    final dynamic priceRaw = report["price"] ?? 0;
    final double priceDouble = (priceRaw is num)
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw.toString()) ?? 0.0;

    final int amountPaise = (priceDouble * 100).round();

    var options = {
      'key': 'rzp_live_I518Ie1i3jkopj',
      'amount': amountPaise,
      'name': 'Jyotishasha Reports',
      'description': report["title"] ?? 'Astrology Report',
      'prefill': {'email': form["email"] ?? ''},
      'theme': {'color': '#6D28D9'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      _showSnack("Unable to start payment. Please try again.");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment SUCCESS: ${response.paymentId}");
    _showSnack("Payment successful!");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment ERROR: ${response.code} | ${response.message}");
    _showSnack("Payment failed or cancelled.");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("Wallet used: ${response.walletName}");
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
