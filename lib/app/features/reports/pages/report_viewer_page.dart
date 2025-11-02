// lib/app/features/reports/pages/report_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ReportViewerPage extends StatefulWidget {
  final String pdfUrl;
  const ReportViewerPage({super.key, required this.pdfUrl});

  @override
  State<ReportViewerPage> createState() => _ReportViewerPageState();
}

class _ReportViewerPageState extends State<ReportViewerPage> {
  bool _downloading = false;

  Future<void> _downloadAndShare() async {
    try {
      setState(() => _downloading = true);

      // 🧾 Request storage permission
      await Permission.storage.request();

      // 📥 Download file
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/jyotishasha_report.pdf";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // 📤 Share file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: "My Jyotishasha Report");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report ready to share/download ✅")),
      );
    } catch (e) {
      debugPrint("⚠️ Download/Share error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to share or download.")),
      );
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfUrl = widget.pdfUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Report"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloading ? null : _downloadAndShare,
          ),
        ],
      ),
      body: pdfUrl.isEmpty
          ? const Center(child: Text("Report not available yet."))
          : SfPdfViewer.network(pdfUrl),
    );
  }
}
