import '../models/transit/transit_contracts.dart';

/// Purpose: owns current and personalized transit data retrieval.
///
/// Responsibilities: retrieve current transit positions and typed transit
/// content for the requested planet, house, language, and ascendant context.
///
/// Excluded responsibilities: screen initialization, alert derivation,
/// external-link navigation, HTTP code, and presentation state.
///
/// Future implementation owner: ESR-003 transit repository implementation.
abstract interface class TransitRepository {
  Future<CurrentTransitResponse> getCurrentTransit();

  Future<TransitContentResponse> getTransitContent(
    TransitContentRequest request,
  );
}
