import 'package:flutter/material.dart';

class AskNowChatPage extends StatelessWidget {
  const AskNowChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ask Now - Free Chat")),
      body: const Center(
        child: Text(
          "This will be the chat screen where user asks\nquestions & GPT gives answers with ads in between.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
