import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/events/event_resource_contracts.dart';
import '../event_repository.dart';

final class HttpEventRepository implements EventRepository {
  HttpEventRepository({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  final http.Client _client;

  @override
  Future<EventResourceResponse> getEventResource({
    required int eventId,
    required String language,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/events/$eventId/resource',
    ).replace(queryParameters: {'lang': language});

    // Release-gate fix (P0): bounds a previously-unbounded request; a
    // TimeoutException propagates to this method's caller exactly like
    // the existing thrown Exception below already does.
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Event resource API error ${response.statusCode}');
    }

    return EventResourceResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
