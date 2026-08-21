import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/horoscope/horoscope_contracts.dart';
import '../horoscope_repository.dart';

final class HttpHoroscopeRepository implements HoroscopeRepository {
  HttpHoroscopeRepository({http.Client? client})
    : _client = client ?? http.Client();

  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';
  final http.Client _client;

  @override
  Future<DailyHoroscope> getDailyHoroscope(HoroscopeQuery query) async =>
      DailyHoroscope.fromJson(await _get('/api/daily-horoscope', query));

  @override
  Future<MonthlyHoroscope> getMonthlyHoroscope(HoroscopeQuery query) async =>
      MonthlyHoroscope.fromJson(await _get('/api/monthly-horoscope', query));

  @override
  Future<YearlyHoroscope> getYearlyHoroscope(HoroscopeQuery query) async =>
      YearlyHoroscope.fromJson(await _get('/api/yearly-horoscope', query));

  @override
  Future<PersonalizedHoroscopeResponse> getPersonalizedDaily(int profileId) =>
      _getPersonalized('/api/personalized/daily', profileId);

  @override
  Future<PersonalizedHoroscopeResponse> getPersonalizedTomorrow(
    int profileId,
  ) => _getPersonalized('/api/personalized/tomorrow', profileId);

  @override
  Future<PersonalizedHoroscopeResponse> getPersonalizedWeekly(int profileId) =>
      _getPersonalized('/api/personalized/weekly', profileId);

  Future<Map<String, dynamic>> _get(String path, HoroscopeQuery query) async {
    final values = query.toJson()..removeWhere((_, value) => value == null);
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: values.map(
        (key, value) => MapEntry(key, value.toString().toLowerCase().trim()),
      ),
    );
    return _getJson(uri);
  }

  Future<PersonalizedHoroscopeResponse> _getPersonalized(
    String path,
    int profileId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: {'profile_id': profileId.toString()});
    return PersonalizedHoroscopeResponse.fromJson(await _getJson(uri));
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    // Release-gate fix (P0): bounds a previously-unbounded request; a
    // TimeoutException propagates to this method's caller exactly like
    // the existing thrown Exception below already does.
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Horoscope API error ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
