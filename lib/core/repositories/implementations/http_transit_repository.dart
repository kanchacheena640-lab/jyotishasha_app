import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/transit/transit_contracts.dart';
import '../transit_repository.dart';

final class HttpTransitRepository implements TransitRepository {
  HttpTransitRepository({http.Client? client})
    : _client = client ?? http.Client();

  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';
  static const Duration _timeout = Duration(seconds: 15);
  final http.Client _client;

  @override
  Future<CurrentTransitResponse> getCurrentTransit() async {
    final data = await _getJson(Uri.parse('$_baseUrl/api/transit/current'));
    return CurrentTransitResponse.fromJson(data);
  }

  @override
  Future<TransitContentResponse> getTransitContent(
    TransitContentRequest request,
  ) async {
    final values = request.toJson()..removeWhere((_, value) => value == null);
    final uri = Uri.parse('$_baseUrl/api/transit').replace(
      queryParameters: values.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    return TransitContentResponse.fromJson(await _getJson(uri));
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Transit API error ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
