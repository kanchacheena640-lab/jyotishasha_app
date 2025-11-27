import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class ReportCheckoutPage extends StatefulWidget {
  final dynamic report;
  const ReportCheckoutPage({super.key, required this.report});

  @override
  State<ReportCheckoutPage> createState() => _ReportCheckoutPageState();
}

class _ReportCheckoutPageState extends State<ReportCheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  String name = "",
      email = "",
      phone = "",
      dob = "",
      tob = "",
      pob = "",
      language = "en";

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report["title"]),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFEEFF5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                t.checkout_fill_details,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A148C),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                decoration: InputDecoration(labelText: t.checkout_name),
                onChanged: (v) => name = v,
                validator: (v) => v!.isEmpty ? t.checkout_name_error : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                decoration: InputDecoration(labelText: t.checkout_email),
                onChanged: (v) => email = v,
                validator: (v) => v!.isEmpty ? t.checkout_email_error : null,
              ),
              const SizedBox(height: 12),

              // Phone
              TextFormField(
                decoration: InputDecoration(labelText: t.checkout_phone),
                keyboardType: TextInputType.phone,
                onChanged: (v) => phone = v,
              ),
              const SizedBox(height: 12),

              // DOB
              TextFormField(
                decoration: InputDecoration(labelText: t.checkout_dob),
                onChanged: (v) => dob = v,
              ),
              const SizedBox(height: 12),

              // TOB
              TextFormField(
                decoration: InputDecoration(labelText: t.checkout_tob),
                onChanged: (v) => tob = v,
              ),
              const SizedBox(height: 12),

              // POB
              TextFormField(
                decoration: InputDecoration(labelText: t.checkout_pob),
                onChanged: (v) => pob = v,
              ),
              const SizedBox(height: 12),

              // Language Dropdown
              DropdownButtonFormField<String>(
                value: language,
                decoration: InputDecoration(labelText: t.checkout_language),
                items: [
                  DropdownMenuItem(
                    value: "en",
                    child: Text(t.checkout_language_en),
                  ),
                  DropdownMenuItem(
                    value: "hi",
                    child: Text(t.checkout_language_hi),
                  ),
                ],
                onChanged: (v) => setState(() => language = v ?? "en"),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.checkout_submit_success)),
                      );
                    }
                  },
                  child: Text(
                    t.checkout_proceed_pay(widget.report["price"].toString()),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
