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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:jyotishasha_app/features/love/providers/love_provider.dart';
import 'package:jyotishasha_app/core/state/monthly_provider.dart';
import 'package:jyotishasha_app/core/state/yearly_provider.dart';
import 'package:jyotishasha_app/core/state/transit_provider.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';
import 'package:jyotishasha_app/core/state/subscription_provider.dart';
import 'package:jyotishasha_app/core/state/report_purchase_provider.dart';
import 'package:jyotishasha_app/core/state/welcome_gift_provider.dart';
import 'package:jyotishasha_app/core/utils/global_context.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/notifications/notification_navigation_service.dart';
import 'package:jyotishasha_app/core/notifications/panchang_dismiss_bridge.dart';
import 'package:jyotishasha_app/core/messaging/fcm_token_manager.dart';
import 'package:jyotishasha_app/app/routes/app_routes.dart';
import 'package:jyotishasha_app/features/cards/provider/cards_provider.dart';
import 'package:jyotishasha_app/core/utils/startup_timeout.dart';

class ForceIPv4 extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => "DIRECT";
    return client;
  }
}

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

/// Application-level singleton, matching the existing top-level singleton
/// pattern already used for [analytics] and `fcmTokenManager`. Owns every
/// decision about how a notification tap reaches its destination screen —
/// see [NotificationNavigationService] for the full rationale.
final notificationNavigationService = NotificationNavigationService(
  router: appRouter,
);

/// Single entry point for every notification tap (foreground-opened,
/// background-opened, and terminated/cold-start). Payload interpretation is
/// delegated to [NotificationDispatcher]; the resolved, strongly-typed
/// destination is then handed to [notificationNavigationService], which
/// alone decides whether it's safe to navigate immediately or whether the
/// tap must be queued until the router has settled — this must work for
/// the terminated/cold-start case too, where `getInitialMessage()` fires
/// before `runApp()` has built any widget tree.
void handleNotificationTap(RemoteMessage message) {
  final destination = NotificationDispatcher.parse(message);
  debugPrint("🔔 handleNotificationTap → $destination");
  notificationNavigationService.openDestination(destination);
}

/// Must be a top-level (or static) function: on Android this runs in a
/// separate background isolate that does not share `main()`'s Firebase
/// initialization, so it re-initializes Firebase itself.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint(
    "🔔 firebaseMessagingBackgroundHandler → messageId: ${message.messageId}, "
    "data: ${message.data}",
  );

  // No-op for every message except the backend's data-only
  // `dismiss_panchang` signal — see PanchangDismissBridge.
  await panchangDismissBridge.maybeDismiss(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global =
      ForceIPv4(); // ⭐ to avoid IPv6 error occuring in love api

  // await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must be registered before runApp(), and before any await that could
  // yield, per FlutterFire guidance.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Primary FCM token synchronization mechanism — must run for the whole
  // app lifetime, independent of which screen (if any) is showing.
  fcmTokenManager.start();

  // Must be listening before any notification tap can be processed below —
  // this is what lets a cold-start tap be queued safely instead of racing
  // appRouter against runApp().
  notificationNavigationService.start();

  FirebaseMessaging.onMessage.listen((message) async {
    if (globalKundaliContext != null) {
      final provider = Provider.of<NotificationProvider>(
        globalKundaliContext!,
        listen: false,
      );

      provider.increment(); // 🔥 unread +1
    }

    // No-op for every message except the backend's data-only
    // `dismiss_panchang` signal — see PanchangDismissBridge.
    await panchangDismissBridge.maybeDismiss(message);
  });

  // App backgrounded (not terminated) and user tapped the notification.
  FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationTap);

  // App was terminated and launched by tapping the notification.
  //
  // Release-gate fix (P0): bounded — this is an optional platform-channel
  // probe (was `initialMessage == null` cold-start, not a notification
  // tap), never something the rest of startup depends on. A stall or
  // thrown exception here (Play Services not yet ready, FCM not fully
  // initialized on a fresh device) must never prevent runApp() from
  // executing; on timeout/failure this just degrades to "no initial
  // message" — a completely normal, already-handled cold-start case.
  final initialMessage = await withStartupTimeout(
    () => FirebaseMessaging.instance.getInitialMessage(),
    debugLabel: 'FirebaseMessaging.getInitialMessage',
  );
  if (initialMessage != null) {
    handleNotificationTap(initialMessage);
  }

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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CardsProvider()),
        ChangeNotifierProvider(create: (_) => WelcomeGiftProvider()),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) {
            final p = SubscriptionProvider();
            p.initPurchaseListener(); // S5.2 — same eager pattern as AskNow below
            return p;
          },
        ),

        ChangeNotifierProvider(
          lazy: false,
          create: (_) {
            final p = AskNowProvider();
            p.initBilling(); // ✅ YAHAN CALL
            return p;
          },
        ),

        ChangeNotifierProvider(
          lazy: false,
          create: (_) {
            final p = ReportPurchaseProvider();
            p.initPurchaseListener(); // Report Purchase Lifecycle Architecture — same eager pattern as Subscription/AskNow above
            return p;
          },
        ),
      ],
      child: const JyotishashaApp(),
    ),
  );
}
