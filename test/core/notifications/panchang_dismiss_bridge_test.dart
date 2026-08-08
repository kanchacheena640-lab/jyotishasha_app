import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/notifications/panchang_dismiss_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('jyotishasha.app/panchang_notification');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  List<MethodCall> calls = [];

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'a dismiss_panchang message with a tag invokes dismissByTag with that tag',
    () async {
      final bridge = PanchangDismissBridge(channel: channel);

      await bridge.maybeDismiss(
        const RemoteMessage(
          data: {'action': 'dismiss_panchang', 'tag': 'panchang_morning'},
        ),
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'dismissByTag');
      expect(calls.single.arguments, {'tag': 'panchang_morning'});
    },
  );

  test('any other action is a no-op — the native channel is never called', () async {
    final bridge = PanchangDismissBridge(channel: channel);

    await bridge.maybeDismiss(
      const RemoteMessage(
        data: {'type': 'festival', 'event_id': '42'},
      ),
    );
    await bridge.maybeDismiss(
      const RemoteMessage(data: {'type': 'panchang', 'event_id': '7'}),
    );
    await bridge.maybeDismiss(const RemoteMessage(data: {}));

    expect(calls, isEmpty);
  });

  test(
    'a dismiss_panchang message without a tag is a no-op — never calls the channel',
    () async {
      final bridge = PanchangDismissBridge(channel: channel);

      await bridge.maybeDismiss(
        const RemoteMessage(data: {'action': 'dismiss_panchang'}),
      );
      await bridge.maybeDismiss(
        const RemoteMessage(data: {'action': 'dismiss_panchang', 'tag': ''}),
      );

      expect(calls, isEmpty);
    },
  );
}
