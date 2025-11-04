import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class JyotishashaApp extends StatelessWidget {
  const JyotishashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Jyotishasha',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
