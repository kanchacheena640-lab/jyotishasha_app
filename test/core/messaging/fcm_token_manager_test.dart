import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:jyotishasha_app/core/messaging/fcm_token_manager.dart';

import '../../mocks/common_mocks.dart';

NotificationSettings _settings(AuthorizationStatus status) =>
    NotificationSettings(
      authorizationStatus: status,
      alert: AppleNotificationSetting.notSupported,
      announcement: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.notSupported,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.notSupported,
      notificationCenter: AppleNotificationSetting.notSupported,
      showPreviews: AppleShowPreviewSetting.never,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.notSupported,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );

void main() {
  late MockFirebaseMessaging messaging;
  late MockNotificationRepository notificationRepository;
  late MockUserRepository userRepository;
  late StreamController<String> refreshController;
  late StreamController<String?> authStateController;

  FcmTokenManager buildManager({
    String? Function()? currentUidProvider,
    Duration? initialBackoff,
  }) {
    return FcmTokenManager(
      messaging: messaging,
      notificationRepository: notificationRepository,
      userRepository: userRepository,
      currentUidProvider: currentUidProvider ?? () => 'uid-123',
      authStateUidChanges: authStateController.stream,
      initialBackoff: initialBackoff ?? const Duration(milliseconds: 1),
    );
  }

  setUp(() {
    messaging = MockFirebaseMessaging();
    notificationRepository = MockNotificationRepository();
    userRepository = MockUserRepository();
    refreshController = StreamController<String>.broadcast();
    authStateController = StreamController<String?>.broadcast();

    when(
      () => messaging.onTokenRefresh,
    ).thenAnswer((_) => refreshController.stream);
    when(() => messaging.subscribeToTopic(any())).thenAnswer((_) async {});
    when(
      () => messaging.unsubscribeFromTopic(any()),
    ).thenAnswer((_) async {});
    when(() => messaging.deleteToken()).thenAnswer((_) async {});
    when(
      () => notificationRepository.registerDeviceToken(any()),
    ).thenAnswer((_) async {});
    when(
      () => userRepository.updateMessagingToken(
        firebaseUid: any(named: 'firebaseUid'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await refreshController.close();
    await authStateController.close();
  });

  group('authentication-ready sync', () {
    test('permission denied: never calls getToken or uploads', () async {
      when(
        () => messaging.requestPermission(),
      ).thenAnswer((_) async => _settings(AuthorizationStatus.denied));

      buildManager().start();
      authStateController.add('uid-123');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => messaging.getToken());
      verifyNever(() => notificationRepository.registerDeviceToken(any()));
    });

    test('getToken returns null: uploads nothing', () async {
      when(
        () => messaging.requestPermission(),
      ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
      when(() => messaging.getToken()).thenAnswer((_) async => null);

      buildManager().start();
      authStateController.add('uid-123');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => notificationRepository.registerDeviceToken(any()));
    });

    test(
      'authentication becoming ready always uploads the current token, '
      'with no cache or comparison to skip it',
      () async {
        when(
          () => messaging.requestPermission(),
        ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
        when(() => messaging.getToken()).thenAnswer((_) async => 'token-new');

        buildManager().start();
        authStateController.add('uid-123');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => notificationRepository.registerDeviceToken('token-new'),
        ).called(1);
        verify(
          () => userRepository.updateMessagingToken(
            firebaseUid: 'uid-123',
            token: 'token-new',
          ),
        ).called(1);
        verify(() => messaging.subscribeToTopic('general_0')).called(1);
      },
    );

    test(
      'every authenticated session start uploads unconditionally, even if '
      'the token is identical to a previously synced one',
      () async {
        when(
          () => messaging.requestPermission(),
        ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
        when(() => messaging.getToken()).thenAnswer((_) async => 'token-same');

        buildManager().start();
        authStateController.add('uid-123');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        authStateController.add(null);
        authStateController.add('uid-123');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => notificationRepository.registerDeviceToken('token-same'),
        ).called(2);
      },
    );

    test('no authenticated user: skips without calling the repository', () async {
      when(
        () => messaging.requestPermission(),
      ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
      when(() => messaging.getToken()).thenAnswer((_) async => 'token-new');

      buildManager(currentUidProvider: () => null).start();
      authStateController.add('uid-123');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => notificationRepository.registerDeviceToken(any()));
    });

    test('a null auth-state emission (signed out) triggers no sync', () async {
      when(
        () => messaging.requestPermission(),
      ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
      when(() => messaging.getToken()).thenAnswer((_) async => 'token-new');

      buildManager().start();
      authStateController.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => messaging.getToken());
      verifyNever(() => notificationRepository.registerDeviceToken(any()));
    });
  });

  group('retry with backoff', () {
    test(
      'eventually succeeds after transient failures, without exceeding max attempts',
      () async {
        var callCount = 0;
        when(() => notificationRepository.registerDeviceToken(any())).thenAnswer((
          _,
        ) async {
          callCount++;
          if (callCount < 3) {
            throw Exception('transient network error');
          }
        });
        when(
          () => messaging.requestPermission(),
        ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
        when(() => messaging.getToken()).thenAnswer((_) async => 'token-x');

        buildManager().start();
        authStateController.add('uid-123');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(callCount, 3);
      },
    );

    test(
      'gives up after the maximum number of attempts instead of retrying forever',
      () async {
        when(
          () => notificationRepository.registerDeviceToken(any()),
        ).thenThrow(Exception('backend permanently unavailable'));
        when(
          () => messaging.requestPermission(),
        ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));
        when(() => messaging.getToken()).thenAnswer((_) async => 'token-x');

        buildManager().start();
        authStateController.add('uid-123');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(
          () => notificationRepository.registerDeviceToken('token-x'),
        ).called(4); // _maxAttempts
      },
    );
  });

  group('start() / onTokenRefresh', () {
    test(
      'a Firebase-issued token refresh triggers an upload of the new token',
      () async {
        buildManager().start();

        refreshController.add('refreshed-token');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => notificationRepository.registerDeviceToken('refreshed-token'),
        ).called(1);
        verify(
          () => userRepository.updateMessagingToken(
            firebaseUid: 'uid-123',
            token: 'refreshed-token',
          ),
        ).called(1);
      },
    );

    test('calling start() twice only registers one listener', () async {
      final manager = buildManager();
      manager.start();
      manager.start();

      refreshController.add('token-once');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        () => notificationRepository.registerDeviceToken('token-once'),
      ).called(1);
    });
  });

  group('clearOnLogout', () {
    test('unsubscribes from the topic and deletes the device token', () async {
      await buildManager().clearOnLogout();

      verify(() => messaging.unsubscribeFromTopic('general_0')).called(1);
      verify(() => messaging.deleteToken()).called(1);
    });

    test(
      'a failure unsubscribing does not prevent the token from still being deleted',
      () async {
        when(
          () => messaging.unsubscribeFromTopic(any()),
        ).thenThrow(Exception('topic error'));

        await buildManager().clearOnLogout();

        verify(() => messaging.deleteToken()).called(1);
      },
    );
  });
}
