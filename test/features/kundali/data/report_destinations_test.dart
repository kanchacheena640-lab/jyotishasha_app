import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/life_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/planet_report_availability.dart';
import 'package:jyotishasha_app/features/kundali/data/report_destinations.dart';

void main() {
  group('ReportDestinations (F8.8 — centralized URL mapping)', () {
    test('Identity — Ascendant and Moon Sign map to their finder tools', () {
      expect(
        ReportDestinations.identityUrl(IdentitySection.ascendant),
        'https://jyotishasha.com/tools/lagna-finder',
      );
      expect(
        ReportDestinations.identityUrl(IdentitySection.moonSign),
        'https://jyotishasha.com/tools/rashi-finder',
      );
    });

    test('Identity — Nakshatra slugifies the real value when known', () {
      expect(
        ReportDestinations.identityUrl(
          IdentitySection.nakshatra,
          value: 'Purva Ashadha',
        ),
        'https://jyotishasha.com/nakshatra/purva-ashadha',
      );
      expect(
        ReportDestinations.identityUrl(IdentitySection.nakshatra, value: 'Chitra'),
        'https://jyotishasha.com/nakshatra/chitra',
      );
    });

    test(
      'Identity — Nakshatra falls back to the hub page when the value is '
      'unknown/absent (never fabricates a slug)',
      () {
        for (final value in [null, '', '-', '   ']) {
          expect(
            ReportDestinations.identityUrl(
              IdentitySection.nakshatra,
              value: value,
            ),
            'https://jyotishasha.com/nakshatra',
          );
        }
      },
    );

    test(
      'Identity — Mahadasha/Antardasha (COMING_SOON) have no destination',
      () {
        expect(
          ReportDestinations.identityUrl(IdentitySection.mahadasha),
          isNull,
        );
        expect(
          ReportDestinations.identityUrl(IdentitySection.antardasha),
          isNull,
        );
      },
    );

    test('Planetary Influences — all 9 planets map to their transit page', () {
      const expected = {
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

      for (final entry in expected.entries) {
        expect(
          ReportDestinations.planetUrl(entry.key),
          'https://jyotishasha.com/${entry.value}',
        );
      }
      // Every PlanetSection has a mapping — none silently missing.
      for (final section in PlanetSection.values) {
        expect(ReportDestinations.planetUrl(section), isNotNull);
      }
    });

    test(
      'Yog & Dosh — every id with a known Next.js page resolves to '
      '/tools/{slug}',
      () {
        const expected = {
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
        };

        for (final entry in expected.entries) {
          expect(
            ReportDestinations.yogDoshUrl(entry.key),
            'https://jyotishasha.com/tools/${entry.value}',
          );
        }
      },
    );

    test(
      'Yog & Dosh — budh_aditya_yog has no known destination (confirmed '
      'no matching Next.js page exists) — a known gap, not a guess',
      () {
        expect(ReportDestinations.yogDoshUrl('budh_aditya_yog'), isNull);
      },
    );

    test(
      'Yog & Dosh — an unrecognized id also has no destination (never '
      'fabricates a URL for something outside the known catalog)',
      () {
        expect(ReportDestinations.yogDoshUrl('some_future_yog'), isNull);
      },
    );

    test(
      'Life Areas — only the 4 AVAILABLE categories resolve to a real '
      'page',
      () {
        expect(
          ReportDestinations.lifeAreaUrl(LifeAreaSection.loveRelationship),
          'https://jyotishasha.com/tools/love-life',
        );
        expect(
          ReportDestinations.lifeAreaUrl(LifeAreaSection.career),
          'https://jyotishasha.com/tools/career-path',
        );
        expect(
          ReportDestinations.lifeAreaUrl(LifeAreaSection.marriage),
          'https://jyotishasha.com/tools/marriage-path',
        );
        expect(
          ReportDestinations.lifeAreaUrl(LifeAreaSection.foreignTravel),
          'https://jyotishasha.com/tools/foreign-travel',
        );
      },
    );

    test(
      'Life Areas — every COMING_SOON category has no destination (no '
      'dead links behind a disabled-looking CTA)',
      () {
        for (final section in [
          LifeAreaSection.financeWealth,
          LifeAreaSection.family,
          LifeAreaSection.children,
          LifeAreaSection.education,
          LifeAreaSection.health,
          LifeAreaSection.property,
          LifeAreaSection.spirituality,
          LifeAreaSection.legalMatters,
        ]) {
          expect(ReportDestinations.lifeAreaUrl(section), isNull);
        }
      },
    );
  });
}
