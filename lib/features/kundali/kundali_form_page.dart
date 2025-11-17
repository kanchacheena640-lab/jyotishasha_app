import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/features/kundali/kundali_detail_page.dart';

/// 👥 Form to generate Kundali for others
class KundaliFormPage extends StatefulWidget {
  const KundaliFormPage({super.key});

  @override
  State<KundaliFormPage> createState() => _KundaliFormPageState();
}

class _KundaliFormPageState extends State<KundaliFormPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final tobCtrl = TextEditingController();
  final pobCtrl = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    dobCtrl.dispose();
    tobCtrl.dispose();
    pobCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateKundali() async {
    setState(() => isLoading = true);
    const apiUrl =
        "https://jyotishasha-backend.onrender.com/api/full-kundali-modern";

    final body = {
      "name": nameCtrl.text,
      "dob": dobCtrl.text,
      "tob": tobCtrl.text,
      "place_name": pobCtrl.text,
      "lat": 26.85, // TODO: connect geocoding API later
      "lng": 80.95,
      "timezone": "+05:30",
      "ayanamsa": "Lahiri",
      "language": "en",
    };

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final kundaliData = jsonDecode(res.body);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KundaliDetailPage(data: kundaliData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate Kundali")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Enter Birth Details"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dobCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialDate: DateTime(2000),
                  );
                  if (d != null) {
                    dobCtrl.text = d.toIso8601String().split('T').first;
                  }
                },
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tobCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Time of Birth",
                  prefixIcon: Icon(Icons.access_time_outlined),
                ),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (t != null) {
                    tobCtrl.text =
                        "${t.hour}:${t.minute.toString().padLeft(2, '0')}";
                  }
                },
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pobCtrl,
                decoration: const InputDecoration(
                  labelText: "Place of Birth",
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _generateKundali();
                        }
                      },
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text(
                        "Generate Kundali",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
