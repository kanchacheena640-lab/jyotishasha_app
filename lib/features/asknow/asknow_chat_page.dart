import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// STATE
import 'package:jyotishasha_app/core/state/asknow_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';

// SERVICES
import 'package:jyotishasha_app/services/asknow_service.dart';

// FIREBASE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ADS
import 'package:jyotishasha_app/core/ads/banner_ad_widget.dart';
import 'package:jyotishasha_app/core/ads/rewarded_ad_manager.dart';

// UI
import 'package:jyotishasha_app/features/asknow/widgets/asknow_header_status_widget.dart';
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class AskNowChatPage extends StatefulWidget {
  const AskNowChatPage({super.key});

  @override
  State<AskNowChatPage> createState() => _AskNowChatPageState();
}

class _AskNowChatPageState extends State<AskNowChatPage> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> chatMessages = [];

  String? _pendingQuestion;
  Map<String, dynamic>? _pendingProfile;
  int? _userIdForPayment;

  int _adsWatched = 0;

  // Provider listeners (for safe auto-send + error snack)
  VoidCallback? _providerListener;
  Timer? _lastErrorDebounce;

  @override
  void initState() {
    super.initState();
    RewardedAdManager.load();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncChatStatus();
      _attachProviderListener();
    });
  }

  @override
  void dispose() {
    _lastErrorDebounce?.cancel();
    _detachProviderListener();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------
  // 🔄 Sync chat status
  // ---------------------------
  Future<void> _syncChatStatus() async {
    final userId = await _getBackendUserId();
    if (userId == null || userId == 0) return;

    final status = await AskNowService.fetchChatStatus(userId);
    final provider = context.read<AskNowProvider>();

    provider.setFreeAvailable(status["free_available"] == true);
    provider.remainingTokens =
        int.tryParse((status["remaining_tokens"] ?? 0).toString()) ?? 0;
    provider.hasActivePack = provider.remainingTokens > 0;
    provider.statusLoaded = true;
    provider.notifyListeners();
  }

  // ---------------------------
  // ✅ Single helper: backend_user_id
  // ---------------------------
  Future<int?> _getBackendUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final rawId = doc.data()?["backend_user_id"];
    final int userId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? "0") ?? 0;

    if (userId == 0) return null;
    return userId;
  }

  // ---------------------------
  // ✅ Auto-scroll to bottom
  // ---------------------------
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------
  // ✅ Provider listener: show errors + auto-send pending after purchase/reward
  // ---------------------------
  void _attachProviderListener() {
    if (!mounted) return;

    final provider = context.read<AskNowProvider>();
    _providerListener ??= () {
      if (!mounted) return;

      // 1) Surface errors (debounced)
      final err = provider.lastErrorMessage;
      if (err != null && err.trim().isNotEmpty) {
        _lastErrorDebounce?.cancel();
        _lastErrorDebounce = Timer(const Duration(milliseconds: 120), () {
          if (!mounted) return;

          // Friendly mapping for known codes
          String msg = err;
          if (err == "WAIT_SYNC") msg = "Please wait… syncing chat status.";
          if (err == "PAYMENT_REQUIRED") msg = "Please buy a pack to continue.";
          if (err == "Payment cancelled") msg = "Payment cancelled.";

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        });
      }

      // 2) If user had a pending question, and now tokens available → auto send
      if (_pendingQuestion != null &&
          _userIdForPayment != null &&
          _pendingProfile != null) {
        final bool canSendNow =
            provider.freeAvailable == true || provider.remainingTokens > 0;

        if (canSendNow && provider.isLoading == false) {
          // Capture and clear pending first (avoid duplicate)
          final q = _pendingQuestion!;
          final profile = _pendingProfile!;
          final userId = _userIdForPayment!;

          _pendingQuestion = null;
          _pendingProfile = null;
          _userIdForPayment = null;

          // Send automatically
          _sendQuestionInternal(q, profile, userId);
        }
      }
    };

    provider.addListener(_providerListener!);
  }

  void _detachProviderListener() {
    if (!mounted) return;
    final provider = context.read<AskNowProvider>();
    if (_providerListener != null) {
      provider.removeListener(_providerListener!);
      _providerListener = null;
    }
  }

  // ---------------------------
  // 🎁 Reward ads → 1 question
  // ---------------------------
  void _startRewardFlow() {
    RewardedAdManager.show(
      onAdCompleted: () async {
        _adsWatched++;
        if (_adsWatched < 2) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("1 more ad needed for 1 free question")),
          );
          return;
        }

        _adsWatched = 0;

        final userId = await _getBackendUserId();
        if (userId == null) return;

        await context.read<AskNowProvider>().earnedReward(userId);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🎉 1 Question added")));
      },
      onFailed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Ad not ready")));
      },
    );
  }

  // ---------------------------
  // 🚀 Send Question (entry)
  // ---------------------------
  Future<void> _sendQuestion() async {
    final q = _questionController.text.trim();
    if (q.isEmpty) return;

    final provider = context.read<AskNowProvider>();
    if (provider.isLoading) return;

    final userId = await _getBackendUserId();
    if (userId == null) return;

    final profile = context.read<ProfileProvider>().activeProfile ?? {};

    setState(() {
      chatMessages.add({"sender": "user", "text": q});
      _questionController.clear();
    });
    _scrollToBottom();

    final bool needPayment =
        provider.freeAvailable != true && provider.remainingTokens == 0;

    if (needPayment) {
      _pendingQuestion = q;
      _pendingProfile = profile;
      _userIdForPayment = userId;
      _showPackSheet();
      return;
    }

    await _sendQuestionInternal(q, profile, userId);
  }

  // ---------------------------
  // ✅ Real send: call provider and append answer
  // ---------------------------
  Future<void> _sendQuestionInternal(
    String q,
    Map<String, dynamic> profile,
    int userId,
  ) async {
    final provider = context.read<AskNowProvider>();

    // 🔒 IMPORTANT GUARD (missing earlier)
    if (!provider.statusLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait, syncing your account…")),
      );
      return;
    }

    await provider.askFreeOrFromTokens(
      question: q,
      profile: profile,
      userId: userId,
    );

    if (!mounted) return;

    final ans = provider.pendingAnswer;
    if (ans != null && ans.toString().isNotEmpty) {
      provider.clearPending();
      setState(() {
        chatMessages.add({"sender": "bot", "text": ans.toString()});
      });
      _scrollToBottom();
    }
  }

  // ---------------------------
  // 💳 Google Play trigger
  // ---------------------------
  Future<void> _showPackSheet() async {
    // 🔐 Ensure backend user id for payment (header + chat both)
    if (_userIdForPayment == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login again")));
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final rawId = doc.data()?["backend_user_id"];
      final int uid = rawId is int
          ? rawId
          : int.tryParse(rawId?.toString() ?? "0") ?? 0;

      if (uid == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not ready. Try again.")),
        );
        return;
      }

      _userIdForPayment = uid;
    }
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    "Unlock Ask Now",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "₹51 • 8 Questions • Lifetime Valid",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (_userIdForPayment == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User not ready. Try again."),
                            ),
                          );
                          return;
                        }
                        context
                            .read<AskNowProvider>()
                            .startGooglePlayPackPurchase(
                              userId: _userIdForPayment!,
                              productId: "asknow8q",
                            );
                      },
                      child: const Text(
                        "Pay with Google Play",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Reward CTA inside sheet (optional but useful)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startRewardFlow();
                      },
                      child: const Text("Or watch 2 ads to get 1 question"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AskNowProvider>();
    final loc = AppLocalizations.of(context)!;

    final bool showRewardCta =
        provider.freeAvailable != true && provider.remainingTokens == 0;

    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: AppBar(title: const Text("Ask Now 🔮")),
        body: Column(
          children: [
            AskNowHeaderStatusWidget(
              freeQ: provider.freeAvailable ? 1 : 0,
              earnedQ: provider.remainingTokens,
              onBuy: _showPackSheet,
            ),

            // Reward CTA when no free and no tokens
            if (showRewardCta)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _startRewardFlow,
                    child: const Text("Watch 2 ads → Get 1 Question"),
                  ),
                ),
              ),

            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "✨ Connecting with stars…",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: chatMessages.length,
                itemBuilder: (_, i) {
                  final msg = chatMessages[i];
                  final isUser = msg["sender"] == "user";
                  return Column(
                    children: [
                      Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.deepPurple
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            msg["text"] ?? "",
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (!isUser) const BannerAdWidget(),
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: loc.asknowInputHint,
                      ),
                      onSubmitted: (_) => _sendQuestion(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendQuestion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
