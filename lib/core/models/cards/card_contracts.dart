import '../contract_support.dart';
import '../muhurth/muhurth_contracts.dart';

final class CardType extends ContractValue {
  const CardType({this.value});
  final String? value;
  factory CardType.fromJson(JsonMap json) =>
      CardType(value: stringFrom(json, const ['value', 'type']));
  JsonMap toJson() => {'value': value};
  CardType copyWith({Object? value = contractUnchanged}) => CardType(
    value: identical(value, contractUnchanged) ? this.value : value as String?,
  );
  @override
  List<Object?> get props => [value];
}

final class CardDesignType extends ContractValue {
  const CardDesignType({this.value});
  final String? value;
  factory CardDesignType.fromJson(JsonMap json) => CardDesignType(
    value: stringFrom(json, const ['value', 'design_type', 'designType']),
  );
  JsonMap toJson() => {'value': value};
  CardDesignType copyWith({Object? value = contractUnchanged}) =>
      CardDesignType(
        value: identical(value, contractUnchanged)
            ? this.value
            : value as String?,
      );
  @override
  List<Object?> get props => [value];
}

final class CardTemplate extends ContractValue {
  const CardTemplate({
    this.titleEn,
    this.titleHi,
    this.subtitleEn,
    this.subtitleHi,
    this.contentEn,
    this.contentHi,
    this.ctaEn,
    this.ctaHi,
    this.footerEn,
    this.footerHi,
    this.shareTextEn,
    this.shareTextHi,
  });
  final String? titleEn;
  final String? titleHi;
  final String? subtitleEn;
  final String? subtitleHi;
  final String? contentEn;
  final String? contentHi;
  final String? ctaEn;
  final String? ctaHi;
  final String? footerEn;
  final String? footerHi;
  final String? shareTextEn;
  final String? shareTextHi;
  factory CardTemplate.fromJson(JsonMap json) => CardTemplate(
    titleEn: asString(json['title_en']),
    titleHi: asString(json['title_hi']),
    subtitleEn: asString(json['subtitle_en']),
    subtitleHi: asString(json['subtitle_hi']),
    contentEn: asString(json['content_en']),
    contentHi: asString(json['content_hi']),
    ctaEn: asString(json['cta_en']),
    ctaHi: asString(json['cta_hi']),
    footerEn: asString(json['footer_en']),
    footerHi: asString(json['footer_hi']),
    shareTextEn: asString(json['share_text_en']),
    shareTextHi: asString(json['share_text_hi']),
  );
  JsonMap toJson() => {
    'title_en': titleEn,
    'title_hi': titleHi,
    'subtitle_en': subtitleEn,
    'subtitle_hi': subtitleHi,
    'content_en': contentEn,
    'content_hi': contentHi,
    'cta_en': ctaEn,
    'cta_hi': ctaHi,
    'footer_en': footerEn,
    'footer_hi': footerHi,
    'share_text_en': shareTextEn,
    'share_text_hi': shareTextHi,
  };
  CardTemplate copyWith({
    Object? titleEn = contractUnchanged,
    Object? titleHi = contractUnchanged,
    Object? subtitleEn = contractUnchanged,
    Object? subtitleHi = contractUnchanged,
    Object? contentEn = contractUnchanged,
    Object? contentHi = contractUnchanged,
    Object? ctaEn = contractUnchanged,
    Object? ctaHi = contractUnchanged,
    Object? footerEn = contractUnchanged,
    Object? footerHi = contractUnchanged,
    Object? shareTextEn = contractUnchanged,
    Object? shareTextHi = contractUnchanged,
  }) => CardTemplate(
    titleEn: identical(titleEn, contractUnchanged)
        ? this.titleEn
        : titleEn as String?,
    titleHi: identical(titleHi, contractUnchanged)
        ? this.titleHi
        : titleHi as String?,
    subtitleEn: identical(subtitleEn, contractUnchanged)
        ? this.subtitleEn
        : subtitleEn as String?,
    subtitleHi: identical(subtitleHi, contractUnchanged)
        ? this.subtitleHi
        : subtitleHi as String?,
    contentEn: identical(contentEn, contractUnchanged)
        ? this.contentEn
        : contentEn as String?,
    contentHi: identical(contentHi, contractUnchanged)
        ? this.contentHi
        : contentHi as String?,
    ctaEn: identical(ctaEn, contractUnchanged) ? this.ctaEn : ctaEn as String?,
    ctaHi: identical(ctaHi, contractUnchanged) ? this.ctaHi : ctaHi as String?,
    footerEn: identical(footerEn, contractUnchanged)
        ? this.footerEn
        : footerEn as String?,
    footerHi: identical(footerHi, contractUnchanged)
        ? this.footerHi
        : footerHi as String?,
    shareTextEn: identical(shareTextEn, contractUnchanged)
        ? this.shareTextEn
        : shareTextEn as String?,
    shareTextHi: identical(shareTextHi, contractUnchanged)
        ? this.shareTextHi
        : shareTextHi as String?,
  );
  @override
  List<Object?> get props => [
    titleEn,
    titleHi,
    subtitleEn,
    subtitleHi,
    contentEn,
    contentHi,
    ctaEn,
    ctaHi,
    footerEn,
    footerHi,
    shareTextEn,
    shareTextHi,
  ];
}

sealed class CardMetadata extends ContractValue {
  const CardMetadata();

  factory CardMetadata.fromJson(JsonMap json, {String? type}) {
    final normalized = type?.trim().toLowerCase();
    if (normalized == 'panchang') return PanchangCardMetadata.fromJson(json);
    if (normalized == 'muhurth') return MuhurthCardMetadata.fromJson(json);
    return GenericCardMetadata.fromJson(json);
  }

  JsonMap toJson();
  CardMetadata copyWith();
}

final class GenericCardMetadata extends CardMetadata {
  const GenericCardMetadata({this.values});
  final JsonMap? values;
  factory GenericCardMetadata.fromJson(JsonMap json) =>
      GenericCardMetadata(values: json);
  @override
  JsonMap toJson() => values ?? const {};
  @override
  GenericCardMetadata copyWith({Object? values = contractUnchanged}) =>
      GenericCardMetadata(
        values: identical(values, contractUnchanged)
            ? this.values
            : values as JsonMap?,
      );
  @override
  List<Object?> get props => [values];
}

final class PanchangCardMetadata extends CardMetadata {
  const PanchangCardMetadata({this.abhijit, this.rahu, this.details});
  final String? abhijit;
  final String? rahu;
  final JsonMap? details;
  factory PanchangCardMetadata.fromJson(JsonMap json) => PanchangCardMetadata(
    abhijit: asString(json['abhijit']),
    rahu: asString(json['rahu']),
    details: json,
  );
  @override
  JsonMap toJson() => {...?details, 'abhijit': abhijit, 'rahu': rahu};
  @override
  PanchangCardMetadata copyWith({
    Object? abhijit = contractUnchanged,
    Object? rahu = contractUnchanged,
    Object? details = contractUnchanged,
  }) => PanchangCardMetadata(
    abhijit: identical(abhijit, contractUnchanged)
        ? this.abhijit
        : abhijit as String?,
    rahu: identical(rahu, contractUnchanged) ? this.rahu : rahu as String?,
    details: identical(details, contractUnchanged)
        ? this.details
        : details as JsonMap?,
  );
  @override
  List<Object?> get props => [abhijit, rahu, details];
}

final class MuhurthCardMetadata extends CardMetadata {
  const MuhurthCardMetadata({this.result});
  final MuhurthResult? result;
  factory MuhurthCardMetadata.fromJson(JsonMap json) =>
      MuhurthCardMetadata(result: MuhurthResult.fromJson(json));
  @override
  JsonMap toJson() => result?.toJson() ?? const {};
  @override
  MuhurthCardMetadata copyWith({Object? result = contractUnchanged}) =>
      MuhurthCardMetadata(
        result: identical(result, contractUnchanged)
            ? this.result
            : result as MuhurthResult?,
      );
  @override
  List<Object?> get props => [result];
}

final class CardShareContent extends ContractValue {
  const CardShareContent({this.title, this.text, this.image});
  final String? title;
  final String? text;
  final String? image;
  factory CardShareContent.fromJson(JsonMap json) => CardShareContent(
    title: asString(json['title']),
    text: stringFrom(json, const ['text', 'share_text']),
    image: asString(json['image']),
  );
  JsonMap toJson() => {'title': title, 'text': text, 'image': image};
  CardShareContent copyWith({
    Object? title = contractUnchanged,
    Object? text = contractUnchanged,
    Object? image = contractUnchanged,
  }) => CardShareContent(
    title: identical(title, contractUnchanged) ? this.title : title as String?,
    text: identical(text, contractUnchanged) ? this.text : text as String?,
    image: identical(image, contractUnchanged) ? this.image : image as String?,
  );
  @override
  List<Object?> get props => [title, text, image];
}

final class AstroCardSource extends ContractValue {
  const AstroCardSource({this.type, this.titleEn, this.titleHi, this.data});
  final String? type;
  final String? titleEn;
  final String? titleHi;
  final JsonMap? data;
  factory AstroCardSource.fromJson(JsonMap json) => AstroCardSource(
    type: asString(json['type']),
    titleEn: asString(json['title_en']),
    titleHi: asString(json['title_hi']),
    data: asJsonMap(json['data'] ?? json['meta']),
  );
  JsonMap toJson() => {
    'type': type,
    'title_en': titleEn,
    'title_hi': titleHi,
    'data': data,
  };
  AstroCardSource copyWith({
    Object? type = contractUnchanged,
    Object? titleEn = contractUnchanged,
    Object? titleHi = contractUnchanged,
    Object? data = contractUnchanged,
  }) => AstroCardSource(
    type: identical(type, contractUnchanged) ? this.type : type as String?,
    titleEn: identical(titleEn, contractUnchanged)
        ? this.titleEn
        : titleEn as String?,
    titleHi: identical(titleHi, contractUnchanged)
        ? this.titleHi
        : titleHi as String?,
    data: identical(data, contractUnchanged) ? this.data : data as JsonMap?,
  );
  @override
  List<Object?> get props => [type, titleEn, titleHi, data];
}

final class InsightCardSource extends ContractValue {
  const InsightCardSource({
    this.titleEn,
    this.titleHi,
    this.contentEn,
    this.contentHi,
    this.ctaEn,
    this.ctaHi,
  });
  final String? titleEn;
  final String? titleHi;
  final String? contentEn;
  final String? contentHi;
  final String? ctaEn;
  final String? ctaHi;
  factory InsightCardSource.fromJson(JsonMap json) => InsightCardSource(
    titleEn: asString(json['title_en']),
    titleHi: asString(json['title_hi']),
    contentEn: asString(json['content_en']),
    contentHi: asString(json['content_hi']),
    ctaEn: asString(json['cta_en']),
    ctaHi: asString(json['cta_hi']),
  );
  JsonMap toJson() => {
    'title_en': titleEn,
    'title_hi': titleHi,
    'content_en': contentEn,
    'content_hi': contentHi,
    'cta_en': ctaEn,
    'cta_hi': ctaHi,
  };
  InsightCardSource copyWith({
    Object? titleEn = contractUnchanged,
    Object? titleHi = contractUnchanged,
    Object? contentEn = contractUnchanged,
    Object? contentHi = contractUnchanged,
    Object? ctaEn = contractUnchanged,
    Object? ctaHi = contractUnchanged,
  }) => InsightCardSource(
    titleEn: identical(titleEn, contractUnchanged)
        ? this.titleEn
        : titleEn as String?,
    titleHi: identical(titleHi, contractUnchanged)
        ? this.titleHi
        : titleHi as String?,
    contentEn: identical(contentEn, contractUnchanged)
        ? this.contentEn
        : contentEn as String?,
    contentHi: identical(contentHi, contractUnchanged)
        ? this.contentHi
        : contentHi as String?,
    ctaEn: identical(ctaEn, contractUnchanged) ? this.ctaEn : ctaEn as String?,
    ctaHi: identical(ctaHi, contractUnchanged) ? this.ctaHi : ctaHi as String?,
  );
  @override
  List<Object?> get props => [
    titleEn,
    titleHi,
    contentEn,
    contentHi,
    ctaEn,
    ctaHi,
  ];
}

final class AppCard extends ContractValue {
  const AppCard({
    this.type,
    this.designType,
    this.image,
    this.template,
    this.titleEn,
    this.titleHi,
    this.contentEn,
    this.contentHi,
    this.cta,
    this.metadata,
    this.muhurthType,
    this.score,
    this.date,
    this.reasons,
  });
  final CardType? type;
  final CardDesignType? designType;
  final String? image;
  final CardTemplate? template;
  final String? titleEn;
  final String? titleHi;
  final String? contentEn;
  final String? contentHi;
  final String? cta;
  final CardMetadata? metadata;
  final String? muhurthType;
  final String? score;
  final String? date;
  final List<MuhurthReason>? reasons;
  factory AppCard.fromJson(JsonMap json) => AppCard(
    type: CardType(value: asString(json['type'])),
    designType: CardDesignType(value: asString(json['design_type'])),
    image: asString(json['image']),
    template: asModel(json['template'], CardTemplate.fromJson),
    titleEn: asString(json['title_en']),
    titleHi: asString(json['title_hi']),
    contentEn: asString(json['content_en']),
    contentHi: asString(json['content_hi']),
    cta: asString(json['cta']),
    metadata: asJsonMap(json['meta']) == null
        ? null
        : CardMetadata.fromJson(
            asJsonMap(json['meta'])!,
            type: asString(json['type']),
          ),
    muhurthType: asString(json['muhurth_type']),
    score: asString(json['score']),
    date: asString(json['date']),
    reasons: json['reasons'] is List
        ? (json['reasons'] as List)
              .map(MuhurthReason.fromValue)
              .toList(growable: false)
        : null,
  );
  JsonMap toJson() => {
    'type': type?.value,
    'design_type': designType?.value,
    'image': image,
    'template': template?.toJson(),
    'title_en': titleEn,
    'title_hi': titleHi,
    'content_en': contentEn,
    'content_hi': contentHi,
    'cta': cta,
    'meta': metadata?.toJson(),
    'muhurth_type': muhurthType,
    'score': score,
    'date': date,
    'reasons': modelsToJson(reasons, (item) => item.toJson()),
  };
  AppCard copyWith({
    Object? type = contractUnchanged,
    Object? designType = contractUnchanged,
    Object? image = contractUnchanged,
    Object? template = contractUnchanged,
    Object? titleEn = contractUnchanged,
    Object? titleHi = contractUnchanged,
    Object? contentEn = contractUnchanged,
    Object? contentHi = contractUnchanged,
    Object? cta = contractUnchanged,
    Object? metadata = contractUnchanged,
    Object? muhurthType = contractUnchanged,
    Object? score = contractUnchanged,
    Object? date = contractUnchanged,
    Object? reasons = contractUnchanged,
  }) => AppCard(
    type: identical(type, contractUnchanged) ? this.type : type as CardType?,
    designType: identical(designType, contractUnchanged)
        ? this.designType
        : designType as CardDesignType?,
    image: identical(image, contractUnchanged) ? this.image : image as String?,
    template: identical(template, contractUnchanged)
        ? this.template
        : template as CardTemplate?,
    titleEn: identical(titleEn, contractUnchanged)
        ? this.titleEn
        : titleEn as String?,
    titleHi: identical(titleHi, contractUnchanged)
        ? this.titleHi
        : titleHi as String?,
    contentEn: identical(contentEn, contractUnchanged)
        ? this.contentEn
        : contentEn as String?,
    contentHi: identical(contentHi, contractUnchanged)
        ? this.contentHi
        : contentHi as String?,
    cta: identical(cta, contractUnchanged) ? this.cta : cta as String?,
    metadata: identical(metadata, contractUnchanged)
        ? this.metadata
        : metadata as CardMetadata?,
    muhurthType: identical(muhurthType, contractUnchanged)
        ? this.muhurthType
        : muhurthType as String?,
    score: identical(score, contractUnchanged) ? this.score : score as String?,
    date: identical(date, contractUnchanged) ? this.date : date as String?,
    reasons: identical(reasons, contractUnchanged)
        ? this.reasons
        : reasons as List<MuhurthReason>?,
  );
  @override
  List<Object?> get props => [
    type,
    designType,
    image,
    template,
    titleEn,
    titleHi,
    contentEn,
    contentHi,
    cta,
    metadata,
    muhurthType,
    score,
    date,
    reasons,
  ];
}

final class CardFeedResponse extends ContractValue {
  const CardFeedResponse({this.cards});
  final List<AppCard>? cards;
  factory CardFeedResponse.fromJson(JsonMap json) =>
      CardFeedResponse(cards: asModelList(json['cards'], AppCard.fromJson));
  JsonMap toJson() => {'cards': modelsToJson(cards, (item) => item.toJson())};
  CardFeedResponse copyWith({Object? cards = contractUnchanged}) =>
      CardFeedResponse(
        cards: identical(cards, contractUnchanged)
            ? this.cards
            : cards as List<AppCard>?,
      );
  @override
  List<Object?> get props => [cards];
}
