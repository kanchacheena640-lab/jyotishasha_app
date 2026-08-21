import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/features/asknow/asknow_chat_page.dart';

/// Flattens every [RichText] currently in the tree into (text, style)
/// leaf pairs — the only reliable way to assert both "this exact text is
/// present" and "it is actually bold/italic", since Markdown rendering
/// produces nested [TextSpan]s, not a single flat [Text].
List<({String text, TextStyle? style})> _flattenSpans(WidgetTester tester) {
  final leaves = <({String text, TextStyle? style})>[];

  void visit(InlineSpan span, TextStyle? inherited) {
    if (span is TextSpan) {
      final style = inherited == null
          ? span.style
          : inherited.merge(span.style);
      if (span.text != null && span.text!.isNotEmpty) {
        leaves.add((text: span.text!, style: style));
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child, style);
      }
    }
  }

  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    visit(richText.text, null);
  }
  return leaves;
}

String _allText(WidgetTester tester) =>
    _flattenSpans(tester).map((l) => l.text).join();

void main() {
  // Matches the real usage context (AskNowChatPage's chat bubble sits
  // inside a `ListView.builder`, which gives each item unbounded/
  // scrollable height — only width is ever bounded) rather than a bare
  // `Scaffold.body`, which would bound height and produce a false
  // "overflow" for long content that the real, scrolling chat list
  // would never actually hit.
  Future<void> pump(WidgetTester tester, String markdown) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AskNowAnswerText(text: markdown),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    '1/2 — "**Strong period**" renders "Strong period" with no visible '
    '"**", and the span is actually styled bold',
    (tester) async {
      await pump(tester, '**Strong period**');

      final all = _allText(tester);
      expect(all, contains('Strong period'));
      expect(all, isNot(contains('**')));

      final leaves = _flattenSpans(tester);
      final boldLeaf = leaves.firstWhere(
        (l) => l.text.contains('Strong period'),
      );
      expect(boldLeaf.style?.fontWeight, FontWeight.bold);
    },
  );

  testWidgets('*italic* renders without visible "*" markers', (
    tester,
  ) async {
    await pump(tester, 'This is *italic text* here.');

    final all = _allText(tester);
    expect(all, contains('italic text'));
    expect(all, isNot(contains('*italic*')));

    final leaves = _flattenSpans(tester);
    final italicLeaf = leaves.firstWhere(
      (l) => l.text.contains('italic text'),
    );
    expect(italicLeaf.style?.fontStyle, FontStyle.italic);
  });

  testWidgets(
    '3 — bullet list renders both items with no raw "-"/"*" markers '
    'left dangling in the visible text',
    (tester) async {
      await pump(tester, '- Point one\n- Point two');

      final all = _allText(tester);
      expect(all, contains('Point one'));
      expect(all, contains('Point two'));
      // The literal list-marker character is never part of the item's
      // own text run once parsed as a real bullet list.
      expect(all, isNot(contains('- Point one')));
      expect(all, isNot(contains('- Point two')));
    },
  );

  testWidgets('4 — numbered list renders both items correctly', (
    tester,
  ) async {
    await pump(tester, '1. First step\n2. Second step');

    final all = _allText(tester);
    expect(all, contains('First step'));
    expect(all, contains('Second step'));
  });

  testWidgets('5 — a multi-paragraph response renders every paragraph', (
    tester,
  ) async {
    await pump(
      tester,
      'First paragraph about your career.\n\n'
      'Second paragraph about your health.\n\n'
      'Third paragraph, a closing thought.',
    );

    final all = _allText(tester);
    expect(all, contains('First paragraph about your career.'));
    expect(all, contains('Second paragraph about your health.'));
    expect(all, contains('Third paragraph, a closing thought.'));
  });

  testWidgets(
    '6 — Hindi text inside bold Markdown renders correctly, still bold, '
    'with no visible "**"',
    (tester) async {
      await pump(tester, '**यह मजबूत अवधि है**');

      final all = _allText(tester);
      expect(all, contains('यह मजबूत अवधि है'));
      expect(all, isNot(contains('**')));

      final leaves = _flattenSpans(tester);
      final boldLeaf = leaves.firstWhere(
        (l) => l.text.contains('यह मजबूत अवधि है'),
      );
      expect(boldLeaf.style?.fontWeight, FontWeight.bold);
    },
  );

  testWidgets(
    '7 — a plain-text answer with no Markdown syntax at all remains '
    'readable and unchanged',
    (tester) async {
      await pump(
        tester,
        'Today looks like a calm day for your career and finances.',
      );

      expect(
        _allText(tester),
        contains(
          'Today looks like a calm day for your career and finances.',
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '8 — malformed Markdown (unmatched **, stray *, broken list marker) '
    'never crashes and still shows the readable content',
    (tester) async {
      await pump(
        tester,
        '**Unclosed bold and *unclosed italic and - broken ** list * marker',
      );

      expect(tester.takeException(), isNull);
      // The actual words are still present somewhere in the render —
      // content is never hidden, even if the exact formatting of a
      // malformed span is ambiguous.
      final all = _allText(tester);
      expect(all, contains('Unclosed bold'));
      expect(all, contains('unclosed italic'));
    },
  );

  testWidgets(
    '9 — a long, unbroken answer does not overflow and renders without '
    'a layout exception',
    (tester) async {
      final longAnswer = List.generate(
        40,
        (i) => 'This is a fairly long sentence number $i about your chart.',
      ).join(' ');

      await pump(tester, longAnswer);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('sentence number 0'), findsOneWidget);
    },
  );

  testWidgets(
    'headings render as plain readable text with no visible "#" markers',
    (tester) async {
      await pump(tester, '## Career\nDetails about your career follow.');

      final all = _allText(tester);
      expect(all, contains('Career'));
      expect(all, isNot(contains('##')));
    },
  );
}
