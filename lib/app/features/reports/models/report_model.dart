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
    required this.purchasedAt,
    this.localPath,
    this.expiresAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> data, String id) {
    return ReportModel(
      id: id,
      title: data['title'] ?? 'Unknown Report',
      language: data['language'] ?? 'English',
      pdfUrl: data['pdfUrl'] ?? '',
      localPath: data['localPath'],
      purchasedAt: (data['purchasedAt'] is Timestamp)
          ? (data['purchasedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: (data['expiresAt'] is Timestamp)
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
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
