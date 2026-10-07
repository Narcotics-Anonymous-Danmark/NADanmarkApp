@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

Future<List<NaRangeValues>> pumpRange(
  WidgetTester tester, {
  NaRangeValues values = const NaRangeValues(lower: 0, upper: 23),
}) async {
  final changes = <NaRangeValues>[];
  await tester.pumpWidget(
    NaTheme(
      data: NaThemeData.light(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 256,
            child: NaRangeSlider(
              values: values,
              min: 0,
              max: 23,
              lowerLabel: 'Tidligste starttid',
              upperLabel: 'Seneste starttid',
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    ),
  );
  return changes;
}

double xFor(WidgetTester tester, int value) {
  final rect = tester.getRect(find.byType(NaRangeSlider));
  const radius = NaRangeSlider.thumbRadius;
  return rect.left + radius + (rect.width - radius * 2) * value / 23;
}

void main() {
  testWidgets('semantics actions move each thumb by one hour', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = await pumpRange(tester);
    tester.semantics.increase(find.semantics.byLabel('Tidligste starttid'));
    await tester.pump();
    tester.semantics.decrease(find.semantics.byLabel('Seneste starttid'));
    await tester.pump();
    expect(changes, const [
      NaRangeValues(lower: 1, upper: 23),
      NaRangeValues(lower: 1, upper: 22),
    ]);
    expect(
      find.semantics.byLabel('Tidligste starttid').evaluate().single,
      matchesSemantics(
        label: 'Tidligste starttid',
        value: '1',
        increasedValue: '2',
        decreasedValue: '0',
        isSlider: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('thumbs stop at the ends and never cross', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = await pumpRange(
      tester,
      values: const NaRangeValues(lower: 5, upper: 5),
    );
    tester.semantics.increase(find.semantics.byLabel('Tidligste starttid'));
    await tester.pump();
    tester.semantics.decrease(find.semantics.byLabel('Seneste starttid'));
    await tester.pump();
    expect(changes, isEmpty);
    handle.dispose();
  });

  testWidgets('a drag moves the nearest thumb', (tester) async {
    final changes = await pumpRange(tester);
    final centerY = tester.getCenter(find.byType(NaRangeSlider)).dy;
    final gesture = await tester.startGesture(
      Offset(xFor(tester, 23), centerY),
    );
    await gesture.moveTo(Offset(xFor(tester, 20), centerY));
    await gesture.up();
    await tester.pump();
    expect(changes.last, const NaRangeValues(lower: 0, upper: 20));
  });

  testWidgets('a tap moves the nearest thumb to the tapped hour', (
    tester,
  ) async {
    final changes = await pumpRange(tester);
    final centerY = tester.getCenter(find.byType(NaRangeSlider)).dy;
    await tester.tapAt(Offset(xFor(tester, 6), centerY));
    await tester.pump();
    expect(changes.single, const NaRangeValues(lower: 6, upper: 23));
  });

  testWidgets('new values from the parent replace the local ones', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpRange(tester);
    await pumpRange(tester, values: const NaRangeValues(lower: 18, upper: 20));
    expect(
      find.semantics.byLabel('Seneste starttid').evaluate().single,
      matchesSemantics(
        label: 'Seneste starttid',
        value: '20',
        increasedValue: '21',
        decreasedValue: '19',
        isSlider: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    expect(const NaRangeValues(lower: 1, upper: 2).toString(), '1-2');
    expect(
      const NaRangeValues(lower: 1, upper: 2).hashCode,
      const NaRangeValues(lower: 1, upper: 2).hashCode,
    );
    handle.dispose();
  });
}
