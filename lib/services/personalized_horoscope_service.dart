import 'package:jyotishasha_app/core/models/horoscope/horoscope_contracts.dart';
import 'package:jyotishasha_app/core/repositories/horoscope_repository.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_horoscope_repository.dart';

class PersonalizedHoroscopeService {
  PersonalizedHoroscopeService({HoroscopeRepository? horoscopeRepository})
    : _horoscopeRepository =
          horoscopeRepository ?? HttpHoroscopeRepository();

  final HoroscopeRepository _horoscopeRepository;

  Future<Map<String, dynamic>> fetchDaily(String profileId) async {
    return _fetchProfileHoroscope(
      profileId: profileId,
      fetch: _horoscopeRepository.getPersonalizedDaily,
      failureMessage: "Failed to load daily horoscope",
    );
  }

  Future<Map<String, dynamic>> fetchTomorrow(String profileId) async {
    return _fetchProfileHoroscope(
      profileId: profileId,
      fetch: _horoscopeRepository.getPersonalizedTomorrow,
      failureMessage: "Failed to load tomorrow horoscope",
    );
  }

  Future<Map<String, dynamic>> fetchWeekly(String profileId) async {
    return _fetchProfileHoroscope(
      profileId: profileId,
      fetch: _horoscopeRepository.getPersonalizedWeekly,
      failureMessage: "Failed to load weekly horoscope",
    );
  }

  Future<Map<String, dynamic>> _fetchProfileHoroscope({
    required String profileId,
    required Future<PersonalizedHoroscopeResponse> Function(int profileId)
    fetch,
    required String failureMessage,
  }) async {
    final parsedProfileId = int.tryParse(profileId);
    if (parsedProfileId == null) {
      throw Exception(failureMessage);
    }

    try {
      final response = await fetch(parsedProfileId);
      if (response.ok == true) {
        return response.toJson();
      }
      throw Exception(failureMessage);
    } catch (_) {
      throw Exception(failureMessage);
    }
  }
}
