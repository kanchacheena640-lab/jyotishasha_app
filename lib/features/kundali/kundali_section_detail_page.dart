// lib/features/kundali/kundali_section_detail_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

class KundaliSectionDetailPage extends StatelessWidget {
  final String title;
  final dynamic data;

  const KundaliSectionDetailPage({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(color: Colors.white),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: _buildContent(context)),
      ),
    );
  }

  // ---------------------------------------------
  // CONTENT BUILDER
  // ---------------------------------------------
  Widget _buildContent(BuildContext context) {
    if (data == null) {
      return _empty("No data available");
    }

    if (data is String) {
      return _textBlock(data);
    }

    if (data is Map<String, dynamic>) {
      return _mapViewer(context, data);
    }

    if (data is List) {
      return _listViewer(context, data);
    }

    return _textBlock(data.toString());
  }

  // ---------------------------------------------
  // Text block
  // ---------------------------------------------
  Widget _textBlock(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decor(),
      child: Text(
        text,
        style: GoogleFonts.montserrat(fontSize: 14, height: 1.45),
      ),
    );
  }

  // ---------------------------------------------
  // Empty state
  // ---------------------------------------------
  Widget _empty(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text(
          msg,
          style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey),
        ),
      ),
    );
  }

  // ---------------------------------------------
  // MAP VIEWER
  // ---------------------------------------------
  Widget _mapViewer(BuildContext context, Map<String, dynamic> map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: map.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: _decor(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _pretty(entry.value),
                style: GoogleFonts.montserrat(fontSize: 13, height: 1.45),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------
  // LIST VIEWER
  // ---------------------------------------------
  Widget _listViewer(BuildContext context, List list) {
    return Column(
      children: list.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: _decor(),
          child: Text(
            _pretty(item),
            style: GoogleFonts.montserrat(fontSize: 13, height: 1.4),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------
  // JSON Pretty Printing
  // ---------------------------------------------
  String _pretty(dynamic value) {
    try {
      if (value is String) return value;
      return const JsonEncoder.withIndent("  ").convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  // ---------------------------------------------
  // BOX DECORATION
  // ---------------------------------------------
  BoxDecoration _decor() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 3)),
      ],
    );
  }
}
