@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

Widget themed(Widget child) => NaTheme(
  data: NaThemeData.light(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

Color boxColour(WidgetTester tester, Finder of) =>
    (tester
                .widget<DecoratedBox>(
                  find.descendant(of: of, matching: find.byType(DecoratedBox)),
                )
                .decoration
            as BoxDecoration)
        .color ??
    const Color(0x00000000);

void main() {
  testWidgets('chips and badges take the colour of their tone', (tester) async {
    for (final (tone, colour) in [
      (NaChipTone.danger, NaColors.light.danger),
      (NaChipTone.language, NaColors.light.tertiary),
      (NaChipTone.primary, NaColors.light.primary),
      (NaChipTone.dark, NaColors.light.dark),
    ]) {
      await tester.pumpWidget(
        themed(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NaChip(key: const Key('chip'), label: 'Åben', tone: tone),
              NaBadge(key: const Key('badge'), label: 'ÅM', tone: tone),
            ],
          ),
        ),
      );
      expect(boxColour(tester, find.byKey(const Key('chip'))), colour);
      expect(boxColour(tester, find.byKey(const Key('badge'))), colour);
    }
    expect(find.text('Åben'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('badge'))).width,
      greaterThanOrEqualTo(NaBadge.minWidth),
    );
  });

  testWidgets('the section header reports taps, tone and expansion', (
    tester,
  ) async {
    var taps = 0;
    Future<void> pump({
      required NaSectionTone tone,
      required NaExpansion expansion,
    }) => tester.pumpWidget(
      themed(
        NaSectionHeader(
          label: 'Mandag (2)',
          tone: tone,
          expansion: expansion,
          onTap: () => taps += 1,
        ),
      ),
    );
    final handle = tester.ensureSemantics();
    await pump(
      tone: NaSectionTone.highlighted,
      expansion: NaExpansion.collapsed,
    );
    expect(
      tester.widget<Text>(find.text('Mandag (2)')).style?.color,
      NaColors.light.secondary,
    );
    expect(find.byIcon(NaIcons.add), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(NaSectionHeader)),
      matchesSemantics(
        label: 'Mandag (2)',
        isButton: true,
        isHeader: true,
        hasExpandedState: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(NaSectionHeader));
    await pump(tone: NaSectionTone.normal, expansion: NaExpansion.expanded);
    expect(
      tester.widget<Text>(find.text('Mandag (2)')).style?.color,
      NaColors.light.primary,
    );
    expect(find.byIcon(NaIcons.close), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(NaSectionHeader)),
      matchesSemantics(
        label: 'Mandag (2)',
        isButton: true,
        isHeader: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
      ),
    );
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('the note shows its text in the legacy callout colours', (
    tester,
  ) async {
    await tester.pumpWidget(themed(const NaNote(text: 'Ingen dyr')));
    expect(
      tester.widget<Text>(find.text('Ingen dyr')).style?.color,
      NaColors.light.noteInk,
    );
    expect(boxColour(tester, find.byType(NaNote)), NaColors.light.noteSurface);
    expect(find.byIcon(NaIcons.note), findsOneWidget);
  });

  testWidgets('the disclosure row and the action button report taps', (
    tester,
  ) async {
    var rows = 0;
    var actions = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themed(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NaDisclosureRow(label: 'Aarhus', onTap: () => rows += 1),
            NaActionButton(
              icon: NaIcons.mapPin,
              label: 'Kørselsvejledning',
              onPressed: () => actions += 1,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(NaDisclosureRow));
    await tester.tap(find.byType(NaActionButton));
    expect((rows, actions), (1, 1));
    expect(find.text('KØRSELSVEJLEDNING'), findsOneWidget);
    expect(find.byIcon(NaIcons.play), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Kørselsvejledning')),
      matchesSemantics(
        label: 'Kørselsvejledning',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Aarhus')),
      matchesSemantics(label: 'Aarhus', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
}
