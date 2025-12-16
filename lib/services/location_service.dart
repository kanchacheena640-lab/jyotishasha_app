import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _apiKey = "AIzaSyBxt6et6THD47K936GIXWJ8o-TP65RayOc";

  // ----------------------------------------------------------------------
  // 🔍 1) AUTOCOMPLETE (Search Suggestions)
  // ----------------------------------------------------------------------
  static Future<List<Map<String, String>>> fetchAutocomplete(
    String input,
  ) async {
    if (input.trim().length < 3) return [];

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeQueryComponent(input)}"
        "&components=country:in"
        "&key=$_apiKey";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["status"] != "OK") return [];

      final List predictions = data["predictions"];

      return predictions.map<Map<String, String>>((p) {
        return {
          "description": p["description"] ?? "",
          "place_id": p["place_id"] ?? "",
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ----------------------------------------------------------------------
  // 📍 2) GET LAT/LNG FROM PLACE_ID
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>?> fetchPlaceDetail(String placeId) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeId"
        "&key=$_apiKey";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["status"] != "OK") return null;

      final loc = data["result"]["geometry"]["location"];

      return {
        "lat": (loc["lat"] as num).toDouble(),
        "lng": (loc["lng"] as num).toDouble(),
      };
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // 🌎 3) GET TIMEZONE FOR LAT/LNG (DST + Offset)
  // ----------------------------------------------------------------------
  static Future<String?> fetchTimeZone(double lat, double lng) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final url =
        "https://maps.googleapis.com/maps/api/timezone/json"
        "?location=$lat,$lng"
        "&timestamp=$timestamp"
        "&key=$_apiKey";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["status"] != "OK") return null;

      return data["timeZoneId"]; // ⭐ सिर्फ यही चाहिए app में
    } catch (e) {
      return null;
    }
  }
}
