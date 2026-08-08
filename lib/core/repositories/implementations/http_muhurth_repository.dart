import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/muhurth/muhurth_contracts.dart';
import '../muhurth_repository.dart';

final class HttpMuhurthRepository implements MuhurthRepository {
  HttpMuhurthRepository({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    'https://jyotishasha-backend.onrender.com/api/muhurth/list',
  );
  final http.Client _client;

  @override
  Future<MuhurthResponse> getMuhurth(MuhurthRequest request) async {
    final response = await _client.post(
      _endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Muhurth API error ${response.statusCode}');
    }
    return MuhurthResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
