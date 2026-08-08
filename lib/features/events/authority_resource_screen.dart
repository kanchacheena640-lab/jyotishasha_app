import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/widgets/in_app_webview.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// Opens the Authority resource's URL inside the app via the existing
/// generic WebView.
///
/// The backend is the single source of truth for this URL
/// (`resource.url`) — Flutter never constructs, resolves, or concatenates
/// it here. When the backend hasn't provided one yet, this shows a plain
/// empty state instead of a WebView; any other URL problem (invalid
/// syntax, load failure, offline) is handled entirely by the WebView
/// itself, not duplicated here.
class AuthorityResourceScreen extends StatelessWidget {
  const AuthorityResourceScreen({super.key, required this.resource});

  final ResourceDto resource;

  @override
  Widget build(BuildContext context) {
    final url = resource.url;
    final t = AppLocalizations.of(context)!;

    // TEMP LOG (BUG-011B)
    debugPrint('[BUG-011B][AuthorityResourceScreen] URL passed to InAppWebView: $url');

    if (url == null) {
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(t.authorityAppBarTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.authorityContentNotAvailableTitle,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t.authorityContentNotAvailableBody,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InAppWebView(url: url, title: t.authorityAppBarTitle);
  }
}
