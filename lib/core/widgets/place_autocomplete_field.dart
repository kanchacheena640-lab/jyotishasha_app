import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String place, double lat, double lng) onSelected;
  final String hint;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.onSelected,
    this.hint = "Enter city or place",
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  List<Map<String, String>> results = [];
  bool loading = false;

  // ---------------- SEARCH AUTOCOMPLETE ----------------
  Future<void> search(String input) async {
    if (input.trim().length < 3) {
      setState(() => results = []);
      return;
    }

    final key = dotenv.env['GOOGLE_PLACES_KEY'];
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$input&components=country:in&key=$key";

    setState(() => loading = true);

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    setState(() => loading = false);

    if (data["status"] == "OK") {
      setState(() {
        results = (data["predictions"] as List)
            .map(
              (p) => {
                "description": p["description"] as String,
                "place_id": p["place_id"] as String,
              },
            )
            .toList();
      });
    } else {
      setState(() => results = []);
    }
  }

  // ---------------- GET LAT/LNG ----------------
  Future<void> selectPrediction(Map<String, String> p) async {
    widget.controller.text = p["description"]!;

    final key = dotenv.env['GOOGLE_PLACES_KEY'];
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=${p["place_id"]}&key=$key";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["status"] != "OK") return;

    final loc = data["result"]?["geometry"]?["location"];
    if (loc == null) return;

    final lat = (loc["lat"] as num).toDouble();
    final lng = (loc["lng"] as num).toDouble();

    widget.onSelected(p["description"]!, lat, lng);

    setState(() => results = []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(hintText: widget.hint),
          onChanged: search,
        ),

        if (loading) const LinearProgressIndicator(),

        if (results.isNotEmpty)
          Container(
            height: 220,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(blurRadius: 12, color: Colors.black12),
              ],
            ),
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final p = results[i];
                return ListTile(
                  title: Text(p["description"]!),
                  onTap: () => selectPrediction(p),
                );
              },
            ),
          ),
      ],
    );
  }
}
