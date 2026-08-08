import '../models/panchang/panchang_contracts.dart';

/// Purpose: owns Panchang retrieval and its remote data contract.
///
/// Responsibilities: resolve a typed Panchang request into a typed response.
///
/// Excluded responsibilities: clocks, reset schedules, location selection,
/// provider caching, HTTP code, and UI-derived Panchang calculations.
///
/// Future implementation owner: ESR-003 Panchang repository implementation.
abstract interface class PanchangRepository {
  Future<PanchangResponse> getPanchang(PanchangRequest request);
}
