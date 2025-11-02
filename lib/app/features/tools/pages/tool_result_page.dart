import 'package:flutter/material.dart';

class ToolResultPage extends StatelessWidget {
  final String toolTitle;
  final Map<String, dynamic> resultData;

  const ToolResultPage({
    super.key,
    required this.toolTitle,
    required this.resultData,
  });

  @override
  Widget build(BuildContext context) {
    // 🧠 Try all possible keys used in backend (summary, result.message etc.)
    final message =
        resultData['result']?['message'] ??
        resultData['summary'] ??
        resultData['result']?['summary'] ??
        "No result available right now.";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FF),
      appBar: AppBar(
        title: Text(toolTitle),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 Main result text
              Text(message, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 24),

              // ℹ️ Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Results are auto-generated using your saved birth details and Jyotishasha’s backend engine.",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
