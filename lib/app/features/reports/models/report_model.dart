// lib/app/features/reports/models/report_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String title;
  final String language;
  final String pdfUrl;
  final String? localPath;
  final DateTime purchasedAt;
  final DateTime? expiresAt;

  ReportModel({
    required this.id,
    required this.title,
    required this.language,
    required this.pdfUrl,
    this.localPath,
    required this.purchasedAt,
    this.expiresAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      title: data['title'] ?? 'Unknown Report',
      language: data['language'] ?? 'English',
      pdfUrl: data['pdfUrl'] ?? '',
      localPath: data['localPath'],
      purchasedAt:
          (data['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'language': language,
      'pdfUrl': pdfUrl,
      'localPath': localPath,
      'purchasedAt': purchasedAt,
      'expiresAt': expiresAt,
    };
  }
}
