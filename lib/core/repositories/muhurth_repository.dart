import '../models/muhurth/muhurth_contracts.dart';

/// Purpose: owns Muhurth result retrieval for pages and card composition.
///
/// Responsibilities: resolve a canonical Muhurth request into a canonical
/// response shared by all consumers.
///
/// Excluded responsibilities: location selection, card composition, cache UI,
/// HTTP code, and presentation state.
///
/// Future implementation owner: ESR-003 Muhurth repository implementation.
abstract interface class MuhurthRepository {
  Future<MuhurthResponse> getMuhurth(MuhurthRequest request);
}
