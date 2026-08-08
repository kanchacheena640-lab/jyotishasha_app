import '../models/profile/birth_details.dart';

/// Purpose: owns place search, place resolution, and timezone lookup.
///
/// Responsibilities: return location-capable ESR-002 birth-detail contracts
/// for suggestions/details and resolve timezone from coordinates.
///
/// Excluded responsibilities: form controllers, location SDK/HTTP access, API
/// keys, profile persistence, and presentation state.
///
/// Future implementation owner: ESR-003 location repository implementation.
abstract interface class LocationRepository {
  Future<List<BirthDetails>> searchPlaces(String query);

  Future<BirthDetails?> getPlaceDetails(String placeId);

  Future<String?> getTimezone({
    required double latitude,
    required double longitude,
  });
}
