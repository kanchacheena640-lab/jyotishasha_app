import '../models/kundali/kundali_contracts.dart';

/// Purpose: owns Kundali generation as a domain data boundary.
///
/// Responsibilities: accept the canonical Kundali request and return the
/// canonical Kundali response without exposing a transport mechanism.
///
/// Excluded responsibilities: profile selection, caching policy, UI state,
/// HTTP serialization, and Firebase access.
///
/// Future implementation owner: ESR-003 Kundali repository implementation.
abstract interface class KundaliRepository {
  Future<KundaliResponse> generateKundali(KundaliRequest request);
}
