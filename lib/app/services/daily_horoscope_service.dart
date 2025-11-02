import 'dart:convert';
import 'package:http/http.dart' as http;

class DailyHoroscopeService {
  final String baseUrl = "https://jyotishasha.pythonanywhere.com";

  Future<Map<String, dynamic>?> fetchDailyHoroscope(String uid) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/personalized/daily?uid=$uid"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print("Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching daily horoscope: $e");
      return null;
    }
  }
}
