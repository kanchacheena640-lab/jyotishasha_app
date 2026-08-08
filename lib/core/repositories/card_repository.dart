import '../models/cards/card_contracts.dart';

/// Purpose: owns retrieval of the application card feed.
///
/// Responsibilities: obtain a typed feed for a coordinate context and expose
/// card data without revealing local-asset or remote-source mechanics.
///
/// Excluded responsibilities: card rendering, image selection, sharing,
/// Panchang provider coupling, HTTP code, and widget state.
///
/// Future implementation owner: ESR-003 card repository implementation.
abstract interface class CardRepository {
  Future<CardFeedResponse> getCardFeed({
    required double latitude,
    required double longitude,
  });
}
