// lib/features/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/profile/add_profile_page.dart';
import 'package:jyotishasha_app/features/profile/edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProfileProvider>().loadProfiles();
    });
  }

  // ⭐ Logout with message + clean redirect
  Future<void> _logout() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logout Successfully"),
        duration: Duration(milliseconds: 800),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFEEFF5),

      appBar: AppBar(
        title: Text("Profile", style: const TextStyle()),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),

      // ⭐ Add Profile Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Profile"),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProfilePage()),
          );
          if (res == true) provider.loadProfiles();
        },
      ),

      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ ACTIVE PROFILE
                  if (provider.activeProfile != null)
                    Column(
                      children: [
                        _activeCard(provider.activeProfile!, theme),

                        const SizedBox(height: 12),

                        // ⭐ Edit + Logout Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit"),
                              onPressed: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfilePage(
                                      profile: provider.activeProfile!,
                                    ),
                                  ),
                                );
                                if (res == true) provider.loadProfiles();
                              },
                            ),

                            TextButton.icon(
                              icon: const Icon(Icons.logout),
                              label: const Text("Logout"),
                              onPressed: _logout,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // ⭐ Other Profiles heading
                  Text(
                    "Other Profiles",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ⭐ OTHER PROFILES LIST
                  Expanded(
                    child: provider.otherProfiles.isEmpty
                        ? const Center(child: Text("No other profiles"))
                        : ListView.builder(
                            itemCount: provider.otherProfiles.length,
                            itemBuilder: (_, i) => _profileTile(
                              context,
                              provider.otherProfiles[i],
                              provider,
                              theme,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // ⭐ ACTIVE CARD
  Widget _activeCard(Map<String, dynamic> p, ThemeData theme) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.25),
          child: const Icon(Icons.person, color: Colors.black87),
        ),
        title: Text(
          (p["name"] ?? "").toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${(p["dob"] ?? "").toString()}  •  ${(p["pob"] ?? "").toString()}",
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Icon(Icons.check_circle, color: theme.colorScheme.primary),
      ),
    );
  }

  // ⭐ OTHER PROFILE TILE
  Widget _profileTile(
    BuildContext context,
    Map<String, dynamic> p,
    ProfileProvider provider,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.person_outline),
        ),
        title: Text((p["name"] ?? "").toString(), style: const TextStyle()),
        subtitle: Text(
          "${(p["dob"] ?? "").toString()} • ${(p["pob"] ?? "").toString()}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == "activate") {
              await provider.setActiveProfile((p["id"] ?? "").toString());
            } else if (v == "edit") {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfilePage(profile: p)),
              );
              if (res == true) provider.loadProfiles();
            } else if (v == "delete") {
              await provider.deleteProfile((p["id"] ?? "").toString());
              provider.loadProfiles();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: "activate", child: Text("Activate")),
            const PopupMenuItem(value: "edit", child: Text("Edit")),
            const PopupMenuItem(
              value: "delete",
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
