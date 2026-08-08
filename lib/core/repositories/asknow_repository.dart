import '../models/asknow/asknow_contracts.dart';

/// Purpose: owns AskNow backend questions, entitlement state, and rewards.
///
/// Responsibilities: ask free or paid questions, retrieve status, apply a
/// reward, and verify a purchased chat pack through typed contracts.
///
/// Excluded responsibilities: purchase SDK lifecycle, ad completion, chat UI,
/// provider state, HTTP code, and backend-user lookup.
///
/// Future implementation owner: ESR-003 AskNow repository implementation.
abstract interface class AskNowRepository {
  Future<AskAnswerResponse> askFree(AskQuestionRequest request);

  Future<AskAnswerResponse> askPaid(AskQuestionRequest request);

  Future<AskNowStatus> getStatus(int userId);

  Future<RewardQuestionResponse> addReward(int userId);

  Future<ChatPackVerificationResult> verifyChatPack(
    ChatPackVerificationRequest request,
  );
}
