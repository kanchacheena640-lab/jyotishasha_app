// // lib/core/widgets/tool_meta_section.dart

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:jyotishasha_app/core/state/kundali_provider.dart';
// import 'package:jyotishasha_app/features/kundali/kundali_section_detail_page.dart';
// import 'package:jyotishasha_app/core/constants/planet_meta.dart';
// import 'dart:ui' as ui;
// import 'dart:io';
// import 'package:flutter/rendering.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:jyotishasha_app/core/utils/share_utils.dart';
// import 'package:jyotishasha_app/core/constants/life_aspect_meta.dart';
// import 'package:jyotishasha_app/core/constants/yog_dosh_meta.dart';

// class ToolMetaSection extends StatefulWidget {
//   const ToolMetaSection({super.key});

//   @override
//   State<ToolMetaSection> createState() => _ToolMetaSectionState();
// }

// class _ToolMetaSectionState extends State<ToolMetaSection>
//     with SingleTickerProviderStateMixin {
//   // ⭐ Detects whether category has data in kundali
//   bool _hasCategoryData(String category, Map<String, dynamic>? k) {
//     if (k == null) return false;

//     // ✅ Profile tab ke liye Missing badge kabhi nahi dikhana
//     if (category == "Profile") return true;

//     if (category == "Planet") return k["planet_overview"] != null;
//     if (category == "House") return k["houses_overview"] != null;
//     if (category == "Mahadasha") return k["dasha_summary"] != null;
//     if (category == "Life Aspects") return k["life_aspects"] != null;
//     if (category == "Yog Dosh") return k["yogas"] != null;

//     // JSON category
//     final list = tools.where((t) => t["category"] == category).toList();
//     return list.isNotEmpty;
//   }

//   late AnimationController _blink;

//   List<dynamic> tools = [];
//   String selectedCategory = "Profile";

//   final GlobalKey _mahaShareKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     _loadTools();

//     // ⭐ Green blinking animation for current Mahadasha bullet
//     _blink = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//       lowerBound: 0.3,
//       upperBound: 1.0,
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _blink.dispose();
//     super.dispose();
//   }

//   // ---------- OPEN TOOL (Detail Page) ----------
//   void _openDetail(
//     BuildContext context,
//     String title,
//     dynamic data,
//     Map<String, dynamic> kundaliData,
//   ) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => KundaliSectionDetailPage(
//           title: title,
//           data: data,
//           kundaliData: kundaliData,
//         ),
//       ),
//     );
//   }

//   Future<void> _loadTools() async {
//     final jsonString = await rootBundle.loadString(
//       "assets/data/tool_meta.json",
//     );
//     final data = jsonDecode(jsonString);

//     setState(() => tools = data);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final kundali = context.watch<KundaliProvider>().kundaliData;

//     // ---------- JSON CATEGORIES ----------
//     List<String> jsonCategories = tools
//         .map((e) => e["category"] as String)
//         .toSet()
//         .toList();

//     // ---------- EXTRA CATEGORIES ----------
//     List<String> extra = [
//       "Planet",
//       "House",
//       "Mahadasha",
//       "Life Aspects",
//       "Yog Dosh",
//     ];

//     List<String> categories = ["Profile", ...jsonCategories, ...extra];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // CATEGORY BAR
//         SizedBox(
//           height: 40,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: categories.length,
//             itemBuilder: (_, i) {
//               final c = categories[i];
//               final selected = c == selectedCategory;

//               return GestureDetector(
//                 onTap: () => setState(() => selectedCategory = c),
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 220),
//                   curve: Curves.easeOut,
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: selected
//                         ? const LinearGradient(
//                             colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           )
//                         : null,
//                     color: selected ? null : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: selected
//                         ? [
//                             BoxShadow(
//                               color: Colors.purple.shade300.withOpacity(0.4),
//                               blurRadius: 10,
//                               offset: const Offset(0, 3),
//                             ),
//                           ]
//                         : [],
//                     border: Border.all(
//                       color: selected
//                           ? Colors.purple.shade700
//                           : Colors.grey.shade400,
//                       width: selected ? 1.4 : 1.0,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Text(
//                         c,
//                         style: TextStyle(
//                           color: selected ? Colors.white : Colors.black87,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 13,
//                         ),
//                       ),

//                       const SizedBox(width: 6),

//                       // ⭐ Count badge for JSON tools
//                       if (c != "All" &&
//                           ![
//                             "Planet",
//                             "House",
//                             "Mahadasha",
//                             "Life Aspects",
//                             "Yog Dosh",
//                             "Profile",
//                           ].contains(c))
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: selected ? Colors.white24 : Colors.black12,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Text(
//                             tools
//                                 .where((t) => t["category"] == c)
//                                 .length
//                                 .toString(),
//                             style: TextStyle(
//                               color: selected ? Colors.white : Colors.black54,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),

//                       // ⭐ Missing badge (yahi pe use ho raha hai _hasCategoryData)
//                       if (c != "Profile" && !_hasCategoryData(c, kundali))
//                         Container(
//                           margin: const EdgeInsets.only(left: 6),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.orange.shade100,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Text(
//                             "Missing",
//                             style: TextStyle(
//                               fontSize: 9,
//                               color: Colors.orange,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),

//         const SizedBox(height: 14),

//         // PLANETS
//         if (selectedCategory == "Planet" && kundali != null)
//           _buildPlanetGrid(kundali),

//         // HOUSES
//         if (selectedCategory == "House" && kundali != null)
//           _buildHouseGrid(kundali),

//         // LIFE ASPECTS
//         if (selectedCategory == "Life Aspects" && kundali != null)
//           _buildLifeAspectGrid(kundali),

//         // YOG DOSH
//         if (selectedCategory == "Yog Dosh" && kundali != null)
//           _buildYogDoshGrid(kundali),

//         // MAHADASHA BLOCKS
//         if (selectedCategory == "Mahadasha" && kundali != null)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: Column(
//               children: [
//                 RepaintBoundary(
//                   key: _mahaShareKey,
//                   child: _buildCurrentMahadashaBlock(kundali),
//                 ),

//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.share, color: Colors.white),
//                     label: const Text(
//                       "Share Mahadasha Block",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     onPressed: _shareMahadashaBlock,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 _buildMahadashaList(kundali),
//               ],
//             ),
//           ),

//         // DEFAULT JSON TOOLS
//         if (selectedCategory != "Planet" &&
//             selectedCategory != "House" &&
//             selectedCategory != "Mahadasha" &&
//             selectedCategory != "Life Aspects" &&
//             selectedCategory != "Yog Dosh")
//           _buildDefaultTools(kundali),
//       ],
//     );
//   }

//   // -----------------------------------------------------------------------------
//   // ⭐ PROFILE INFO CARD (Name, DOB, TOB, Place, etc.)
//   // -----------------------------------------------------------------------------
//   // Ye card Profile tab me show hoga.
//   // Kundali ke "profile" object ko readable format me convert karta hai.
//   Widget _buildProfileCard(Map<String, dynamic> profile) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       margin: const EdgeInsets.only(bottom: 18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12.withOpacity(0.08),
//             blurRadius: 14,
//             offset: const Offset(0, 6),
//           ),
//         ],
//         border: Border.all(color: Colors.purple.shade50, width: 1.2),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 🔮 HEADER — Name + Emoji
//           Row(
//             children: [
//               const Text("🕉️", style: TextStyle(fontSize: 26)),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   profile["name"] ?? "-",
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // Kundali Basic Info
//           _profileRow("Date of Birth", _formatDob(profile["dob"])),
//           _profileRow("Time of Birth", profile["tob"]),
//           _profileRow("Place of Birth", profile["place"]),
//           _profileRow("Timezone", profile["timezone"]),
//           _profileRow("Ayanamsa", profile["ayanamsa"]),
//         ],
//       ),
//     );
//   }

//   String _formatDob(String? iso) {
//     if (iso == null || iso.isEmpty) return "-";
//     try {
//       final d = DateTime.parse(iso); // 2025-11-12
//       final dd = d.day.toString().padLeft(2, '0');
//       final mm = d.month.toString().padLeft(2, '0');
//       final yyyy = d.year.toString();
//       return "$dd-$mm-$yyyy"; // dd-mm-yyyy
//     } catch (_) {
//       return iso; // fallback
//     }
//   }

//   // -----------------------------------------------------------------------------
//   // ⭐ SMALL ROW: (Label : Value)
//   // Example → DOB: 1985-03-31
//   // -----------------------------------------------------------------------------
//   Widget _profileRow(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               "$label:",
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//                 color: Colors.purple.shade900,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value ?? "-",
//               style: const TextStyle(fontSize: 14.5, height: 1.35),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // -------------------------------------------------------------
//   // PLANET GRID
//   // -------------------------------------------------------------
//   Widget _buildPlanetGrid(Map<String, dynamic> kundali) {
//     final planets = PlanetMeta.allPlanets;

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: planets.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 12,
//         childAspectRatio: 0.85,
//       ),
//       itemBuilder: (_, i) {
//         final p = planets[i];

//         return GestureDetector(
//           onTap: () => _openDetail(
//             context,
//             p["name"], // Title
//             kundali["planet_overview"]?.firstWhere(
//               (e) => e["planet"] == p["name"],
//               orElse: () => {"text": "No data available"},
//             ),
//             kundali,
//           ),
//           child: Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 6,
//                   offset: Offset(2, 3),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(p["emoji"], style: const TextStyle(fontSize: 30)),
//                 const SizedBox(height: 6),
//                 Text(
//                   p["name"],
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   p["effect"],
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 10, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // -------------------------------------------------------------
//   // HOUSE GRID (Jhompdi style: big number + small house + 1–2 traits)
//   // -------------------------------------------------------------
//   Widget _buildHouseGrid(Map<String, dynamic> kundali) {
//     final houses = kundali["houses_overview"] as List<dynamic>? ?? [];

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: houses.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         childAspectRatio: 0.9,
//         mainAxisSpacing: 12,
//         crossAxisSpacing: 10,
//       ),
//       itemBuilder: (_, i) {
//         final h = houses[i] as Map<String, dynamic>;
//         final num = h["house"];

//         final focus = (h["focus"] ?? "") as String;
//         final parts = focus
//             .split(",")
//             .map((e) => e.trim())
//             .where((e) => e.isNotEmpty)
//             .toList();

//         String tag = "";
//         if (parts.isNotEmpty) {
//           tag = parts.length == 1 ? parts[0] : "${parts[0]} • ${parts[1]}";
//         }

//         return GestureDetector(
//           onTap: () => _openDetail(context, "$num House", h, kundali),
//           child: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFF8F0), // soft warm jhopdi feel
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.brown.shade200, width: 0.8),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(1, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Big house number
//                 Text(
//                   "$num",
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 // Small house icon
//                 const Text("🏠", style: TextStyle(fontSize: 18)),
//                 const SizedBox(height: 4),
//                 if (tag.isNotEmpty)
//                   Text(
//                     tag,
//                     textAlign: TextAlign.center,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: Colors.brown.shade700,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // -------------------------------------------------------------
//   // CURRENT MAHADASHA HEADER BLOCK
//   // -------------------------------------------------------------
//   Widget _buildCurrentMahadashaBlock(Map<String, dynamic> kundali) {
//     final dashaSummary =
//         kundali["dasha_summary"] as Map<String, dynamic>? ?? {};
//     final currentBlock =
//         dashaSummary["current_block"] as Map<String, dynamic>? ?? {};
//     final currentMahaNode =
//         dashaSummary["current_mahadasha"] as Map<String, dynamic>? ?? {};
//     final currentAntarNode =
//         dashaSummary["current_antardasha"] as Map<String, dynamic>? ?? {};
//     final grahBlock =
//         kundali["grah_dasha_block"] as Map<String, dynamic>? ?? {};

//     final String mahaPlanet =
//         (currentBlock["mahadasha"] ?? currentMahaNode["mahadasha"] ?? "-")
//             .toString();
//     final String antarPlanet =
//         (currentBlock["antardasha"] ?? currentAntarNode["planet"] ?? "-")
//             .toString();

//     final String mahaStart = (currentMahaNode["start"] ?? "").toString();
//     final String mahaEnd = (currentMahaNode["end"] ?? "").toString();
//     final String antarStart = (currentAntarNode["start"] ?? "").toString();
//     final String antarEnd = (currentAntarNode["end"] ?? "").toString();

//     final int? mahaHouse = grahBlock["mahadasha_house"] as int?;
//     final int? antarHouse = grahBlock["antardasha_house"] as int?;
//     final String impact = (grahBlock["grah_dasha_text"] ?? "")
//         .toString()
//         .trim();

//     // Agar kuch bhi data nahi mila to block na dikhaye
//     if (mahaPlanet == "-" && antarPlanet == "-") {
//       return const SizedBox.shrink();
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // --------------------------------------------------
//         // 🌙 TOP PURPLE BLOCK (Mahadasha + Antardasha + Impact)
//         // --------------------------------------------------
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(18),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 10,
//                 offset: Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 🔵 Header
//               Row(
//                 children: [
//                   FadeTransition(
//                     opacity: _blink,
//                     child: Container(
//                       width: 10,
//                       height: 10,
//                       decoration: const BoxDecoration(
//                         color: Colors.greenAccent,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   const Text(
//                     "Currently Undergoing",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // ⭐ Mahadasha
//               Text(
//                 "$mahaPlanet Mahadasha"
//                 "${mahaHouse != null ? " (House $mahaHouse)" : ""}",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w700,
//                   height: 1.5,
//                 ),
//               ),
//               Text(
//                 "$mahaStart → $mahaEnd",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 13.2,
//                   height: 1.45,
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // ⭐ Antardasha
//               Text(
//                 "$antarPlanet Antardasha"
//                 "${antarHouse != null ? " (House $antarHouse)" : ""}",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   height: 1.5,
//                 ),
//               ),
//               Text(
//                 "$antarStart → $antarEnd",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 13,
//                   height: 1.45,
//                 ),
//               ),

//               // ⭐ IMPACT – same purple block
//               if (impact.isNotEmpty) ...[
//                 const SizedBox(height: 22),
//                 Text(
//                   impact,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 13.8,
//                     height: 1.55,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),

//         const SizedBox(height: 24),
//       ],
//     );
//   }

//   Future<void> _shareMahadashaBlock() async {
//     try {
//       final boundary =
//           _mahaShareKey.currentContext!.findRenderObject()
//               as RenderRepaintBoundary;

//       final image = await boundary.toImage(pixelRatio: 3.0);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       final pngBytes = byteData!.buffer.asUint8List();

//       final dir = await getTemporaryDirectory();
//       final file = File("${dir.path}/current_mahadasha_block.png");
//       await file.writeAsBytes(pngBytes);

//       await ShareUtils.shareImage(
//         file.path,
//         text: "✨ Current Mahadasha — Generated by Jyotishasha App",
//       );
//     } catch (e) {
//       print("❌ Share failed: $e");
//     }
//   }

//   // -------------------------------------------------------------
//   // MAHADASHA LIST (pill strips + blinking bullet)
//   // -------------------------------------------------------------
//   Widget _buildMahadashaList(Map<String, dynamic> kundali) {
//     final dashaSummary = kundali["dasha_summary"] as Map<String, dynamic>?;

//     if (dashaSummary == null) {
//       return const SizedBox.shrink();
//     }

//     final current =
//         (dashaSummary["current_block"] as Map<String, dynamic>?)?["mahadasha"];
//     final all = dashaSummary["mahadashas"] as List<dynamic>? ?? [];

//     if (all.isEmpty) {
//       return const Text(
//         "No Mahadasha data available.",
//         style: TextStyle(fontSize: 12, color: Colors.grey),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: all.length,
//       itemBuilder: (_, i) {
//         final m = all[i] as Map<String, dynamic>;
//         final planet = m["mahadasha"] ?? "";
//         final isCurrent = planet == current;

//         final start = (m["start"] ?? "") as String;
//         final end = (m["end"] ?? "") as String;

//         String range;
//         if (start.length >= 4 && end.length >= 4) {
//           range = "${start.substring(0, 4)}–${end.substring(0, 4)}";
//         } else {
//           range = "$start – $end";
//         }

//         Widget bullet;
//         if (isCurrent) {
//           bullet = FadeTransition(
//             opacity: _blink,
//             child: Container(
//               width: 10,
//               height: 10,
//               decoration: const BoxDecoration(
//                 color: Colors.green,
//                 shape: BoxShape.circle,
//               ),
//             ),
//           );
//         } else {
//           bullet = Container(
//             width: 10,
//             height: 10,
//             decoration: const BoxDecoration(
//               color: Colors.black54,
//               shape: BoxShape.circle,
//             ),
//           );
//         }

//         return GestureDetector(
//           onTap: () => _openDetail(context, "$planet Mahadasha", m, kundali),
//           child: Container(
//             margin: const EdgeInsets.only(bottom: 8),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(999), // pill strip
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(1, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 bullet,
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     "$planet Mahadasha",
//                     style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   range,
//                   style: const TextStyle(fontSize: 11, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // -------------------------------------------------------------
//   // LIFE ASPECT GRID
//   // -------------------------------------------------------------
//   Widget _buildLifeAspectGrid(Map<String, dynamic> kundali) {
//     final aspects = LifeAspectMeta.allAspects; // <-- meta file se icons + emoji
//     final list = kundali["life_aspects"] as List<dynamic>? ?? [];

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: list.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 1.1,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//       ),
//       itemBuilder: (_, i) {
//         final a = list[i];
//         final name = a["aspect"] ?? "-";

//         // meta match
//         final meta = aspects.firstWhere(
//           (m) => m["name"] == name,
//           orElse: () => {},
//         );

//         final emoji = meta["emoji"] ?? "✨";
//         final colorHex = meta["color"] ?? 0xFF7C3AED;

//         return GestureDetector(
//           onTap: () {
//             _openDetail(context, name, a, kundali);
//           },
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Color(colorHex).withOpacity(0.08),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: Color(colorHex).withOpacity(0.4),
//                 width: 1,
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(emoji, style: const TextStyle(fontSize: 30)),
//                 const SizedBox(height: 8),
//                 Text(
//                   name,
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // -------------------------------------------------------------
//   // YOG DOSH GRID  (with Active / Inactive badge)
//   // -------------------------------------------------------------
//   Widget _buildYogDoshGrid(Map<String, dynamic> kundali) {
//     final list = YogDoshMeta.all;
//     final yogas = kundali["yogas"] ?? {};

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: list.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         childAspectRatio: 0.80, // ← SAFE RATIO (overflow fix)
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 12,
//       ),
//       itemBuilder: (_, i) {
//         final meta = list[i];
//         final yogId = meta["id"];

//         final data =
//             yogas[yogId] ??
//             {
//               "id": yogId,
//               "name": meta["label"],
//               "emoji": meta["emoji"],
//               "is_active": false,
//             };

//         final bool isActive = data["is_active"] == true;

//         return GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => KundaliSectionDetailPage(
//                   title: meta["label"],
//                   data: data,
//                   kundaliData: kundali,
//                 ),
//               ),
//             );
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
//             decoration: BoxDecoration(
//               color: Color(meta["color"]).withOpacity(0.12),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: Color(meta["color"]).withOpacity(0.4),
//                 width: 1,
//               ),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(1, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Emoji
//                 Text(meta["emoji"], style: const TextStyle(fontSize: 26)),

//                 const SizedBox(height: 6),

//                 // Label
//                 Text(
//                   meta["label"],
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 11.5,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),

//                 const SizedBox(height: 6),

//                 // Active / Inactive
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 6,
//                     vertical: 2,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isActive
//                         ? Colors.green.withOpacity(0.15)
//                         : Colors.grey.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     isActive ? "Active" : "Inactive",
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: isActive ? Colors.green : Colors.grey[700],
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // -------------------------------------------------------------
//   // DEFAULT JSON TOOLS
//   // -------------------------------------------------------------
//   Widget _buildDefaultTools(Map<String, dynamic>? kundali) {
//     // -----------------------------------------------------------------
//     // ⭐ PROFILE TAB OVERRIDE
//     // Agar Profile tab selected hai → JSON tools ignore karo
//     // Sirf Profile Info Card + 3 Profile Tools hai
//     // -----------------------------------------------------------------
//     if (selectedCategory == "Profile") {
//       return Column(
//         children: [
//           // 🟣 PROFILE CARD
//           if (kundali != null && kundali["profile"] != null)
//             _buildProfileCard(kundali["profile"]),

//           const SizedBox(height: 6),

//           // 🟡 3 FIXED PROFILE TOOLS (Lagna / Rashi / Gemstone)
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: ProfileMeta.profileTools.length,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               childAspectRatio: 0.85,
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 12,
//             ),
//             itemBuilder: (_, i) {
//               final t = ProfileMeta.profileTools[i];
//               final name = t["name"];

//               return GestureDetector(
//                 onTap: () {
//                   // ---------- BACKEND SOURCES ----------
//                   final asc =
//                       kundali?["chart_data"]?["ascendant"] ??
//                       (kundali?["planet_overview"] as List<dynamic>?)
//                           ?.firstWhere(
//                             (p) => p["planet"] == "Ascendant (Lagna)",
//                             orElse: () => null,
//                           );

//                   final moonTraits = kundali?["moon_traits"] ?? {};
//                   final gemData = kundali?["gemstone_data"] ?? {};

//                   // ---------- LAGNA ----------
//                   if (name == "Lagna Finder") {
//                     final lagnaTitle =
//                         "Your Lagna is ${kundali?["lagna_sign"]}";
//                     final lagnaText =
//                         kundali?["lagna_trait"] ?? "No Lagna details found";

//                     _openDetail(context, "Lagna Finder", {
//                       "result": lagnaTitle,
//                       "text": lagnaText,
//                     }, kundali ?? {});
//                   }
//                   // ---------- MOON SIGN ----------
//                   else if (name == "Rashi Finder") {
//                     _openDetail(context, "Rashi Finder", {
//                       "result": moonTraits["title"] ?? "Your Moon Sign",
//                       "text":
//                           moonTraits["personality"] ??
//                           "Moon sign content not found",
//                     }, kundali ?? {});
//                   }
//                   // ---------- GEMSTONE ----------
//                   else if (name == "Gemstone Suggestion") {
//                     final gem =
//                         kundali?["gemstone_suggestion"]?["gemstone"] ??
//                         "Not Found";
//                     final para =
//                         kundali?["gemstone_suggestion"]?["paragraph"] ?? "";
//                     final planet =
//                         kundali?["gemstone_suggestion"]?["planet"] ?? "-";
//                     final sub =
//                         kundali?["gemstone_suggestion"]?["substone"] ?? "-";

//                     _openDetail(context, "Gemstone Recommendation", {
//                       "result": gem,
//                       "text":
//                           "$para\n\nRecommended by: $planet\nAlternate Stone: $sub",
//                     }, kundali ?? {});
//                   }
//                 },
//                 child: _ToolCard(
//                   emoji: t["emoji"],
//                   title: t["name"],
//                   badge: null,
//                 ),
//               );
//             },
//           ),
//         ],
//       );
//     }

//     // -----------------------------------------------------------
//     // ⭐ NORMAL JSON TOOL LIST (used for All + other categories)
//     // Yeh list PROFILE case ke baad hi declare karna hai,
//     // warna Profile section me duplicate list ban jayega.
//     // -----------------------------------------------------------
//     final filteredList = selectedCategory == "All"
//         ? tools
//         : tools.where((t) => t["category"] == selectedCategory).toList();

//     // Inject Profile Tools (Lagna, Rashi, Gemstone)
//     if (selectedCategory == "All" || selectedCategory == "Profile") {
//       filteredList.addAll(
//         ProfileMeta.profileTools.map(
//           (m) => {
//             "emoji": m["emoji"],
//             "title": m["name"],
//             "category": "Profile",
//             "badge": null, // optional
//           },
//         ),
//       );
//     }

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: filteredList.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         childAspectRatio: 0.85,
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 12,
//       ),
//       itemBuilder: (_, i) {
//         final t = filteredList[i];

//         return GestureDetector(
//           onTap: () {
//             if (t["title"] == "Lagna Finder") {
//               _openDetail(context, "Lagna Finder", {
//                 "result": kundali?["lagna_sign"] ?? "Not Found",
//                 "text": "Your Lagna is ${kundali?["lagna_sign"] ?? "-"}",
//               }, kundali ?? {});
//             } else if (t["title"] == "Rashi Finder") {
//               _openDetail(context, "Rashi Finder", {
//                 "result": kundali?["rashi"] ?? "Not Found",
//                 "text": "Your Moon Sign (Rashi) is ${kundali?["rashi"] ?? "-"}",
//               }, kundali ?? {});
//             } else if (t["title"] == "Gemstone Suggestion") {
//               _openDetail(context, "Gemstone Suggestion", {
//                 "result": kundali?["gemstone"] ?? "Opal",
//                 "text":
//                     kundali?["gemstone_full"] ??
//                     "Recommended gemstone based on your Kundali",
//               }, kundali ?? {});
//             } else {
//               _openDetail(context, t["title"], t, kundali ?? {});
//             }
//           },
//           child: _ToolCard(
//             emoji: t["emoji"],
//             title: t["title"],
//             badge: t["badge"],
//           ),
//         );
//       },
//     );
//   }
// }

// // -------------------------------------------------------------
// // COMMON TOOL CARD
// // -------------------------------------------------------------
// class _ToolCard extends StatelessWidget {
//   final String emoji;
//   final String title;
//   final String? badge;

//   const _ToolCard({required this.emoji, required this.title, this.badge});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: const [
//           BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3)),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(emoji, style: const TextStyle(fontSize: 30)),
//           const SizedBox(height: 6),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//           ),
//           if (badge != null) ...[
//             const SizedBox(height: 4),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.orange.shade100,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 badge!,
//                 style: const TextStyle(fontSize: 10, color: Colors.orange),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
