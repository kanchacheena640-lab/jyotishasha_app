import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/core/config/app_config.dart';

import '../../models/kundali/kundali_contracts.dart';
import '../kundali_repository.dart';

final class HttpKundaliRepository implements KundaliRepository {
  HttpKundaliRepository({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _endpoint = Uri.parse(
    '${AppConfig.backendBaseUrl}/api/full-kundali-modern',
  );

  final http.Client _client;

  @override
  Future<KundaliResponse> generateKundali(KundaliRequest request) async {
    final response = await _client.post(
      _endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Kundali API error ${response.statusCode}');
    }
    return KundaliResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
