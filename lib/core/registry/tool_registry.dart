import 'package:flutter/widgets.dart';
import 'package:jyotishasha_app/features/tools/widgets/lagna_finder_widget.dart';
import 'package:jyotishasha_app/features/tools/widgets/rashi_finder_widget.dart';
import 'package:jyotishasha_app/features/tools/widgets/dasha_finder_widget.dart';
import 'package:jyotishasha_app/features/tools/widgets/gemstone_suggestion_widget.dart';
import 'package:jyotishasha_app/features/tools/widgets/mangal_dosh_widget.dart';
import 'package:jyotishasha_app/features/tools/widgets/kaalsarp_dosh_widget.dart';
import 'package:jyotishasha_app/features/tools/widgets/sade_sati_widget.dart';

/// Central map: toolId → widget builder
class ToolRegistry {
  static final Map<String, Widget Function(Map<String, dynamic>)> toolWidgets =
      {
        "lagna-finder": (data) => LagnaFinderWidget(data: data),
        "rashi-finder": (data) => RashiFinderWidget(data: data),
        "grah-dasha-finder": (data) => DashaFinderWidget(data: data),
        "gemstone-suggestion": (data) => GemstoneSuggestionWidget(data),
        "mangal-dosh": (data) => MangalDoshWidget(kundaliData: data),
        "kaalsarp-dosh": (data) => KaalsarpDoshWidget(kundaliData: data),
        "sadhesati-calculator": (data) => SadhesatiWidget(data: data),

        // yahan baaki tools plug karte jana:
        // "mangal-dosh": (data) => MangalDoshWidget(data: data),
        // ...
      };
}
