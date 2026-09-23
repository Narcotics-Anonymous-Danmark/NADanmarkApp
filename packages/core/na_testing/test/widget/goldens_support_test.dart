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

void main() {
  setUpAll(loadNaFonts);

  testWidgets('the bundled fonts render text and icons in a golden', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(
        goldenFrame(
          width: 200,
          child: ColoredBox(
            color: NaColors.light.surface,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(NaIcons.mapPin, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Åben Møde',
                    style: NaThemeData.light().typography.body,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'fonts_sample');
  });

  testWidgets('an accessible widget meets the guidelines', (tester) async {
    await tester.pumpWidget(
      themed(
        Center(
          child: NaButton(label: 'Prøv igen', onPressed: () {}),
        ),
      ),
    );
    await expectAccessible(tester);
  });

  testWidgets('a tiny unlabelled tap target fails the guidelines', (
    tester,
  ) async {
    await tester.pumpWidget(
      themed(
        Center(
          child: GestureDetector(
            onTap: () {},
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
    await expectLater(expectAccessible(tester), throwsA(isA<TestFailure>()));
  });
}
