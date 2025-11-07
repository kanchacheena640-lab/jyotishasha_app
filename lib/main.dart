import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:jyotishasha_app/app/app.dart';
import 'package:jyotishasha_app/core/state/kundali_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Auth / Firestore / FCM

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => KundaliProvider())],
      child: const JyotishashaApp(), // 🔮 GoRouter intact
    ),
  );
}
