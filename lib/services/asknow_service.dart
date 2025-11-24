import 'dart:convert';
import 'package:http/http.dart' as http;

class AskNowService {
  static Future<String> askQuestion({
    required String question,
    required Map<String, dynamic> profile,
  }) async {
    // 🔍 Debug: incoming profile
    print("🔍 ASK-NOW RAW PROFILE = $profile");
    print("🔍 ASK-NOW QUESTION = $question");

    // ---- SAFE FIELD EXTRACTION ----
    final String name = (profile["name"] ?? "").toString();
    final String dob = (profile["dob"] ?? "").toString();
    final String tob = (profile["tob"] ?? "").toString();

    // pob can be "pob" or "place"
    String pob = "";
    if (profile["pob"] != null && profile["pob"].toString().trim().isNotEmpty) {
      pob = profile["pob"].toString();
    } else if (profile["place"] != null &&
        profile["place"].toString().trim().isNotEmpty) {
      pob = profile["place"].toString();
    }

    // timezone key fallback
    final String tz = (profile["tz"] ?? profile["timezone"] ?? "+05:30")
        .toString();

    // lat / lng – profile me na mile to sensible defaults (Lucknow)
    double lat = 0.0;
    double lng = 0.0;

    if (profile["lat"] != null) {
      lat = (profile["lat"] as num).toDouble();
    }
    if (profile["lng"] != null) {
      lng = (profile["lng"] as num).toDouble();
    }

    if (lat == 0.0) lat = 26.8467;
    if (lng == 0.0) lng = 80.9462;

    // 🔐 FINAL PAYLOAD (exact structure as backend)
    final payload = {
      "question": question,
      "birth": {
        "name": name,
        "dob": dob,
        "tob": tob,
        "pob": pob,
        "lat": lat,
        "lng": lng,
        "tz": tz,
      },
    };

    print("🚀 ASK-NOW FINAL PAYLOAD → ${jsonEncode(payload)}");

    final url = Uri.parse(
      "https://jyotishasha-backend.onrender.com/api/free-consult",
    );

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("📩 ASK-NOW RESPONSE STATUS = ${res.statusCode}");
      print("📩 ASK-NOW RESPONSE BODY = ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["answer"] ?? "No answer received.";
      } else {
        return "Server error. Please try again.";
      }
    } catch (e) {
      print("❌ ASK-NOW NETWORK EXCEPTION = $e");
      return "Network error. Please try again later.";
    }
  }
}
