import 'package:flutter/material.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

class AppFooterFeedbackWidget extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  AppFooterFeedbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: Colors.grey.shade100, // soft neutral background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 💬 Feedback input box (centered)
          SizedBox(
            width: 300,
            child: TextField(
              controller: _controller,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Share your thoughts or suggestions...",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 🚀 Send Button (centered)
          SizedBox(
            width: 140,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thanks for your feedback!")),
                );
                _controller.clear();
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text("Send"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ⚖️ Copyright & Links
          Text(
            "© 2025 Jyotishasha. All rights reserved.",
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {}, // TODO: open Privacy/Terms
            child: const Text(
              "Privacy Policy  •  Terms of Use",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
