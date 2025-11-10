import 'package:flutter/material.dart';

class AppFooterFeedbackWidget extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  AppFooterFeedbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🌈 Jyotishasha gradient (saffron → purple)
    const jyotishashaGradient = LinearGradient(
      colors: [Color(0xFFFF9933), Color(0xFF8E2DE2)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

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

          const SizedBox(height: 16),

          // ✨ Gradient "Send" text button (See More style)
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thanks for your feedback!")),
              );
              _controller.clear();
            },
            child: ShaderMask(
              shaderCallback: (bounds) => jyotishashaGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.send_rounded,
                    size: 22, // 🔹 slightly bigger icon
                    color: Colors.white, // placeholder for gradient
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Send",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // needed for gradient
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

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
