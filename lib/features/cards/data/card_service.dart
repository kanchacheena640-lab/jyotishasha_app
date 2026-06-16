import 'dart:convert';
import 'package:http/http.dart' as http;

import 'card_model.dart';

class CardService {
  static const String baseUrl =
      "https://jyotishasha-backend.onrender.com/api/cards";

  static Future<List<CardModel>> fetchCards({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"lat": lat, "lng": lng}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      if (data == null || data["cards"] == null) {
        return [];
      }

      final List list = data["cards"];

      return list
          .where((e) => e != null)
          .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
