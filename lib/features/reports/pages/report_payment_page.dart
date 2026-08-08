// lib/features/reports/pages/report_payment_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/love/love_contracts.dart';
import 'package:jyotishasha_app/core/models/profile/birth_details.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/state/report_purchase_provider.dart';
import 'package:jyotishasha_app/features/reports/pages/report_success_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Report Purchase Lifecycle Architecture (Bucket A): this page is now
/// pure UI. All Google Play billing -- listening, backend confirmation,
/// completePurchase()/consumePurchase(), and crash/restart recovery --
/// lives in [ReportPurchaseProvider] (registered `lazy: false` in
/// main.dart, so it's already listening before this page ever exists).
/// This page only: (1) collects the report request shape from
/// [formData]/[selectedReport], (2) tells the provider to start a
/// purchase, and (3) reacts to the provider's state to show progress,
/// errors, and the success screen -- the exact same relationship
/// `SubscriptionPage` already has with `SubscriptionProvider`.
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
  int? _backendUserId;

  /// De-duplication markers, matching the pattern already used by
  /// `SubscriptionPage` (`_lastShownPurchaseError`) -- a provider
  /// rebuild must never re-show an already-handled outcome, and a
  /// success that happened while this page wasn't even mounted (app-
  /// restart recovery, per Requirement 5) must never be retroactively
  /// shown here either.
  int _lastHandledSuccessCount = 0;
  String? _lastShownError;

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

    final provider = context.read<ReportPurchaseProvider>();
    // This page may mount partway through an already-recovering purchase
    // (e.g. the provider is mid-retry from a previous crash) -- baseline
    // both markers to the provider's CURRENT counters so only outcomes
    // that happen from this point on are shown here.
    _lastHandledSuccessCount = provider.successCount;
    provider.addListener(_onProviderChanged);
  }

  Future<void> _initUser() async {
    _backendUserId = await _getBackendUserId();
  }

  @override
  void dispose() {
    context.read<ReportPurchaseProvider>().removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<ReportPurchaseProvider>();

    if (provider.successCount != _lastHandledSuccessCount) {
      _lastHandledSuccessCount = provider.successCount;
      _lastShownError = null;

      final isRelationship = provider.lastSuccessWasRelationship == true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportSuccessPage(
            email: isRelationship ? "" : widget.formData["email"].toString(),
            reportTitle: isRelationship
                ? "Relationship Future Report"
                : widget.selectedReport["title"]?.toString() ?? "",
          ),
        ),
      );
      return;
    }

    final error = provider.errorMessage;
    if (error != null && error != _lastShownError && !provider.isProcessing) {
      _lastShownError = error;
      _showSnack(_errorText(error));
    }
  }

  String _errorText(String code) {
    switch (code) {
      case "cancelled":
        return "Payment cancelled.";
      case "billing_unavailable":
        return "Google Play Billing not available.";
      case "product_not_found":
        return "Product not available. Please try again.";
      case "report_failed":
        return "Payment received but report failed. Tap Retry.";
      case "unknown_pending_purchase":
        return "We found a pending purchase we couldn't identify. Please contact support.";
      default:
        return "Payment error. Please try again.";
    }
  }

  String _normalizeDob(dynamic dob) {
    if (dob == null) return "";
    final s = dob.toString().trim();

    if (s.contains(" ")) {
      return s.split(" ").first;
    }

    return s;
  }

  Future<void> _startGooglePayment() async {
    final provider = context.read<ReportPurchaseProvider>();
    if (provider.isProcessing) return;

    if (widget.selectedReport["id"] == "relationship_future_report") {
      final love = widget.formData["love_payload"];
      if (love == null) {
        _showSnack("Invalid relationship data.");
        return;
      }
      final loveMap = Map<String, dynamic>.from(love as Map);
      final partner = LovePersonInput.fromJson(
        Map<String, dynamic>.from(loveMap["partner"] as Map),
      );

      await provider.purchaseReport(
        request: ReportGenerationRequest(
          name: loveMap["user"]["name"]?.toString(),
          email: loveMap["user"]["email"]?.toString() ?? "",
          phone: loveMap["user"]["phone"]?.toString() ?? "",
          product: "relationship_future_report",
          birthDetails: BirthDetails(
            dateOfBirth: loveMap["user"]["dob"]?.toString(),
            timeOfBirth: loveMap["user"]["tob"]?.toString(),
            placeOfBirth: loveMap["user"]["pob"]?.toString(),
            latitude: (loveMap["user"]["lat"] as num?)?.toDouble(),
            longitude: (loveMap["user"]["lng"] as num?)?.toDouble(),
          ),
          language: loveMap["language"]?.toString(),
        ),
        isRelationship: true,
        boyIsUser: loveMap["boy_is_user"] as bool?,
        partner: partner,
      );
      return;
    }

    if (_backendUserId == null) {
      _showSnack("User not ready. Please try again.");
      return;
    }

    await provider.purchaseReport(
      request: ReportGenerationRequest(
        name: widget.formData["name"].toString(),
        email: widget.formData["email"].toString(),
        phone: widget.formData["phone"]?.toString() ?? "",
        product: widget.selectedReport["id"]?.toString(),
        birthDetails: BirthDetails(
          dateOfBirth: _normalizeDob(widget.formData["dob"]),
          timeOfBirth: widget.formData["tob"]?.toString(),
          placeOfBirth: widget.formData["pob"]?.toString(),
          latitude: (widget.formData["lat"] as num?)?.toDouble(),
          longitude: (widget.formData["lng"] as num?)?.toDouble(),
        ),
        userId: _backendUserId,
        language: widget.formData["language"]?.toString() ?? "en",
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.selectedReport;
    final form = widget.formData;
    final provider = context.watch<ReportPurchaseProvider>();

    final isProcessing = provider.isProcessing;
    final canRetry =
        !isProcessing &&
        provider.errorMessage == "report_failed";

    return Scaffold(
      appBar: AppBar(title: const Text("Confirm & Pay")),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isProcessing
                ? null
                : (canRetry
                      ? () => context
                            .read<ReportPurchaseProvider>()
                            .retryPendingReportPurchase()
                      : _startGooglePayment),
            child: Text(
              isProcessing
                  ? "Processing..."
                  : (canRetry ? "Retry" : "Pay with Google Play"),
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
}
