import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
              Text(
                "Fill Your Details",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A148C),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                decoration: const InputDecoration(labelText: "Full Name"),
                onChanged: (v) => name = v,
                validator: (v) => v!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                onChanged: (v) => email = v,
                validator: (v) => v!.isEmpty ? "Enter your email" : null,
              ),
              const SizedBox(height: 12),

              // Phone
              TextFormField(
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
                onChanged: (v) => phone = v,
              ),
              const SizedBox(height: 12),

              // DOB
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Date of Birth (YYYY-MM-DD)",
                ),
                onChanged: (v) => dob = v,
              ),
              const SizedBox(height: 12),

              // TOB
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Time of Birth (HH:MM)",
                ),
                onChanged: (v) => tob = v,
              ),
              const SizedBox(height: 12),

              // POB
              TextFormField(
                decoration: const InputDecoration(labelText: "Place of Birth"),
                onChanged: (v) => pob = v,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: language,
                decoration: const InputDecoration(labelText: "Language"),
                items: const [
                  DropdownMenuItem(value: "en", child: Text("English")),
                  DropdownMenuItem(value: "hi", child: Text("Hindi")),
                ],
                onChanged: (v) => setState(() => language = v ?? "en"),
              ),
              const SizedBox(height: 30),

              // Button
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
                        const SnackBar(
                          content: Text(
                            "✅ Form submitted (Next: Payment setup)",
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Proceed to Pay ₹${widget.report["price"]}",
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
