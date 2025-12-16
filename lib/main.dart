import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// ⭐ IMPORTANT

import 'package:jyotishasha_app/app/app.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';
import 'package:jyotishasha_app/core/state/profile_provider.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/core/state/firebase_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/manual_kundali_provider.dart';
import 'package:jyotishasha_app/core/state/asknow_provider.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';

BuildContext? globalKundaliContext;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ⭐ MUST-HAVE for ads
  // await MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..loadSavedLanguage(),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseKundaliProvider()),
        ChangeNotifierProvider(create: (_) => KundaliProvider()),
        ChangeNotifierProvider(create: (_) => ManualKundaliProvider()),
        ChangeNotifierProvider(create: (_) => DailyProvider()),
        ChangeNotifierProvider(create: (_) => PanchangProvider()),
        ChangeNotifierProvider(lazy: false, create: (_) => AskNowProvider()),
      ],
      child: const JyotishashaApp(),
    ),
  );
}
