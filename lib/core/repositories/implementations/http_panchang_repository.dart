import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/panchang/panchang_contracts.dart';
import '../panchang_repository.dart';

final class HttpPanchangRepository implements PanchangRepository {
  HttpPanchangRepository({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    'https://jyotishasha-backend.onrender.com/api/panchang',
  );

  final http.Client _client;

  @override
  Future<PanchangResponse> getPanchang(PanchangRequest request) async {
    // Release-gate fix (P0): bounds a previously-unbounded request; a
    // TimeoutException propagates to this method's caller exactly like
    // the existing thrown Exception below already does.
    final response = await _client
        .post(
          _endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Panchang API error ${response.statusCode}');
    }
    return PanchangResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
