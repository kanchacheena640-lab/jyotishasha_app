import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// STATE
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/asknow_provider.dart';
import 'package:jyotishasha_app/features/asknow/widgets/asknow_header_status_widget.dart';

// SERVICES
import 'package:jyotishasha_app/services/asknow_service.dart';

// If you already use razorpay_flutter elsewhere, keep this import.
// Otherwise add dependency in pubspec: razorpay_flutter: ^1.3.5
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';

class AskNowChatPage extends StatefulWidget {
  const AskNowChatPage({super.key});

  @override
  State<AskNowChatPage> createState() => _AskNowChatPageState();
}

class _AskNowChatPageState extends State<AskNowChatPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> chatMessages = [];

  late Razorpay _razorpay;

  String? _pendingPaidQuestionText;
  Map<String, dynamic>? _pendingPaidProfile;
  int? _userIdForPayment;
  String? _currentOrderId; // razorpay_order_id from backend

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
    _questionController.dispose();
    super.dispose();
  }

  // =====================================================
  // PAYMENT HANDLERS
  // =====================================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify with backend
    if (_userIdForPayment == null || _currentOrderId == null) return;

    final userId = _userIdForPayment!;
    final paymentId = response.paymentId ?? "";
    final orderId = _currentOrderId!;

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

        // If there was a pending question, ask it now from paid pack
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
    // Optional: handle wallets
  }

  // =====================================================
  // ASK AFTER PAYMENT (Pack)
  // =====================================================

  Future<void> _askFromPaidPackAfterPayment() async {
    final provider = context.read<AskNowProvider>();
    final question = _pendingPaidQuestionText!;
    final profile = _pendingPaidProfile!;
    final userId = _userIdForPayment!;

    await provider.askFromPaidPack(
      question: question,
      profile: profile,
      userId: userId,
    );

    if (!mounted) return;

    if (provider.pendingAnswer != null) {
      await Future.delayed(const Duration(seconds: 2)); // ad delay feel
      final ans = provider.pendingAnswer!;
      provider.clearPending();

      setState(() {
        chatMessages.add({"sender": "bot", "text": ans});
      });
    } else if (provider.lastErrorMessage != null &&
        provider.lastErrorMessage != "PAYMENT_REQUIRED") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.lastErrorMessage!)));
    }

    // Clear pending
    _pendingPaidQuestionText = null;
    _pendingPaidProfile = null;
  }

  // =====================================================
  // MAIN SEND QUESTION
  // =====================================================

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    final kundaliProvider = context.read<FirebaseKundaliProvider>();
    final profile =
        kundaliProvider.kundaliData?["profile"] as Map<String, dynamic>? ?? {};

    // ⚠️ Adjust this according to how you store backend user_id
    final int userId = (profile["backend_user_id"] ?? 0) as int;

    final askProvider = context.read<AskNowProvider>();

    // 1) Add user message bubble
    setState(() {
      chatMessages.add({"sender": "user", "text": question});
      _questionController.clear();
    });

    // 2) Call provider (free OR tokens)
    await askProvider.askFreeOrFromTokens(
      question: question,
      profile: profile,
      userId: userId,
    );

    if (!mounted) return;

    // 3) If answer available → show after small delay (ad / feel)
    if (askProvider.pendingAnswer != null) {
      await Future.delayed(const Duration(seconds: 2));
      final ans = askProvider.pendingAnswer!;
      askProvider.clearPending();

      setState(() {
        chatMessages.add({"sender": "bot", "text": ans});
      });
      return;
    }

    // 4) If payment required → open pack purchase flow
    if (askProvider.lastErrorMessage == "PAYMENT_REQUIRED") {
      _pendingPaidQuestionText = question;
      _pendingPaidProfile = profile;
      _userIdForPayment = userId;
      _showPackSheet();
      return;
    }

    // 5) Any other error
    if (askProvider.lastErrorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(askProvider.lastErrorMessage!)));
    }
  }

  // =====================================================
  // BOTTOM SHEET — BUY PACK
  // =====================================================

  void _showPackSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Unlock 8 Detailed Answers",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You’ve used your free question for today.\nGet a question pack for just ₹51 and ask 8 questions anytime.",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startPackPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  "Pay ₹51 & Unlock 8 Questions",
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pack has no expiry – valid until all 8 questions are used.",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startPackPayment() async {
    if (_userIdForPayment == null) return;
    final userId = _userIdForPayment!;

    try {
      final orderRes = await AskNowService.createPackOrder(
        userId: userId,
      ); // API call

      final order = orderRes["order"] as Map<String, dynamic>?;
      if (order == null) throw Exception("Invalid order response");

      final razorpayOrderId = order["razorpay_order_id"]?.toString() ?? "";
      final amount = (order["amount"] ?? 51) as int;

      _currentOrderId = razorpayOrderId;

      final options = {
        "key": "RAZORPAY_KEY_ID", // 🔴 replace with your key
        "amount": amount * 100, // in paise
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
            // -------------- TOP NOTE --------------
            AskNowHeaderStatusWidget(
              freeQ: provider.freeUsedToday ? 0 : 1, // daily toggling
              earnedQ: provider.remainingTokens, // backend tokens
              onBuy: _showPackSheet,
            ),

            // -------------- CHAT WINDOW --------------
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
                    // Chat list
                    Expanded(
                      child: chatMessages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  'Start your free consultation by typing your question below 💬',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: chatMessages.length,
                              itemBuilder: (context, index) {
                                final msg = chatMessages[index];
                                final isUser = msg['sender'] == 'user';

                                return Align(
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
                                      msg['text']!,
                                      style: GoogleFonts.montserrat(
                                        color: isUser
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // -------------- INPUT BAR --------------
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
                                hintText: 'Type your question...',
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
