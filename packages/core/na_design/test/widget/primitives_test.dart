@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';

Widget themed(Widget child) => NaTheme(
  data: NaThemeData.light(),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  testWidgets('button, icon button, list row and menu tile report taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      themed(
        Column(
          children: [
            NaButton(label: 'Send', onPressed: () => taps += 1),
            NaIconButton(
              icon: NaIcons.menu,
              label: 'Menu',
              onPressed: () => taps += 1,
            ),
            NaListRow(label: 'Sprog', value: 'Dansk', onTap: () => taps += 1),
            NaMenuTile(
              icon: NaIcons.home,
              label: 'Hjem',
              selected: NaSelection.selected,
              onTap: () => taps += 1,
            ),
          ],
        ),
      ),
    );
    expect(find.text('SEND'), findsOneWidget);
    for (final finder in [
      find.text('SEND'),
      find.byType(NaIconButton),
      find.text('Sprog'),
      find.text('Hjem'),
    ]) {
      await tester.tap(finder);
    }
    expect(taps, 4);
  });

  testWidgets('the option dialog returns the pick or a cancellation', (
    tester,
  ) async {
    NaOptionChoice<int> choice = const NaOptionCancelled();
    await tester.pumpWidget(
      themed(
        WidgetsApp(
          color: const Color(0xFF000000),
          onGenerateRoute: (settings) => PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => Center(
              child: NaButton(
                label: 'Open',
                onPressed: () async {
                  choice = await showNaOptionDialog<int>(
                    context: context,
                    title: 'Pick',
                    options: const [
                      NaOption(value: 1, label: 'One'),
                      NaOption(value: 2, label: 'Two'),
                    ],
                    selected: 1,
                    cancelLabel: 'Cancel',
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(
      choice,
      isA<NaOptionPicked<int>>().having((c) => c.value, 'value', 2),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(choice, isA<NaOptionCancelled<int>>());
  });

  testWidgets('the slider reports drags, taps and semantic steps', (
    tester,
  ) async {
    final changes = <int>[];
    final ends = <int>[];
    await tester.pumpWidget(
      themed(
        Center(
          child: SizedBox(
            width: 224,
            child: NaSlider(
              value: 15,
              min: 5,
              max: 50,
              label: 'Radius',
              onChanged: changes.add,
              onChangeEnd: ends.add,
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(NaSlider));
    await tester.tapAt(Offset(rect.right - 12, rect.center.dy));
    await tester.pump();
    expect(ends, [50]);
    final gesture = await tester.startGesture(
      Offset(rect.right - 12, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 12, rect.center.dy));
    await gesture.up();
    await tester.pump();
    expect(changes.last, 5);
    expect(ends.last, 5);
    final semantics = tester.getSemantics(find.byType(NaSlider));
    expect(semantics.value, '5');
  });

  testWidgets('drawer layout, fade clip, error state and loading bar render', (
    tester,
  ) async {
    var dismissed = 0;
    await tester.pumpWidget(
      themed(
        NaDrawerLayout(
          visibility: NaDrawerVisibility.open,
          drawer: const NaSideMenu(
            title: 'Menu',
            entries: [Text('entry')],
            footer: Text('footer'),
          ),
          body: const Column(
            children: [
              NaIndeterminateBar(statusText: 'Loading'),
              NaErrorState(message: 'Nope'),
              NaFadeClip(maxHeight: 40, child: SizedBox(height: 200)),
              NaHeaderBar(
                leading: NaHeaderSpacer(),
                title: 'Title',
                trailing: NaHeaderSpacer(),
              ),
            ],
          ),
          onDismiss: () => dismissed += 1,
          dismissLabel: 'Close',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('entry'), findsOneWidget);
    expect(find.text('Nope'), findsOneWidget);
    expect(tester.getSize(find.byType(NaFadeClip)).height, 40);
    await tester.tapAt(const Offset(700, 500));
    expect(dismissed, 1);
    await tester.pumpWidget(
      themed(
        NaDrawerLayout(
          visibility: NaDrawerVisibility.closed,
          drawer: const SizedBox(),
          body: const NaPageFrame(
            header: SizedBox(),
            body: NaScrollBody(
              children: [NaCard(child: NaCardTitle(text: 'Card'))],
            ),
            bottomInset: 0,
          ),
          onDismiss: () => dismissed += 1,
          dismissLabel: 'Close',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Card'), findsOneWidget);
  });
}
