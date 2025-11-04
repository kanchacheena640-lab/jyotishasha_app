import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔹 Direct import for test
import 'features/dashboard/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jyotishasha',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFF7C3AED),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFFFBBF24),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F6FB),
        textTheme: GoogleFonts.montserratTextTheme(),
      ),

      // ⚡ Test dashboard directly
      home: const DashboardPage(),
    );
  }
}
