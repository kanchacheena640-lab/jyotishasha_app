import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Oops! Something went wrong.\nCheck your internet or try again.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        ),
      ),
    );
  }
}
