import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/data/trending_questions.dart';
import 'package:jyotishasha_app/features/asknow/asknow_chat_page.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

class TrendingQuestionsWidget extends StatefulWidget {
  const TrendingQuestionsWidget({super.key});

  @override
  State<TrendingQuestionsWidget> createState() =>
      _TrendingQuestionsWidgetState();
}

class _TrendingQuestionsWidgetState extends State<TrendingQuestionsWidget> {
  TrendingCategory _active = TrendingCategory.general;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLang;
    final t = AppLocalizations.of(context)!;

    final questions = getTrendingQuestions(
      category: _active,
      count: 2, // visible 2 only
    );

    if (questions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- HEADING ----------
          Text(
            lang == "hi" ? "आज के ट्रेंडिंग सवाल" : "Trending Questions Today",
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // ---------- CATEGORY CHIPS (SCROLLABLE) ----------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  label: t.trendingGeneral,
                  active: _active == TrendingCategory.general,
                  onTap: () =>
                      setState(() => _active = TrendingCategory.general),
                ),
                const SizedBox(width: 6),
                _chip(
                  label: t.trendingLove,
                  active: _active == TrendingCategory.love,
                  onTap: () => setState(() => _active = TrendingCategory.love),
                ),
                const SizedBox(width: 6),
                _chip(
                  label: t.trendingFinance,
                  active: _active == TrendingCategory.finance,
                  onTap: () =>
                      setState(() => _active = TrendingCategory.finance),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ---------- QUESTIONS (AUTO TICKER) ----------
          SizedBox(
            height: 42, // 🔒 fixed height = space saving
            child: _QuestionTicker(
              questions: questions
                  .map((q) => localizedQuestionText(q, lang))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ================== CHIP ==================
  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? AppColors.primary : Colors.grey.shade400,
            width: 1,
          ),
          color: active
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _QuestionTicker extends StatefulWidget {
  final List<String> questions;
  const _QuestionTicker({required this.questions});

  @override
  State<_QuestionTicker> createState() => _QuestionTickerState();
}

class _QuestionTickerState extends State<_QuestionTicker> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();

    Future.delayed(const Duration(seconds: 2), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted || widget.questions.length <= 1) return;

    _index = (_index + 1) % widget.questions.length;

    _controller.animateToPage(
      _index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(), // 🔒 auto only
      itemCount: widget.questions.length,
      itemBuilder: (context, i) {
        final text = widget.questions[i];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AskNowChatPage(prefillQuestion: text),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.trending_up, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}
