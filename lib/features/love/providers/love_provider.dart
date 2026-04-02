import 'package:flutter/material.dart';
import '../enums/love_tool.dart';
import '../services/love_api_service.dart';

class LoveProvider extends ChangeNotifier {
  final LoveApiService _api = LoveApiService();

  Map<String, dynamic>? _payload;

  final Map<LoveTool, int> _resultVersion = {};

  final Map<LoveTool, Map<String, dynamic>> _resultsByTool = {};
  final Map<LoveTool, bool> _loadingByTool = {};

  String? _error;

  // ================= GETTERS =================

  Map<String, dynamic>? get payload => _payload; // ✅ REQUIRED
  Map<String, dynamic>? resultFor(LoveTool tool) => _resultsByTool[tool];
  bool isLoadingFor(LoveTool tool) => _loadingByTool[tool] == true;
  String? get error => _error;

  // ================= PAYLOAD =================

  void setPayload(Map<String, dynamic> data) {
    _payload = {...data};

    _resultsByTool.clear();
    _loadingByTool.clear();
    _resultVersion.clear();
    _error = null;

    notifyListeners();
  }

  // ================= INTERNAL RUN =================

  Future<void> _runInternal(LoveTool tool) async {
    _loadingByTool[tool] = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.run(tool, _payload!);
      _resultsByTool[tool] = res;
      // 🔥 RESULT ARRIVAL SIGNAL
      _resultVersion[tool] = (_resultVersion[tool] ?? 0) + 1;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingByTool[tool] = false;
      notifyListeners();
    }
  }

  // ================= ENSURE TOOL =================

  Future<void> ensureTool(LoveTool tool) async {
    if (_payload == null) {
      _error = "Payload missing";
      notifyListeners();
      return;
    }

    // 🔒 HARD CACHE GUARD — result already exists, no API call
    final cached = _resultsByTool[tool];
    if (cached != null) {
      _loadingByTool[tool] = false;

      // 🔔 force UI to rebuild for cached result
      _resultVersion[tool] = (_resultVersion[tool] ?? 0) + 1;
      notifyListeners();
      return;
    }

    if (_loadingByTool[tool] == true) {
      while (_loadingByTool[tool] == true) {
        await Future.delayed(const Duration(milliseconds: 40));
      }
      return;
    }

    await _runInternal(tool);
  }

  // ================= RESET =================

  void reset() {
    _payload = null;
    _resultsByTool.clear();
    _loadingByTool.clear();
    _resultVersion.clear();
    _error = null;
    notifyListeners();
  }

  int resultVersionFor(LoveTool tool) {
    return _resultVersion[tool] ?? 0;
  }
}
