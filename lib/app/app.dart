import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';
import 'package:jyotishasha_app/app/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class JyotishashaApp extends StatelessWidget {
  const JyotishashaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLang;

    return MaterialApp.router(
      title: 'Jyotishasha',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // ⭐ LANGUAGE APPLY HERE
      locale: Locale(lang),
      supportedLocales: const [Locale('en'), Locale('hi')],

      // ❌ const hata diya
      localizationsDelegates: [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: appRouter,
    );
  }
}
