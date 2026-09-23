@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

import '../support/framed.dart';

void main() {
  setUpAll(loadNaFonts);

  testWidgets('header bar with menu and back buttons', (tester) async {
    await pumpFramed(
      tester,
      NaHeaderBar(
        leading: NaIconButton(
          icon: NaIcons.menu,
          label: 'Åbn menu',
          onPressed: () {},
        ),
        title: 'Indstillinger',
        trailing: NaIconButton(
          icon: NaIcons.back,
          label: 'Tilbage',
          onPressed: () {},
        ),
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'header_bar');
    await expectAccessible(tester);
  });

  testWidgets('side menu with entries and footer', (tester) async {
    await pumpFramed(
      tester,
      SizedBox(
        height: 320,
        child: NaSideMenu(
          title: 'Menu',
          entries: [
            NaMenuTile(
              icon: NaIcons.home,
              label: 'Hjem',
              selected: NaSelection.selected,
              onTap: () {},
            ),
            NaMenuTile(
              icon: NaIcons.list,
              label: 'Mødeliste',
              selected: NaSelection.unselected,
              onTap: () {},
            ),
          ],
          footer: const Text('Version: 2.0.0'),
        ),
      ),
      width: 300,
    );
    await expectGolden(finder: goldenTarget, name: 'side_menu');
    await expectAccessible(tester);
  });

  testWidgets('drawer layout open over a page', (tester) async {
    await pumpFramed(
      tester,
      SizedBox(
        height: 300,
        child: NaDrawerLayout(
          visibility: NaDrawerVisibility.open,
          drawer: ColoredBox(
            color: NaColors.light.surface,
            child: const Center(child: Text('Menu')),
          ),
          body: const Center(child: Text('Side')),
          onDismiss: () {},
          dismissLabel: 'Luk menu',
        ),
      ),
      width: 400,
    );
    await tester.pumpAndSettle();
    await expectGolden(finder: goldenTarget, name: 'drawer_layout');
    await expectTapTargetsAccessible(tester);
  });

  testWidgets('card, button, list row, slider and error state', (
    tester,
  ) async {
    await pumpFramed(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NaCard(child: NaCardTitle(text: 'Cleantime')),
          NaButton(label: 'Send', onPressed: () {}),
          NaListRow(label: 'Sprog', value: 'Dansk', onTap: () {}),
          NaSlider(
            value: 15,
            min: 5,
            max: 50,
            label: 'Standard søgeradius',
            onChanged: (value) {},
            onChangeEnd: (value) {},
          ),
          const NaErrorState(message: 'Dagens tekst kunne ikke hentes'),
        ],
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'card_button_row_slider');
    await expectAccessible(tester);
  });

  testWidgets('option sheet', (tester) async {
    await pumpFramed(
      tester,
      NaOptionSheet<int>(
        title: 'Sprog',
        options: const [
          NaOption(value: 1, label: 'Dansk'),
          NaOption(value: 2, label: 'Engelsk'),
        ],
        selected: 1,
        cancelLabel: 'Annuller',
        onPicked: (value) {},
        onCancelled: () {},
      ),
    );
    await expectGolden(finder: goldenTarget, name: 'option_sheet');
    await expectAccessible(tester);
  });

  testWidgets('indeterminate bar and fade clip', (tester) async {
    await pumpFramed(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NaIndeterminateBar(statusText: 'Finder møder …'),
          SizedBox(height: 8),
          NaFadeClip(
            maxHeight: 60,
            child: Text(
              'Dagens tekst fortsætter længere end kortet kan vise, så den '
              'tones ud nederst og fortsætter på næste side.',
            ),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectGolden(finder: goldenTarget, name: 'bar_and_fade_clip');
  });
}
