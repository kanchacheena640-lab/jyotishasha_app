import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/asknow_provider.dart'; // ← IMPORTANT
import 'package:jyotishasha_app/core/widgets/keyboard_dismiss.dart';

class AskNowChatPage extends StatefulWidget {
  const AskNowChatPage({super.key});

  @override
  State<AskNowChatPage> createState() => _AskNowChatPageState();
}

class _AskNowChatPageState extends State<AskNowChatPage> {
  final TextEditingController _questionController = TextEditingController();

  // Topic list
  String selectedSubject = 'Career';
  final List<String> subjects = [
    'Love',
    'Marriage',
    'Career',
    'Job',
    'Finance',
    'Business',
    'Health',
    'Today',
    'Education',
    'Travel',
    'Family',
  ];

  // Chat window list
  final List<Map<String, String>> chatMessages = [];

  // -----------------------------------------------------------
  // SEND QUESTION → Provider → Backend → Ad Delay → Chat Insert
  // -----------------------------------------------------------

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    final profile =
        context.read<FirebaseKundaliProvider>().kundaliData?["profile"] ?? {};

    print("🟣 UI DEBUG: QUESTION BEING SENT = $question");
    print("🟣 UI DEBUG: PROFILE FROM PROVIDER = $profile");

    final provider = context.read<AskNowProvider>();

    // 1) Add user message
    setState(() {
      chatMessages.add({"sender": "user", "text": question});
      _questionController.clear();
    });

    // 2) Fetch from backend (does NOT show immediately)
    await provider.fetchAnswer(question, profile);

    // 3) Simulate reward ad
    await Future.delayed(const Duration(seconds: 3));

    // 4) Show backend answer
    final ans = provider.pendingAnswer ?? "No answer received.";
    provider.clearPending();

    setState(() {
      chatMessages.add({"sender": "bot", "text": ans});
    });
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
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
            // ------------------------------
            // TOP SUBJECT CHIPS
            // ------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a Topic',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: subjects.map((s) {
                        final isActive = selectedSubject == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(s),
                            selected: isActive,
                            onSelected: (_) {
                              setState(() {
                                selectedSubject = s;
                                chatMessages.clear();
                              });
                            },
                            selectedColor: const Color(0xFF7C3AED),
                            labelStyle: GoogleFonts.montserrat(
                              color: isActive ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------
            // CHAT WINDOW
            // ------------------------------
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

                    // ------------------------------
                    // INPUT BAR
                    // ------------------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _questionController,
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
