import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/cards/card_contracts.dart';
import '../card_repository.dart';

final class HttpCardRepository implements CardRepository {
  HttpCardRepository({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    'https://jyotishasha-backend.onrender.com/api/cards',
  );
  final http.Client _client;

  @override
  Future<CardFeedResponse> getCardFeed({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client
        .post(
          _endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'lat': latitude, 'lng': longitude}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const CardFeedResponse(cards: []);
    return CardFeedResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
