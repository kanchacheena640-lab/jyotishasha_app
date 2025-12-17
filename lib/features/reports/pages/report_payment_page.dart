// lib/features/reports/pages/report_payment_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:jyotishasha_app/services/report_service.dart';
import 'package:jyotishasha_app/features/reports/pages/report_success_page.dart';

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
  // 🔒 MUST match Play Console product ID
  static const String _productId = "reports51";

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _isProcessing = false;
  bool _hasTriggeredPurchase = false;
  bool _reportTriggered = false;

  @override
  void initState() {
    super.initState();

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {
        _endProcessing();
        _showSnack("Payment error. Please try again.");
      },
    );
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  // --------------------------------------------------
  // START GOOGLE PLAY PAYMENT
  // --------------------------------------------------
  Future<void> _startGooglePayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _hasTriggeredPurchase = true;
    });

    final available = await _iap.isAvailable();
    if (!available) {
      _endProcessing();
      _showSnack("Google Play Billing not available.");
      return;
    }

    final response = await _iap.queryProductDetails({_productId});
    if (response.error != null || response.productDetails.isEmpty) {
      _endProcessing();
      _showSnack("Product not available. Please try again.");
      return;
    }

    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);

    // One-time report purchase
    _iap.buyNonConsumable(purchaseParam: param);
  }

  // --------------------------------------------------
  // PURCHASE STREAM HANDLER
  // --------------------------------------------------
  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    // 🔒 double-fire protection
    if (!_isProcessing || !_hasTriggeredPurchase) return;

    for (final p in purchases) {
      if (p.productID != _productId) continue;

      if (p.status == PurchaseStatus.error) {
        _endProcessing();
        _showSnack("Payment failed or cancelled.");
        return;
      }

      if (p.status == PurchaseStatus.purchased) {
        if (_reportTriggered) return;
        _reportTriggered = true;

        try {
          // ✅ Always complete purchase first

          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }

          // ✅ Notify backend (PAID = frontend truth)
          final ok = await ReportService().sendReportRequest(
            name: (widget.formData["name"] ?? "").toString(),
            email: (widget.formData["email"] ?? "").toString(),
            birthDetails: {
              "dob": widget.formData["dob"],
              "tob": widget.formData["tob"],
              "pob": widget.formData["pob"],
              "lat": widget.formData["lat"],
              "lng": widget.formData["lng"],
              "language": widget.formData["language"] ?? "en",
            },
            purchaseToken:
                p.verificationData.serverVerificationData, // future-proof
          );

          _endProcessing();
          if (!mounted) return;

          if (ok) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ReportSuccessPage(
                  email: (widget.formData["email"] ?? "").toString(),
                  reportTitle: (widget.selectedReport["title"] ?? "")
                      .toString(),
                ),
              ),
            );
          } else {
            _showSnack(
              "Payment received, but report failed. Please contact support.",
            );
          }
        } catch (_) {
          _endProcessing();
          _showSnack(
            "Payment received, but report processing failed. Try again later.",
          );
        }

        return;
      }
    }
  }

  void _endProcessing() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _hasTriggeredPurchase = false;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final report = widget.selectedReport;
    final form = widget.formData;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Confirm & Pay",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      // 🔒 Price not shown (Google controls final price)
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
            onPressed: _isProcessing ? null : _startGooglePayment,
            child: Text(
              _isProcessing ? "Processing..." : "Pay with Google Play",
              style: const TextStyle(
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
            // REPORT SUMMARY
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You will receive this report on email after payment confirmation.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // USER SUMMARY
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

            const SizedBox(height: 80),
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
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
