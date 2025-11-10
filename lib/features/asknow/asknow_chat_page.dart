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

    // 🔮 Next step (Step 2): show rewarded ad + call backend API
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
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Subject selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: selectedSubject,
              decoration: InputDecoration(
                labelText: 'Select Subject',
                labelStyle: GoogleFonts.montserrat(
                  color: const Color(0xFF4A148C),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => selectedSubject = v!),
            ),
          ),

          // Suggestions bar
          if (preQuestions[selectedSubject] != null)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: preQuestions[selectedSubject]!
                    .map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(
                            q,
                            style: GoogleFonts.montserrat(fontSize: 12),
                          ),
                          backgroundColor: Colors.white,
                          onPressed: () {
                            setState(() => _questionController.text = q);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 10),

          // Chat area
          Expanded(
            child: ListView.builder(
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
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF7C3AED) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: GoogleFonts.montserrat(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
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
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
