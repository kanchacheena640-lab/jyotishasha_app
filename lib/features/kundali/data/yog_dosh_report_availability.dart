// lib/features/kundali/data/yog_dosh_report_availability.dart

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart'
    show ReportAvailabilityStatus;

/// The known Yog/Dosh catalog — one member per id in
/// `lib/core/constants/yog_dosh_meta.dart`'s `YogDoshMeta.all`, the same
/// catalog every existing Yog/Dosh widget in this app already keys off.
enum YogDoshSection {
  adhiRajyog,
  budhAdityaYog,
  chandraMangalYog,
  dhanYog,
  dharmaKarmadhipatiRajyog,
  gajakesariYog,
  kaalsarpDosh,
  kuberRajyog,
  lakshmiYog,
  manglikDosh,
  neechbhangRajyog,
  panchMahapurushRajyog,
  parashariRajyog,
  rajyaSambandhRajyog,
  sadhesati,
  shubhKartariYog,
  vipreetRajyog,
}

/// F8.4 — the ONE centralized report-availability configuration for the
/// Yog & Dosh sections, following exactly the same architecture as
/// [IdentityReportAvailability] (F8.2) and `PlanetReportAvailability`
/// (F8.3). Every Yog/Dosh card reads its status from here — nowhere else
/// in the UI branches on availability. Each [YogDoshSection] has exactly
/// one [ReportAvailabilityStatus]; to change what's available, change
/// this map only.
class YogDoshReportAvailability {
  const YogDoshReportAvailability._();

  /// Maps the backend's yog/dosh id (the key used in
  /// `kundaliData["yogas"]`, identical to `YogDoshMeta` ids) to its
  /// [YogDoshSection].
  static const Map<String, YogDoshSection> _sectionById = {
    'adhi_rajyog': YogDoshSection.adhiRajyog,
    'budh_aditya_yog': YogDoshSection.budhAdityaYog,
    'chandra_mangal_yog': YogDoshSection.chandraMangalYog,
    'dhan_yog': YogDoshSection.dhanYog,
    'dharma_karmadhipati_rajyog': YogDoshSection.dharmaKarmadhipatiRajyog,
    'gajakesari_yog': YogDoshSection.gajakesariYog,
    'kaalsarp_dosh': YogDoshSection.kaalsarpDosh,
    'kuber_rajyog': YogDoshSection.kuberRajyog,
    'lakshmi_yog': YogDoshSection.lakshmiYog,
    'manglik_dosh': YogDoshSection.manglikDosh,
    'neechbhang_rajyog': YogDoshSection.neechbhangRajyog,
    'panch_mahapurush_rajyog': YogDoshSection.panchMahapurushRajyog,
    'parashari_rajyog': YogDoshSection.parashariRajyog,
    'rajya_sambandh_rajyog': YogDoshSection.rajyaSambandhRajyog,
    'sadhesati': YogDoshSection.sadhesati,
    'shubh_kartari_yog': YogDoshSection.shubhKartariYog,
    'vipreet_rajyog': YogDoshSection.vipreetRajyog,
  };

  static const Map<YogDoshSection, ReportAvailabilityStatus> _status = {
    YogDoshSection.adhiRajyog: ReportAvailabilityStatus.available,
    YogDoshSection.budhAdityaYog: ReportAvailabilityStatus.available,
    YogDoshSection.chandraMangalYog: ReportAvailabilityStatus.available,
    YogDoshSection.dhanYog: ReportAvailabilityStatus.available,
    YogDoshSection.dharmaKarmadhipatiRajyog:
        ReportAvailabilityStatus.available,
    YogDoshSection.gajakesariYog: ReportAvailabilityStatus.available,
    YogDoshSection.kaalsarpDosh: ReportAvailabilityStatus.available,
    YogDoshSection.kuberRajyog: ReportAvailabilityStatus.available,
    YogDoshSection.lakshmiYog: ReportAvailabilityStatus.available,
    YogDoshSection.manglikDosh: ReportAvailabilityStatus.available,
    YogDoshSection.neechbhangRajyog: ReportAvailabilityStatus.available,
    YogDoshSection.panchMahapurushRajyog: ReportAvailabilityStatus.available,
    YogDoshSection.parashariRajyog: ReportAvailabilityStatus.available,
    YogDoshSection.rajyaSambandhRajyog: ReportAvailabilityStatus.available,
    YogDoshSection.sadhesati: ReportAvailabilityStatus.available,
    YogDoshSection.shubhKartariYog: ReportAvailabilityStatus.available,
    YogDoshSection.vipreetRajyog: ReportAvailabilityStatus.available,
  };

  static ReportAvailabilityStatus statusOf(YogDoshSection section) =>
      _status[section]!;

  /// Resolves status directly from a backend yog/dosh id (the same id
  /// used as a key in `kundaliData["yogas"]`) — the entry point the
  /// Kundali Yog/Dosh sections actually use, since the backend deals in
  /// ids, not [YogDoshSection] values directly. An id outside the known
  /// catalog defaults to [ReportAvailabilityStatus.comingSoon] — a safe,
  /// explicit fallback for an unrecognized entry, never a guess about a
  /// specific yog/dosh's real availability.
  static ReportAvailabilityStatus statusForId(String id) {
    final section = _sectionById[id];
    if (section == null) return ReportAvailabilityStatus.comingSoon;
    return statusOf(section);
  }
}
