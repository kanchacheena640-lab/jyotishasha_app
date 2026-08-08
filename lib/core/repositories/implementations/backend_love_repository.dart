import '../../../features/love/enums/love_tool.dart';
import '../../../features/love/services/love_api_service.dart';
import '../../models/love/love_contracts.dart';
import '../love_repository.dart';

final class BackendLoveRepository implements LoveRepository {
  BackendLoveRepository({required LoveTool tool, LoveApiService? service})
    : _tool = tool,
      _service = service ?? LoveApiService();

  final LoveTool _tool;
  final LoveApiService _service;

  @override
  Future<LoveApiResponse<LoveResult>> submit(
    LoveCompatibilityRequest request,
  ) async {
    final data = await _service.run(_tool, request.toJson());
    return LoveApiResponse<LoveResult>(
      ok: true,
      data: LoveResult.fromJson(data, type: _resultType),
    );
  }

  String get _resultType => switch (_tool) {
    LoveTool.matchMaking => 'match_making',
    LoveTool.mangalDosh => 'mangal_dosh',
    LoveTool.truthOrDare => 'truth_or_dare',
    LoveTool.marriageProbability => 'marriage_probability',
  };
}
