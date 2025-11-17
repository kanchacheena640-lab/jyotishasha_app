import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;
  String? activeProfileId;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .get();

    if (!mounted) return;
    setState(() {
      profiles = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      activeProfileId = profiles
          .firstWhere((p) => p['isActive'] == true, orElse: () => {})
          .cast<String, dynamic>()['id'];
      isLoading = false;
    });
  }

  Future<void> _activateProfile(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('profiles');

    // reset all to false
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in profiles) {
      batch.update(ref.doc(doc['id']), {'isActive': doc['id'] == id});
    }
    await batch.commit();

    _loadProfiles();
  }

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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Settings",
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Divider(),
          _settingTile(Icons.language, "Language", "English / Hindi"),
          _settingTile(
            Icons.color_lens_outlined,
            "Theme",
            "Light / Dark  — Coming Soon",
          ),
          _settingTile(Icons.history, "Purchase History", "Your past orders"),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                "Close",
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: GoogleFonts.montserrat(fontSize: 13)),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFEEFF5),
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profiles.isNotEmpty && activeProfileId != null)
                    _activeProfileCard(theme),

                  const SizedBox(height: 20),

                  Text(
                    "Other Profiles",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: profiles.isEmpty
                        ? const Center(
                            child: Text("No profiles yet — Add one below"),
                          )
                        : ListView(
                            children: profiles
                                .where((p) => p['id'] != activeProfileId)
                                .map((p) => _profileCard(theme, p))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Add New Profile",
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddProfilePage(),
                          ),
                        );
                        if (result == true) _loadProfiles();
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  _logoutAndDeleteRow(theme),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/more'),
                      child: Text(
                        "More (Privacy Policy, Terms, Support, About)",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          decoration: TextDecoration.underline,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _activeProfileCard(ThemeData theme) {
    final active = profiles.firstWhere(
      (p) => p['id'] == activeProfileId,
      orElse: () => {},
    );
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: const Icon(Icons.person, color: Colors.black87),
        ),
        title: Text(
          active['name'] ?? 'Unknown',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${active['dob'] ?? ''} • ${active['pob'] ?? ''}",
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        trailing: Icon(Icons.check_circle, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _profileCard(ThemeData theme, Map<String, dynamic> p) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.person_outline, color: Colors.black54),
        ),
        title: Text(p['name'] ?? '', style: GoogleFonts.montserrat()),
        subtitle: Text(
          "${p['dob'] ?? ''} • ${p['pob'] ?? ''}",
          style: GoogleFonts.montserrat(fontSize: 12),
        ),
        trailing: TextButton(
          child: Text(
            "Activate",
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => _activateProfile(p['id']),
        ),
      ),
    );
  }

  Widget _logoutAndDeleteRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final auth = AuthService();
              await auth.signOut();

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully 🌸")),
              );

              await Future.delayed(const Duration(milliseconds: 500));
              SystemNavigator.pop();
            },
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .delete();
                  await user.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deleted successfully 🧹"),
                    ),
                  );
                  if (context.mounted) SystemNavigator.pop();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("❌ Failed: $e")));
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
