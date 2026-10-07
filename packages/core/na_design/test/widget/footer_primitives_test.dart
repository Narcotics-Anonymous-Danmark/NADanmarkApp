@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

Widget themed(Widget child) => NaTheme(
  data: NaThemeData.light(),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

const Key slider = Key('slider');

void main() {
  setUpAll(loadNaFonts);

  testWidgets('the footer bar with a button and a slider with ends', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(
        goldenFrame(
          child: NaFooterBar(
            children: [
              NaButton(label: 'Møder i nærheden', onPressed: () {}),
              NaSliderWithEnds(
                sliderKey: slider,
                value: const SliderValue(15),
                min: const SliderValue(5),
                max: const SliderValue(50),
                label: const NaLabel('Søgeradius'),
                minLabel: const NaLabel('5 km'),
                maxLabel: const NaLabel('50 km'),
                onChanged: (value) {},
                onChangeEnd: (value) {},
              ),
            ],
          ),
        ),
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'footer_bar_slider_ends');
    await expectAccessible(tester);
  });

  testWidgets('the slider with ends shows both end labels and reports values', (
    tester,
  ) async {
    final changes = <SliderValue>[];
    final ends = <SliderValue>[];
    await tester.pumpWidget(
      themed(
        SizedBox(
          width: 300,
          child: NaSliderWithEnds(
            sliderKey: slider,
            value: const SliderValue(15),
            min: const SliderValue(5),
            max: const SliderValue(50),
            label: const NaLabel('Radius'),
            minLabel: const NaLabel('5 km'),
            maxLabel: const NaLabel('50 km'),
            onChanged: changes.add,
            onChangeEnd: ends.add,
          ),
        ),
      ),
    );
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('50 km'), findsOneWidget);
    expect(tester.widget<NaSlider>(find.byKey(slider)).value, 15);
    final rect = tester.getRect(find.byKey(slider));
    await tester.tapAt(Offset(rect.right - 13, rect.center.dy));
    await tester.pumpAndSettle();
    expect(changes.last, const SliderValue(50));
    expect(ends.last, const SliderValue(50));
  });

  testWidgets('the page frame draws the footer below the body', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(
        const MediaQuery(
          data: MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(bottom: 20),
          ),
          child: NaPageFrame(
            header: SizedBox(height: 50),
            body: NaScrollBody(
              children: [SizedBox(key: Key('content'), height: 10)],
            ),
            footer: NaFooterBar(
              children: [SizedBox(key: Key('footer-content'), height: 40)],
            ),
            bottomInset: 30,
          ),
        ),
      ),
    );
    final footer = tester.getRect(find.byType(NaFooterBar));
    final content = tester.getRect(find.byKey(const Key('footer-content')));
    final frame = tester.getRect(find.byType(NaPageFrame));
    expect(footer.bottom, frame.bottom - 30);
    expect(content.bottom, footer.bottom - Space.sm - 20);
    expect(
      tester.getRect(find.byKey(const Key('content'))).top,
      lessThan(footer.top),
    );
  });
}
