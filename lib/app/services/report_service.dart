import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class ReportService {
  static Future<void> downloadReport(
    BuildContext context, {
    required String reportId,
    required String pdfUrl,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 📥 Download file
      final response = await http.get(Uri.parse(pdfUrl));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$reportId.pdf');
      await file.writeAsBytes(response.bodyBytes);

      // 🗓️ Set expiry (7 days)
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      // 🔄 Update Firestore
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

  static Future<void> shareReport(String localPath) async {
    try {
      await Share.shareXFiles([
        XFile(localPath),
      ], text: "My Jyotishasha Report");
    } catch (e) {
      debugPrint('⚠️ Share error: $e');
    }
  }

  static bool isExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }
}
