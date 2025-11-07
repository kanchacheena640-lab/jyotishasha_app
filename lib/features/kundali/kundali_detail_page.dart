// lib/features/kundali/kundali_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/features/kundali/kundali_detail_page.dart';

/// 🪔 Kundali Dashboard (Mother Page)
/// - Shows all sections as beautiful cards
/// - Tapping a card opens a focused detail page (placeholders included)
/// - Plug your real widgets later; routes & data wiring are ready.
class KundaliDetailPage extends StatelessWidget {
  final Map<String, dynamic> kundaliData;
  const KundaliDetailPage({super.key, required this.kundaliData});

  @override
  Widget build(BuildContext context) {
    final profile = kundaliData['profile'] ?? {};
    final name = (profile['name'] ?? '').toString();
    final lagna = (kundaliData['lagna_sign'] ?? '--').toString();
    final rashi = (kundaliData['rashi'] ?? '--').toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _Header(name: name, lagna: lagna, rashi: rashi),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.08,
              children: [
                _DashTile(
                  emoji: '🪷',
                  title: 'Birth Summary',
                  subtitle: "${profile['dob'] ?? ''} • ${profile['tob'] ?? ''}",
                  onTap: () => _open(
                    context,
                    'Birth Summary',
                    _KVDetail(
                      title: 'Birth Summary',
                      json: {
                        'profile': kundaliData['profile'],
                        'lagna_sign': kundaliData['lagna_sign'],
                        'rashi': kundaliData['rashi'],
                        'lagna_trait': kundaliData['lagna_trait'],
                      },
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '🧭',
                  title: 'Birth Chart',
                  subtitle: (kundaliData['chart_data']?['ascendant'] ?? '--')
                      .toString(),
                  onTap: () => _open(
                    context,
                    'Birth Chart',
                    _KVDetail(
                      title: 'Birth Chart',
                      json: kundaliData['chart_data'] ?? {},
                      hint:
                          'Placeholder: yahan North-Indian chart + Navamsa render hoga.',
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '🕉️',
                  title: 'Vimshottari Dasha',
                  subtitle: _dashaSubtitle(kundaliData),
                  onTap: () => _open(
                    context,
                    'Vimshottari Dasha',
                    _KVDetail(
                      title: 'Vimshottari Dasha',
                      json: kundaliData['dasha_summary'] ?? {},
                      hint:
                          'Timeline + expand for Mahadasha → Antardasha → Pratyantardasha.',
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '🔮',
                  title: 'Current Dasha',
                  subtitle: _currentBlockLine(kundaliData),
                  onTap: () => _open(
                    context,
                    'Current Dasha Insight',
                    _KVDetail(
                      title: 'Current Dasha Insight',
                      json: kundaliData['grah_dasha_block'] ?? {},
                      hint:
                          'Toggle: Mahadasha / Antardasha / Pratyantardasha impact.',
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '☀️',
                  title: 'Planet Overview',
                  subtitle:
                      '${(kundaliData['planet_overview'] as List?)?.length ?? 0} items',
                  onTap: () => _open(
                    context,
                    'Planet Overview',
                    _ListDetail(
                      title: 'Planet Overview',
                      list: (kundaliData['planet_overview'] as List?) ?? [],
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '🏛️',
                  title: 'House Insights',
                  subtitle:
                      '${(kundaliData['houses_overview'] as List?)?.length ?? 0} houses',
                  onTap: () => _open(
                    context,
                    'House-wise Insights',
                    _ListDetail(
                      title: 'House-wise Insights',
                      list: (kundaliData['houses_overview'] as List?) ?? [],
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '💎',
                  title: 'Gemstone',
                  subtitle:
                      (kundaliData['gemstone_suggestion']?['gemstone'] ?? '--')
                          .toString(),
                  onTap: () => _open(
                    context,
                    'Gemstone & Remedies',
                    _KVDetail(
                      title: 'Gemstone & Remedies',
                      json: kundaliData['gemstone_suggestion'] ?? {},
                      hint: 'CTA cards + remedy bullets + purchase flow later.',
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '⚡',
                  title: 'Yogas & Doshas',
                  subtitle: _activeYogCount(kundaliData),
                  onTap: () => _open(
                    context,
                    'Yogas & Doshas',
                    _MapDetail(
                      title: 'Yogas & Doshas',
                      map:
                          (kundaliData['yogas'] as Map?)
                              ?.cast<String, dynamic>() ??
                          {},
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '🌙',
                  title: 'Moon Traits',
                  subtitle: (kundaliData['moon_traits']?['title'] ?? '--')
                      .toString(),
                  onTap: () => _open(
                    context,
                    'Moon Sign Traits',
                    _KVDetail(
                      title: 'Moon Sign Traits',
                      json: kundaliData['moon_traits'] ?? {},
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '📿',
                  title: 'Life Aspects',
                  subtitle:
                      '${(kundaliData['life_aspects'] as List?)?.length ?? 0} aspects',
                  onTap: () => _open(
                    context,
                    'Life Aspects',
                    _ListDetail(
                      title: 'Life Aspects',
                      list: (kundaliData['life_aspects'] as List?) ?? [],
                    ),
                  ),
                ),
                _DashTile(
                  emoji: '🛰️',
                  title: 'Transit Now',
                  subtitle:
                      '${(kundaliData['transit_analysis'] as List?)?.length ?? 0} items',
                  onTap: () => _open(
                    context,
                    'Transit Analysis',
                    _ListDetail(
                      title: 'Transit Analysis',
                      list: (kundaliData['transit_analysis'] as List?) ?? [],
                      hint:
                          'Transit sentences + date-bound blocks (30-day window) yahan aaenge.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dashaSubtitle(Map<String, dynamic> data) {
    final cb = data['dasha_summary']?['current_block'];
    if (cb == null) return '—';
    final m = (cb['mahadasha'] ?? '').toString();
    final a = (cb['antardasha'] ?? '').toString();
    return m.isEmpty ? '—' : '$m → $a';
  }

  static String _currentBlockLine(Map<String, dynamic> data) {
    final cb = data['dasha_summary']?['current_block'];
    if (cb == null) return '—';
    final period = (cb['period'] ?? '').toString();
    return period.isEmpty ? 'Active period' : period;
  }

  static String _activeYogCount(Map<String, dynamic> data) {
    final yogs = (data['yogas'] as Map?)?.cast<String, dynamic>() ?? {};
    final active = yogs.values
        .where((e) => (e is Map) && (e['is_active'] == true))
        .length;
    return '$active active';
  }

  void _open(BuildContext context, String title, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScaffoldWrap(title: title, child: page),
      ),
    );
  }
}

/// ---------- Header ----------
class _Header extends StatelessWidget {
  final String name;
  final String lagna;
  final String rashi;
  const _Header({required this.name, required this.lagna, required this.rashi});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 170,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🪔 My Kundali Overview',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? '—' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _Chip(text: 'Lagna: $lagna'),
                      const SizedBox(width: 8),
                      _Chip(text: 'Rashi: $rashi'),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Tap a card to dive deeper →',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

/// ---------- Tile ----------
class _DashTile extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _DashTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_DashTile> createState() => _DashTileState();
}

class _DashTileState extends State<_DashTile>
    with SingleTickerProviderStateMixin {
  double _elev = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (v) => setState(() => _elev = v ? 6 : 2),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: _elev,
              offset: const Offset(2, 3),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            Text(
              widget.title,
              maxLines: 2,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                height: 1.2,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              widget.subtitle.isEmpty ? '—' : widget.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Detail Scaffolding ----------
class _ScaffoldWrap extends StatelessWidget {
  final String title;
  final Widget child;
  const _ScaffoldWrap({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(color: Colors.white),
        ),
      ),
      body: SafeArea(child: child),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}

/// ---------- Generic Detail: Key-Value JSON pretty viewer ----------
class _KVDetail extends StatelessWidget {
  final String title;
  final Map<String, dynamic> json;
  final String? hint;
  const _KVDetail({required this.title, required this.json, this.hint});

  @override
  Widget build(BuildContext context) {
    final entries = json.entries.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + (hint == null ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        if (hint != null && i == 0) {
          return _Hint(hint!);
        }
        final e = entries[hint == null ? i : i - 1];
        return _KVCard(k: e.key, v: e.value);
      },
    );
  }
}

class _MapDetail extends StatelessWidget {
  final String title;
  final Map<String, dynamic> map;
  const _MapDetail({required this.title, required this.map});

  @override
  Widget build(BuildContext context) {
    final keys = map.keys.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final k = keys[i];
        final v = map[k];
        return _KVCard(k: k, v: v);
      },
    );
  }
}

class _ListDetail extends StatelessWidget {
  final String title;
  final List list;
  final String? hint;
  const _ListDetail({required this.title, required this.list, this.hint});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length + (hint == null ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        if (hint != null && i == 0) return _Hint(hint!);
        final item = list[hint == null ? i : i - 1];
        return _KVCard(k: 'item ${i + 1}', v: item);
      },
    );
  }
}

/// ---------- Shared Cards ----------
class _KVCard extends StatelessWidget {
  final String k;
  final dynamic v;
  const _KVCard({required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _pretty(v),
            style: GoogleFonts.montserrat(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  static String _pretty(dynamic value) {
    try {
      if (value is String) return value;
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(color: Colors.white, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
