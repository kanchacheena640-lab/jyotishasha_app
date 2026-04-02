import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HomeUpcomingEventsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  List<Map<String, dynamic>> events = [];

  double savedLat = 28.61;
  double savedLng = 77.23;

  Future<void> fetchEvents({required double lat, required double lng}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    savedLat = lat;
    savedLng = lng;

    const endpoint =
        "https://jyotishasha-backend.onrender.com/api/events/home-upcoming";

    try {
      final res = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"latitude": lat, "longitude": lng}),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        final List raw = decoded["events"] ?? [];

        events = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        error = "Server error ${res.statusCode}";
      }
    } catch (e) {
      error = "Network error $e";
    }

    isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic>? get nextEvent {
    if (events.isEmpty) return null;
    return events.first;
  }
}
