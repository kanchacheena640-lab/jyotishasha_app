import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/asknow_service.dart';
import '../../models/asknow/asknow_contracts.dart';
import '../asknow_repository.dart';

final class BackendAskNowRepository implements AskNowRepository {
  BackendAskNowRepository({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _verificationEndpoint = Uri.parse(
    'https://jyotishasha-backend.onrender.com/api/chatpack/verify',
  );

  final http.Client _client;

  @override
  Future<AskAnswerResponse> askFree(AskQuestionRequest request) async =>
      AskAnswerResponse.fromJson(
        await AskNowService.askFreeQuestion(
          userId: _requiredUserId(request.userId),
          question: request.question ?? '',
          profile: request.birth?.toJson() ?? const {},
        ),
      );

  @override
  Future<AskAnswerResponse> askPaid(AskQuestionRequest request) async =>
      AskAnswerResponse.fromJson(
        await AskNowService.askPaidQuestion(
          userId: _requiredUserId(request.userId),
          question: request.question ?? '',
          profile: request.birth?.toJson() ?? const {},
        ),
      );

  @override
  Future<AskNowStatus> getStatus(int userId) async =>
      AskNowStatus.fromJson(await AskNowService.fetchChatStatus(userId));

  @override
  Future<RewardQuestionResponse> addReward(int userId) async =>
      RewardQuestionResponse.fromJson(
        await AskNowService.addRewardQuestion(userId),
      );

  @override
  Future<ChatPackVerificationResult> verifyChatPack(
    ChatPackVerificationRequest request,
  ) async {
    final response = await _client.post(
      _verificationEndpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Chat-pack verification error ${response.statusCode}');
    }
    return ChatPackVerificationResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static int _requiredUserId(int? userId) {
    if (userId == null) throw ArgumentError.value(userId, 'userId');
    return userId;
  }
}
