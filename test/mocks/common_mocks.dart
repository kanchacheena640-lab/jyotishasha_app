import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import 'package:jyotishasha_app/core/repositories/event_repository.dart';
import 'package:jyotishasha_app/core/repositories/notification_repository.dart';
import 'package:jyotishasha_app/core/repositories/user_repository.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockEventRepository extends Mock implements EventRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
