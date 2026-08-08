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
  const InAppWebView({super.key, required this.url, this.title});

  final String url;
  final String? title;

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
          // Never intercept navigation — everything stays inside the app,
          // matching the existing WebView (BlogReaderPage) behavior.
          onNavigationRequest: (request) => NavigationDecision.navigate,
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
