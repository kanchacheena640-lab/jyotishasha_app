import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/models/premium_reports/premium_ai_report_contracts.dart';

/// Local, UI-only model for the 5 Premium Report categories (matching the
/// Welcome Gift / Explore Premium Reports Hub set). Every "Premium
/// Report" card opens `BirthChartReportReader` passing only this — no
/// backend id, no entitlement data.
enum PremiumReportType { love, career, finance, health, family }

/// Per-type display content for the landing page, plus [segment] — the
/// backend segment string (`PremiumAiReportSegments`) `BirthChartReportReader`
/// passes to `GET /api/premium-report` for this type's real DNA/Current
/// Phase content. [aboutEn]/[aboutHi] remain in use only as the
/// `fallbackText` shown while a call is in flight or has never been made
/// (mirrors Love's own pre-existing behavior — never a placeholder
/// standing in for real content once the backend has responded).
class PremiumReportContent {
  const PremiumReportContent({
    required this.icon,
    required this.titleEn,
    required this.titleHi,
    required this.aboutEn,
    required this.aboutHi,
    required this.discoverEn,
    required this.discoverHi,
    required this.segment,
  });

  final IconData icon;
  final String titleEn;
  final String titleHi;
  final String aboutEn;
  final String aboutHi;
  final List<String> discoverEn;
  final List<String> discoverHi;
  final String segment;

  String title(bool isHindi) => isHindi ? titleHi : titleEn;
  String about(bool isHindi) => isHindi ? aboutHi : aboutEn;
  List<String> discover(bool isHindi) => isHindi ? discoverHi : discoverEn;
}

extension PremiumReportTypeContent on PremiumReportType {
  PremiumReportContent get content => _content[this]!;

  static const Map<PremiumReportType, PremiumReportContent> _content = {
    PremiumReportType.love: PremiumReportContent(
      icon: Icons.favorite_rounded,
      titleEn: 'Love Report',
      titleHi: 'प्रेम रिपोर्ट',
      aboutEn:
          'Your Love Report explores your relationship patterns, emotional '
          'connections, and compatibility style based on your birth chart '
          'placements.',
      aboutHi:
          'आपकी प्रेम रिपोर्ट आपकी जन्म कुंडली के आधार पर आपके रिश्तों की '
          'प्रवृत्ति, भावनात्मक जुड़ाव और अनुकूलता शैली को समझाती है।',
      discoverEn: [
        'Relationship Nature',
        'Emotional Pattern',
        'Strengths',
        'Challenges',
        'Compatibility Style',
      ],
      discoverHi: [
        'संबंधों की प्रकृति',
        'भावनात्मक प्रवृत्ति',
        'शक्तियां',
        'चुनौतियां',
        'अनुकूलता शैली',
      ],
      segment: PremiumAiReportSegments.love,
    ),
    PremiumReportType.career: PremiumReportContent(
      icon: Icons.work_rounded,
      titleEn: 'Career Report',
      titleHi: 'करियर रिपोर्ट',
      aboutEn:
          'Your Career Report explores your work nature, growth path, and '
          'professional strengths based on your birth chart placements.',
      aboutHi:
          'आपकी करियर रिपोर्ट आपकी जन्म कुंडली के आधार पर आपके कार्य स्वभाव, '
          'विकास पथ और व्यावसायिक शक्तियों को समझाती है।',
      discoverEn: [
        'Work Nature',
        'Growth Path',
        'Strengths',
        'Challenges',
        'Success Timing',
      ],
      discoverHi: [
        'कार्य स्वभाव',
        'विकास पथ',
        'शक्तियां',
        'चुनौतियां',
        'सफलता का समय',
      ],
      segment: PremiumAiReportSegments.career,
    ),
    PremiumReportType.finance: PremiumReportContent(
      icon: Icons.account_balance_wallet_rounded,
      titleEn: 'Finance Report',
      titleHi: 'वित्त रिपोर्ट',
      aboutEn:
          'Your Finance Report explores your money flow, saving pattern, '
          'and financial strengths based on your birth chart placements.',
      aboutHi:
          'आपकी वित्त रिपोर्ट आपकी जन्म कुंडली के आधार पर आपके धन प्रवाह, '
          'बचत प्रवृत्ति और वित्तीय शक्तियों को समझाती है।',
      discoverEn: [
        'Money Flow',
        'Saving Pattern',
        'Strengths',
        'Challenges',
        'Growth Opportunities',
      ],
      discoverHi: [
        'धन प्रवाह',
        'बचत प्रवृत्ति',
        'शक्तियां',
        'चुनौतियां',
        'विकास के अवसर',
      ],
      segment: PremiumAiReportSegments.finance,
    ),
    PremiumReportType.health: PremiumReportContent(
      icon: Icons.spa_rounded,
      titleEn: 'Health Report',
      titleHi: 'स्वास्थ्य रिपोर्ट',
      aboutEn:
          'Your Health Report explores your vitality pattern, body '
          'constitution, and wellness focus based on your birth chart '
          'placements.',
      aboutHi:
          'आपकी स्वास्थ्य रिपोर्ट आपकी जन्म कुंडली के आधार पर आपकी ऊर्जा '
          'प्रवृत्ति, शारीरिक संरचना और कल्याण केंद्र को समझाती है।',
      discoverEn: [
        'Vitality Pattern',
        'Body Constitution',
        'Strengths',
        'Challenges',
        'Wellness Focus',
      ],
      discoverHi: [
        'ऊर्जा प्रवृत्ति',
        'शारीरिक संरचना',
        'शक्तियां',
        'चुनौतियां',
        'कल्याण केंद्र',
      ],
      segment: PremiumAiReportSegments.health,
    ),
    PremiumReportType.family: PremiumReportContent(
      icon: Icons.groups_rounded,
      titleEn: 'Family Report',
      titleHi: 'परिवार रिपोर्ट',
      aboutEn:
          'Your Family Report explores your family bonding, domestic '
          'harmony, and relationship style based on your birth chart '
          'placements.',
      aboutHi:
          'आपकी परिवार रिपोर्ट आपकी जन्म कुंडली के आधार पर आपके पारिवारिक '
          'जुड़ाव, घरेलू सामंजस्य और संबंध शैली को समझाती है।',
      discoverEn: [
        'Family Bonding',
        'Domestic Harmony',
        'Strengths',
        'Challenges',
        'Relationship Style',
      ],
      discoverHi: [
        'पारिवारिक जुड़ाव',
        'घरेलू सामंजस्य',
        'शक्तियां',
        'चुनौतियां',
        'संबंध शैली',
      ],
      segment: PremiumAiReportSegments.family,
    ),
  };
}
