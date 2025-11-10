import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class BlogCarouselWidget extends StatelessWidget {
  final List<Map<String, String>> blogs;
  final VoidCallback? onExplore;

  const BlogCarouselWidget({super.key, required this.blogs, this.onExplore});

  @override
  Widget build(BuildContext context) {
    // 🌈 Jyotishasha gradient (saffron → purple)
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
          // 🔹 Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gradient heading
              ShaderMask(
                shaderCallback: (bounds) => jyotishashaGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: Text(
                  "Astrology Blog",
                  style: GoogleFonts.playfairDisplay(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // placeholder for gradient
                    ),
                  ),
                ),
              ),

              // Light-feel gradient "Explore Blog" link
              GestureDetector(
                onTap: onExplore ?? () => context.go('/blogs'),
                child: ShaderMask(
                  shaderCallback: (bounds) => jyotishashaGradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    "Explore Blog →",
                    style: GoogleFonts.montserrat(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500, // lighter feel
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔹 Horizontal Blog Cards (Greeting-style)
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: blogs.length,
              itemBuilder: (context, index) {
                final blog = blogs[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    // 🌸 Greeting-style soft background
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFF3E8FF), // soft lavender tint
                      ],
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
                      // 🔸 Image
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          blog['image'] ?? '',
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => Container(
                            height: 90,
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

                      // 🔸 Text Content
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Blog Title
                            Text(
                              blog['title'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF240046), // violet text
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Blog Tag
                            Text(
                              blog['tag'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5A189A), // deep purple tag
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
