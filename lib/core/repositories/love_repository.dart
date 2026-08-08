import '../models/love/love_contracts.dart';

/// Purpose: owns Love feature request dispatch and result retrieval.
///
/// Responsibilities: submit the canonical compatibility request and return a
/// typed Love result envelope for the requested tool.
///
/// Excluded responsibilities: form state, location lookup, report checkout,
/// endpoint selection in UI code, HTTP code, and navigation.
///
/// Future implementation owner: ESR-003 Love repository implementation.
abstract interface class LoveRepository {
  Future<LoveApiResponse<LoveResult>> submit(LoveCompatibilityRequest request);
}
