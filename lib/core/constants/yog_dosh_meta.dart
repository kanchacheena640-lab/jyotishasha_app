// lib/core/constants/yog_dosh_meta.dart

class YogDoshMeta {
  static final List<Map<String, dynamic>> all = [
    {
      "id": "adhi_rajyog",
      "label": "Adhi Rajyog",
      "emoji": "👑",
      "color": 0xFF7C3AED,
    },
    {
      "id": "budh_aditya_yog",
      "label": "Budh-Aditya Yog",
      "emoji": "🧠",
      "color": 0xFF4A90E2,
    },
    {
      "id": "chandra_mangal_yog",
      "label": "Chandra–Mangal Yog",
      "emoji": "🌙🔥",
      "color": 0xFFE53935,
    },
    {"id": "dhan_yog", "label": "Dhan Yog", "emoji": "💰", "color": 0xFF4CAF50},
    {
      "id": "dharma_karmadhipati_rajyog",
      "label": "Dharma-Karmadhipati Rajyog",
      "emoji": "🪔",
      "color": 0xFF6A1B9A,
    },
    {
      "id": "gajakesari_yog",
      "label": "Gajakesari Yog",
      "emoji": "🐘🌙",
      "color": 0xFF8E24AA,
    },
    {
      "id": "kaalsarp_dosh",
      "label": "Kaalsarp Dosh",
      "emoji": "🐍",
      "color": 0xFFD32F2F,
    },
    {
      "id": "kuber_rajyog",
      "label": "Kuber Rajyog",
      "emoji": "🪙",
      "color": 0xFFFFB300,
    },
    {
      "id": "lakshmi_yog",
      "label": "Lakshmi Yog",
      "emoji": "💎",
      "color": 0xFFAD1457,
    },
    {
      "id": "manglik_dosh",
      "label": "Mangal Dosh",
      "emoji": "🔥",
      "color": 0xFFE64A19,
    },
    {
      "id": "neechbhang_rajyog",
      "label": "Neechbhang Rajyog",
      "emoji": "⚡",
      "color": 0xFF3949AB,
    },
    {
      "id": "panch_mahapurush_rajyog",
      "label": "Panch Mahapurush Rajyog",
      "emoji": "🌟",
      "color": 0xFF7E57C2,
    },
    {
      "id": "parashari_rajyog",
      "label": "Parashari Rajyog",
      "emoji": "🔥",
      "color": 0xFFD81B60,
    },
    {
      "id": "rajya_sambandh_rajyog",
      "label": "Rajya Sambandh Rajyog",
      "emoji": "🏛️",
      "color": 0xFF5C6BC0,
    },
    {
      "id": "sadhesati",
      "label": "Sade Sati",
      "emoji": "⏳",
      "color": 0xFF455A64,
    },
    {
      "id": "shubh_kartari_yog",
      "label": "Shubh Kartari Yog",
      "emoji": "🌿",
      "color": 0xFF43A047,
    },
    {
      "id": "vipreet_rajyog",
      "label": "Vipreet Rajyog",
      "emoji": "🌀",
      "color": 0xFF6D4C41,
    },
  ];

  /// Find metadata by ID
  static Map<String, dynamic>? find(String id) {
    try {
      return all.firstWhere((item) => item["id"] == id);
    } catch (_) {
      return null;
    }
  }
}
