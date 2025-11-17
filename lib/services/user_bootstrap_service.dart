import 'dart:convert';
import 'package:http/http.dart' as http;

class UserBootstrapService {
  static const String baseUrl = "https://jyotishasha-backend.onrender.com";

  Future<Map<String, dynamic>> syncProfile(
    Map<String, dynamic> profileData,
  ) async {
    final url = Uri.parse("$baseUrl/api/user/bootstrap");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(profileData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["ok"] == true) {
      return data;
    } else {
      throw Exception("Bootstrap failed: ${data["error"]}");
    }
  }
}
