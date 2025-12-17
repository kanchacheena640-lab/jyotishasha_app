// lib/features/reports/pages/report_checkout_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/reports/widgets/report_checkout_form.dart';
import 'package:jyotishasha_app/features/reports/pages/report_payment_page.dart';

class ReportCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> selectedReport;
  final Map<String, dynamic> initialProfile;

  const ReportCheckoutPage({
    super.key,
    required this.selectedReport,
    required this.initialProfile,
  });

  @override
  State<ReportCheckoutPage> createState() => _ReportCheckoutPageState();
}

class _ReportCheckoutPageState extends State<ReportCheckoutPage> {
  Map<String, dynamic> formData = {};

  // --------------------------------------------------------
  // SHOW ERROR
  // --------------------------------------------------------
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --------------------------------------------------------
  // VALIDATION + NEXT PAGE
  // --------------------------------------------------------
  void _validateAndProceed() {
    if ((formData["name"] ?? "").toString().trim().isEmpty) {
      _showError("Please enter your name.");
      return;
    }
    if ((formData["dob"] ?? "").toString().trim().isEmpty) {
      _showError("Please select Date of Birth.");
      return;
    }
    if ((formData["tob"] ?? "").toString().trim().isEmpty) {
      _showError("Please select Time of Birth.");
      return;
    }
    if ((formData["pob"] ?? "").toString().trim().isEmpty) {
      _showError("Please select Place of Birth.");
      return;
    }

    if (formData["lat"] == null || formData["lng"] == null) {
      _showError("Please select place from suggestions.");
      return;
    }

    debugPrint("==== FINAL CHECKOUT DATA ====");
    debugPrint(formData.toString());
    debugPrint("================================");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPaymentPage(
          selectedReport: widget.selectedReport,
          formData: formData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.selectedReport;

    final profile = context.watch<ProfileProvider>().activeProfile ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          report["title"] ?? "Checkout",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // REPORT HEADER
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report["short_description"] ?? "",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------
            // CHECKOUT FORM
            // ----------------------------------------------------
            ReportCheckoutForm(
              initialProfile:
                  context.watch<ProfileProvider>().activeProfile ?? {},
              onFormUpdated: (data) {
                setState(() => formData = data);
              },
            ),

            const SizedBox(height: 28),

            // ----------------------------------------------------
            // BUTTON
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _validateAndProceed,
                child: Text(
                  "Proceed to Pay",
                  style: const TextStyle(
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
}
