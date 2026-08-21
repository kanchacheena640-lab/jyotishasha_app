import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:jyotishasha_app/core/models/blog_models.dart';

class BlogService {
  static const String _url =
      "https://astroblog.in/wp-json/wp/v2/posts?_embed&categories=1626&per_page=10";

  static Future<List<BlogPost>> fetchBlogs() async {
    try {
      // Release-gate fix (P0): a stalled/never-responding request
      // previously hung this await forever. TimeoutException flows into
      // the existing catch below exactly like any other failure -- same
      // empty-list-on-failure contract.
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        print("❌ Blog fetch failed: ${response.statusCode}");
        return [];
      }

      final List data = jsonDecode(response.body);

      return data.map((json) => BlogPost.fromJson(json)).toList();
    } catch (e) {
      print("❌ Blog fetch exception: $e");
      return [];
    }
  }
}
