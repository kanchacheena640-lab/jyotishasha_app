import 'package:flutter/material.dart';

import '../../services/location_service.dart';

class PlacePicker extends StatefulWidget {
  final TextEditingController controller;
  final Function(double lat, double lng) onLocationSelected;
  final String label;
  final IconData icon;

  const PlacePicker({
    super.key,
    required this.controller,
    required this.onLocationSelected,
    this.label = "Place of Birth",
    this.icon = Icons.location_on_outlined,
  });

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  List<Map<String, String>> _suggestions = [];
  bool _loading = false;

  // ------------------------------- SEARCH API ---------------------------------
  Future<void> _onSearch(String input) async {
    if (input.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _loading = true);

    final result = await LocationService.fetchAutocomplete(input);

    setState(() {
      _suggestions = result;
      _loading = false;
    });
  }

  // -------------------------- SELECT PLACE → GET LAT/LNG ----------------------
  Future<void> _selectPlace(Map<String, String> item) async {
    final placeId = item["place_id"]!;
    final placeDetail = await LocationService.fetchPlaceDetail(placeId);

    if (placeDetail != null) {
      final lat = placeDetail["lat"];
      final lng = placeDetail["lng"];

      widget.controller.text = item["description"]!;
      widget.onLocationSelected(lat, lng);

      setState(() => _suggestions = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: [
          // ------------------------- INPUT FIELD -------------------------
          TextFormField(
            controller: widget.controller,
            onChanged: _onSearch,
            validator: (v) =>
                v == null || v.trim().isEmpty ? "Required field" : null,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: Icon(widget.icon, color: Colors.deepPurple),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),

          // ------------------------- LOADING BAR -------------------------
          if (_loading) const LinearProgressIndicator(minHeight: 2),

          // ------------------------- SUGGESTIONS LIST -------------------------
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) {
                  final item = _suggestions[i];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.deepPurple,
                    ),
                    title: Text(item["description"]!, style: const TextStyle()),
                    onTap: () => _selectPlace(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
