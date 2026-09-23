@Tags(['widget'])
library;

import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  setUpAll(loadNaFonts);

  testWidgets('the home page', (tester) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(
        child: const SizedBox(
          height: 480,
          child: ShellPage(
            title: 'Hjem',
            back: NoBack(),
            body: HomeBody(
              cards: [NaCard(child: NaCardTitle(text: 'Dagens tekst'))],
            ),
          ),
        ),
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'home_page');
    await expectAccessible(tester);
  });

  testWidgets('the shell with the menu open', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(
        width: 400,
        child: SizedBox(
          height: 780,
          child: NaShell(
            location: MenuDestination.settings.path,
            child: const ShellPage(
              title: 'Indstillinger',
              back: NoBack(),
              body: SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('menu-button')));
    await tester.pumpAndSettle();
    await expectGolden(finder: goldenTarget, name: 'shell_menu_open');
    await expectTapTargetsAccessible(tester);
  });
}
