import 'dart:convert';
import 'package:http/http.dart' as http;

class ToolsService {
  final String baseUrl = "https://jyotishasha.pythonanywhere.com/api/tools";

  Future<Map<String, dynamic>?> runTool(
    String toolSlug,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$toolSlug'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error in ToolsService: $e");
      return null;
    }
  }
}
