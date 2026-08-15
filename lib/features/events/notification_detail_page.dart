import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// N1 (Navigation Reliability) — the destination for every notification tap
/// whose `eventId` is NOT a resolvable AstroEvent integer id: Personalized
/// Alerts (semantic catalog keys, e.g. `"mood_positive"`) and Dasha/
/// Dasha-pre (composite ids, e.g. `"dasha_pre_{uid}_{maha}_{antar}"`)
/// today, plus any future type or malformed-but-not-empty payload that
/// lands here the same way — see
/// `NotificationNavigationService._resolveRoute()`'s own docstring for the
/// routing decision that sends destinations here instead of `/event`.
///
/// Renders ONLY what the notification itself already carried
/// (`title`/`body`/`payload`, captured on [NotificationDispatchDestination]
/// at parse time — see that class's own docstring) — no backend fetch, no
/// id lookup, since there is no numeric id to look anything up by. This is
/// what makes the fix safe: it never forces a semantic/composite id
/// through `EventDispatcherPage`'s `int.tryParse()`, and it never invents
/// content the backend didn't actually send.
///
/// `category`/`severity` (Alerts) and `mahadasha`/`antardasha` (Dasha/
/// Dasha-pre) are shown as small context chips when present in
/// [NotificationDispatchDestination.payload] — the same keys
/// `modules/alerts/notification_content_adapter.py` and
/// `services/notification_builder.py` already put there for the push
/// itself; nothing here is derived or guessed.
class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key, this.destination});

  final NotificationDispatchDestination? destination;

  bool get _hasTitle => (destination?.title ?? '').trim().isNotEmpty;
  bool get _hasBody => (destination?.body ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? 16.0
        : 20.0;

    return Scaffold(
      appBar: AppBar(title: Text(t.notificationDetailAppBarTitle)),
      body: (_hasTitle || _hasBody)
          ? SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: _buildContent(t, theme),
            )
          : _CenteredMessage(
              text: t.notificationDetailNoDetails,
              theme: theme,
              horizontalPadding: horizontalPadding,
            ),
    );
  }

  Widget _buildContent(AppLocalizations t, ThemeData theme) {
    final chips = _buildContextChips(t);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 8, children: chips),
          const SizedBox(height: 16),
        ],
        if (_hasTitle) ...[
          Text(
            destination!.title!,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_hasBody)
          Text(
            destination!.body!,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
      ],
    );
  }

  List<Widget> _buildContextChips(AppLocalizations t) {
    final payload = destination?.payload ?? const {};
    final chips = <Widget>[];

    final category = _stringOrNull(payload['category']);
    if (category != null) {
      chips.add(
        _InfoChip(
          label: t.notificationDetailCategoryLabel,
          value: _titleCase(category),
        ),
      );
    }

    final severity = _stringOrNull(payload['severity']);
    if (severity != null) {
      chips.add(
        _InfoChip(
          label: t.notificationDetailSeverityLabel,
          value: _titleCase(severity),
        ),
      );
    }

    final mahadasha = _stringOrNull(payload['mahadasha']);
    if (mahadasha != null) {
      chips.add(
        _InfoChip(label: t.notificationDetailMahadashaLabel, value: mahadasha),
      );
    }

    final antardasha = _stringOrNull(payload['antardasha']);
    if (antardasha != null) {
      chips.add(
        _InfoChip(
          label: t.notificationDetailAntardashaLabel,
          value: antardasha,
        ),
      );
    }

    return chips;
  }

  static String? _stringOrNull(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _titleCase(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text('$label: $value'),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
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
