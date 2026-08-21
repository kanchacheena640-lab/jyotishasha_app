import 'dart:convert';
import 'package:http/http.dart' as http;

import '../enums/love_tool.dart';

class LoveApiService {
  // 🔒 Same backend base URL you already use elsewhere
  static const String _baseUrl = 'https://jyotishasha-backend.onrender.com';

  Future<Map<String, dynamic>> run(
    LoveTool tool,
    Map<String, dynamic> payload,
  ) async {
    final String endpoint;

    switch (tool) {
      case LoveTool.matchMaking:
      case LoveTool.mangalDosh:
        endpoint = '/api/love/report';
        break;

      case LoveTool.truthOrDare:
        endpoint = '/api/love/truth-or-dare';
        break;

      case LoveTool.marriageProbability:
        endpoint = '/api/love/love-marriage-probability';
        break;
    }

    final uri = Uri.parse('$_baseUrl$endpoint');

    // Release-gate fix (P0): bounds a previously-unbounded request; a
    // TimeoutException propagates to this method's caller exactly like
    // the existing thrown Exceptions below already do -- no local
    // try/catch to preserve here.
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Love API failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw Exception('Invalid response from Love API');
    }

    return decoded['data'] as Map<String, dynamic>;
  }
}
