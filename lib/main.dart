import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'dart:io';

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
import 'services/play_billing_stub.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:jyotishasha_app/features/love/providers/love_provider.dart';
import 'package:jyotishasha_app/core/state/monthly_provider.dart';
import 'package:jyotishasha_app/core/state/yearly_provider.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';

class ForceIPv4 extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => "DIRECT";
    return client;
  }
}

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

BuildContext? globalKundaliContext;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global =
      ForceIPv4(); // ⭐ to avoid IPv6 error occuring in love api

  // await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  await PlayBillingStub.init();

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
        ChangeNotifierProvider(create: (_) => MonthlyProvider()),
        ChangeNotifierProvider(create: (_) => YearlyProvider()),
        ChangeNotifierProvider(create: (_) => PanchangProvider()),
        ChangeNotifierProvider(create: (_) => TransitProvider()),
        ChangeNotifierProvider(create: (_) => LoveProvider()),

        ChangeNotifierProvider(
          lazy: false,
          create: (_) {
            final p = AskNowProvider();
            p.initBilling(); // ✅ YAHAN CALL
            return p;
          },
        ),
      ],
      child: const JyotishashaApp(),
    ),
  );
}
