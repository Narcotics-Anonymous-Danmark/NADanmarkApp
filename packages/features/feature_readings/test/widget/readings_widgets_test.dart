@Tags(['widget'])
library;

import 'package:adapter_assets/adapter_assets.dart';
import 'package:feature_readings/feature_readings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

Future<TestContainer> pumpReadings({
  required WidgetTester tester,
  Language language = Language.danish,
  Outcome<ReadingCollection, Failure>? outcome,
}) async {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  harness.readings.outcome =
      outcome ??
      await tester
          .runAsync(
            () => AssetReadings(bundle: RepoAssetBundle.locate()).load(),
          )
          .then(
            (loaded) =>
                loaded ??
                const Err(error: UnavailableFailure(what: 'readings')),
          );
  await pumpFeature(
    tester: tester,
    harness: harness,
    language: language,
    child: goldenFrame(
      child: const SizedBox(height: 900, child: ReadingsBody()),
    ),
  );
  return harness;
}

Future<void> pick(WidgetTester tester, String title) async {
  await tester.tap(find.byKey(const Key('readings-select')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title).last);
  await tester.pumpAndSettle();
}

String headingOf(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('reading-heading'))).data ?? '';

Color backgroundOf(WidgetTester tester) => tester
    .widget<ColoredBox>(find.byKey(const Key('readings-background')))
    .color;

void main() {
  setUpAll(loadNaFonts);

  testWidgets('first reading by default', (tester) async {
    await pumpReadings(tester: tester);
    expect(headingOf(tester), 'Hvem er en addict?');
    expect(
      tester
          .widget<NaSelectRow>(find.byKey(const Key('readings-select')))
          .value,
      'Hvem er en addict?',
    );
    expect(find.text('Vælg venligst'), findsNothing);
    expect(backgroundOf(tester), const Color(0xFF9AD9E8));
    await expectGolden(finder: goldenTarget, name: 'readings_first');
    await expectAccessible(tester);
  });

  testWidgets('seven readings available', (tester) async {
    await pumpReadings(tester: tester);
    await tester.tap(find.byKey(const Key('readings-select')));
    await tester.pumpAndSettle();
    for (final title in [
      'Hvem er en addict?',
      "Hvad er NA's program?",
      'Hvorfor er vi her?',
      'Sådan virker det',
      "NA's Tolv Traditioner",
      'Vi kommer i bedring',
      'Bare for i dag',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }
  });

  testWidgets('selecting another reading', (tester) async {
    await pumpReadings(tester: tester);
    await pick(tester, 'Vi kommer i bedring');
    expect(headingOf(tester), 'Vi kommer i bedring');
    expect(
      tester
          .widget<NaSelectRow>(find.byKey(const Key('readings-select')))
          .value,
      'Vi kommer i bedring',
    );
    expect(backgroundOf(tester), const Color(0xFF55CC80));
  });

  testWidgets('steps are numbered and the colour follows the reading', (
    tester,
  ) async {
    await pumpReadings(tester: tester);
    await pick(tester, 'Sådan virker det');
    expect(find.byKey(const Key('reading-item-1')), findsOneWidget);
    expect(find.byKey(const Key('reading-item-12')), findsOneWidget);
    expect(find.text('12.'), findsOneWidget);
    expect(backgroundOf(tester), const Color(0xFFFFFFFF));
    final card = tester.widget<DecoratedBox>(
      find.byKey(const Key('reading-card')),
    );
    expect(
      card.decoration,
      isA<BoxDecoration>()
          .having((box) => box.color, 'color', const Color(0xFFFFFFFF))
          .having((box) => box.border?.top.width, 'border', 2),
    );
    await expectGolden(finder: goldenTarget, name: 'readings_steps');
    await pick(tester, "NA's Tolv Traditioner");
    expect(headingOf(tester), 'Narcotics Anonymous’ Tolv Traditioner');
    expect(find.byKey(const Key('reading-item-12')), findsOneWidget);
  });

  testWidgets('cancelling keeps the reading', (tester) async {
    await pumpReadings(tester: tester);
    await pick(tester, 'Hvorfor er vi her?');
    await tester.tap(find.byKey(const Key('readings-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuller').last);
    await tester.pumpAndSettle();
    expect(headingOf(tester), 'Hvorfor er vi her?');
  });

  testWidgets('English UI keeps Danish readings', (tester) async {
    await pumpReadings(tester: tester, language: Language.english);
    expect(find.text('Please select'), findsNothing);
    expect(headingOf(tester), 'Hvem er en addict?');
  });

  testWidgets('readings that cannot be read', (tester) async {
    await pumpReadings(
      tester: tester,
      language: Language.english,
      outcome: const Err(error: UnavailableFailure(what: 'missing')),
    );
    expect(find.text('The readings could not be loaded.'), findsOneWidget);
  });
}
