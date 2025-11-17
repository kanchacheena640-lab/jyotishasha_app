import 'dart:convert';
import 'package:http/http.dart' as http;

class PersonalizedHoroscopeService {
  static const String baseUrl = "https://jyotishasha-backend.onrender.com";

  Future<Map<String, dynamic>> fetchDaily(String profileId) async {
    final url = Uri.parse(
      "$baseUrl/api/personalized/daily?profile_id=$profileId",
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["ok"] == true) {
      return data;
    } else {
      throw Exception("Failed to load daily horoscope");
    }
  }

  Future<Map<String, dynamic>> fetchTomorrow(String profileId) async {
    final url = Uri.parse(
      "$baseUrl/api/personalized/tomorrow?profile_id=$profileId",
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["ok"] == true) {
      return data;
    } else {
      throw Exception("Failed to load tomorrow horoscope");
    }
  }

  Future<Map<String, dynamic>> fetchWeekly(String profileId) async {
    final url = Uri.parse(
      "$baseUrl/api/personalized/weekly?profile_id=$profileId",
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["ok"] == true) {
      return data;
    } else {
      throw Exception("Failed to load weekly horoscope");
    }
  }
}
