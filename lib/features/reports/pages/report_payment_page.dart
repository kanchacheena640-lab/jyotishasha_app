// lib/features/reports/pages/report_payment_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:jyotishasha_app/services/report_service.dart';
import 'package:jyotishasha_app/features/reports/pages/report_success_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  int? _backendUserId;

  // --------------------------------------------------
  // LOAD BACKEND USER ID (MANDATORY)
  // --------------------------------------------------
  Future<int?> _getBackendUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final raw = doc.data()?["backend_user_id"];
    return raw is int ? raw : int.tryParse(raw?.toString() ?? "");
  }

  @override
  void initState() {
    super.initState();

    _initUser();

    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {
        _endProcessing();
        _showSnack("Payment error. Please try again.");
      },
    );
  }

  Future<void> _initUser() async {
    _backendUserId = await _getBackendUserId();
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

    if (_backendUserId == null) {
      _showSnack("User not ready. Please try again.");
      return;
    }

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

    // ✅ CONSUMABLE (important)
    _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  // --------------------------------------------------
  // NORMALIZE DOB → yyyy-mm-dd (MANDATORY FOR BACKEND)
  // --------------------------------------------------
  String _normalizeDob(dynamic dob) {
    if (dob == null) return "";
    final s = dob.toString().trim();

    // Case: DateTime.toString() → "1985-03-31 00:00:00.000"
    if (s.contains(" ")) {
      return s.split(" ").first; // yyyy-mm-dd
    }

    // Case: already yyyy-mm-dd
    return s;
  }

  // --------------------------------------------------
  // PURCHASE STREAM HANDLER
  // --------------------------------------------------
  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
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
          // 🔥 RELATIONSHIP FUTURE REPORT (WEBHOOK BASED)
          if (widget.selectedReport["id"] == "relationship_future_report") {
            if (p.pendingCompletePurchase) {
              await _iap.completePurchase(p);
            }

            if (widget.formData["love_payload"] == null) {
              _endProcessing();
              _showSnack("Invalid relationship data.");
              return;
            }

            final love = widget.formData["love_payload"];

            final ok = await ReportService().sendReportRequest(
              name: love["user"]["name"],
              email: love["user"]["email"] ?? "",
              birthDetails: {
                "product": "relationship_future_report",
                "language": love["language"],

                // 👤 user (same-level fields)
                "dob": love["user"]["dob"],
                "tob": love["user"]["tob"],
                "pob": love["user"]["pob"],
                "latitude": love["user"]["lat"],
                "longitude": love["user"]["lng"],
                "phone": love["user"]["phone"] ?? "",

                // ❤️ relationship-specific
                "boy_is_user": love["boy_is_user"],
                "partner": love["partner"],
              },
              purchaseToken: p.verificationData.serverVerificationData,
            );

            _endProcessing();
            if (!mounted) return;

            if (ok) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportSuccessPage(
                    email: "",
                    reportTitle: "Relationship Future Report",
                  ),
                ),
              );
            } else {
              _showSnack("Payment received but report failed.");
            }
            return; // ⛔ IMPORTANT
          }
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }

          final ok = await ReportService().sendReportRequest(
            name: widget.formData["name"].toString(),
            email: widget.formData["email"].toString(),
            birthDetails: {
              "user_id": _backendUserId,

              "dob": _normalizeDob(widget.formData["dob"]),
              "tob": widget.formData["tob"],
              "pob": widget.formData["pob"],

              // ✅ EXACT keys backend expects
              "latitude": widget.formData["lat"],
              "longitude": widget.formData["lng"],

              // ✅ optional but website sends it
              "phone": widget.formData["phone"] ?? "",

              "language": widget.formData["language"] ?? "en",

              // ✅ REAL report slug (prompt selector)
              "product": widget.selectedReport["id"],
            },
            purchaseToken: p.verificationData.serverVerificationData,
          );

          _endProcessing();
          if (!mounted) return;

          if (ok) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ReportSuccessPage(
                  email: widget.formData["email"].toString(),
                  reportTitle: widget.selectedReport["title"]?.toString() ?? "",
                ),
              ),
            );
          } else {
            _showSnack("Payment received but report failed.");
          }
        } catch (_) {
          _endProcessing();
          _showSnack("Payment received but processing failed.");
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
      appBar: AppBar(title: const Text("Confirm & Pay")),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _startGooglePayment,
            child: Text(
              _isProcessing ? "Processing..." : "Pay with Google Play",
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report["title"] ?? "", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text("Product: ${report["id"]}"),
            Text("Name: ${form["name"]}"),
            Text("Email: ${form["email"]}"),
            Text("DOB: ${form["dob"]}"),
            Text("TOB: ${form["tob"]}"),
            Text("POB: ${form["pob"]}"),
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
