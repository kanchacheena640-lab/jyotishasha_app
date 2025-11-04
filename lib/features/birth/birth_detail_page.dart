import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BirthDetailPage extends StatelessWidget {
  const BirthDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Birth Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: "Full Name"),
            ),
            const TextField(
              decoration: InputDecoration(labelText: "Date of Birth"),
            ),
            const TextField(
              decoration: InputDecoration(labelText: "Time of Birth"),
            ),
            const TextField(
              decoration: InputDecoration(labelText: "Place of Birth"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
