import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String snippet,
    required String link,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: () => _openLink(link),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("More")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              snippet:
                  "We value your privacy. Learn how Jyotishasha handles your data and user information securely.",
              link: "https://jyotishasha.com/privacy-policy/",
            ),
            _buildSection(
              icon: Icons.article_outlined,
              title: "Terms of Service",
              snippet:
                  "Understand the terms and conditions governing usage of Jyotishasha services.",
              link: "https://jyotishasha.com/terms-and-conditions/",
            ),
            _buildSection(
              icon: Icons.support_agent_outlined,
              title: "Support & Feedback",
              snippet:
                  "Need help or want to share feedback? Contact our support team anytime.",
              link: "mailto:support@jyotishasha.com",
            ),
            _buildSection(
              icon: Icons.info_outline,
              title: "About Jyotishasha",
              snippet:
                  "India’s trusted astrology platform offering personalized reports and guidance.",
              link: "https://jyotishasha.com/about/",
            ),
            const SizedBox(height: 20),
            const Text(
              "Made with ❤️ in India",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
