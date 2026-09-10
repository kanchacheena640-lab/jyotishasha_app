import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/state/notification_provider.dart';

import '../helpers/source_characterization.dart';

void main() {
  group('notification characterization', () {
    test('increment and reset update count and notify listeners', () {
      final provider = NotificationProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.increment();
      expect(provider.unreadCount, 1);
      provider.reset();
      expect(provider.unreadCount, 0);
      expect(notifications, 2);
    });

    test('unread loading preserves success and error transitions', () {
      final source = normalizeWhitespace(
        readProjectSource('lib/core/state/notification_provider.dart'),
      );

      expectMarkersInOrder(source, const [
        'isLoading = true;',
        'final count = await NotificationService.getUnreadCount();',
        'unreadCount = count;',
        'isLoading = false;',
      ]);
      expect(source, contains('catch (e) { isLoading = false;'));
    });

    test('API fallbacks, shapes, and mark-read payload stay fixed', () {
      final service = readProjectSource(
        'lib/services/notification_service.dart',
      );
      final contracts = readProjectSource(
        'lib/core/models/notifications/notification_contracts.dart',
      );
      final repository = readProjectSource(
        'lib/core/repositories/implementations/backend_notification_repository.dart',
      );

      expect(service, contains('static Future<int> getUnreadCount() async'));
      expect(service, contains('static Future<List> getNotifications() async'));
      // N6 -- widened from `int notificationId` to the backend's own
      // composite Bell identity (`"ab:<int>"` / `"cc:<uuid>"`), sent
      // verbatim; see notification_repository.dart's own docstring.
      expect(service, contains('static Future<void> markAsRead(String itemId) async'));
      expect(service, contains('if (user == null)'));
      expect(service, contains('if (token == null)'));
      expect(service, contains('return 0;'));
      expect(service, contains('return [];'));
      expect(service, contains('catch (e) {'));
      expect(service, contains('await _repository.markAsRead('));
      expect(service, isNot(contains('data["unread_count"] ?? 0')));
      expect(service, isNot(contains('data["notifications"]')));

      expect(contracts, contains("json['unread_count'] ?? json['unreadCount']"));
      expect(contracts, contains('final list = json is List'));
      expect(contracts, contains("asJsonMap(json)?['notifications'] as List?"));
      // N6 -- `item_id` (the composite Bell id) wins when present; the
      // legacy `notification_id` shape is kept only as a fallback.
      expect(contracts, contains("? {'item_id': itemId}"));
      expect(contracts, contains(": {'notification_id': notificationId};"));

      expect(repository, contains('body: jsonEncode(request.toJson())'));
      expect(
        repository,
        contains('body: jsonEncode(request.toJson())'),
      );
    });

    test('resume, refresh, and notification-open reload unread state', () {
      final dashboard = normalizeWhitespace(
        readProjectSource('lib/features/dashboard/dashboard_home_section.dart'),
      );
      final greeting = readProjectSource(
        'lib/core/widgets/greeting_header_widget.dart',
      );

      expect(
        dashboard,
        contains(
          'if (state == AppLifecycleState.resumed) { _loadUnreadCount();',
        ),
      );
      expect(dashboard, contains('_loadUnreadCount(),'));
      expectMarkersInOrder(greeting, const [
        // N6 -- `id` (best-effort int parse) replaced by `itemId` (the
        // backend's own composite Bell identity), same reload order.
        // N6 row-tap composite-id fix -- `n["id"]` (always null for a
        // unified-list row) replaced by `n["item_id"]` (the real
        // composite id), and the direct NotificationService.markAsRead()
        // static call replaced by a thin NotificationProvider.markAsRead()
        // pass-through (a testability seam only -- same call, same
        // reload order, see NotificationProvider's own docstring).
        'await provider.markAsRead(itemId);',
        'await provider.loadUnreadCount();',
        // N5: the literal getNotifications() call was extracted into a
        // small _load() helper (defaults to NotificationService.
        // getNotifications(), overridable via NotificationPreview's new
        // testability constructor param) -- same reload-after-mark-read
        // order, same underlying call by default, source line updated.
        '_future = _load();',
      ]);
    });
  });
}
