import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // ⏳ Navigate to login after 3 sec
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; // ✅ Add this before using context
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_purple500_outlined,
              color: Colors.deepPurple,
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              '✨ Jyotishasha ✨',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Astrology that adapts to You',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
