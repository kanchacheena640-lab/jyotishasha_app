class CardModel {
  final String type;
  final String designType;
  final String image;

  /// 🔥 NEW (template आधारित rendering)
  final Map<String, dynamic>? template;

  final String? titleEn;
  final String? titleHi;
  final String? contentEn;
  final String? contentHi;

  final String? cta;

  /// 🔥 Dynamic values (API / Panchang)
  final Map<String, dynamic>? meta;

  final String? muhurthType;
  final String? score;
  final String? date;
  final List<dynamic>? reasons;

  CardModel({
    required this.type,
    required this.designType,
    required this.image,
    this.template,
    this.titleEn,
    this.titleHi,
    this.contentEn,
    this.contentHi,
    this.cta,
    this.meta,
    this.muhurthType,
    this.score,
    this.date,
    this.reasons,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      type: json['type'] ?? '',
      designType: json['design_type'] ?? 'minimal',
      image: json['image'] ?? '',

      /// 🔥 template support
      template: json['template'],

      titleEn: json['title_en'],
      titleHi: json['title_hi'],
      contentEn: json['content_en'],
      contentHi: json['content_hi'],

      cta: json['cta'],
      meta: json['meta'],

      muhurthType: json['muhurth_type'],
      score: json['score']?.toString(),
      date: json['date'],
      reasons: json['reasons'],
    );
  }

  // ===============================
  // 🔥 TEMPLATE BASED HELPERS
  // ===============================

  String getTitle(String lang) {
    if (template != null) {
      return lang == 'hi'
          ? template!['title_hi'] ?? ''
          : template!['title_en'] ?? '';
    }

    return lang == 'hi'
        ? (titleHi ?? titleEn ?? "")
        : (titleEn ?? titleHi ?? "");
  }

  String getSubtitle(String lang) {
    if (template != null) {
      return lang == 'hi'
          ? template!['subtitle_hi'] ?? ''
          : template!['subtitle_en'] ?? '';
    }
    return "";
  }

  String getCTA(String lang) {
    // 1. template (highest priority)
    if (template != null) {
      return lang == 'hi'
          ? template!['cta_hi'] ?? ''
          : template!['cta_en'] ?? '';
    }

    // 2. meta (for dynamic cards like insight)
    if (meta != null) {
      return lang == 'hi'
          ? meta!['cta_hi']?.toString() ?? ''
          : meta!['cta_en']?.toString() ?? '';
    }

    // 3. fallback
    return cta ?? "";
  }

  String getFooter(String lang) {
    if (template != null) {
      return lang == 'hi'
          ? template!['footer_hi'] ?? ''
          : template!['footer_en'] ?? '';
    }
    return "";
  }

  String getContent(String lang) {
    String base;

    if (template != null) {
      base = lang == 'hi'
          ? template!['content_hi'] ?? ''
          : template!['content_en'] ?? '';
    } else {
      base = lang == 'hi'
          ? (contentHi ?? contentEn ?? "")
          : (contentEn ?? contentHi ?? "");
    }

    /// 🔥 Placeholder replace
    base = base.replaceAll('{abhijit}', meta?['abhijit'] ?? '--');

    base = base.replaceAll('{rahu}', meta?['rahu'] ?? '--');

    return base;
  }

  // 🔹 fallback (optional)
  String get title => titleEn ?? titleHi ?? "";
  String get content => contentEn ?? contentHi ?? "";
}
