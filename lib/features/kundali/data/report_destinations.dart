// lib/features/kundali/data/report_destinations.dart

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/life_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/planet_report_availability.dart';

/// F8.8 — the ONE centralized report-DESTINATION map (as opposed to
/// [IdentityReportAvailability]/`PlanetReportAvailability`/
/// `YogDoshReportAvailability`/[LifeReportAvailability], which decide
/// AVAILABLE vs COMING_SOON). Every "View Full Free Report" CTA on
/// [KundaliOverviewPage] resolves its URL from here — no section builds
/// its own URL, so there's exactly one place to update if a destination
/// ever changes.
///
/// Every URL below was verified directly against the live route
/// structure of the `jyotishasha-frontend` repository — not guessed:
/// `app/[locale]/tools/[toolId]/` (the locked `toolContentMap` in
/// `app/data/toolContent/index.ts`), the per-planet
/// `app/[locale]/{planet}-transit/` routes (the only per-planet page
/// that exists on the site — natal per-planet report pages don't exist,
/// so this reuses the one real destination that does, exactly like
/// `TransitAlertWidget` already links to on Home), and the
/// `app/[locale]/nakshatra/[slug]/` route. No backend change, no
/// Next.js change — this only tells the existing, generic
/// [InAppWebView] widget which existing URL to load.
///
/// `budh_aditya_yog` intentionally has no entry in [_yogDoshSlugs]: no
/// matching Next.js page exists for it (confirmed directly against
/// `toolContentMap`, unlike all 16 other Yog/Dosh ids). Its
/// [YogDoshReportAvailability] entry stays AVAILABLE, untouched — this
/// class does not override availability, only destinations — but
/// `yogDoshUrl` returns `null` for it, so its CTA has no working link
/// until a real page exists. Flagged as a known gap, not silently
/// guessed.
class ReportDestinations {
  const ReportDestinations._();

  static const String _base = 'https://jyotishasha.com';

  // ---------------------------------------------------------------
  // Know Yourself — Ascendant, Moon Sign, Nakshatra. Mahadasha/
  // Antardasha (now the merged Current Dasha card) are COMING_SOON —
  // no destination.
  // ---------------------------------------------------------------

  static String? identityUrl(IdentitySection section, {String? value}) {
    switch (section) {
      case IdentitySection.ascendant:
        return '$_base/tools/lagna-finder';
      case IdentitySection.moonSign:
        return '$_base/tools/rashi-finder';
      case IdentitySection.nakshatra:
        final slug = _slugify(value);
        return slug == null ? '$_base/nakshatra' : '$_base/nakshatra/$slug';
      case IdentitySection.mahadasha:
      case IdentitySection.antardasha:
        return null;
    }
  }

  // ---------------------------------------------------------------
  // Planetary Influences — Sun..Ketu.
  // ---------------------------------------------------------------

  static const Map<PlanetSection, String> _planetSlugs = {
    PlanetSection.sun: 'sun-transit',
    PlanetSection.moon: 'moon-transit',
    PlanetSection.mars: 'mars-transit',
    PlanetSection.mercury: 'mercury-transit',
    PlanetSection.jupiter: 'jupiter-transit',
    PlanetSection.venus: 'venus-transit',
    PlanetSection.saturn: 'saturn-transit',
    PlanetSection.rahu: 'rahu-transit',
    PlanetSection.ketu: 'ketu-transit',
  };

  static String? planetUrl(PlanetSection section) {
    final slug = _planetSlugs[section];
    return slug == null ? null : '$_base/$slug';
  }

  // ---------------------------------------------------------------
  // Yog & Dosh — keyed by the same backend id
  // `YogDoshReportAvailability.statusForId` already uses (the
  // `YogDoshMeta` ids / `kundaliData["yogas"]` keys).
  // ---------------------------------------------------------------

  static const Map<String, String> _yogDoshSlugs = {
    'adhi_rajyog': 'adhi-rajyog',
    'chandra_mangal_yog': 'chandra-mangal',
    'dhan_yog': 'dhan-yog',
    'dharma_karmadhipati_rajyog': 'dharma-karmadhipati',
    'gajakesari_yog': 'gajakesari-yog',
    'kaalsarp_dosh': 'kaalsarp-dosh',
    'kuber_rajyog': 'kuber-rajyog',
    'lakshmi_yog': 'lakshmi-yog',
    'manglik_dosh': 'mangal-dosh',
    'neechbhang_rajyog': 'neechbhang-rajyog',
    'panch_mahapurush_rajyog': 'panch-mahapurush',
    'parashari_rajyog': 'parashari-rajyog',
    'rajya_sambandh_rajyog': 'rajya-sambandh',
    'sadhesati': 'sadhesati-calculator',
    'shubh_kartari_yog': 'shubh-kartari',
    'vipreet_rajyog': 'vipreet-rajyog',
    // 'budh_aditya_yog' intentionally omitted — see class doc.
  };

  static String? yogDoshUrl(String backendId) {
    final slug = _yogDoshSlugs[backendId];
    return slug == null ? null : '$_base/tools/$slug';
  }

  // ---------------------------------------------------------------
  // Life Areas — only the 4 AVAILABLE categories have a real page.
  // ---------------------------------------------------------------

  static const Map<LifeAreaSection, String> _lifeAreaSlugs = {
    LifeAreaSection.loveRelationship: 'love-life',
    LifeAreaSection.career: 'career-path',
    LifeAreaSection.marriage: 'marriage-path',
    LifeAreaSection.foreignTravel: 'foreign-travel',
  };

  static String? lifeAreaUrl(LifeAreaSection section) {
    final slug = _lifeAreaSlugs[section];
    return slug == null ? null : '$_base/tools/$slug';
  }

  static String? _slugify(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '-') return null;
    return trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }
}
