import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

class EngagementCardsWidget extends StatelessWidget {
  const EngagementCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          /// Top Row
          Row(
            children: [
              Expanded(
                child: _card(
                  context,
                  title: "Perfect Match",
                  subtitle: "Check love compatibility",
                  icon: Icons.favorite,
                  route: "/love-compatibility",
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _card(
                  context,
                  title: "Yog & Dosh",
                  subtitle: "Discover powerful yogas",
                  icon: Icons.auto_awesome,
                  route: "/yog-dosh",
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// Bottom Full Width Card
          _card(
            context,
            title: "Ask Astrology AI",
            subtitle: "Ask about love, career or life",
            icon: Icons.chat_bubble_outline,
            route: "/asknow",
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: () {
        context.go(route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: fullWidth ? 90 : 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
