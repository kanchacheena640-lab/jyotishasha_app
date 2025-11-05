import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jyotishasha_app/app/app.dart'; // ✅ single entry app widget

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Auth / Firestore / FCM

  runApp(const JyotishashaApp()); // ✅ clean entry point
}
