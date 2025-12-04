import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/features/profile/add_profile_page.dart';
import 'package:jyotishasha_app/features/profile/edit_profile_page.dart';
import 'package:jyotishasha_app/core/widgets/bottom_nav_bar_widget.dart';

class ProfileListPage extends StatefulWidget {
  const ProfileListPage({super.key});

  @override
  State<ProfileListPage> createState() => _ProfileListPageState();
}

class _ProfileListPageState extends State<ProfileListPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profiles",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),

      // ⭐ ADD THIS
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: 4, // Profile tab
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, "/home");
          if (index == 1) Navigator.pushReplacementNamed(context, "/panchang");
          if (index == 2) Navigator.pushReplacementNamed(context, "/astrology");
          if (index == 3) Navigator.pushReplacementNamed(context, "/asknow");
          if (index == 4) return; // already here
        },
      ),
      // ⭐ END
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProfilePage()),
          );
          if (result == true && mounted) {
            provider.loadProfiles();
          }
        },
        backgroundColor: theme.colorScheme.primary,
        label: const Text("Add Profile"),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(provider, theme),
    );
  }

  Widget _buildContent(ProfileProvider provider, ThemeData theme) {
    final active = provider.activeProfile;
    final others = provider.otherProfiles;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ ACTIVE PROFILE CARD
          if (active != null) _activeProfileCard(theme, active),

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
            child: others.isEmpty
                ? const Center(child: Text("No other profiles yet"))
                : ListView(
                    children: others
                        .map((p) => _profileCard(theme, p))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ⭐ ACTIVE PROFILE CARD
  Widget _activeProfileCard(ThemeData theme, Map<String, dynamic> p) {
    return Card(
      color: theme.colorScheme.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: const Icon(Icons.person, color: Colors.black87),
        ),
        title: Text(
          p["name"] ?? "",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${p["dob"] ?? ''} • ${p["pob"] ?? ''}",
          style: GoogleFonts.montserrat(fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditProfilePage(profile: p)),
            );

            if (result == true && mounted) {
              context.read<ProfileProvider>().loadProfiles();
            }
          },
        ),
      ),
    );
  }

  // ⭐ OTHER PROFILE CARD
  Widget _profileCard(ThemeData theme, Map<String, dynamic> p) {
    final provider = context.read<ProfileProvider>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.person_outline, color: Colors.black54),
        ),
        title: Text(p["name"] ?? "", style: GoogleFonts.montserrat()),
        subtitle: Text(
          "${p["dob"] ?? ''} • ${p["pob"] ?? ''}",
          style: GoogleFonts.montserrat(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 ACTIVATE BUTTON
            TextButton(
              child: Text(
                "Activate",
                style: GoogleFonts.montserrat(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                await provider.setActiveProfile(p["id"]);
                if (mounted) provider.loadProfiles();
              },
            ),

            // 🔹 DELETE BUTTON
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.redAccent,
              onPressed: () async {
                final ok = await provider.deleteProfile(p["id"]);
                if (ok && mounted) {
                  provider.loadProfiles(); // ⭐ refresh list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile deleted")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
