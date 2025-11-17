import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/data/asknow_questions.dart';

class AskNowChatPage extends StatefulWidget {
  const AskNowChatPage({super.key});

  @override
  State<AskNowChatPage> createState() => _AskNowChatPageState();
}

class _AskNowChatPageState extends State<AskNowChatPage> {
  final TextEditingController _questionController = TextEditingController();

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

  final preQuestions = askNowQuestions;
  final List<Map<String, String>> chatMessages = [];

  void _sendQuestion() {
    if (_questionController.text.trim().isEmpty) return;

    setState(() {
      chatMessages.add({
        'sender': 'user',
        'text': _questionController.text.trim(),
      });
      _questionController.clear();
    });

    // Dummy bot reply (backend integration next step)
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        chatMessages.add({
          'sender': 'bot',
          'text':
              'Your personalized ${selectedSubject.toLowerCase()} insight will appear here after backend integration 🔮',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEFF5),
      appBar: AppBar(
        title: const Text('Ask Now 🔮'),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🟣 Top Category Bar
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

          // 🟣 Chat Window Sheet
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chat Messages
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

                  // Input Bar
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
                          onPressed: _sendQuestion,
                          backgroundColor: const Color(0xFF7C3AED),
                          mini: true,
                          child: const Icon(
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
    );
  }
}
