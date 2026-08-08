import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/repositories/event_repository.dart';
import 'package:jyotishasha_app/core/repositories/implementations/http_event_repository.dart';
import 'package:jyotishasha_app/core/resources/resource_router.dart';
import 'package:jyotishasha_app/core/sharing/share_service.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// Single, generic landing page every notification tap resolves to.
///
/// Fetches the backend Event Resource for the tapped notification's
/// `eventId` and renders Title/Body/Type/Date. "Know More" navigates via
/// [ResourceRouter]; "Share" builds a [ShareableContent] and hands it to
/// the centralized [ShareService] — this page never talks to the share
/// plugin or formats share text itself.
class EventDispatcherPage extends StatefulWidget {
  const EventDispatcherPage({
    super.key,
    this.destination,
    EventRepository? eventRepository,
  }) : _eventRepository = eventRepository;

  final NotificationDispatchDestination? destination;
  final EventRepository? _eventRepository;

  @override
  State<EventDispatcherPage> createState() => _EventDispatcherPageState();
}

class _EventDispatcherPageState extends State<EventDispatcherPage> {
  late final EventRepository _repository =
      widget._eventRepository ?? HttpEventRepository();
  late final int? _eventId = int.tryParse(widget.destination?.eventId ?? '');

  Future<EventResourceResponse>? _future;

  @override
  void initState() {
    super.initState();
    final eventId = _eventId;
    if (eventId != null) {
      _future = _load(eventId);
    }
  }

  // `async` is deliberate, not stylistic: it guarantees any exception the
  // injected repository raises — sync or async — becomes this Future's
  // error instead of propagating synchronously out of initState().
  Future<EventResourceResponse> _load(int eventId) async {
    final language = context.read<LanguageProvider>().currentLang;
    return _repository.getEventResource(eventId: eventId, language: language);
  }

  // Builds a ShareableContent from this event and hands it to the
  // centralized ShareService — no share-plugin call and no text formatting
  // happens on this page. The branding/label strings are resolved via
  // AppLocalizations, which already reflects the app's current locale, so
  // the share text automatically follows whatever language this event's
  // title/body were fetched in (both ultimately driven by the same
  // LanguageProvider.currentLang) — nothing is ever hardcoded to English.
  void _shareEvent(
    BuildContext context, {
    required String? title,
    required String? description,
    required String? canonicalUrl,
  }) {
    final t = AppLocalizations.of(context)!;
    ShareService.share(
      ShareableContent(
        title: title ?? t.appName,
        description: description,
        canonicalUrl: canonicalUrl,
        brandingTagline: t.shareBranding,
        downloadAppLabel: t.shareDownloadApp,
        visitWebsiteLabel: t.shareVisitWebsite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? 16.0
        : 20.0;

    return Scaffold(
      appBar: AppBar(title: Text(t.eventDetailAppBarTitle)),
      body: _eventId == null
          ? _CenteredMessage(
              text: t.eventNoDataAvailable,
              theme: theme,
              horizontalPadding: horizontalPadding,
            )
          : FutureBuilder<EventResourceResponse>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _CenteredMessage(
                    text: t.eventLoadError,
                    theme: theme,
                    horizontalPadding: horizontalPadding,
                  );
                }

                final event = snapshot.data!.event;
                if (event == null) {
                  return _CenteredMessage(
                    text: t.eventNoDataAvailable,
                    theme: theme,
                    horizontalPadding: horizontalPadding,
                  );
                }

                final resource = snapshot.data!.resource;

                // TEMP LOG (BUG-011B)
                debugPrint(
                  '[BUG-011B][EventDispatcherPage] RAW URL from backend resource: ${resource?.url}',
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.type != null && event.type!.isNotEmpty) ...[
                        Chip(
                          label: Text(event.type!.toUpperCase()),
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Event title — the most prominent element on the page.
                      Text(
                        event.title ?? '-',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatEventDate(event.date),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Body copy — generous line height for readability.
                      Text(
                        event.body ?? '-',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      if (resource != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                ResourceRouter.open(context, resource),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            child: Text(t.eventKnowMoreCta),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _shareEvent(
                            context,
                            title: event.title,
                            description: event.body,
                            canonicalUrl: resource?.url,
                          ),
                          icon: const Icon(Icons.ios_share),
                          label: Text(t.eventShareCta),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Formats a backend date string (e.g. `2026-07-11`) as `DD-MM-YYYY`.
/// Falls back to the raw value rather than crashing or hiding it if the
/// backend ever sends something unparseable.
String _formatEventDate(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) return '-';
  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) return rawDate;

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString().padLeft(4, '0');
  return '$day-$month-$year';
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.text,
    required this.theme,
    required this.horizontalPadding,
  });

  final String text;
  final ThemeData theme;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
