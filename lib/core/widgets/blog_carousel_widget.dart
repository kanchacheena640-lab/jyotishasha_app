import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/features/blog/blog_reader_page.dart';

class BlogCarouselWidget extends StatelessWidget {
  final List<Map<String, String>> blogs;
  final VoidCallback? onExplore;

  const BlogCarouselWidget({super.key, required this.blogs, this.onExplore});

  @override
  Widget build(BuildContext context) {
    // 🌈 Jyotishasha Gradient (Saffron → Purple)
    const jyotishashaGradient = LinearGradient(
      colors: [Color(0xFFFF9933), Color(0xFF8E2DE2)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header + Explore Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    jyotishashaGradient.createShader(bounds),
                child: Text(
                  "Astrology Blog",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              GestureDetector(
                onTap: onExplore,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      jyotishashaGradient.createShader(bounds),
                  child: Text(
                    "Explore →",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 🔹 Horizontal Blog Cards
          SizedBox(
            height: 190, // ⭐ FINAL PERFECT HEIGHT — no overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: blogs.length,
              itemBuilder: (context, index) {
                final blog = blogs[index];

                return GestureDetector(
                  onTap: () {
                    final url = blog["link"] ?? "";
                    if (url.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlogReaderPage(
                            url: blog["link"] ?? "",
                            title: blog["title"] ?? "Blog",
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF3E8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(1, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ⭐ IMAGE
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            blog["image"] ?? "",
                            height: 95,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) => Container(
                              height: 95,
                              color: const Color(0xFFECE4FF),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // TEXT CONTENT
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blog["title"] ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF240046),
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                blog["tag"] ?? "Astrology",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5A189A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
