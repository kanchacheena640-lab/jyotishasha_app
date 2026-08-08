import '../models/events/event_resource_contracts.dart';

/// Purpose: owns retrieval of the backend-authored resource attached to a
/// notification/event (title, body, type, date, and an optional linked
/// resource pointer).
///
/// Excluded responsibilities: navigation, resource rendering (Authority
/// page, WebView), and checkout.
abstract interface class EventRepository {
  Future<EventResourceResponse> getEventResource({
    required int eventId,
    required String language,
  });
}
