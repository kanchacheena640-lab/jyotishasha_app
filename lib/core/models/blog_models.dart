// lib/core/models/blog_models.dart

class BlogPost {
  final int id;
  final String title;
  final String link;
  final String imageUrl;
  final String excerpt;
  final String date;

  BlogPost({
    required this.id,
    required this.title,
    required this.link,
    required this.imageUrl,
    required this.excerpt,
    required this.date,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    String safeTitle = "";
    if (json["title"] != null && json["title"]["rendered"] != null) {
      safeTitle = json["title"]["rendered"];
    }

    String safeExcerpt = "";
    if (json["excerpt"] != null && json["excerpt"]["rendered"] != null) {
      safeExcerpt = json["excerpt"]["rendered"];
    }

    String img = "";
    try {
      img = json["_embedded"]["wp:featuredmedia"][0]["source_url"] ?? "";
    } catch (_) {
      img = "";
    }

    return BlogPost(
      id: json["id"] ?? 0,
      title: safeTitle.replaceAll(RegExp(r'<[^>]*>'), ''),
      link: json["link"] ?? "",
      imageUrl: img,
      excerpt: safeExcerpt.replaceAll(RegExp(r'<[^>]*>'), ''),
      date: json["date"] ?? "",
    );
  }

  Map<String, String> toMap() {
    return {
      "title": title,
      "image": imageUrl,
      "excerpt": excerpt,
      "link": link,
      "tag": "Astrology",
    };
  }
}
