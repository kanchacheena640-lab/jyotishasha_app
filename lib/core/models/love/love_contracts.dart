import '../contract_support.dart';
import '../profile/birth_details.dart';

final class LovePersonInput extends ContractValue {
  const LovePersonInput({this.name, this.birthDetails, this.gender});
  final String? name;
  final BirthDetails? birthDetails;
  final String? gender;
  factory LovePersonInput.fromJson(JsonMap json) => LovePersonInput(
    name: asString(json['name']),
    birthDetails: BirthDetails.fromJson(json),
    gender: asString(json['gender']),
  );
  JsonMap toJson() => {
    'name': name,
    ...?birthDetails?.toJson(),
    'gender': gender,
  };
  LovePersonInput copyWith({
    Object? name = contractUnchanged,
    Object? birthDetails = contractUnchanged,
    Object? gender = contractUnchanged,
  }) => LovePersonInput(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    birthDetails: identical(birthDetails, contractUnchanged)
        ? this.birthDetails
        : birthDetails as BirthDetails?,
    gender: identical(gender, contractUnchanged)
        ? this.gender
        : gender as String?,
  );
  @override
  List<Object?> get props => [name, birthDetails, gender];
}

final class LoveCompatibilityRequest extends ContractValue {
  const LoveCompatibilityRequest({
    this.language,
    this.boyIsUser,
    this.user,
    this.partner,
  });
  final String? language;
  final bool? boyIsUser;
  final LovePersonInput? user;
  final LovePersonInput? partner;
  factory LoveCompatibilityRequest.fromJson(JsonMap json) =>
      LoveCompatibilityRequest(
        language: stringFrom(json, const ['language', 'lang']),
        boyIsUser: asBool(json['boy_is_user'] ?? json['boyIsUser']),
        user: asModel(json['user'], LovePersonInput.fromJson),
        partner: asModel(json['partner'], LovePersonInput.fromJson),
      );
  JsonMap toJson() => {
    'language': language,
    'boy_is_user': boyIsUser,
    'user': user?.toJson(),
    'partner': partner?.toJson(),
  };
  LoveCompatibilityRequest copyWith({
    Object? language = contractUnchanged,
    Object? boyIsUser = contractUnchanged,
    Object? user = contractUnchanged,
    Object? partner = contractUnchanged,
  }) => LoveCompatibilityRequest(
    language: identical(language, contractUnchanged)
        ? this.language
        : language as String?,
    boyIsUser: identical(boyIsUser, contractUnchanged)
        ? this.boyIsUser
        : boyIsUser as bool?,
    user: identical(user, contractUnchanged)
        ? this.user
        : user as LovePersonInput?,
    partner: identical(partner, contractUnchanged)
        ? this.partner
        : partner as LovePersonInput?,
  );
  @override
  List<Object?> get props => [language, boyIsUser, user, partner];
}

final class LoveApiResponse<T extends LoveResult> extends ContractValue {
  const LoveApiResponse({this.ok, this.data, this.error});
  final bool? ok;
  final T? data;
  final String? error;
  factory LoveApiResponse.fromJson(
    JsonMap json,
    T Function(JsonMap json) dataFromJson,
  ) => LoveApiResponse(
    ok: asBool(json['ok']),
    data: asModel(json['data'], dataFromJson),
    error: asString(json['error']),
  );
  JsonMap toJson() => {'ok': ok, 'data': data?.toJson(), 'error': error};
  LoveApiResponse<T> copyWith({
    Object? ok = contractUnchanged,
    Object? data = contractUnchanged,
    Object? error = contractUnchanged,
  }) => LoveApiResponse<T>(
    ok: identical(ok, contractUnchanged) ? this.ok : ok as bool?,
    data: identical(data, contractUnchanged) ? this.data : data as T?,
    error: identical(error, contractUnchanged) ? this.error : error as String?,
  );
  @override
  List<Object?> get props => [ok, data, error];
}

sealed class LoveResult extends ContractValue {
  const LoveResult();

  factory LoveResult.fromJson(JsonMap json, {String? type}) {
    final normalized = type?.trim().toLowerCase();
    if (normalized == 'mangal_dosh' ||
        json.containsKey('mangal_dosh') ||
        json.containsKey('boy')) {
      return MangalDoshaResult.fromJson(json);
    }
    if (normalized == 'marriage_probability' ||
        json.containsKey('user_result')) {
      return MarriageProbabilityResult.fromJson(json);
    }
    if (normalized == 'truth_or_dare' || json.containsKey('blocks')) {
      return TruthOrDareResult.fromJson(json);
    }
    return MatchMakingResult.fromJson(json);
  }

  JsonMap toJson();
  LoveResult copyWith();
}

final class LoveResultSection extends ContractValue {
  const LoveResultSection({this.id, this.title, this.data});
  final String? id;
  final String? title;
  final JsonMap? data;
  factory LoveResultSection.fromJson(JsonMap json) => LoveResultSection(
    id: asString(json['id']),
    title: asString(json['title']),
    data: asJsonMap(json['data']),
  );
  JsonMap toJson() => {'id': id, 'title': title, 'data': data};
  LoveResultSection copyWith({
    Object? id = contractUnchanged,
    Object? title = contractUnchanged,
    Object? data = contractUnchanged,
  }) => LoveResultSection(
    id: identical(id, contractUnchanged) ? this.id : id as String?,
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    data: identical(data, contractUnchanged) ? this.data : data as JsonMap?,
  );
  @override
  List<Object?> get props => [id, title, data];
}

final class KootaResult extends ContractValue {
  const KootaResult({this.name, this.score, this.maxScore, this.notes});
  final String? name;
  final double? score;
  final double? maxScore;
  final String? notes;
  factory KootaResult.fromJson(JsonMap json) => KootaResult(
    name: stringFrom(json, const ['name', 'koota']),
    score: asDouble(json['score']),
    maxScore: asDouble(json['max_score']),
    notes: stringFrom(json, const ['notes', 'reason']),
  );
  JsonMap toJson() => {
    'name': name,
    'score': score,
    'max_score': maxScore,
    'notes': notes,
  };
  KootaResult copyWith({
    Object? name = contractUnchanged,
    Object? score = contractUnchanged,
    Object? maxScore = contractUnchanged,
    Object? notes = contractUnchanged,
  }) => KootaResult(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    score: identical(score, contractUnchanged) ? this.score : score as double?,
    maxScore: identical(maxScore, contractUnchanged)
        ? this.maxScore
        : maxScore as double?,
    notes: identical(notes, contractUnchanged) ? this.notes : notes as String?,
  );
  @override
  List<Object?> get props => [name, score, maxScore, notes];
}

final class AshtakootResult extends ContractValue {
  const AshtakootResult({this.totalScore, this.maxScore, this.kootas});
  final double? totalScore;
  final double? maxScore;
  final List<KootaResult>? kootas;
  factory AshtakootResult.fromJson(JsonMap json) => AshtakootResult(
    totalScore: asDouble(json['total_score'] ?? json['score']),
    maxScore: asDouble(json['max_score']),
    kootas: asModelList(
      json['kootas'] ?? json['details'],
      KootaResult.fromJson,
    ),
  );
  JsonMap toJson() => {
    'total_score': totalScore,
    'max_score': maxScore,
    'kootas': modelsToJson(kootas, (item) => item.toJson()),
  };
  AshtakootResult copyWith({
    Object? totalScore = contractUnchanged,
    Object? maxScore = contractUnchanged,
    Object? kootas = contractUnchanged,
  }) => AshtakootResult(
    totalScore: identical(totalScore, contractUnchanged)
        ? this.totalScore
        : totalScore as double?,
    maxScore: identical(maxScore, contractUnchanged)
        ? this.maxScore
        : maxScore as double?,
    kootas: identical(kootas, contractUnchanged)
        ? this.kootas
        : kootas as List<KootaResult>?,
  );
  @override
  List<Object?> get props => [totalScore, maxScore, kootas];
}

final class CompatibilityVerdict extends ContractValue {
  const CompatibilityVerdict({this.level, this.reasonLine, this.scorePercent});
  final String? level;
  final String? reasonLine;
  final double? scorePercent;
  factory CompatibilityVerdict.fromJson(JsonMap json) => CompatibilityVerdict(
    level: asString(json['level']),
    reasonLine: asString(json['reason_line']),
    scorePercent: asDouble(json['score_pct']),
  );
  JsonMap toJson() => {
    'level': level,
    'reason_line': reasonLine,
    'score_pct': scorePercent,
  };
  CompatibilityVerdict copyWith({
    Object? level = contractUnchanged,
    Object? reasonLine = contractUnchanged,
    Object? scorePercent = contractUnchanged,
  }) => CompatibilityVerdict(
    level: identical(level, contractUnchanged) ? this.level : level as String?,
    reasonLine: identical(reasonLine, contractUnchanged)
        ? this.reasonLine
        : reasonLine as String?,
    scorePercent: identical(scorePercent, contractUnchanged)
        ? this.scorePercent
        : scorePercent as double?,
  );
  @override
  List<Object?> get props => [level, reasonLine, scorePercent];
}

final class MatchMakingResult extends LoveResult {
  const MatchMakingResult({this.ashtakoot, this.verdict, this.sections});
  final AshtakootResult? ashtakoot;
  final CompatibilityVerdict? verdict;
  final List<LoveResultSection>? sections;
  factory MatchMakingResult.fromJson(JsonMap json) => MatchMakingResult(
    ashtakoot: asModel(json['ashtakoot'], AshtakootResult.fromJson),
    verdict: asModel(json['verdict'], CompatibilityVerdict.fromJson),
    sections: asModelList(json['sections'], LoveResultSection.fromJson),
  );
  @override
  JsonMap toJson() => {
    'ashtakoot': ashtakoot?.toJson(),
    'verdict': verdict?.toJson(),
    'sections': modelsToJson(sections, (item) => item.toJson()),
  };
  @override
  MatchMakingResult copyWith({
    Object? ashtakoot = contractUnchanged,
    Object? verdict = contractUnchanged,
    Object? sections = contractUnchanged,
  }) => MatchMakingResult(
    ashtakoot: identical(ashtakoot, contractUnchanged)
        ? this.ashtakoot
        : ashtakoot as AshtakootResult?,
    verdict: identical(verdict, contractUnchanged)
        ? this.verdict
        : verdict as CompatibilityVerdict?,
    sections: identical(sections, contractUnchanged)
        ? this.sections
        : sections as List<LoveResultSection>?,
  );
  @override
  List<Object?> get props => [ashtakoot, verdict, sections];
}

final class PersonDoshaResult extends ContractValue {
  const PersonDoshaResult({
    this.name,
    this.isMangalic,
    this.severity,
    this.dosha,
    this.remedies,
  });
  final String? name;
  final bool? isMangalic;
  final String? severity;
  final String? dosha;
  final List<String>? remedies;
  factory PersonDoshaResult.fromJson(JsonMap json) => PersonDoshaResult(
    name: asString(json['name']),
    isMangalic: asBool(json['is_mangalic']),
    severity: asString(json['severity']),
    dosha: asString(json['dosha']),
    remedies: asStringList(json['remedies']),
  );
  JsonMap toJson() => {
    'name': name,
    'is_mangalic': isMangalic,
    'severity': severity,
    'dosha': dosha,
    'remedies': remedies,
  };
  PersonDoshaResult copyWith({
    Object? name = contractUnchanged,
    Object? isMangalic = contractUnchanged,
    Object? severity = contractUnchanged,
    Object? dosha = contractUnchanged,
    Object? remedies = contractUnchanged,
  }) => PersonDoshaResult(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    isMangalic: identical(isMangalic, contractUnchanged)
        ? this.isMangalic
        : isMangalic as bool?,
    severity: identical(severity, contractUnchanged)
        ? this.severity
        : severity as String?,
    dosha: identical(dosha, contractUnchanged) ? this.dosha : dosha as String?,
    remedies: identical(remedies, contractUnchanged)
        ? this.remedies
        : remedies as List<String>?,
  );
  @override
  List<Object?> get props => [name, isMangalic, severity, dosha, remedies];
}

final class MangalDoshaResult extends LoveResult {
  const MangalDoshaResult({this.signal, this.summary, this.boy, this.girl});
  final String? signal;
  final String? summary;
  final PersonDoshaResult? boy;
  final PersonDoshaResult? girl;
  factory MangalDoshaResult.fromJson(JsonMap json) {
    final data = asJsonMap(json['mangal_dosh']) ?? json;
    return MangalDoshaResult(
      signal: asString(data['signal']),
      summary: asString(data['summary']),
      boy: asModel(data['boy'], PersonDoshaResult.fromJson),
      girl: asModel(data['girl'], PersonDoshaResult.fromJson),
    );
  }
  @override
  JsonMap toJson() => {
    'mangal_dosh': {
      'signal': signal,
      'summary': summary,
      'boy': boy?.toJson(),
      'girl': girl?.toJson(),
    },
  };
  @override
  MangalDoshaResult copyWith({
    Object? signal = contractUnchanged,
    Object? summary = contractUnchanged,
    Object? boy = contractUnchanged,
    Object? girl = contractUnchanged,
  }) => MangalDoshaResult(
    signal: identical(signal, contractUnchanged)
        ? this.signal
        : signal as String?,
    summary: identical(summary, contractUnchanged)
        ? this.summary
        : summary as String?,
    boy: identical(boy, contractUnchanged)
        ? this.boy
        : boy as PersonDoshaResult?,
    girl: identical(girl, contractUnchanged)
        ? this.girl
        : girl as PersonDoshaResult?,
  );
  @override
  List<Object?> get props => [signal, summary, boy, girl];
}

final class MarriagePersonResult extends ContractValue {
  const MarriagePersonResult({
    this.name,
    this.percent,
    this.band,
    this.reasons,
  });
  final String? name;
  final double? percent;
  final String? band;
  final List<String>? reasons;
  factory MarriagePersonResult.fromJson(JsonMap json) => MarriagePersonResult(
    name: asString(json['name']),
    percent: asDouble(json['pct'] ?? json['probability']),
    band: stringFrom(json, const ['band', 'status']),
    reasons: asStringList(json['reasons']),
  );
  JsonMap toJson() => {
    'name': name,
    'pct': percent,
    'band': band,
    'reasons': reasons,
  };
  MarriagePersonResult copyWith({
    Object? name = contractUnchanged,
    Object? percent = contractUnchanged,
    Object? band = contractUnchanged,
    Object? reasons = contractUnchanged,
  }) => MarriagePersonResult(
    name: identical(name, contractUnchanged) ? this.name : name as String?,
    percent: identical(percent, contractUnchanged)
        ? this.percent
        : percent as double?,
    band: identical(band, contractUnchanged) ? this.band : band as String?,
    reasons: identical(reasons, contractUnchanged)
        ? this.reasons
        : reasons as List<String>?,
  );
  @override
  List<Object?> get props => [name, percent, band, reasons];
}

final class MarriageProbabilityResult extends LoveResult {
  const MarriageProbabilityResult({this.userResult, this.partnerResult});
  final MarriagePersonResult? userResult;
  final MarriagePersonResult? partnerResult;
  factory MarriageProbabilityResult.fromJson(JsonMap json) =>
      MarriageProbabilityResult(
        userResult: asModel(json['user_result'], MarriagePersonResult.fromJson),
        partnerResult: asModel(
          json['partner_result'],
          MarriagePersonResult.fromJson,
        ),
      );
  @override
  JsonMap toJson() => {
    'user_result': userResult?.toJson(),
    'partner_result': partnerResult?.toJson(),
  };
  @override
  MarriageProbabilityResult copyWith({
    Object? userResult = contractUnchanged,
    Object? partnerResult = contractUnchanged,
  }) => MarriageProbabilityResult(
    userResult: identical(userResult, contractUnchanged)
        ? this.userResult
        : userResult as MarriagePersonResult?,
    partnerResult: identical(partnerResult, contractUnchanged)
        ? this.partnerResult
        : partnerResult as MarriagePersonResult?,
  );
  @override
  List<Object?> get props => [userResult, partnerResult];
}

final class TruthOrDareResult extends LoveResult {
  const TruthOrDareResult({this.verdict, this.verdictLine, this.blocks});
  final String? verdict;
  final String? verdictLine;
  final List<LoveResultSection>? blocks;
  factory TruthOrDareResult.fromJson(JsonMap json) => TruthOrDareResult(
    verdict: asString(json['verdict']),
    verdictLine: asString(json['verdict_line']),
    blocks: asModelList(json['blocks'], LoveResultSection.fromJson),
  );
  @override
  JsonMap toJson() => {
    'verdict': verdict,
    'verdict_line': verdictLine,
    'blocks': modelsToJson(blocks, (item) => item.toJson()),
  };
  @override
  TruthOrDareResult copyWith({
    Object? verdict = contractUnchanged,
    Object? verdictLine = contractUnchanged,
    Object? blocks = contractUnchanged,
  }) => TruthOrDareResult(
    verdict: identical(verdict, contractUnchanged)
        ? this.verdict
        : verdict as String?,
    verdictLine: identical(verdictLine, contractUnchanged)
        ? this.verdictLine
        : verdictLine as String?,
    blocks: identical(blocks, contractUnchanged)
        ? this.blocks
        : blocks as List<LoveResultSection>?,
  );
  @override
  List<Object?> get props => [verdict, verdictLine, blocks];
}

final class LoveReportHandoff extends ContractValue {
  const LoveReportHandoff({this.reportId, this.reportTitle, this.request});
  final String? reportId;
  final String? reportTitle;
  final LoveCompatibilityRequest? request;
  factory LoveReportHandoff.fromJson(JsonMap json) => LoveReportHandoff(
    reportId: stringFrom(json, const ['report_id', 'id']),
    reportTitle: stringFrom(json, const ['report_title', 'title']),
    request: asModel(
      json['love_payload'] ?? json['request'],
      LoveCompatibilityRequest.fromJson,
    ),
  );
  JsonMap toJson() => {
    'report_id': reportId,
    'report_title': reportTitle,
    'love_payload': request?.toJson(),
  };
  LoveReportHandoff copyWith({
    Object? reportId = contractUnchanged,
    Object? reportTitle = contractUnchanged,
    Object? request = contractUnchanged,
  }) => LoveReportHandoff(
    reportId: identical(reportId, contractUnchanged)
        ? this.reportId
        : reportId as String?,
    reportTitle: identical(reportTitle, contractUnchanged)
        ? this.reportTitle
        : reportTitle as String?,
    request: identical(request, contractUnchanged)
        ? this.request
        : request as LoveCompatibilityRequest?,
  );
  @override
  List<Object?> get props => [reportId, reportTitle, request];
}
