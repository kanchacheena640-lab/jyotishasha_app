import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BlogReaderPage extends StatefulWidget {
  final String url;
  final String title;

  const BlogReaderPage({super.key, required this.url, required this.title});

  @override
  State<BlogReaderPage> createState() => _BlogReaderPageState();
}

class _BlogReaderPageState extends State<BlogReaderPage> {
  bool isLoading = true;
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ⭐ MOST IMPORTANT FIX ⭐
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // forces everything to stay inside the app
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            setState(() => isLoading = false);
          },
        ),
      )
      // Load URL inside WebView
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      body: Stack(
        children: [
          WebViewWidget(controller: controller),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
        ],
      ),
    );
  }
}
