import 'dart:convert'; // for JSON parsing
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),

              // ⭐ Heading
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

              // ⭐ WATCH ADS BUTTON
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
                onPressed: () {
                  Navigator.pop(context);
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
  // 🔧 CLEAN BOT ANSWER TEXT AT UI LEVEL
  // ---------------------------------------------------
  String _cleanBotText(String? raw) {
    if (raw == null) return "";
    String text = raw.trim();
    if (text.isEmpty) return "";

    // 1) Try if it's proper JSON → {"success":true, "answer":"..."}
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        if (decoded["answer"] is String) {
          return (decoded["answer"] as String).trim();
        }
        if (decoded["message"] is String) {
          return (decoded["message"] as String).trim();
        }
      }
    } catch (_) {
      // Not JSON, ignore
    }

    // 2) Try if it's Dart Map.toString():
    // {success: true, answer: Aaj ka din..., remaining_tokens: 7, message: null}
    final lower = text.toLowerCase();
    const key = "answer:";
    final idx = lower.indexOf(key);
    if (idx != -1) {
      String rest = text.substring(idx + key.length).trim();

      // Cut when next ", someKey:"
      final reg = RegExp(r',\s*\w+\s*:');
      final match = reg.firstMatch(rest);
      if (match != null) {
        rest = rest.substring(0, match.start).trim();
      }

      // Remove trailing brace
      if (rest.endsWith('}')) {
        rest = rest.substring(0, rest.length - 1).trim();
      }

      // Trim quotes if wrapped
      if ((rest.startsWith("'") && rest.endsWith("'")) ||
          (rest.startsWith('"') && rest.endsWith('"'))) {
        rest = rest.substring(1, rest.length - 1);
      }

      if (rest.isNotEmpty) return rest;
    }

    // 3) Fallback → jo aaya hai wahi
    return text;
  }

  // ---------------------------------------------------
  // 🔥 SYNC CHAT STATUS FROM BACKEND
  // ---------------------------------------------------
  Future<void> _syncChatStatus() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

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

    final provider = context.read<AskNowProvider>();
    provider.setFreeAvailable(status["free_available"] == true);

    // 🔥 tokens ko hamesha INT bana do
    final dynamic rawTokens =
        status["remaining_tokens"] ??
        status["remaining"] ??
        status["remaining_questions"] ??
        0;

    final int tokens = int.tryParse(rawTokens.toString()) ?? 0;

    provider.hasActivePack = tokens > 0;
    provider.remainingTokens = tokens;
    provider.statusLoaded = true;
    provider.notifyListeners();
  }

  @override
  void initState() {
    super.initState();
    RewardedAdManager.load();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _syncChatStatus();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _questionController.dispose();
    super.dispose();
  }

  // =====================================================
  // PAYMENT HANDLERS
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

      final ok =
          verifyRes["success"] == true &&
          verifyRes["result"] != null &&
          verifyRes["result"]["success"] == true;

      if (!mounted) return;

      if (ok) {
        final tokens = verifyRes["result"]["total_tokens"];
        context.read<AskNowProvider>().markPackActive(
          tokens: tokens is int ? tokens : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment verified. Question pack activated ✅"),
          ),
        );

        if (_pendingPaidQuestionText != null && _pendingPaidProfile != null) {
          await _askFromPaidPackAfterPayment();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (verifyRes["result"]?["message"] ??
                      "Payment verification failed.")
                  .toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Verify error: $e")));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.code} ${response.message}"),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional
  }

  // =====================================================
  // ASK AFTER PAYMENT (Pack)
  // =====================================================

  Future<void> _askFromPaidPackAfterPayment() async {
    final provider = context.read<AskNowProvider>();
    final String question = _pendingPaidQuestionText!;
    final Map<String, dynamic> profile = _pendingPaidProfile!;
    final int userId = _userIdForPayment!;

    await provider.askFromPaidPack(
      question: question,
      profile: profile,
      userId: userId,
    );

    if (!mounted) return;

    if (provider.pendingAnswer != null) {
      await Future.delayed(const Duration(seconds: 2));

      // ✅ CLEAN HERE
      final String ansText = _cleanBotText(provider.pendingAnswer);
      provider.clearPending();

      setState(() {
        chatMessages.add({"sender": "bot", "text": ansText});
      });

      _scrollToBottom();
    } else if (provider.lastErrorMessage != null &&
        provider.lastErrorMessage != "PAYMENT_REQUIRED") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.lastErrorMessage!)));
    }

    _pendingPaidQuestionText = null;
    _pendingPaidProfile = null;
  }

  // =====================================================
  // ⭐ FIXED MAIN SEND QUESTION — 100% CORRECT FLOW
  // =====================================================
  Future<void> _sendQuestion() async {
    final String question = _questionController.text.trim();
    if (question.isEmpty) return;

    final provider = context.read<AskNowProvider>();

    // ⛔ Prevent double-send
    if (provider.isLoading) return;

    // -------------------------------
    // 1) FETCH USER + BACKEND ID
    // -------------------------------
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      debugPrint("❌ No Firebase user");
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
      debugPrint("❌ backend_user_id missing");
      return;
    }

    final profileSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid)
        .collection("profiles")
        .doc("default")
        .get();

    final Map<String, dynamic> profile = profileSnap.data() ?? {};

    // -------------------------------
    // 2) SHOW IMMEDIATELY IN UI
    // -------------------------------
    setState(() {
      chatMessages.add({"sender": "user", "text": question});
      _questionController.clear();
    });

    _scrollToBottom();

    // -------------------------------------------------------------------
    // ⭐ NEW PRIORITY LOGIC (THE REAL FIX)
    //
    // 1️⃣ If free question available → use free
    // 2️⃣ Else if pack tokens > 0 → use tokens
    // 3️⃣ Else → NO free + NO tokens → show reward + pack sheet
    // -------------------------------------------------------------------

    bool useFree = provider.freeAvailable == true; // free not used today
    bool usePack = !useFree && provider.remainingTokens > 0; // pack available
    bool needPayment = !useFree && !usePack; // nothing available

    // -------------------------------
    // ⭐ 3) NOTHING AVAILABLE → SHOW OPTIONS
    // -------------------------------
    if (needPayment) {
      // Save question for after-payment if user chooses pack
      _pendingPaidQuestionText = question;
      _pendingPaidProfile = profile;
      _userIdForPayment = userId;

      // ⭐ Show bottom sheet: Buy Pack OR Watch Reward Ads
      _showPackSheet();

      return;
    }

    // -------------------------------
    // ⭐ 4) USE FREE OR PACK — MAKE API CALL
    // -------------------------------
    await provider.askFreeOrFromTokens(
      question: question,
      profile: profile,
      userId: userId,
    );

    if (!mounted) return;

    // -------------------------------
    // ⭐ 5) GOT BOT ANSWER
    // -------------------------------
    if (provider.pendingAnswer != null) {
      await Future.delayed(const Duration(seconds: 2));
      final String ansText = _cleanBotText(provider.pendingAnswer);
      provider.clearPending();

      setState(() {
        chatMessages.add({"sender": "bot", "text": ansText});
      });

      return;
    }

    // -------------------------------
    // ⭐ 6) PAYMENT NEEDED (Pack Required)
    // -------------------------------
    if (provider.lastErrorMessage == "PAYMENT_REQUIRED") {
      _pendingPaidQuestionText = question;
      _pendingPaidProfile = profile;
      _userIdForPayment = userId;

      _showPackSheet();
      return;
    }

    // -------------------------------
    // ⭐ 7) ANY OTHER ERROR
    // -------------------------------
    if (provider.lastErrorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.lastErrorMessage!)));
    }
  }

  // =====================================================
  // ⭐ UPGRADED PACK + REWARD COMBINED BOTTOM SHEET
  // =====================================================
  void _showPackSheet() {
    showModalBottomSheet(
      context: context,
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
              const SizedBox(height: 20),

              // Title
              Text(
                "You’ve used your free question today",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              Text(
                "Choose how you want to continue asking:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 26),

              // --------------------------------------------------
              // 1️⃣ OPTION: WATCH ADS FOR 1 FREE QUESTION
              // --------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Watch 2 Ads → Get 1 Free Question",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "No payment needed. Complete both ads and get 1 instant free question added.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                      ),
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
                      onPressed: () {
                        Navigator.pop(context);
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
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // --------------------------------------------------
              // 2️⃣ OPTION: BUY PACK (₹51 → 8 QUESTIONS)
              // --------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Buy Pack – ₹51",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Get 8 premium questions you can use anytime. No expiry.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startPackPayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Pay ₹51 & Get 8 Questions",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
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

  Future<void> _startPackPayment() async {
    if (_userIdForPayment == null) return;
    final int userId = _userIdForPayment!;

    try {
      final orderRes = await AskNowService.createPackOrder(userId: userId);

      final order = orderRes["order"] as Map<String, dynamic>?;
      if (order == null) throw Exception("Invalid order response");

      final String razorpayOrderId =
          order["razorpay_order_id"]?.toString() ?? "";
      final int amount = (order["amount"] ?? 51) as int;

      _currentOrderId = razorpayOrderId;

      final options = {
        "key": "RAZORPAY_KEY_ID", // TODO: replace with real key
        "amount": amount * 100,
        "name": "Jyotishasha AskNow",
        "description": "ChatPack 8 Questions",
        "order_id": razorpayOrderId,
        "prefill": {"contact": "", "email": ""},
      };

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

        body: Column(
          children: [
            AskNowHeaderStatusWidget(
              freeQ: provider.statusLoaded && provider.freeAvailable ? 1 : 0,
              earnedQ: provider.remainingTokens, // ✅ int hi jaa raha hai
              onBuy: _showPackSheet,
            ),
            const SizedBox(height: 12),

            // ⭐ FREE QUESTION UNLOCK BUTTON ⭐
            if (provider.statusLoaded &&
                provider.freeAvailable == false && // free NOT available
                provider.freeUsedToday == true && // free USED TODAY
                provider.remainingTokens == 0) // no pack tokens
              Center(
                child: GestureDetector(
                  onTap: () => _showEarnFreeQuestionSheet(),
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
                                  style: GoogleFonts.montserrat(
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
                                final bool isUser = msg['sender'] == 'user';

                                List<Widget> items = [];

                                // ⭐ 1. Normal Chat Bubble
                                items.add(
                                  Align(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? const Color(0xFF7C3AED)
                                            : const Color(0xFFF6F6F6),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        msg['text'] ?? "",
                                        style: GoogleFonts.montserrat(
                                          color: isUser
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                // ⭐ 2. Ad Insert — हर bot message के बाद ad दिखे
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _questionController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                if (!provider.isLoading) {
                                  _sendQuestion();
                                }
                              },
                              decoration: InputDecoration(
                                // 🔁 ARB text: input hint
                                hintText: loc.asknowInputHint,
                                hintStyle: GoogleFonts.montserrat(),
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
                                : _sendQuestion,
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
    );
  }
}
