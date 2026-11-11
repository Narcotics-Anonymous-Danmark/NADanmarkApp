@Tags(['widget'])
library;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

import '../support/framed.dart';

final class Taps {
  final List<NaLabel> values = [];

  VoidCallback of(NaLabel label) =>
      () => values.add(label);
}

Future<void> pumpMedia(WidgetTester tester, Widget child) =>
    pumpFramed(tester, MediaQuery(data: const MediaQueryData(), child: child));

Future<ValueNotifier<NaInputText>> pumpSearch(WidgetTester tester) async {
  final text = ValueNotifier(const NaInputText(''));
  addTearDown(text.dispose);
  await pumpMedia(
    tester,
    ValueListenableBuilder<NaInputText>(
      valueListenable: text,
      builder: (context, value, child) => NaSearchField(
        text: value,
        placeholder: const NaLabel('Search name, convention, city, year …'),
        clearLabel: const NaLabel('Clear'),
        onChanged: (typed) => text.value = typed,
      ),
    ),
  );
  return text;
}

Future<Taps> pumpSwipe(WidgetTester tester) async {
  final taps = Taps();
  await pumpMedia(
    tester,
    NaSwipeActions(
      actionLabel: const NaLabel('Remove from list'),
      onAction: taps.of(const NaLabel('Remove from list')),
      child: GestureDetector(
        key: const Key('row'),
        onTap: taps.of(const NaLabel('row')),
        child: const NaListBlock(child: Text('A speak row')),
      ),
    ),
  );
  return taps;
}

Future<Taps> pumpRefresh(
  WidgetTester tester, {
  NaActivity activity = NaActivity.idle,
}) async {
  final taps = Taps();
  await pumpMedia(
    tester,
    SizedBox(
      height: 400,
      child: NaPullToRefresh(
        activity: activity,
        busyLabel: const NaLabel('Loading'),
        onRefresh: taps.of(const NaLabel('refresh')),
        child: ListView(
          key: const Key('list'),
          physics: NaPullToRefresh.physics,
          children: [
            for (final row in List.generate(20, (index) => index))
              NaListBlock(child: Text('Row $row')),
          ],
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  setUpAll(loadNaFonts);

  group('NaToggleChip and NaChipStrip', () {
    testWidgets('selected chips are filled and report taps', (tester) async {
      final taps = Taps();
      await pumpFramed(
        tester,
        NaChipStrip(
          chips: [
            NaToggleChip(
              label: const NaLabel('All'),
              selection: NaSelection.unselected,
              onTap: taps.of(const NaLabel('All')),
            ),
            NaToggleChip(
              label: const NaLabel('KOKNA'),
              selection: NaSelection.selected,
              onTap: taps.of(const NaLabel('KOKNA')),
            ),
            NaToggleChip(
              label: const NaLabel('Konvent-camp Skanderborg'),
              selection: NaSelection.unselected,
              onTap: taps.of(const NaLabel('camp')),
            ),
          ],
        ),
      );
      await expectGolden(finder: goldenTarget, name: 'toggle_chips');
      await expectAccessible(tester);
      await tester.tap(find.text('KOKNA'));
      expect(taps.values, const [NaLabel('KOKNA')]);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.bySemanticsLabel('KOKNA')),
        matchesSemantics(
          label: 'KOKNA',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('NaMessageBlock, NaSkeletonRow and NaToolbarButton', () {
    testWidgets('a message with a button', (tester) async {
      final taps = Taps();
      await pumpFramed(
        tester,
        NaMessageBlock(
          title: const NaLabel('Could not load the speaks'),
          body: const NaLabel('Check your internet connection and try again.'),
          action: NaMessageButton(
            label: const NaLabel('Try again'),
            onPressed: taps.of(const NaLabel('retry')),
          ),
        ),
      );
      await expectGolden(finder: goldenTarget, name: 'message_block');
      await expectAccessible(tester);
      await tester.tap(find.text('TRY AGAIN'));
      expect(taps.values, const [NaLabel('retry')]);
    });

    testWidgets('a message without a button', (tester) async {
      await pumpFramed(
        tester,
        const NaMessageBlock(
          title: NaLabel('No speaks found'),
          body: NaLabel('Try another search word, or reset the filters.'),
          action: NoMessageAction(),
        ),
      );
      expect(find.byType(NaButton), findsNothing);
    });

    testWidgets('skeleton rows and a toolbar button', (tester) async {
      final taps = Taps();
      await pumpFramed(
        tester,
        Column(
          children: [
            const NaSkeletonRow(),
            const NaSkeletonRow(),
            NaToolbarButton(
              icon: NaIcons.funnel,
              label: const NaLabel('Filters'),
              semanticLabel: const NaLabel('Filters'),
              onPressed: taps.of(const NaLabel('filters')),
            ),
          ],
        ),
      );
      await expectGolden(finder: goldenTarget, name: 'skeleton_toolbar');
      await expectAccessible(tester);
      await tester.tap(find.text('Filters'));
      expect(taps.values, const [NaLabel('filters')]);
    });
  });

  group('NaSearchField', () {
    testWidgets('shows the placeholder until something is typed', (
      tester,
    ) async {
      final text = await pumpSearch(tester);
      await expectGolden(finder: goldenTarget, name: 'search_field_empty');
      await expectAccessible(tester);
      await tester.enterText(find.byType(EditableText), 'kokna');
      await tester.pump();
      expect(text.value, const NaInputText('kokna'));
      expect(find.text('Search name, convention, city, year …'), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'search_field_text');
    });

    testWidgets('clear empties the field and reports it', (tester) async {
      final text = await pumpSearch(tester);
      await tester.enterText(find.byType(EditableText), 'kokna');
      await tester.pump();
      await tester.tap(find.byKey(const Key('na-search-clear')));
      await tester.pump();
      expect(text.value, const NaInputText(''));
      expect(find.byKey(const Key('na-search-clear')), findsNothing);
    });

    testWidgets('a new text from outside replaces the typed one', (
      tester,
    ) async {
      final text = await pumpSearch(tester);
      await tester.enterText(find.byType(EditableText), 'kokna');
      await tester.pump();
      text.value = const NaInputText('');
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
      );
      expect(find.text('Search name, convention, city, year …'), findsOne);
    });

    testWidgets('submitting drops the focus', (tester) async {
      await pumpSearch(tester);
      await tester.showKeyboard(find.byType(EditableText));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });
  });

  group('NaSwipeActions', () {
    testWidgets('a swipe reveals the action and a tap runs it', (
      tester,
    ) async {
      final taps = await pumpSwipe(tester);
      await tester.drag(find.byKey(const Key('row')), const Offset(-200, 0));
      await tester.pumpAndSettle();
      await expectGolden(finder: goldenTarget, name: 'swipe_open');
      await tester.tap(find.text('Remove from list'));
      await tester.pumpAndSettle();
      expect(taps.values, const [NaLabel('Remove from list')]);
    });

    testWidgets('a short swipe snaps back and a tap closes it', (
      tester,
    ) async {
      final taps = await pumpSwipe(tester);
      await tester.drag(find.byKey(const Key('row')), const Offset(-30, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('row')));
      expect(taps.values, const [NaLabel('row')]);
      await tester.drag(find.byKey(const Key('row')), const Offset(-200, 0));
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(NaSwipeActions)));
      await tester.pumpAndSettle();
      expect(taps.values, const [NaLabel('row')]);
      await tester.tap(find.byKey(const Key('row')));
      expect(taps.values, const [NaLabel('row'), NaLabel('row')]);
    });

    testWidgets('screen readers reach the action without swiping', (
      tester,
    ) async {
      final taps = await pumpSwipe(tester);
      final handle = tester.ensureSemantics();
      tester.semantics.customAction(
        find.semantics.byAction(SemanticsAction.customAction),
        const CustomSemanticsAction(label: 'Remove from list'),
      );
      await tester.pumpAndSettle();
      expect(taps.values, const [NaLabel('Remove from list')]);
      handle.dispose();
    });
  });

  group('NaPullToRefresh', () {
    testWidgets('pulling far enough at the top refreshes once', (
      tester,
    ) async {
      final taps = await pumpRefresh(tester);
      await tester.drag(find.byKey(const Key('list')), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(taps.values, const [NaLabel('refresh')]);
    });

    testWidgets('a short pull or a scroll does not refresh', (tester) async {
      final taps = await pumpRefresh(tester);
      await tester.drag(find.byKey(const Key('list')), const Offset(0, 60));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('list')), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(taps.values, isEmpty);
    });

    testWidgets('while busy it shows a spinner and ignores pulls', (
      tester,
    ) async {
      final taps = await pumpRefresh(tester, activity: NaActivity.busy);
      expect(find.byKey(const Key('na-refreshing')), findsOneWidget);
      await tester.drag(find.byKey(const Key('list')), const Offset(0, 500));
      await tester.pump(const Duration(seconds: 1));
      expect(taps.values, isEmpty);
    });
  });
}
