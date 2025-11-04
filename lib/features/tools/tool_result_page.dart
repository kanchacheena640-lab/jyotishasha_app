import 'package:flutter/material.dart';

class ToolResultPage extends StatefulWidget {
  final String toolName;
  const ToolResultPage({super.key, required this.toolName});

  @override
  State<ToolResultPage> createState() => _ToolResultPageState();
}

class _ToolResultPageState extends State<ToolResultPage> {
  bool _isLoading = true;
  Map<String, String>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // 🧩 TODO: Replace with ProfileService.getActiveProfile() in future
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _profile = {
        "name": "Rohit Sharma",
        "dob": "15-Aug-1995",
        "tob": "10:30 AM",
        "pob": "Mumbai, India",
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.toolName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Birth Details",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow("Name", _profile!["name"]!),
                  _buildInfoRow("Date of Birth", _profile!["dob"]!),
                  _buildInfoRow("Time of Birth", _profile!["tob"]!),
                  _buildInfoRow("Place of Birth", _profile!["pob"]!),
                  const Divider(height: 32),

                  Text(
                    "🪐 Kundali Section",
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Kundali Chart Placeholder",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    "Result Summary",
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your personalized analysis will appear here once the backend API is connected.\n\n"
                    "Example: Your Lagna is Virgo, Moon is in Leo, and your chart shows strong career growth.",
                    style: TextStyle(color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text("$label:")),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
