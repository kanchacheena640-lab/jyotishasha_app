import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:jyotishasha_app/l10n/app_localizations.dart';

enum _WebViewLoadState { loading, loaded, error }

/// True only when [error] originated from the main frame — i.e. the page
/// itself failed to load, as opposed to a secondary resource (ad, font,
/// analytics call, image, XHR/fetch request) that an already-loaded page
/// happens to be making on its own. Exposed (not private) specifically so
/// this decision can be unit tested without needing a real platform
/// WebView, which `WebResourceError` itself does not require.
@visibleForTesting
bool isMainFrameWebResourceError(WebResourceError error) =>
    error.isForMainFrame == true;

/// Generic, reusable full-screen WebView.
///
/// Any feature that needs to open a URL inside the app should push this
/// widget rather than building its own `WebViewController`/`WebViewWidget`
/// wiring, so there is only ever one WebView architecture to maintain.
/// Handles loading and error/offline states; never injects JavaScript into
/// the page and never intercepts/blocks navigation within it.
class InAppWebView extends StatefulWidget {
  const InAppWebView({
    super.key,
    required this.url,
    this.title,
    this.isNavigationAllowed,
  });

  final String url;
  final String? title;

  /// P3E -- OPT-IN defense-in-depth against redirects. `null` (the
  /// default for every existing call site -- BlogReaderPage,
  /// TransitArticlePage, EventDispatcherPage's "Know More") preserves
  /// this widget's original, unchanged behavior EXACTLY: every navigation
  /// (including any in-page redirect) is allowed, matching this class's
  /// own long-standing "never intercept navigation" contract. Only a
  /// caller that supplies this (today: [CampaignWebResourcePage], via
  /// [AuthorityResourceScreen]) gets BOTH the initial load AND every
  /// subsequent navigation request (redirects, in-page link taps)
  /// checked against it; a rejected navigation fails closed to this
  /// widget's existing error state, never a silent partial load.
  final bool Function(Uri uri)? isNavigationAllowed;

  @override
  State<InAppWebView> createState() => _InAppWebViewState();
}

class _InAppWebViewState extends State<InAppWebView> {
  _WebViewLoadState _state = _WebViewLoadState.loading;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();

    final uri = Uri.tryParse(widget.url);
    final isValid =
        uri != null && (uri.isScheme('http') || uri.isScheme('https'));

    if (!isValid) {
      _state = _WebViewLoadState.error;
      return;
    }

    // P3E -- the initial load itself is checked too, not only subsequent
    // navigation requests below: a caller that opted into
    // [isNavigationAllowed] gets the SAME guarantee on the very first URL,
    // never just on redirects after it.
    if (widget.isNavigationAllowed != null && !widget.isNavigationAllowed!(uri)) {
      _state = _WebViewLoadState.error;
      return;
    }

    // TEMP LOG (BUG-011B)
    debugPrint('[BUG-011B][InAppWebView] RAW URL: ${widget.url}');
    // TEMP LOG (BUG-011B)
    debugPrint('[BUG-011B][InAppWebView] PARSED URI: $uri');
    // TEMP LOG (BUG-011B)
    debugPrint('[BUG-011B][InAppWebView] FINAL URI passed to loadRequest(): ${uri.toString()}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Default (widget.isNavigationAllowed == null): never intercept
          // navigation — everything stays inside the app, matching the
          // existing WebView (BlogReaderPage) behavior, byte-for-byte
          // unchanged for every call site that doesn't opt in below.
          //
          // P3E -- when a caller DOES opt in, every navigation request
          // (a redirect the loaded page issues, a link tap inside it,
          // anything) is checked against the SAME predicate the initial
          // load already was; a rejected request never partially loads --
          // WebViewController stays on its last successfully-loaded
          // content, and the failed request is silently prevented (no
          // error banner for a REJECTED navigation specifically, since
          // this is normal, expected behavior for a page that tries to
          // leave the approved destination, not a load failure).
          onNavigationRequest: (request) {
            final allowed = widget.isNavigationAllowed;
            if (allowed == null) return NavigationDecision.navigate;
            final uri = Uri.tryParse(request.url);
            if (uri == null || !allowed(uri)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _state = _WebViewLoadState.loaded);
          },
          onWebResourceError: (error) {
            if (!isMainFrameWebResourceError(error)) return;
            if (!mounted) return;
            setState(() => _state = _WebViewLoadState.error);
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? '')),
      body: _state == _WebViewLoadState.error
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppLocalizations.of(context)!.webViewLoadError,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_state == _WebViewLoadState.loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
