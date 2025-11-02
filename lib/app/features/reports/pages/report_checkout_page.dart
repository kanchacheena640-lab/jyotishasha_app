import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/services/payment_service.dart'; // ✅ import added

class ReportCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> report;
  const ReportCheckoutPage({super.key, required this.report});

  @override
  State<ReportCheckoutPage> createState() => _ReportCheckoutPageState();
}

class _ReportCheckoutPageState extends State<ReportCheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController(text: "Your Name");
  final _dob = TextEditingController(text: "01 Jan 2000");
  final _tob = TextEditingController(text: "10:00 AM");
  final _pob = TextEditingController(text: "Lucknow");
  String language = 'English';
  bool forOther = false;

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _tob.dispose();
    _pob.dispose();
    super.dispose();
  }

  void _handlePay() {
    if (!_formKey.currentState!.validate()) return;

    final form = {
      "name": _name.text.trim(),
      "dob": _dob.text.trim(),
      "tob": _tob.text.trim(),
      "pob": _pob.text.trim(),
      "language": language,
    };

    PaymentService.startPayment(
      context: context,
      report: widget.report,
      form: form,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Scaffold(
      appBar: AppBar(title: Text("Buy ${report['title']}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📘 Info note
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Your birth details are pre-filled from your profile.\n"
                  "If buying for someone else, toggle below to edit them.",
                  style: TextStyle(color: Colors.deepPurple, height: 1.4),
                ),
              ),

              // Toggle switch
              SwitchListTile(
                title: const Text("Buying for someone else?"),
                value: forOther,
                onChanged: (v) => setState(() => forOther = v),
              ),
              const SizedBox(height: 8),

              // Editable fields
              TextFormField(
                controller: _name,
                readOnly: !forOther,
                validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dob,
                readOnly: !forOther,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter date of birth" : null,
                decoration: const InputDecoration(labelText: "Date of Birth"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tob,
                readOnly: !forOther,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter time of birth" : null,
                decoration: const InputDecoration(labelText: "Time of Birth"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pob,
                readOnly: !forOther,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter place of birth" : null,
                decoration: const InputDecoration(labelText: "Place of Birth"),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField(
                value: language,
                decoration: const InputDecoration(labelText: "Language"),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Hindi', child: Text('हिंदी')),
                ],
                onChanged: (v) => setState(() => language = v!),
              ),

              const SizedBox(height: 24),

              // Pay button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _handlePay,
                  label: Text("Proceed to Pay ₹${report['price']}"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
