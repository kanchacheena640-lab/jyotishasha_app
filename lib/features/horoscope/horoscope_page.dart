import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/state/daily_provider.dart';
import 'package:jyotishasha_app/core/widgets/horoscope_card_widget.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';

class HoroscopePage extends StatefulWidget {
  final int initialTab; // 👈 For Today (0), Tomorrow (1), Weekly (2)

  const HoroscopePage({
    super.key,
    this.initialTab = 0, // default = Today
  });

  @override
  State<HoroscopePage> createState() => _HoroscopePageState();
}

class _HoroscopePageState extends State<HoroscopePage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab, // 👈 FIXED
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = context.watch<DailyProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Your Horoscope",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,

        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Today"),
            Tab(text: "Tomorrow"),
            Tab(text: "Weekly"),
          ],
        ),
      ),

      body: TabBarView(
        controller: tabController,
        children: [
          // ⭐ TODAY
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: const HoroscopeCardWidget(title: "Today"),
          ),

          // ⭐ TOMORROW (same dynamic card)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: const HoroscopeCardWidget(title: "Tomorrow"),
          ),

          // ⭐ WEEKLY (coming soon)
          _buildWeeklyPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "Weekly horoscope is coming soon...",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}
