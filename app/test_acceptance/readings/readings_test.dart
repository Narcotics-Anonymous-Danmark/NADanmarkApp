@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';

import '../support/media.dart';
import '../support/pump_app.dart';

const List<String> titles = [
  'Hvem er en addict?',
  "Hvad er NA's program?",
  'Hvorfor er vi her?',
  'Sådan virker det',
  "NA's Tolv Traditioner",
  'Vi kommer i bedring',
  'Bare for i dag',
];

Future<AppHarness> pumpReadings({
  required WidgetTester tester,
  Map<String, String> storedValues = const {},
}) async {
  final app = await pumpAt(
    tester: tester,
    location: readingsPath,
    storedValues: storedValues,
  );
  addTearDown(app.dispose);
  return app;
}

Future<void> pick(WidgetTester tester, String title) => chooseOption(
  tester: tester,
  row: const Key('readings-select'),
  option: title,
);

String headingOf(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('reading-heading'))).data ?? '';

String selectorValue(WidgetTester tester) =>
    tester.widget<NaSelectRow>(find.byKey(const Key('readings-select'))).value;

Color pageColour(WidgetTester tester) => tester
    .widget<ColoredBox>(find.byKey(const Key('readings-background')))
    .color;

void main() {
  group('Requirement: The seven readings', () {
    testWidgets('Seven readings available', (tester) async {
      await pumpReadings(tester: tester);
      await tester.tap(find.byKey(const Key('readings-select')));
      await settle(tester);
      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(titles.contains)
          .toSet();
      expect(shown, titles.toSet());
    });

    testWidgets('Steps and traditions are numbered', (tester) async {
      await pumpReadings(tester: tester);
      await pick(tester, 'Sådan virker det');
      for (var number = 1; number <= 12; number += 1) {
        expect(find.byKey(Key('reading-item-$number')), findsOneWidget);
      }
      await pick(tester, "NA's Tolv Traditioner");
      expect(find.byKey(const Key('reading-item-1')), findsOneWidget);
      expect(find.byKey(const Key('reading-item-12')), findsOneWidget);
      expect(find.byKey(const Key('reading-item-13')), findsNothing);
    });
  });

  group('Requirement: Selection', () {
    testWidgets('First reading by default', (tester) async {
      await pumpReadings(tester: tester);
      expect(headingOf(tester), 'Hvem er en addict?');
      expect(selectorValue(tester), 'Hvem er en addict?');
    });

    testWidgets('Selecting another reading', (tester) async {
      await pumpReadings(tester: tester);
      await pick(tester, 'Vi kommer i bedring');
      expect(headingOf(tester), 'Vi kommer i bedring');
      expect(selectorValue(tester), 'Vi kommer i bedring');
    });

    testWidgets('Cancelling keeps the reading', (tester) async {
      await pumpReadings(tester: tester);
      await pick(tester, 'Hvorfor er vi her?');
      await tester.tap(find.byKey(const Key('readings-select')));
      await settle(tester);
      await tester.tap(find.text('Cancel').last);
      await settle(tester);
      expect(headingOf(tester), 'Hvorfor er vi her?');
    });
  });

  group('Requirement: Card appearance', () {
    testWidgets('Colour follows the reading', (tester) async {
      await pumpReadings(tester: tester);
      await pick(tester, 'Sådan virker det');
      expect(pageColour(tester), const Color(0xFFFFFFFF));
      expect(
        tester
            .widget<DecoratedBox>(find.byKey(const Key('reading-card')))
            .decoration,
        isA<BoxDecoration>()
            .having((box) => box.color, 'colour', const Color(0xFFFFFFFF))
            .having((box) => box.border?.top.width, 'border', 2)
            .having(
              (box) => box.border?.top.color,
              'border colour',
              const Color(0xFF000000),
            ),
      );
    });
  });

  group('Requirement: Text remains Danish', () {
    testWidgets('English UI keeps Danish readings', (tester) async {
      await pumpReadings(tester: tester);
      expect(find.text('Group readings'), findsWidgets);
      expect(find.text('Please select'), findsNothing);
      expect(headingOf(tester), 'Hvem er en addict?');
    });

    testWidgets('Readings that cannot be read', (tester) async {
      final app = await pumpAt(tester: tester, location: audiobooksPath);
      addTearDown(app.dispose);
      app.container.readings.outcome = const Err(
        error: UnavailableFailure(what: 'missing'),
      );
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-groupReadings')));
      await settle(tester);
      expect(pageText('The readings could not be loaded.'), findsOneWidget);
    });
  });
}
