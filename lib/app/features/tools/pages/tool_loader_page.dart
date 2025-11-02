import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jyotishasha_app/app/services/tools_service.dart';
import 'tool_result_page.dart';

class ToolLoaderPage extends StatefulWidget {
  final String toolSlug;
  final String toolTitle;
  const ToolLoaderPage({
    super.key,
    required this.toolSlug,
    required this.toolTitle,
  });

  @override
  State<ToolLoaderPage> createState() => _ToolLoaderPageState();
}

class _ToolLoaderPageState extends State<ToolLoaderPage> {
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _runTool();
  }

  Future<void> _runTool() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final user = doc.data();
    if (user == null) return;

    final payload = {
      "name": user['name'],
      "dob": user['dob'],
      "tob": user['tob'],
      "pob": user['birthPlace'],
      "lat": user['lat'],
      "lng": user['lng'],
    };

    final service = ToolsService();
    final res = await service.runTool(widget.toolSlug, payload);

    if (mounted) setState(() => _result = res);
  }

  @override
  Widget build(BuildContext context) {
    if (_result == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.toolTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ToolResultPage(toolTitle: widget.toolTitle, resultData: _result!);
  }
}
