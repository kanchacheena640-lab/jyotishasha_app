import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/models/asknow/asknow_contracts.dart';
import 'package:jyotishasha_app/core/models/cards/card_contracts.dart';
import 'package:jyotishasha_app/core/models/horoscope/horoscope_contracts.dart';
import 'package:jyotishasha_app/core/models/kundali/kundali_contracts.dart';
import 'package:jyotishasha_app/core/models/love/love_contracts.dart';
import 'package:jyotishasha_app/core/models/muhurth/muhurth_contracts.dart';
import 'package:jyotishasha_app/core/models/notifications/notification_contracts.dart';
import 'package:jyotishasha_app/core/models/panchang/panchang_contracts.dart';
import 'package:jyotishasha_app/core/models/reports/report_contracts.dart';
import 'package:jyotishasha_app/core/models/transit/transit_contracts.dart';

void main() {
  test('Kundali contracts preserve nested response aliases', () {
    final response = KundaliResponse.fromJson({
      'ok': true,
      'lagna': 'Aries',
      'moon_sign': 'Taurus',
      'chart_data': {
        'planets': [
          {'name': 'Sun', 'rashi': 'Aries', 'degree': '12.5'},
        ],
      },
      'dasha_summary': {
        'current_block': {'mahadasha': 'Sun', 'antardasha': 'Moon'},
      },
    });

    expect(response.lagnaSign, 'Aries');
    expect(response.chartData?.planets?.single.degree, 12.5);
    expect(response.dashaSummary?.currentAntardasha, 'Moon');
    expect(response, KundaliResponse.fromJson(response.toJson()));
  });

  test('Horoscope contracts preserve audited snake-case fields', () {
    final monthly = MonthlyHoroscope.fromJson({
      'title': 'June',
      'career_money': 'Steady',
      'key_dates': ['1', '10'],
    });

    expect(monthly.careerMoney, 'Steady');
    expect(monthly.toJson()['key_dates'], ['1', '10']);
    expect(monthly.copyWith(title: null).title, isNull);
  });

  test('Panchang contracts parse day, ranges, and chaughadiya', () {
    final response = PanchangResponse.fromJson({
      'selected_date': {
        'sunrise': '06:00',
        'tithi': {'name': 'Ekadashi', 'paksha': 'Shukla'},
        'rahu_kaal': {'start': '10:00', 'end': '11:30'},
        'chaughadiya': {
          'day': [
            {'name': 'Shubh', 'active': 1},
          ],
        },
      },
    });

    expect(response.selectedDate?.tithi?.paksha, 'Shukla');
    expect(response.selectedDate?.rahuKaal?.end, '11:30');
    expect(response.selectedDate?.chaughadiya?.day?.single.active, isTrue);
  });

  test('Transit contracts parse keyed positions and future transitions', () {
    final response = CurrentTransitResponse.fromJson({
      'positions': {
        'Sun': {'rashi': 'Aries', 'degree': '9.5', 'motion': 'Direct'},
      },
      'future_transits': {
        'Sun': [
          {'entering_date': '2026-07-01'},
        ],
      },
    });

    expect(response.positions?['Sun']?.degree, 9.5);
    expect(response.futureTransits?['Sun']?.single.enteringDate, '2026-07-01');
  });

  test('Notification contracts support both list envelopes', () {
    final direct = NotificationListResponse.fromJson([
      {
        'id': '7',
        'title': 'Transit',
        'data': {'route': '/transit'},
      },
    ]);
    final enveloped = NotificationListResponse.fromJson({
      'notifications': [direct.notifications!.single.toJson()],
    });

    expect(direct.notifications?.single.id, 7);
    expect(
      enveloped.notifications?.single.data?.destination?.route,
      '/transit',
    );
  });

  test('Love contracts reuse birth details and type result variants', () {
    final request = LoveCompatibilityRequest.fromJson({
      'language': 'en',
      'boy_is_user': true,
      'user': {'name': 'A', 'dob': '2000-01-01', 'lat': '1.5'},
      'partner': {'name': 'B', 'dob': '2001-01-01'},
    });
    final result = MatchMakingResult.fromJson({
      'ashtakoot': {'total_score': '28', 'max_score': 36},
      'verdict': {'level': 'GOOD', 'score_pct': '77.7'},
    });

    expect(request.user?.birthDetails?.latitude, 1.5);
    expect(result.ashtakoot?.totalScore, 28);
    expect(result.verdict?.scorePercent, 77.7);
  });

  test('Report contracts preserve webhook wire names', () {
    final request = ReportGenerationRequest.fromJson({
      'name': 'Asha',
      'product': 'reports51',
      'latitude': '26.8',
      'longitude': 80.9,
      'purchaseToken': 'purchase-token',
      'user_id': '42',
    });

    expect(request.birthDetails?.latitude, 26.8);
    expect(request.userId, 42);
    expect(request.toJson()['purchase_token'], 'purchase-token');
  });

  test('AskNow contracts normalize answer and token aliases', () {
    final answer = AskAnswerResponse.fromJson({
      'answer': {'answer': 'Guidance'},
      'tokens_left': '3',
    });
    final status = AskNowStatus.fromJson({
      'free_available': 1,
      'remaining': '2',
    });

    expect(answer.answer, 'Guidance');
    expect(answer.remainingTokens, 3);
    expect(status.freeAvailable, isTrue);
    expect(status.remainingTokens, 2);
  });

  test('Muhurth contracts preserve request and result fields', () {
    final request = MuhurthRequest.fromJson({
      'activity': 'marriage',
      'latitude': '26.8',
      'longitude': 80.9,
      'top_k': '3',
    });
    final response = MuhurthResponse.fromJson({
      'results': [
        {
          'date': '2026-07-01',
          'score': '88.5',
          'reasons': [
            {'type': 'tithi', 'description': 'Favourable'},
            'Strong weekday',
          ],
        },
      ],
    });

    expect(request.topK, 3);
    expect(response.results?.single.score, 88.5);
    expect(response.results?.single.reasons?[0].type, 'tithi');
    expect(response.results?.single.reasons?[1].description, 'Strong weekday');
  });

  test('Card contracts type templates, metadata, and reasons', () {
    final feed = CardFeedResponse.fromJson({
      'cards': [
        {
          'type': 'muhurth',
          'design_type': 'minimal',
          'score': 90,
          'template': {'title_en': 'Best time'},
          'meta': {'abhijit': '11:45'},
          'reasons': [
            {'type': 'yoga', 'name': 'Shubh'},
          ],
        },
      ],
    });

    expect(feed.cards?.single.type?.value, 'muhurth');
    expect(feed.cards?.single.score, '90');
    expect(feed.cards?.single.template?.titleEn, 'Best time');
    expect(feed.cards?.single.reasons?.single.name, 'Shubh');
  });
}
