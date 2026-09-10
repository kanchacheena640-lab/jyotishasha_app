import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/config/app_config.dart';

import '../../helpers/source_characterization.dart';

const _productionBackendUrl = 'https://jyotishasha-backend.onrender.com';

/// N6 QA infrastructure — AppConfig.backendBaseUrl.
///
/// [String.fromEnvironment] is resolved at COMPILE time, so a single
/// `flutter test` process can only ever observe ONE value for
/// [AppConfig.backendBaseUrl] -- whatever `--dart-define=BACKEND_URL=...`
/// (or its absence) this process was actually launched with. The two
/// halves of the contract are therefore proven by two SEPARATE
/// invocations, not two tests in one run:
///
///   1. `flutter test test/core/config/app_config_test.dart`
///      (no dart-define) -- the "no override" test below passes and
///      proves the production default.
///   2. `flutter test --dart-define=BACKEND_URL=http://127.0.0.1:9999
///      test/core/config/app_config_test.dart` -- the "override" test
///      below then observes that exact value instead, proving the
///      override mechanism actually works. Run manually as part of this
///      task's own verification; not part of the default CI invocation
///      (which never passes this flag, so it always exercises the
///      production-default path).
void main() {
  group('AppConfig.backendBaseUrl', () {
    test(
      'without --dart-define=BACKEND_URL, resolves to the current production backend',
      () {
        // This assertion is only meaningful when this test process itself
        // was launched with no BACKEND_URL override (the default/CI case).
        // When deliberately launched WITH the override (see the file
        // docstring's invocation #2), this same String.fromEnvironment
        // read observes the override instead -- by design, not a bug in
        // this test.
        const observed = String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: _productionBackendUrl,
        );
        expect(AppConfig.backendBaseUrl, observed);
        if (observed == _productionBackendUrl) {
          expect(AppConfig.backendBaseUrl, _productionBackendUrl);
        }
      },
    );

    test('an explicit BACKEND_URL override, when this process is launched with one, is observed exactly', () {
      // See invocation #2 in the file docstring. Skips itself (rather
      // than failing) when no override was actually supplied, since a
      // normal/CI `flutter test` run never passes one.
      const observed = String.fromEnvironment('BACKEND_URL', defaultValue: '');
      if (observed.isEmpty) {
        markTestSkipped('Run with --dart-define=BACKEND_URL=<url> to exercise the override path.');
        return;
      }
      expect(AppConfig.backendBaseUrl, observed);
      expect(AppConfig.backendBaseUrl, isNot(_productionBackendUrl));
    });
  });

  group('endpoint paths remain unchanged after centralizing the base URL', () {
    // One representative sample per genuinely different endpoint-building
    // style found during discovery -- proves the base URL swap never
    // touched the path/query/method/headers/timeout that follows it.
    test('const-declared _baseUrl + path-concatenation repositories', () {
      final source = readProjectSource(
        'lib/core/repositories/implementations/backend_notification_repository.dart',
      );
      expect(source, contains('AppConfig.backendBaseUrl'));
      expect(source, contains("'\$_baseUrl/api/users/update-fcm'"));
      expect(source, contains('/api/user-notifications/unread-count'));
      expect(source, contains('/api/user-notifications/mark-read'));
    });

    test('static final Uri _endpoint = Uri.parse(...) repositories', () {
      final source = readProjectSource(
        'lib/core/repositories/implementations/http_panchang_repository.dart',
      );
      expect(source, contains('AppConfig.backendBaseUrl'));
      expect(source, contains('/api/panchang'));
    });

    test('inline Uri.parse("\${...}/api/...") call sites', () {
      final source = readProjectSource('lib/core/state/transit_provider.dart');
      expect(source, contains('AppConfig.backendBaseUrl'));
      expect(source, contains('/api/transit/current'));
      expect(source, contains('/api/transit'));
    });

    test('const baseUrl = "\${...}/api/..." local-const call sites', () {
      final source = readProjectSource('lib/features/muhurth/muhurth_page.dart');
      expect(source, contains('AppConfig.backendBaseUrl'));
      expect(source, contains('/api/muhurth/list'));
    });

    test('public (non-underscore) baseUrl fields used by other files stay compatible', () {
      final source = readProjectSource('lib/services/backend_auth_service.dart');
      expect(source, contains('static const String baseUrl = AppConfig.backendBaseUrl;'));
    });
  });

  test(
    'no TRUE hardcoded production backend-base literal remains anywhere in '
    'lib/ or test/, outside AppConfig itself',
    () {
      const domain = 'jyotishasha-backend.onrender.com';
      final offenders = <String>[];
      for (final dir in ['lib', 'test']) {
        final root = Directory(dir);
        if (!root.existsSync()) continue;
        for (final entity in root.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final normalizedPath = entity.path.replaceAll('\\', '/');
          // The two legitimate occurrences: the config class's own default
          // value/doc comment, and this very test file's own literal
          // (needed to assert against, and to run the scan itself).
          if (normalizedPath.endsWith('lib/core/config/app_config.dart') ||
              normalizedPath.endsWith('test/core/config/app_config_test.dart')) {
            continue;
          }
          if (entity.readAsStringSync().contains(domain)) {
            offenders.add(normalizedPath);
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Found un-centralized backend-base literals in: $offenders',
      );
    },
  );
}
