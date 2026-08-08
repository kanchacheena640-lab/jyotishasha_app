import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';

void main() {
  group('EventResourceResponse.fromJson', () {
    test('parses the documented response with a non-null resource', () {
      final json = {
        'schema_version': 1,
        'event': {
          'id': 62,
          'type': 'vrat',
          'title': 'Trisparsha Mahadwadashi, Yogini Ekadashi Tomorrow',
          'body': '...',
          'date': '2026-07-11',
        },
        'resource': {
          'type': 'authority',
          'id': 'ekadashi/yogini',
          'url': 'https://jyotishasha.com/en/ekadashi/yogini',
          'meta': {},
        },
      };

      final response = EventResourceResponse.fromJson(json);

      expect(response.schemaVersion, 1);
      expect(response.event?.id, 62);
      expect(response.event?.type, 'vrat');
      expect(
        response.event?.title,
        'Trisparsha Mahadwadashi, Yogini Ekadashi Tomorrow',
      );
      expect(response.event?.body, '...');
      expect(response.event?.date, '2026-07-11');
      expect(response.resource?.type, 'authority');
      expect(response.resource?.id, 'ekadashi/yogini');
      expect(
        response.resource?.url,
        'https://jyotishasha.com/en/ekadashi/yogini',
      );
      expect(response.resource?.meta, <String, dynamic>{});
    });

    test('parses the documented response with resource: null', () {
      final json = {
        'schema_version': 1,
        'event': {
          'id': 62,
          'type': 'vrat',
          'title': 'Trisparsha Mahadwadashi, Yogini Ekadashi Tomorrow',
          'body': '...',
          'date': '2026-07-11',
        },
        'resource': null,
      };

      final response = EventResourceResponse.fromJson(json);

      expect(response.event, isNotNull);
      expect(response.resource, isNull);
    });

    test('round-trips through toJson without losing fields', () {
      const response = EventResourceResponse(
        schemaVersion: 1,
        event: EventDto(
          id: 62,
          type: 'vrat',
          title: 'Title',
          body: 'Body',
          date: '2026-07-11',
        ),
        resource: ResourceDto(
          type: 'authority',
          id: 'ekadashi/yogini',
          url: 'https://jyotishasha.com/en/ekadashi/yogini',
        ),
      );

      final roundTripped = EventResourceResponse.fromJson(response.toJson());

      expect(roundTripped, response);
    });
  });
}
