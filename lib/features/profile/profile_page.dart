// lib/features/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEEFF5),
      appBar: AppBar(title: Text("Profile", style: GoogleFonts.montserrat())),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ SHOW LOADER WHEN SWITCHING ACTIVE PROFILE
            if (provider.isSwitching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),

            // ⭐ ACTIVE PROFILE CARD + EDIT BUTTON
            if (provider.activeProfile != null)
              Column(
                children: [
                  _activeCard(provider.activeProfile!, theme),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit Profile"),
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
                  ),
                ],
              ),

            const SizedBox(height: 20),

            Text(
              "Other Profiles",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: provider.otherProfiles.isEmpty
                  ? const Center(child: Text("No other profiles"))
                  : ListView.builder(
                      itemCount: provider.otherProfiles.length,
                      itemBuilder: (_, i) {
                        return _profileTile(
                          context,
                          provider.otherProfiles[i],
                          provider,
                          theme,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Profile"),
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddProfilePage()),
                  );
                  if (res == true) provider.loadProfiles();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ ACTIVE PROFILE CARD

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
          p["name"] ?? "",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${p["dob"] ?? ""}  •  ${p["pob"] ?? ""}",
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        trailing: Icon(Icons.check_circle, color: theme.colorScheme.primary),
      ),
    );
  }

  // ⭐ OTHER PROFILES TILE
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
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: const Icon(Icons.person_outline),
        ),
        title: Text(p["name"] ?? "", style: GoogleFonts.montserrat()),
        subtitle: Text(
          "${p["dob"]} • ${p["pob"]}",
          style: GoogleFonts.montserrat(fontSize: 12),
        ),

        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == "activate") {
              await provider.setActive(p["id"]);
            } else if (value == "edit") {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfilePage(profile: p)),
              );
              if (res == true) provider.loadProfiles();
            } else if (value == "delete") {
              await provider.removeProfile(p["id"]);
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
