import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';

class BirthDetailPage extends StatefulWidget {
  const BirthDetailPage({super.key});

  @override
  State<BirthDetailPage> createState() => _BirthDetailPageState();
}

class _BirthDetailPageState extends State<BirthDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;

  /// Function to pick birth date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Function to proceed to next screen
  void _proceed() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all details")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Birth Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Full Name", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "Enter your full name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 20),

              Text("Date of Birth", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                        : "Tap to select date",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
