import 'package:flutter/material.dart';

class AddProfilePage extends StatefulWidget {
  const AddProfilePage({super.key});

  @override
  State<AddProfilePage> createState() => _AddProfilePageState();
}

class _AddProfilePageState extends State<AddProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _tobCtrl = TextEditingController();
  final TextEditingController _pobCtrl = TextEditingController();

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _dobCtrl.text = "${date.day}-${date.month}-${date.year}";
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      _tobCtrl.text = "${time.hour}:${time.minute}";
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final newProfile = {
        "name": _nameCtrl.text,
        "dob": _dobCtrl.text,
        "tob": _tobCtrl.text,
        "pob": _pobCtrl.text,
      };

      Navigator.pop(context, newProfile); // 👈 Return to ProfilePage with data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
                validator: (v) => v!.isEmpty ? "Select DOB" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tobCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Time of Birth",
                  suffixIcon: Icon(Icons.access_time),
                ),
                onTap: _pickTime,
                validator: (v) => v!.isEmpty ? "Select TOB" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pobCtrl,
                decoration: const InputDecoration(labelText: "Place of Birth"),
                validator: (v) => v!.isEmpty ? "Enter POB" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Save Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
