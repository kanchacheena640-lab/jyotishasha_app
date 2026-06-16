// 🔥 Card Templates (Final Clean + Paragraph Style)

const Map<String, dynamic> CARD_TEMPLATES = {
  // 🌅 MORNING CARD
  "morning": {
    "type": "morning",

    "title_en": "Good Morning",
    "title_hi": "सुप्रभात",

    // ✅ PARAGRAPH STYLE (NO EXTRA LINE BREAKS)
    "content_en": """Something important today?

Start → Abhijit Muhurta {abhijit}
Avoid → Rahu Kaal {rahu}.""",

    "content_hi": """आज कोई ज़रूरी काम है?

शुभ समय → अभिजीत मुहूर्त {abhijit}
अशुभ समय → राहु काल {rahu}""",

    "cta_en": "Hourly auspicious time alerts on Jyotishasha app.",
    "cta_hi": "हर घंटे मुहुर्थ अलर्ट के लिए Download Jyotishasha",

    "share_text_en": "Download Jyotishasha",
    "share_text_hi": "Jyotishasha ऐप डाउनलोड करें",
  },

  // 🌙 EVENING / NIGHT CARD
  "night": {
    "type": "night",

    "title_en": "Good Night",
    "title_hi": "शुभ रात्रि",

    // ✅ PARAGRAPH STYLE
    "content_en": "{night_thought}",

    "content_hi": "{night_thought}",

    "cta_en": "Not suggestions, get guidance — Jyotishasha App",
    "cta_hi": "केवल दर्शन नहीं, सही मार्गदर्शन - Jyotishasha App",
  },
};
