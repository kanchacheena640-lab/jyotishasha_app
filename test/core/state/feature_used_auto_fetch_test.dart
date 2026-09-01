import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jyotishasha_app/core/analytics/activity_events.dart';
import 'package:jyotishasha_app/core/identity/current_user_identity_port.dart';
import 'package:jyotishasha_app/core/models/horoscope/horoscope_contracts.dart';
import 'package:jyotishasha_app/core/models/panchang/panchang_contracts.dart';
import 'package:jyotishasha_app/core/repositories/horoscope_repository.dart';
import 'package:jyotishasha_app/core/repositories/panchang_repository.dart';
import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/state/panchang_provider.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

class _FakeIdentityPort implements CurrentUserIdentityPort {
  const _FakeIdentityPort();
  @override
  String? get currentFirebaseUid => 'test-uid';
}

class _FakeHoroscopeRepository implements HoroscopeRepository {
  int dailyCallCount = 0;
  bool shouldFail = false;

  @override
  Future<DailyHoroscope> getDailyHoroscope(HoroscopeQuery query) async {
    dailyCallCount++;
    if (shouldFail) throw Exception('network down');
    return const DailyHoroscope(
      heading: 'h',
      intro: 'i',
      paragraph: 'p',
      tips: 't',
      luckyColor: 'red',
      luckyNumber: '7',
    );
  }

  @override
  Future<MonthlyHoroscope> getMonthlyHoroscope(HoroscopeQuery query) =>
      throw UnimplementedError();

  @override
  Future<YearlyHoroscope> getYearlyHoroscope(HoroscopeQuery query) =>
      throw UnimplementedError();

  @override
  Future<PersonalizedHoroscopeResponse> getPersonalizedDaily(int profileId) =>
      throw UnimplementedError();

  @override
  Future<PersonalizedHoroscopeResponse> getPersonalizedTomorrow(int profileId) =>
      throw UnimplementedError();

  @override
  Future<PersonalizedHoroscopeResponse> getPersonalizedWeekly(int profileId) =>
      throw UnimplementedError();
}

class _FakePanchangRepository implements PanchangRepository {
  int callCount = 0;

  @override
  Future<PanchangResponse> getPanchang(PanchangRequest request) async {
    callCount++;
    return const PanchangResponse(
      selectedDate: PanchangDay(sunrise: '06:00', sunset: '18:00'),
      nextDate: PanchangDay(sunrise: '06:01', sunset: '18:01'),
    );
  }
}

/// Phase 5B foundation tests -- feature_used producer semantics for the
/// auto-fetch representative features (DailyProvider/PanchangProvider;
/// MonthlyProvider/YearlyProvider follow the byte-for-byte identical
/// `_lastSign`/`_lastLang` cache-guard pattern, verified by code
/// inspection in the final report rather than duplicated here).
void main() {
  late List<http.Request> captured;

  setUp(() {
    captured = <http.Request>[];
    final mockClient = MockClient((request) async {
      captured.add(request);
      return http.Response('{"status":"written","event_id":"x"}', 201);
    });
    ActivityEvents.debugOverrideClient(
      ActivityEventClient(
        httpClient: mockClient,
        identityPort: const _FakeIdentityPort(),
        tokenProvider: (firebaseUid, {client}) async => 'fake-token',
      ),
    );
  });

  tearDown(() {
    ActivityEvents.debugResetClient();
  });

  // Every provider call below fires ActivityEvents.featureUsed(...)
  // fire-and-forget (never awaited internally, by design -- analytics
  // must never make product code wait). A short settle here just gives
  // that already-in-flight Future a turn to actually reach the mock
  // client before this test asserts on `captured` -- it is not masking
  // a real timing dependency in production code, which never awaits it
  // either.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

  group('DailyProvider (feature_name=horoscope_daily)', () {
    test('successful first fetch -> exactly one feature_used', () async {
      final provider = DailyProvider(horoscopeRepository: _FakeHoroscopeRepository());
      await provider.fetchDaily(sign: 'aries', lang: 'en');
      await settle();
      expect(captured, hasLength(1));
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['event_name'], 'feature_used');
      expect(body['properties'], {'feature_name': 'horoscope_daily'});
    });

    test(
      'a cache-hit re-fetch (same sign/lang, not forced) -> no duplicate '
      'event and no second network call',
      () async {
        final repo = _FakeHoroscopeRepository();
        final provider = DailyProvider(horoscopeRepository: repo);
        await provider.fetchDaily(sign: 'aries', lang: 'en');
        await settle();
        await provider.fetchDaily(sign: 'aries', lang: 'en');
        await settle();
        expect(repo.dailyCallCount, 1, reason: 'cache guard must skip the network call');
        expect(captured, hasLength(1), reason: 'no duplicate feature_used');
      },
    );

    test('a genuinely new fetch (different sign) -> a second event', () async {
      final provider = DailyProvider(horoscopeRepository: _FakeHoroscopeRepository());
      await provider.fetchDaily(sign: 'aries', lang: 'en');
      await settle();
      await provider.fetchDaily(sign: 'leo', lang: 'en');
      await settle();
      expect(captured, hasLength(2));
    });

    test('a failed fetch -> no feature_used at all', () async {
      final repo = _FakeHoroscopeRepository()..shouldFail = true;
      final provider = DailyProvider(horoscopeRepository: repo);
      await provider.fetchDaily(sign: 'aries', lang: 'en');
      await settle();
      expect(captured, isEmpty);
    });

    test('notifyListeners()/rebuild alone never produces an event', () async {
      final provider = DailyProvider(horoscopeRepository: _FakeHoroscopeRepository());
      await provider.fetchDaily(sign: 'aries', lang: 'en');
      await settle();
      captured.clear();
      // Simulates a widget rebuild reading the provider's already-set
      // fields -- no fetchDaily() call, so nothing should fire.
      provider.notifyListeners();
      await settle();
      expect(captured, isEmpty);
    });
  });

  group('PanchangProvider (feature_name=panchang_view)', () {
    test('successful fetchPanchang -> exactly one feature_used', () async {
      final provider = PanchangProvider(panchangRepository: _FakePanchangRepository());
      await provider.fetchPanchang(lat: 1, lng: 1, lang: 'en');
      await settle();
      expect(captured, hasLength(1));
      final body = jsonDecode(captured.single.body) as Map<String, dynamic>;
      expect(body['properties'], {'feature_name': 'panchang_view'});
    });

    test('a second explicit fetchPanchang call -> a second event (this '
        'method has no cache guard of its own; loadPanchang() is the '
        'cache-guarded entry point production code actually calls)', () async {
      final provider = PanchangProvider(panchangRepository: _FakePanchangRepository());
      await provider.fetchPanchang(lat: 1, lng: 1, lang: 'en');
      await settle();
      await provider.fetchPanchang(lat: 1, lng: 1, lang: 'en');
      await settle();
      expect(captured, hasLength(2));
    });

    test(
      'loadPanchang() (the production cache-guarded seam) -> a same-day '
      're-entry is a no-op, no duplicate event',
      () async {
        final repo = _FakePanchangRepository();
        final provider = PanchangProvider(panchangRepository: repo);
        await provider.loadPanchang(lat: 1, lng: 1, lang: 'en');
        await settle();
        await provider.loadPanchang(lat: 1, lng: 1, lang: 'en');
        await settle();
        expect(repo.callCount, 1);
        expect(captured, hasLength(1));
      },
    );
  });
}
