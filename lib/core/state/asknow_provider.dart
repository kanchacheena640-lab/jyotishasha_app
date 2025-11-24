import 'package:flutter/material.dart';
import 'package:jyotishasha_app/services/asknow_service.dart';

class AskNowProvider extends ChangeNotifier {
  bool isLoading = false;
  String? pendingAnswer;

  Future<void> fetchAnswer(
    String question,
    Map<String, dynamic> profile,
  ) async {
    isLoading = true;
    notifyListeners();

    final answer = await AskNowService.askQuestion(
      question: question,
      profile: profile,
    );

    pendingAnswer = answer;
    isLoading = false;
    notifyListeners();
  }

  void clearPending() {
    pendingAnswer = null;
    notifyListeners();
  }
}
