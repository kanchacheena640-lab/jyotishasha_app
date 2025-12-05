import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => isLoading = false);
          },
        ),
      )
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
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      body: Stack(
        children: [
          WebViewWidget(controller: controller),

          // Loader
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
        ],
      ),
    );
  }
}
