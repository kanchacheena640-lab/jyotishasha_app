// lib/app/services/report_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/features/reports/models/report_model.dart';

class ReportService {
  /// 🔹 Fetch all reports of logged-in user
  static Future<List<ReportModel>> fetchUserReports() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .orderBy('purchasedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching reports: $e');
      return [];
    }
  }

  /// 📥 Download PDF report to local storage
  static Future<void> downloadReport(
    BuildContext context, {
    required String reportId,
    required String pdfUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) throw Exception('Failed to download PDF');

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$reportId.pdf');
      await file.writeAsBytes(response.bodyBytes);

      final expiresAt = DateTime.now().add(const Duration(days: 7));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .doc(reportId)
          .update({'localPath': file.path, 'expiresAt': expiresAt});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report downloaded successfully ✅')),
      );
    } catch (e) {
      debugPrint('⚠️ Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download report')),
      );
    }
  }

  /// 📤 Share downloaded report
  static Future<void> shareReport(String localPath) async {
    try {
      await Share.shareXFiles([
        XFile(localPath),
      ], text: "My Jyotishasha Report ✨");
    } catch (e) {
      debugPrint('⚠️ Share error: $e');
    }
  }

  /// ⏰ Check if report expired
  static bool isExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }
}
