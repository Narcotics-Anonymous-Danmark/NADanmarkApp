@Tags(['widget'])
library;

import 'dart:ui' show CheckedState;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

enum Fruit { apple, pear, plum }

final class ChoiceLog {
  final List<NaMultiChoice<Fruit>> choices = [];
}

const List<NaMultiOption<Fruit>> fruitOptions = [
  NaMultiOption(value: Fruit.apple, label: NaLabel('Æble')),
  NaMultiOption(value: Fruit.pear, label: NaLabel('Pære')),
  NaMultiOption(value: Fruit.plum, label: NaLabel('Blomme')),
];

Future<ChoiceLog> pumpOpener(
  WidgetTester tester, {
  Set<Fruit> selected = const {Fruit.pear},
}) async {
  final log = ChoiceLog();
  await tester.pumpWidget(
    NaTheme(
      data: NaThemeData.light(),
      child: WidgetsApp(
        color: const Color(0xFF000000),
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => Center(
            child: GestureDetector(
              key: const Key('open'),
              behavior: HitTestBehavior.opaque,
              onTap: () async => log.choices.add(
                await showNaMultiOptionDialog<Fruit>(
                  context: context,
                  title: const NaLabel('Frugt'),
                  options: fruitOptions,
                  selected: selected,
                  cancelLabel: const NaLabel('Annuller'),
                  confirmLabel: const NaLabel('OK'),
                ),
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return log;
}

Set<Fruit> confirmedIn(ChoiceLog log) => switch (log.choices.single) {
  NaOptionsConfirmed(:final values) => values,
  NaOptionsCancelled() => fail('the sheet was cancelled'),
};

void main() {
  setUpAll(loadNaFonts);

  testWidgets('starts with the selected options checked', (tester) async {
    await pumpOpener(tester);
    final semantics = tester.getSemantics(
      find.byKey(const Key('na-multi-option-Pære')),
    );
    expect(semantics.flagsCollection.isChecked, CheckedState.isTrue);
    expect(
      tester
          .getSemantics(find.byKey(const Key('na-multi-option-Æble')))
          .flagsCollection
          .isChecked,
      CheckedState.isFalse,
    );
  });

  testWidgets('the sheet looks right and is accessible', (tester) async {
    await tester.pumpWidget(
      NaTheme(
        data: NaThemeData.light(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: goldenFrame(
            child: NaMultiOptionSheet<Fruit>(
              title: const NaLabel('Frugt'),
              options: fruitOptions,
              selected: const {Fruit.pear},
              cancelLabel: const NaLabel('Annuller'),
              confirmLabel: const NaLabel('OK'),
              onConfirmed: (values) {},
              onCancelled: () {},
            ),
          ),
        ),
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'multi_option_sheet');
    await expectAccessible(tester);
  });

  testWidgets('OK returns every checked option', (tester) async {
    final log = await pumpOpener(tester);
    await tester.tap(find.text('Æble'));
    await tester.tap(find.text('Pære'));
    await tester.tap(find.text('Blomme'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('na-multi-option-confirm')));
    await tester.pumpAndSettle();
    expect(confirmedIn(log), {Fruit.apple, Fruit.plum});
  });

  testWidgets('OK with nothing checked returns an empty set', (tester) async {
    final log = await pumpOpener(tester);
    await tester.tap(find.text('Pære'));
    await tester.tap(find.byKey(const Key('na-multi-option-confirm')));
    await tester.pumpAndSettle();
    expect(confirmedIn(log), isEmpty);
  });

  testWidgets('Cancel discards the changes', (tester) async {
    final log = await pumpOpener(tester);
    await tester.tap(find.text('Æble'));
    await tester.tap(find.byKey(const Key('na-multi-option-cancel')));
    await tester.pumpAndSettle();
    expect(log.choices.single, isA<NaOptionsCancelled<Fruit>>());
  });

  testWidgets('tapping outside cancels', (tester) async {
    final log = await pumpOpener(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(log.choices.single, isA<NaOptionsCancelled<Fruit>>());
  });
}
