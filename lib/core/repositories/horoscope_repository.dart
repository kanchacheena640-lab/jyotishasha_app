import '../models/horoscope/horoscope_contracts.dart';

/// Purpose: owns horoscope retrieval for every supported period.
///
/// Responsibilities: retrieve daily, monthly, yearly, and personalized
/// horoscope contracts and preserve their current query semantics.
///
/// Excluded responsibilities: sign/profile selection, cache presentation,
/// HTTP concerns, derived astrology logic, and widget state.
///
/// Future implementation owner: ESR-003 horoscope repository implementation.
abstract interface class HoroscopeRepository {
  Future<DailyHoroscope> getDailyHoroscope(HoroscopeQuery query);

  Future<MonthlyHoroscope> getMonthlyHoroscope(HoroscopeQuery query);

  Future<YearlyHoroscope> getYearlyHoroscope(HoroscopeQuery query);

  Future<PersonalizedHoroscopeResponse> getPersonalizedDaily(int profileId);

  Future<PersonalizedHoroscopeResponse> getPersonalizedTomorrow(int profileId);

  Future<PersonalizedHoroscopeResponse> getPersonalizedWeekly(int profileId);
}
