import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../enums/love_tool.dart';
import '../providers/love_provider.dart';
import '../widgets/intro_tool_card.dart';

import '../pages/match_making_result_page.dart';
import '../pages/mangal_dosh_result_page.dart';
import '../pages/truth_or_dare_result_page.dart';
import '../pages/marriage_probability_result_page.dart';

class LoveResultHubPage extends StatefulWidget {
  final LoveTool tool;
  final Map<String, dynamic> payload;

  const LoveResultHubPage({
    super.key,
    required this.tool,
    required this.payload,
  });

  @override
  State<LoveResultHubPage> createState() => _LoveResultHubPageState();
}

class _LoveResultHubPageState extends State<LoveResultHubPage> {
  bool _initialized = false;
  // 🔒 navigation guards (VERY IMPORTANT)
  bool _mmNavigated = false;
  bool _mdNavigated = false;
  bool _tdNavigated = false;
  bool _mpNavigated = false;
  LoveTool? _tappedTool;
  late LoveProvider _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _provider = context.read<LoveProvider>();
      _provider.setPayload(widget.payload);
      _provider.addListener(_onProviderUpdate);
      _initialized = true;
    }
  }

  void _onProviderUpdate() {
    if (!mounted) return;

    void pushOnce({
      required bool already,
      required VoidCallback mark,
      required Widget page,
    }) {
      if (already) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        mark();
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      });
    }

    if (_provider.resultFor(LoveTool.matchMaking) != null && !_mmNavigated) {
      pushOnce(
        already: _mmNavigated,
        mark: () => setState(() {
          _mmNavigated = true;
          _tappedTool = null;
        }),
        page: const MatchMakingResultPage(),
      );
    }

    if (_provider.resultFor(LoveTool.mangalDosh) != null && !_mdNavigated) {
      pushOnce(
        already: _mdNavigated,
        mark: () => setState(() {
          _mdNavigated = true;
          _tappedTool = null;
        }),
        page: const MangalDoshResultPage(),
      );
    }

    if (_provider.resultFor(LoveTool.truthOrDare) != null && !_tdNavigated) {
      pushOnce(
        already: _tdNavigated,
        mark: () => setState(() {
          _tdNavigated = true;
          _tappedTool = null;
        }),
        page: const TruthOrDareResultPage(),
      );
    }

    if (_provider.resultFor(LoveTool.marriageProbability) != null &&
        !_mpNavigated) {
      pushOnce(
        already: _mpNavigated,
        mark: () => setState(() {
          _mpNavigated = true;
          _tappedTool = null;
        }),
        page: const MarriageProbabilityResultPage(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relationship Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= MATCH MAKING =================
          Selector<LoveProvider, int>(
            selector: (_, p) => p.resultVersionFor(LoveTool.matchMaking),
            builder: (context, version, _) {
              final provider = context.watch<LoveProvider>();
              final result = provider.resultFor(LoveTool.matchMaking);

              return IntroToolCard(
                title: 'Match Making',
                subtitle: 'Ashtakoot compatibility and relationship score.',
                icon: Icons.favorite,
                indicator: _ashtakootIndicator(result),
                isLoading:
                    _tappedTool == LoveTool.matchMaking ||
                    provider.isLoadingFor(LoveTool.matchMaking),
                onTap: () {
                  if (provider.isLoadingFor(LoveTool.matchMaking)) return;

                  final result = provider.resultFor(LoveTool.matchMaking);
                  if (result != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MatchMakingResultPage(),
                        settings: RouteSettings(
                          arguments: {
                            "source": "love_tools",
                            "tool": "match_making",
                            "report": provider.resultFor(LoveTool.matchMaking),
                          },
                        ),
                      ),
                    );
                    return;
                  }

                  setState(() => _tappedTool = LoveTool.matchMaking);
                  provider.ensureTool(LoveTool.matchMaking);
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // ================= MANGAL DOSH =================
          Selector<LoveProvider, int>(
            selector: (_, p) => p.resultVersionFor(LoveTool.mangalDosh),
            builder: (context, version, _) {
              final provider = context.watch<LoveProvider>();
              final result = provider.resultFor(LoveTool.mangalDosh);

              return IntroToolCard(
                title: 'Mangal Dosh',
                subtitle: 'Presence, cancellation and impact on marriage.',
                icon: Icons.warning_amber_rounded,
                indicator: _mangalIndicator(result),
                isLoading:
                    _tappedTool == LoveTool.mangalDosh ||
                    provider.isLoadingFor(LoveTool.mangalDosh),
                onTap: () {
                  if (provider.isLoadingFor(LoveTool.mangalDosh)) return;

                  final result = provider.resultFor(LoveTool.mangalDosh);
                  if (result != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MangalDoshResultPage(),
                        settings: RouteSettings(
                          arguments: {
                            "source": "love_tools",
                            "tool": "mangal_dosh",
                            "report": provider.resultFor(LoveTool.mangalDosh),
                          },
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() => _tappedTool = LoveTool.mangalDosh);
                  provider.ensureTool(LoveTool.mangalDosh);
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // ================= TRUTH OR DARE =================
          Selector<LoveProvider, int>(
            selector: (_, p) => p.resultVersionFor(LoveTool.truthOrDare),
            builder: (context, version, _) {
              final provider = context.watch<LoveProvider>();
              final result = provider.resultFor(LoveTool.truthOrDare);

              return IntroToolCard(
                title: 'Truth or Dare',
                subtitle: 'Is this relationship emotionally safe?',
                icon: Icons.psychology,
                indicator: _truthDareIndicator(result),
                isLoading:
                    _tappedTool == LoveTool.truthOrDare ||
                    provider.isLoadingFor(LoveTool.truthOrDare),
                onTap: () {
                  if (provider.isLoadingFor(LoveTool.truthOrDare)) return;

                  final result = provider.resultFor(LoveTool.truthOrDare);
                  if (result != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TruthOrDareResultPage(),
                      ),
                    );
                    return;
                  }

                  setState(() => _tappedTool = LoveTool.truthOrDare);
                  provider.ensureTool(LoveTool.truthOrDare);
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // ================= MARRIAGE PROBABILITY =================
          Selector<LoveProvider, int>(
            selector: (_, p) =>
                p.resultVersionFor(LoveTool.marriageProbability),
            builder: (context, version, _) {
              final provider = context.watch<LoveProvider>();
              final result = provider.resultFor(LoveTool.marriageProbability);

              return IntroToolCard(
                title: 'Marriage Probability',
                subtitle: 'Chances of love or marriage.',
                icon: Icons.ring_volume,
                indicator: _marriageIndicator(result),
                isLoading:
                    _tappedTool == LoveTool.marriageProbability ||
                    provider.isLoadingFor(LoveTool.marriageProbability),
                onTap: () {
                  if (provider.isLoadingFor(LoveTool.marriageProbability)) {
                    return;
                  }

                  final result = provider.resultFor(
                    LoveTool.marriageProbability,
                  );
                  if (result != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MarriageProbabilityResultPage(),
                      ),
                    );
                    return;
                  }

                  setState(() => _tappedTool = LoveTool.marriageProbability);
                  provider.ensureTool(LoveTool.marriageProbability);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= INDICATORS =================

  Widget _ashtakootIndicator(Map<String, dynamic>? raw) {
    final data = raw?['data'] ?? raw;
    final ashta = data?['ashtakoot'];
    final verdict = data?['verdict'];

    if (ashta == null) return _empty();

    return _pill(
      '${ashta['total_score']} / ${ashta['max_score']}',
      verdict?['level'] ?? '',
      Colors.pink,
    );
  }

  Widget _mangalIndicator(Map<String, dynamic>? raw) {
    final data = raw?['data'] ?? raw;
    final signal = data?['signal'];
    if (signal == null) return _empty();

    return _pill(
      'Mangal',
      signal,
      signal == 'GREEN' ? Colors.green : Colors.red,
    );
  }

  Widget _truthDareIndicator(Map<String, dynamic>? raw) {
    final data = raw?['data'] ?? raw;
    final verdict = data?['verdict'];
    if (verdict == null) return _empty();

    return _pill(
      'Result',
      verdict,
      verdict == 'TRUTH' ? Colors.green : Colors.red,
    );
  }

  Widget _marriageIndicator(Map<String, dynamic>? raw) {
    final data = raw?['data'] ?? raw;
    final user = data?['user_result'];
    if (user == null) return _empty();

    return _pill('${user['pct']}%', user['band'], Colors.indigo);
  }

  // ================= UI HELPERS =================

  Widget _pill(String top, String bottom, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            top,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(bottom, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _empty() => const SizedBox(width: 1);
  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);

    _mmNavigated = false;
    _mdNavigated = false;
    _tdNavigated = false;
    _mpNavigated = false;
    _tappedTool = null;

    super.dispose();
  }
}
