import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // ✅ Added for GoRouter
import 'more_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Dummy data for profiles
  final List<String> profiles = ["Kanchan", "Suhani", "Ravi"];
  String activeProfile = "Kanchan";

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _settingsSheet(),
    );
  }

  Widget _settingsSheet() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Settings",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _settingTile(Icons.language, "Language", "English / Hindi"),
          _settingTile(Icons.color_lens_outlined, "Theme", "Light / Dark"),
          _settingTile(Icons.history, "Purchase History", "Your past orders"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Active Profile
            Card(
              color: Colors.deepPurple[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  activeProfile,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Active Profile"),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Other Profiles
            const Text(
              "Other Profiles",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...profiles // ✅ Removed the wrong leading dot `.profiles`
                .where((p) => p != activeProfile)
                .map(
                  (p) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(p),
                      trailing: TextButton(
                        child: const Text("Activate"),
                        onPressed: () => setState(() => activeProfile = p),
                      ),
                    ),
                  ),
                ),
            const Spacer(),

            // 🔹 Add Profile Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add New Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {},
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 More Button (converted to GoRouter)
            Center(
              child: TextButton(
                onPressed: () {
                  context.go('/more'); // ✅ GoRouter navigation
                },
                child: const Text(
                  "More (Privacy Policy, Terms, Support, About)",
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
