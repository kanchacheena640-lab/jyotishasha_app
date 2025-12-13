import 'dart:convert'; // for JSON parsing
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// STATE
import 'package:jyotishasha_app/core/state/asknow_provider.dart';
import 'package:jyotishasha_app/features/asknow/widgets/asknow_header_status_widget.dart';

// SERVICES
import 'package:jyotishasha_app/services/asknow_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/core/ads/rewarded_ad_manager.dart';
import 'package:jyotishasha_app/core/constants/razorpay_keys.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';

// RAZORPAY
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
// ⭐ NEW: localization import
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class AskNowChatPage extends StatefulWidget {
  const AskNowChatPage({super.key});

  @override
  State<AskNowChatPage> createState() => _AskNowChatPageState();
}

class _AskNowChatPageState extends State<AskNowChatPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> chatMessages = [];

  final ScrollController _scrollController = ScrollController();

  late Razorpay _razorpay;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // ⭐ REWARD FLOW STARTER — (2 ads → 1 reward)
  int _adsWatched = 0; // <-- add this above startRewardFlow()

  void _startRewardFlow() {
    RewardedAdManager.show(
      onAdCompleted: () async {
        _adsWatched++;

        if (_adsWatched < 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Ad $_adsWatched/2 completed. Watch one more!"),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        _adsWatched = 0;

        final provider = context.read<AskNowProvider>();
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) return;

        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(firebaseUser.uid)
            .get();

        final rawId = doc.data()?["backend_user_id"];
        final int userId = rawId is int
            ? rawId
            : int.tryParse(rawId?.toString() ?? "0") ?? 0;

        if (userId == 0) return;

        await provider.earnedReward(userId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 You earned 1 Free Question!"),
            duration: Duration(seconds: 2),
          ),
        );
      },

      onFailed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ad not ready. Try again..."),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  String? _pendingPaidQuestionText;
  Map<String, dynamic>? _pendingPaidProfile;
  int? _userIdForPayment;
  String? _currentOrderId;

  // ⭐ BOTTOM SHEET — EARN FREE QUESTION (Watch Ads)
  void _showEarnFreeQuestionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),

              // Heading
              const Text(
                "Earn 1 Free Question",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              const Text(
                "Watch 2 short ads and instantly get 1 free question added to your account.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 20),

              // ⭐ WATCH ADS BUTTON — CORRECT FLOW
              ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);

                  // Bottom sheet animation complete hone ka wait
                  await Future.delayed(const Duration(milliseconds: 350));

                  // 🔥 CORRECT ACTION — reward ads flow
                  _startRewardFlow();
                },
                label: const Text(
                  "Watch Ads",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Complete both ads to unlock the reward.",
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------
  // 🔧 CLEAN BOT ANSWER TEXT (Final Optimized Version)
  // ---------------------------------------------------
  String _cleanBotText(String? raw) {
    if (raw == null) return "";
    String text = raw.trim();
    if (text.isEmpty) return "";

    // 1) Proper JSON response
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        if (decoded["answer"] is String) {
          return decoded["answer"].toString().trim();
        }
        if (decoded["message"] is String) {
          return decoded["message"].toString().trim();
        }
      }
    } catch (_) {
      // ignore
    }

    // 2) Map.toString() fallback:  {answer: "...", message: null}
    final lower = text.toLowerCase();
    const key = "answer:";
    final idx = lower.indexOf(key);

    if (idx != -1) {
      String rest = text.substring(idx + key.length).trim();

      // remove next ", key:"
      final reg = RegExp(r',\s*\w+\s*:', caseSensitive: false);
      final match = reg.firstMatch(rest);
      if (match != null) {
        rest = rest.substring(0, match.start).trim();
      }

      // clean braces
      rest = rest.replaceAll(RegExp(r'[{}]'), '').trim();

      // clean single/double quotes
      if ((rest.startsWith('"') && rest.endsWith('"')) ||
          (rest.startsWith("'") && rest.endsWith("'"))) {
        rest = rest.substring(1, rest.length - 1).trim();
      }

      if (rest.isNotEmpty) return rest;
    }

    // 3) If text contains ASTROLOGICAL JSON fragments
    if (text.contains("prediction") || text.contains("remedy")) {
      return text.replaceAll(RegExp(r'[{}"]'), "").trim();
    }

    // 4) Final fallback
    return text;
  }

  // ---------------------------------------------------
  // 🔥 SYNC CHAT STATUS FROM BACKEND (Final Version)
  // ---------------------------------------------------
  Future<void> _syncChatStatus() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(firebaseUser.uid)
          .get();

      final rawId = userDoc.data()?["backend_user_id"];
      final int userId = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? "0") ?? 0;

      if (userId == 0) return;

      final status = await AskNowService.fetchChatStatus(userId);

      if (!mounted) return;

      final provider = context.read<AskNowProvider>();

      provider.setFreeAvailable(status["free_available"] == true);

      // Normalized token extraction
      final rawTokens =
          status["remaining_tokens"] ??
          status["remaining"] ??
          status["remaining_questions"] ??
          0;

      final int tokens = int.tryParse(rawTokens.toString()) ?? 0;

      provider.hasActivePack = tokens > 0;
      provider.remainingTokens = tokens;
      provider.statusLoaded = true;

      provider.notifyListeners();
    } catch (e) {
      debugPrint("⚠ syncChatStatus error: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    RewardedAdManager.load();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncChatStatus();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =====================================================
  // PAYMENT HANDLERS (Enterprise Safe Version)
  // =====================================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_userIdForPayment == null || _currentOrderId == null) return;

    final int userId = _userIdForPayment!;
    final String paymentId = response.paymentId ?? "";
    final String orderId = _currentOrderId!;

    try {
      final verifyRes = await AskNowService.verifyPayment(
        userId: userId,
        orderId: orderId,
        paymentId: paymentId,
      );

      final bool ok =
          verifyRes["success"] == true &&
          verifyRes["result"] != null &&
          verifyRes["result"]["success"] == true;

      if (!mounted) return;

      if (ok) {
        // normalized token pull
        final raw = verifyRes["result"]["total_tokens"];
        final int tokens = raw is int ? raw : int.tryParse(raw.toString()) ?? 8;

        // update provider
        context.read<AskNowProvider>().markPackActive(tokens: tokens);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment verified successfully 🔮 Pack activated!"),
            duration: Duration(seconds: 2),
          ),
        );

        // if user had asked a question before payment
        if (_pendingPaidQuestionText != null && _pendingPaidProfile != null) {
          await _askFromPaidPackAfterPayment();
        }

        // reset state
        _pendingPaidProfile = null;
        _pendingPaidQuestionText = null;
        _currentOrderId = null;
        _userIdForPayment = null;
      } else {
        final msg =
            verifyRes["result"]?["message"] ?? "Payment verification failed.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.toString()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unexpected error verifying payment. Please try again.",
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    final code = response.code;
    final msg = response.message ?? "Unknown error";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment cancelled or failed ($code): $msg"),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External wallet selected: ${response.walletName}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =====================================================
  // ASK AFTER PAYMENT (Pack) — ENTERPRISE SAFE
  // =====================================================
  Future<void> _askFromPaidPackAfterPayment() async {
    final provider = context.read<AskNowProvider>();

    // ---------- SAFETY CHECKS ----------
    final String? q = _pendingPaidQuestionText;
    final Map<String, dynamic>? prof = _pendingPaidProfile;
    final int? uid = _userIdForPayment;

    if (q == null || prof == null || uid == null) {
      debugPrint("⚠️ Missing pending question data after payment.");
      return;
    }

    try {
      await provider.askFromPaidPack(question: q, profile: prof, userId: uid);

      if (!mounted) return;

      // ---------- BOT ANSWER AVAILABLE ----------
      final rawAnswer = provider.pendingAnswer;
      final error = provider.lastErrorMessage;

      if (rawAnswer != null && rawAnswer.toString().trim().isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));

        final String cleaned = _cleanBotText(rawAnswer);
        provider.clearPending();

        setState(() {
          chatMessages.add({"sender": "bot", "text": cleaned});
        });

        _scrollToBottom();
      }
      // ---------- ANY NON-PAYMENT ERROR ----------
      else if (error != null && error != "PAYMENT_REQUIRED") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Please try again."),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      // ---------- ALWAYS RESET ----------
      _pendingPaidQuestionText = null;
      _pendingPaidProfile = null;
      // userIdForPayment aur order id mat reset karo – wo payment flow me reset honge
    }
  }

  // =====================================================
  // ⭐ FIXED MAIN SEND QUESTION — ENTERPRISE SAFE VERSION
  // =====================================================
  Future<void> _sendQuestion() async {
    final String question = _questionController.text.trim();
    if (question.isEmpty) return;

    final provider = context.read<AskNowProvider>();

    // ⛔ Prevent double-send
    if (provider.isLoading) return;

    // Close keyboard instantly for smoother UI
    FocusScope.of(context).unfocus();

    // -------------------------------
    // 1) FETCH USER + BACKEND ID
    // -------------------------------
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      debugPrint("❌ No Firebase user.");
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid)
        .get();

    final rawId = userDoc.data()?["backend_user_id"];
    final int userId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? "0") ?? 0;

    if (userId == 0) {
      debugPrint("❌ backend_user_id missing.");
      return;
    }

    // Fetch active profile
    final profileProvider = context.read<ProfileProvider>();
    final Map<String, dynamic> profile = profileProvider.activeProfile ?? {};

    // -------------------------------
    // 2) UI: Show user message instantly
    // -------------------------------
    setState(() {
      chatMessages.add({"sender": "user", "text": question});
      _questionController.clear();
    });

    _scrollToBottom();

    // -------------------------------
    // 3) DECISION TREE (MOST IMPORTANT)
    // -------------------------------
    final bool freeAvailable = provider.freeAvailable == true;
    final bool packAvailable = provider.remainingTokens > 0;
    final bool needPayment = !freeAvailable && !packAvailable;

    // -------------------------------
    // 4) NOTHING AVAILABLE → PAYMENT SHEET
    // -------------------------------
    if (needPayment) {
      _pendingPaidQuestionText = question;
      _pendingPaidProfile = profile;
      _userIdForPayment = userId;
      _showPackSheet();
      return;
    }

    // -------------------------------
    // 5) CALL API USING FREE OR PACK
    // -------------------------------
    try {
      await provider.askFreeOrFromTokens(
        question: question,
        profile: profile,
        userId: userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong. Try again.")),
        );
      }
      return;
    }

    if (!mounted) return;

    // -------------------------------
    // 6) ANSWER FROM BACKEND
    // -------------------------------
    final rawAnswer = provider.pendingAnswer;

    if (rawAnswer != null && rawAnswer.toString().trim().isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 900)); // smoother feel
      final ansText = _cleanBotText(rawAnswer);
      provider.clearPending();

      setState(() {
        chatMessages.add({"sender": "bot", "text": ansText});
      });

      _scrollToBottom();
      return;
    }

    // -------------------------------
    // 7) PAYMENT REQUIRED MID-FLOW
    // -------------------------------
    if (provider.lastErrorMessage == "PAYMENT_REQUIRED") {
      _pendingPaidQuestionText = question;
      _pendingPaidProfile = profile;
      _userIdForPayment = userId;
      _showPackSheet();
      return;
    }

    // -------------------------------
    // 8) ANY OTHER ERROR
    // -------------------------------
    if (provider.lastErrorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.lastErrorMessage!)));
    }
  }

  // =====================================================
  // ⭐ UPGRADED PACK + PURE ENTERPRISE BOTTOM SHEET
  // =====================================================
  void _showPackSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                "You’ve used your free question today",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                "To continue asking, buy a question pack:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 26),

              // ⭐ PACK CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Buy Pack – ₹51",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      "Get 8 premium questions. No expiry. Use anytime.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          // Prevent immediate UI lag
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );

                          _startPackPayment();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Pay ₹51 & Get 8 Questions",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Pack questions never expire.",
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // ⭐ START PACK PAYMENT — SAFE & CLEAN
  // =====================================================
  Future<void> _startPackPayment() async {
    try {
      int userId;

      // 1️⃣ If already cached (user pressed Send earlier)
      if (_userIdForPayment != null) {
        userId = _userIdForPayment!;
      } else {
        final firebaseUser = FirebaseAuth.instance.currentUser;

        if (firebaseUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please login again to buy a pack."),
              ),
            );
          }
          return;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(firebaseUser.uid)
            .get();

        final rawId = userDoc.data()?["backend_user_id"];
        userId = rawId is int
            ? rawId
            : int.tryParse(rawId?.toString() ?? "0") ?? 0;

        if (userId == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("User ID missing. Please restart the app."),
              ),
            );
          }
          return;
        }

        _userIdForPayment = userId;
      }

      // 2️⃣ Create Razorpay Order
      final orderRes = await AskNowService.createPackOrder(userId: userId);

      final order = orderRes["order"] as Map<String, dynamic>?;
      if (order == null) throw Exception("Invalid order data");

      final String razorpayOrderId =
          order["razorpay_order_id"]?.toString() ?? "";
      final int amount = (order["amount"] ?? 51) as int;

      _currentOrderId = razorpayOrderId;

      // 3️⃣ Razorpay Options
      final options = {
        "key": RazorpayKeys.liveKey,
        "amount": amount * 100,
        "currency": "INR",
        "name": "Jyotishasha AskNow",
        "description": "ChatPack 8 Questions",
        "order_id": razorpayOrderId,
        "prefill": {"contact": "", "email": ""},
      };

      // 4️⃣ Open Razorpay
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Payment init failed: $e")));
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AskNowProvider>();
    final loc = AppLocalizations.of(context)!; // ⭐ ARB localizations

    return KeyboardDismissOnTap(
      child: Scaffold(
        backgroundColor: const Color(0xFFFEEFF5),
        appBar: AppBar(
          title: const Text('Ask Now 🔮'),
          backgroundColor: const Color(0xFF7C3AED),
          elevation: 0,
          centerTitle: true,
        ),

        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              // 🔹 Top status: free Q + pack summary
              AskNowHeaderStatusWidget(
                freeQ: provider.statusLoaded && provider.freeAvailable ? 1 : 0,
                earnedQ: provider.remainingTokens, // ✅ int hi jaa raha hai
                onBuy: _showPackSheet,
              ),
              const SizedBox(height: 12),

              // ⭐ FREE QUESTION UNLOCK BUTTON (Watch Ads)
              if (provider.statusLoaded &&
                  provider.freeAvailable == false && // free NOT available
                  provider.freeUsedToday == true && // free USED TODAY
                  provider.remainingTokens == 0) // no pack tokens
                Center(
                  child: GestureDetector(
                    onTap: _showEarnFreeQuestionSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Unlock 1 Free Question",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 🔹 Main Chat + Input
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 🔹 Chat list + optional "typing..." bubble
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: chatMessages.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          // 🔁 ARB text: empty state hint
                                          loc.asknowEmptyHint,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: chatMessages.length,
                                      itemBuilder: (context, index) {
                                        final msg = chatMessages[index];
                                        final bool isUser =
                                            msg['sender'] == 'user';

                                        List<Widget> items = [];

                                        // ⭐ 1. Normal Chat Bubble
                                        items.add(
                                          Align(
                                            alignment: isUser
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isUser
                                                    ? const Color(0xFF7C3AED)
                                                    : const Color(0xFFF6F6F6),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                msg['text'] ?? "",
                                                style: TextStyle(
                                                  color: isUser
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );

                                        // ⭐ 2. Ad Insert — har bot message ke baad ad
                                        if (!isUser) {
                                          items.add(const SizedBox(height: 10));
                                          items.add(const BannerAdWidget());
                                          items.add(const SizedBox(height: 10));
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: items,
                                        );
                                      },
                                    ),
                            ),

                            // ⭐ Typing indicator — jab answer load ho raha ho
                            if (provider.isLoading &&
                                chatMessages.isNotEmpty &&
                                chatMessages.last['sender'] == 'user')
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F6F6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "✨ Connecting to stars…",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // 🔹 Input bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _questionController,
                                textInputAction: TextInputAction.send,
                                minLines: 1,
                                maxLines: 4,
                                onSubmitted: (_) {
                                  if (!provider.isLoading) {
                                    FocusScope.of(
                                      context,
                                    ).unfocus(); // ⬅ keyboard hide
                                    _sendQuestion();
                                  }
                                },
                                decoration: InputDecoration(
                                  // 🔁 ARB text: input hint
                                  hintText: loc.asknowInputHint,
                                  hintStyle: const TextStyle(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FloatingActionButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () {
                                      FocusScope.of(
                                        context,
                                      ).unfocus(); // ⬅ keyboard hide
                                      _sendQuestion();
                                    },
                              backgroundColor: provider.isLoading
                                  ? Colors.grey
                                  : const Color(0xFF7C3AED),
                              mini: true,
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
