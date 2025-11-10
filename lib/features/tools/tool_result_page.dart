import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../astrology/astrology_page.dart';
import 'package:jyotishasha_app/core/widgets/kundali_chart_north_widget.dart';
import 'package:jyotishasha_app/core/registry/tool_registry.dart';

class ToolResultPage extends StatefulWidget {
  final String toolId;
  final Map<String, dynamic> formData;

  const ToolResultPage({
    super.key,
    required this.toolId,
    required this.formData,
  });

  @override
  State<ToolResultPage> createState() => _ToolResultPageState();
}

class _ToolResultPageState extends State<ToolResultPage> {
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  Map<String, dynamic>? data;

  /// cache key based on user details
  String get _cacheKey {
    final name = (widget.formData["name"] ?? "").toString();
    final dob = (widget.formData["dob"] ?? "").toString();
    final tob = (widget.formData["tob"] ?? "").toString();
    final pob = (widget.formData["pob"] ?? "").toString();
    return "tool_cache_${widget.toolId}_${name}_${dob}_${tob}_$pob";
  }

  @override
  void initState() {
    super.initState();
    fetchToolData();
  }

  // 🧠 Load from cache
  Future<Map<String, dynamic>?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cacheKey);
    if (jsonStr == null) return null;
    try {
      final wrapper = jsonDecode(jsonStr);
      final ts = DateTime.parse(wrapper["timestamp"]);
      if (DateTime.now().difference(ts).inMinutes > 5) return null;
      return wrapper["data"] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // 💾 Save new data to cache
  Future<void> _saveCache(Map<String, dynamic> fresh) async {
    final prefs = await SharedPreferences.getInstance();
    final wrapper = {
      "timestamp": DateTime.now().toIso8601String(),
      "data": fresh,
    };
    await prefs.setString(_cacheKey, jsonEncode(wrapper));
  }

  // 🌐 Fetch Kundali or Tool data
  Future<void> fetchToolData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    try {
      // 1️⃣ Try from cache first
      final cached = await _loadCache();
      if (cached != null) {
        debugPrint("ToolResultPage → Loaded from cache ✅");
        setState(() {
          data = cached;
          isLoading = false;
        });
        return;
      }

      // 2️⃣ Prepare backend payload
      final rawDob = widget.formData["dob"]?.toString() ?? "";
      String backendDob = rawDob;

      if (rawDob.isNotEmpty) {
        try {
          final parsed = DateFormat("dd-MM-yyyy").parse(rawDob);
          backendDob = DateFormat("yyyy-MM-dd").format(parsed);
        } catch (_) {
          backendDob = rawDob;
        }
      }

      final rawTob = widget.formData["tob"]?.toString() ?? "";
      final cleanedTob = rawTob.replaceAll(
        RegExp(r'\s?(AM|PM)', caseSensitive: false),
        '',
      );

      final payload = {
        "name": widget.formData["name"],
        "dob": backendDob,
        "tob": cleanedTob,
        "place_name": widget.formData["pob"] ?? "Lucknow, India",
        "lat": widget.formData["lat"] ?? 26.8467,
        "lng": widget.formData["lng"] ?? 80.9462,
        "timezone": "+05:30",
        "ayanamsa": "Lahiri",
        "language": "en",
      };

      debugPrint("ToolResultPage → Request: $payload");

      final url = Uri.parse(
        'https://jyotishasha-backend.onrender.com/api/full-kundali-modern',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint("ToolResultPage → Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveCache(decoded);
        setState(() {
          data = decoded;
          isLoading = false;
        });
      } else {
        debugPrint("ToolResultPage → Error body: ${response.body}");
        setState(() {
          hasError = true;
          isLoading = false;
          errorMessage =
              "Backend error (${response.statusCode}). Please try again.";
        });
      }
    } catch (e) {
      debugPrint("ToolResultPage → Exception: $e");
      setState(() {
        hasError = true;
        isLoading = false;
        errorMessage = "Something went wrong. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.toolId
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (e) => e.isEmpty
              ? e
              : e[0].toUpperCase() + (e.length > 1 ? e.substring(1) : ''),
        )
        .join(' ');

    if (isLoading) {
      return Scaffold(
        appBar: _buildAppBar(theme, title),
        body: _buildShimmerLoader(),
      );
    }

    if (hasError || data == null) {
      return Scaffold(
        appBar: _buildAppBar(theme, title),
        body: _buildErrorState(),
      );
    }

    final chartData = data?["chart_data"] as Map<String, dynamic>?;
    final planets = (chartData?["planets"] is List)
        ? chartData!["planets"] as List
        : [];
    final lagnaSign = data?["lagna_sign"];
    final toolBuilder = ToolRegistry.toolWidgets[widget.toolId];

    return Scaffold(
      appBar: _buildAppBar(theme, title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBirthChartOverview(theme),
            if (planets.isNotEmpty && lagnaSign != null) ...[
              const SizedBox(height: 20),
              KundaliChartNorthWidget(
                planets: planets,
                lagnaSign: lagnaSign,
                size: 280,
              ),
            ],
            const SizedBox(height: 20),
            if (toolBuilder != null)
              toolBuilder(data!)
            else
              _emptyToolBlock("This tool is under development."),
            const SizedBox(height: 28),
            _buildExploreMoreSection(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, String title) {
    return AppBar(
      title: Text(title, style: GoogleFonts.playfairDisplay()),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
    );
  }

  /// 🌅 Birth Chart Overview (always dd-MM-yyyy visible)
  Widget _buildBirthChartOverview(ThemeData theme) {
    final rawDob = widget.formData["dob"]?.toString();
    String formattedDob = "--";

    if (rawDob != null && rawDob.isNotEmpty) {
      try {
        final parsed = DateFormat("dd-MM-yyyy").parse(rawDob);
        formattedDob = DateFormat("dd-MM-yyyy").format(parsed);
      } catch (_) {
        try {
          final parsed = DateFormat("yyyy-MM-dd").parse(rawDob);
          formattedDob = DateFormat("dd-MM-yyyy").format(parsed);
        } catch (_) {
          formattedDob = rawDob;
        }
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "🪔 Birth Chart Overview",
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.formData["name"]?.toString().toUpperCase() ?? "USER",
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "DOB: $formattedDob   •   TOB: ${widget.formData["tob"] ?? '--'}",
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "POB: ${widget.formData["pob"] ?? 'Lucknow, India'}",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: index == 0 ? 90 : 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Something went wrong.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchToolData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyToolBlock(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }

  Widget _buildExploreMoreSection(BuildContext context) {
    final tools = [
      {"name": "Rajyog Check", "icon": Icons.auto_graph_outlined},
      {"name": "Mangal Dosh", "icon": Icons.whatshot_outlined},
      {"name": "Health Astrology", "icon": Icons.health_and_safety_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Explore More Tools",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final t = tools[i];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AstrologyPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t["icon"] as IconData, color: Colors.deepPurple),
                    const SizedBox(height: 6),
                    Text(
                      t["name"] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
