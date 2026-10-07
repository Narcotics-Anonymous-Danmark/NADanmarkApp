@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

import '../support/framed.dart';

void main() {
  setUpAll(loadNaFonts);

  testWidgets('chips and badges in every tone', (tester) async {
    await pumpFramed(
      tester,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tone in NaChipTone.values) ...[
            NaChip(label: 'Chip ${tone.name}', tone: tone),
            NaBadge(label: tone.name.substring(0, 2).toUpperCase(), tone: tone),
          ],
        ],
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'chips_and_badges');
    await expectAccessible(tester);
  });

  testWidgets('section headers in every tone and expansion', (tester) async {
    await pumpFramed(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tone in NaSectionTone.values)
            for (final expansion in NaExpansion.values)
              NaSectionHeader(
                label: 'Mandag (2) ${tone.name} ${expansion.name}',
                tone: tone,
                expansion: expansion,
                onTap: () {},
              ),
        ],
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'section_headers');
    await expectAccessible(tester);
  });

  testWidgets('note, disclosure row and action button', (tester) async {
    await pumpFramed(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NaNote(text: 'Dyr er ikke tilladt i lokalerne'),
          NaDisclosureRow(label: 'Aarhus', onTap: () {}),
          NaActionButton(
            icon: NaIcons.mapPin,
            label: 'Kørselsvejledning',
            onPressed: () {},
          ),
        ],
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'note_row_action');
    await expectAccessible(tester);
  });

  testWidgets('range slider', (tester) async {
    await pumpFramed(
      tester,
      NaRangeSlider(
        values: const NaRangeValues(lower: 6, upper: 20),
        min: 0,
        max: 23,
        lowerLabel: 'Tidligste starttid',
        upperLabel: 'Seneste starttid',
        onChanged: (values) {},
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'range_slider');
    await expectAccessible(tester);
  });

  testWidgets('popover', (tester) async {
    await pumpFramed(
      tester,
      SizedBox(
        height: 240,
        child: NaPopover(
          closeKey: const Key('close'),
          title: 'Mødeformater',
          closeLabel: 'Luk',
          onClose: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Åben Møde',
              style: NaThemeData.light().typography.body,
            ),
          ),
        ),
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'popover');
    await expectAccessible(tester);
  });
}
