// lib/data/trending_questions.dart

import 'dart:math';

enum TrendingCategory { general, love, finance }

class TrendingQuestion {
  final String id;
  final TrendingCategory category;
  final String en;
  final String hi;

  const TrendingQuestion({
    required this.id,
    required this.category,
    required this.en,
    required this.hi,
  });
}

/// ------------------------------------------------------------
/// 🔮 MASTER LIST (4–5 per category recommended)
/// ------------------------------------------------------------
const List<TrendingQuestion> _allQuestions = [
  // ---------------- GENERAL ----------------
  TrendingQuestion(
    id: "g1",
    category: TrendingCategory.general,
    en: "How will my day be today as per planetary transits?",
    hi: "आज ग्रहों के गोचर के अनुसार मेरा दिन कैसा रहेगा?",
  ),
  TrendingQuestion(
    id: "g2",
    category: TrendingCategory.general,
    en: "Is today favorable for important decisions?",
    hi: "क्या आज महत्वपूर्ण निर्णय लेने के लिए अनुकूल दिन है?",
  ),
  TrendingQuestion(
    id: "g3",
    category: TrendingCategory.general,
    en: "What should I be careful about today?",
    hi: "आज मुझे किन बातों में सावधानी रखनी चाहिए?",
  ),
  TrendingQuestion(
    id: "g4",
    category: TrendingCategory.general,
    en: "Which area of life needs attention today?",
    hi: "आज जीवन के किस क्षेत्र पर ध्यान देना चाहिए?",
  ),
  TrendingQuestion(
    id: "g5",
    category: TrendingCategory.general,
    en: "Is today good for travel or meetings?",
    hi: "क्या आज यात्रा या मीटिंग के लिए अच्छा दिन है?",
  ),

  // ---------------- LOVE ----------------
  TrendingQuestion(
    id: "l1",
    category: TrendingCategory.love,
    en: "How is my day for love and relationships?",
    hi: "प्यार और रिश्तों के लिए आज का दिन कैसा है?",
  ),
  TrendingQuestion(
    id: "l2",
    category: TrendingCategory.love,
    en: "Is my partner likely to contact me today?",
    hi: "क्या आज मेरा पार्टनर मुझसे संपर्क करेगा?",
  ),
  TrendingQuestion(
    id: "l3",
    category: TrendingCategory.love,
    en: "Is today suitable to express my feelings?",
    hi: "क्या आज अपनी भावनाएं व्यक्त करने के लिए सही है?",
  ),
  TrendingQuestion(
    id: "l4",
    category: TrendingCategory.love,
    en: "Can misunderstandings be resolved today?",
    hi: "क्या आज गलतफहमियां दूर हो सकती हैं?",
  ),

  // ---------------- FINANCE ----------------
  TrendingQuestion(
    id: "f1",
    category: TrendingCategory.finance,
    en: "Is there any financial gain or loss indicated today?",
    hi: "क्या आज धन लाभ या हानि का योग है?",
  ),
  TrendingQuestion(
    id: "f2",
    category: TrendingCategory.finance,
    en: "Should I avoid spending money today?",
    hi: "क्या आज खर्च करने से बचना चाहिए?",
  ),
  TrendingQuestion(
    id: "f3",
    category: TrendingCategory.finance,
    en: "Is today good for business or investments?",
    hi: "क्या आज व्यापार या निवेश के लिए अनुकूल है?",
  ),
  TrendingQuestion(
    id: "f4",
    category: TrendingCategory.finance,
    en: "Any financial caution I should follow today?",
    hi: "आज मुझे कौन-सी आर्थिक सावधानी रखनी चाहिए?",
  ),
];

/// ------------------------------------------------------------
/// 🎯 PUBLIC API
/// ------------------------------------------------------------

/// Returns **daily-random** questions (default = 2)
/// - Same day → same questions
/// - Next day → different questions
List<TrendingQuestion> getTrendingQuestions({
  required TrendingCategory category,
  int count = 2,
}) {
  final pool = _allQuestions.where((q) => q.category == category).toList();

  if (pool.isEmpty) return [];

  // 📅 Date-based seed (daily change, no rebuild jitter)
  final now = DateTime.now();
  final seed = int.parse(
    "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}",
  );

  final rnd = Random(seed);
  pool.shuffle(rnd);

  return pool.take(count.clamp(1, pool.length)).toList();
}

/// Helper: localized text chooser
String localizedQuestionText(
  TrendingQuestion q,
  String lang, // "en" | "hi"
) {
  return lang == "hi" ? q.hi : q.en;
}
