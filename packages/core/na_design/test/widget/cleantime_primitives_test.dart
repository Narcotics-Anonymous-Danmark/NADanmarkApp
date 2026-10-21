@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/framed.dart';
import '../support/opener.dart';

const NaDateWheelLabels wheelLabels = NaDateWheelLabels(
  day: NaLabel('Dag'),
  month: NaLabel('Måned'),
  year: NaLabel('År'),
  monthNames: [
    NaLabel('januar'),
    NaLabel('februar'),
    NaLabel('marts'),
    NaLabel('april'),
    NaLabel('maj'),
    NaLabel('juni'),
    NaLabel('juli'),
    NaLabel('august'),
    NaLabel('september'),
    NaLabel('oktober'),
    NaLabel('november'),
    NaLabel('december'),
  ],
);

const LocalDate today = LocalDate(year: 2026, month: 9, day: 10);
const LocalDate first = LocalDate(year: 1950, month: 1, day: 1);

Future<NaTextEntry> openTextInput(
  BuildContext context, {
  NaInputText initialText = const NaInputText(''),
}) => showNaTextInputDialog(
  context: context,
  title: const NaLabel('Ny profil'),
  placeholder: const NaLabel('Ny profilnavn her'),
  initialText: initialText,
  cancelLabel: const NaLabel('Afbryd'),
  confirmLabel: const NaLabel('Opret'),
);

Future<NaDateChoice> openPicker(
  BuildContext context, {
  LocalDate initial = const LocalDate(year: 2020, month: 5, day: 3),
}) => showNaDatePicker(
  context: context,
  initial: initial,
  first: first,
  last: today,
  labels: wheelLabels,
  cancelLabel: const NaLabel('Annuller'),
  confirmLabel: const NaLabel('OK'),
);

LocalDate pickedIn(ResultLog<NaDateChoice> log) => switch (log.results.single) {
  NaDatePicked(:final date) => date,
  NaDateCancelled() => fail('the picker was cancelled'),
};

enum DateWheel { day, month, year }

extension type const WheelSteps(int count) {}

Future<void> turn(
  WidgetTester tester,
  DateWheel wheel,
  WheelSteps steps,
) async {
  await tester.drag(
    find.byKey(Key('na-date-wheel-${wheel.name}')),
    Offset(0, -NaDatePicker.itemExtent * steps.count),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadNaFonts);

  group('NaIconButton tones', () {
    testWidgets('every tone renders and taps', (tester) async {
      final taps = <NaTone>[];
      await pumpFramed(
        tester,
        Row(
          children: NaTone.values
              .map(
                (tone) => NaIconButton(
                  key: Key('tone-${tone.name}'),
                  icon: NaIcons.edit,
                  label: tone.name,
                  tone: tone,
                  onPressed: () => taps.add(tone),
                ),
              )
              .toList(),
        ),
      );
      for (final tone in NaTone.values) {
        await tester.tap(find.byKey(Key('tone-${tone.name}')));
      }
      expect(taps, NaTone.values);
      expect(find.byIcon(NaIcons.trash), findsNothing);
      await expectGolden(finder: goldenTarget, name: 'icon_button_tones');
      await expectTapTargetsAccessible(tester);
    });
  });

  group('showNaTextInputDialog', () {
    testWidgets('confirm returns the trimmed text', (tester) async {
      final log = await pumpOpener<NaTextEntry>(
        tester: tester,
        open: openTextInput,
      );
      await tester.enterText(find.byType(EditableText), '  Anna ');
      await tester.pump();
      await tapKey(tester, const Key('na-dialog-confirm'));
      expect(
        (log.results.single as NaTextEntered).text,
        const NaInputText('Anna'),
      );
    });

    testWidgets('a blank name disables confirm', (tester) async {
      final log = await pumpOpener<NaTextEntry>(
        tester: tester,
        open: openTextInput,
      );
      expect(find.text('Ny profilnavn her'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '   ');
      await tester.pump();
      await tapKey(tester, const Key('na-dialog-confirm'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(log.results, isEmpty);
      expect(find.byType(NaTextInputSheet), findsOneWidget);
    });

    testWidgets('submitting from the keyboard confirms', (tester) async {
      final log = await pumpOpener<NaTextEntry>(
        tester: tester,
        open: openTextInput,
      );
      await tester.enterText(find.byType(EditableText), 'Bo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        (log.results.single as NaTextEntered).text,
        const NaInputText('Bo'),
      );
    });

    testWidgets('the initial text is editable', (tester) async {
      await pumpOpener<NaTextEntry>(
        tester: tester,
        open: (context) =>
            openTextInput(context, initialText: const NaInputText('Anna')),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Anna',
      );
      expect(find.text('Ny profilnavn her'), findsNothing);
    });

    testWidgets('cancel and the barrier cancel', (tester) async {
      final log = await pumpOpener<NaTextEntry>(
        tester: tester,
        open: openTextInput,
      );
      await tapKey(tester, const Key('na-dialog-cancel'));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(log.results, [isA<NaTextCancelled>(), isA<NaTextCancelled>()]);
    });

    testWidgets('the sheet looks right and is accessible', (tester) async {
      await pumpFramed(
        tester,
        NaTextInputSheet(
          title: const NaLabel('Omdøb profil'),
          placeholder: const NaLabel('Anna'),
          initialText: const NaInputText('Anna'),
          cancelLabel: const NaLabel('Afbryd'),
          confirmLabel: const NaLabel('Omdøb'),
          onDone: (entry) {},
        ),
      );
      await expectGolden(finder: goldenTarget, name: 'text_input_sheet');
      await expectAccessible(tester);
    });
  });

  group('showNaConfirmDialog', () {
    testWidgets('confirm, cancel and the barrier answer', (tester) async {
      final log = await pumpOpener<NaConfirmation>(
        tester: tester,
        open: (context) => showNaConfirmDialog(
          context: context,
          title: const NaLabel('Er du sikker?'),
          cancelLabel: const NaLabel('Afbryd'),
          confirmLabel: const NaLabel('Slet'),
        ),
      );
      await tapKey(tester, const Key('na-dialog-confirm'));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tapKey(tester, const Key('na-dialog-cancel'));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(log.results, [
        NaConfirmation.confirmed,
        NaConfirmation.declined,
        NaConfirmation.declined,
      ]);
    });

    testWidgets('the sheet looks right and is accessible', (tester) async {
      await pumpFramed(
        tester,
        NaConfirmSheet(
          title: const NaLabel('Er du sikker?'),
          cancelLabel: const NaLabel('Afbryd'),
          confirmLabel: const NaLabel('Slet'),
          onAnswered: (answer) {},
        ),
      );
      await expectGolden(finder: goldenTarget, name: 'confirm_sheet');
      await expectAccessible(tester);
    });
  });

  group('showNaDatePicker', () {
    testWidgets('picks the date the wheels show', (tester) async {
      final log = await pumpOpener<NaDateChoice>(
        tester: tester,
        open: openPicker,
      );
      await turn(tester, DateWheel.year, const WheelSteps(-1));
      await turn(tester, DateWheel.month, const WheelSteps(2));
      await turn(tester, DateWheel.day, const WheelSteps(4));
      await tapKey(tester, const Key('na-dialog-confirm'));
      expect(pickedIn(log), const LocalDate(year: 2019, month: 7, day: 7));
    });

    testWidgets('a future day snaps back to today', (tester) async {
      final log = await pumpOpener<NaDateChoice>(
        tester: tester,
        open: (context) => openPicker(context, initial: today),
      );
      await turn(tester, DateWheel.day, const WheelSteps(15));
      await tapKey(tester, const Key('na-dialog-confirm'));
      expect(pickedIn(log), today);
    });

    testWidgets('a future month snaps back to today', (tester) async {
      final log = await pumpOpener<NaDateChoice>(
        tester: tester,
        open: (context) => openPicker(context, initial: today),
      );
      await turn(tester, DateWheel.month, const WheelSteps(2));
      await tapKey(tester, const Key('na-dialog-confirm'));
      expect(pickedIn(log), today);
    });

    testWidgets('a day the month does not have is clamped', (tester) async {
      final log = await pumpOpener<NaDateChoice>(
        tester: tester,
        open: (context) => openPicker(
          context,
          initial: const LocalDate(year: 2023, month: 1, day: 31),
        ),
      );
      await turn(tester, DateWheel.month, const WheelSteps(1));
      await tapKey(tester, const Key('na-dialog-confirm'));
      expect(pickedIn(log), const LocalDate(year: 2023, month: 2, day: 28));
    });

    testWidgets('leap days exist only in leap years', (tester) async {
      final log = await pumpOpener<NaDateChoice>(
        tester: tester,
        open: (context) => openPicker(
          context,
          initial: const LocalDate(year: 2024, month: 2, day: 29),
        ),
      );
      await turn(tester, DateWheel.year, const WheelSteps(1));
      await tapKey(tester, const Key('na-dialog-confirm'));
      expect(pickedIn(log), const LocalDate(year: 2025, month: 2, day: 28));
    });

    testWidgets('cancel keeps nothing', (tester) async {
      final log = await pumpOpener<NaDateChoice>(
        tester: tester,
        open: openPicker,
      );
      await turn(tester, DateWheel.year, const WheelSteps(-3));
      await tapKey(tester, const Key('na-dialog-cancel'));
      expect(log.results.single, isA<NaDateCancelled>());
    });

    testWidgets('each wheel is an adjustable control', (tester) async {
      final log = await pumpOpener<NaDateChoice>(
        tester: tester,
        open: openPicker,
      );
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(const Key('na-date-wheel-month'))),
        matchesSemantics(
          label: 'Måned',
          value: 'maj',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      tester.semantics.increase(find.semantics.byLabel('Dag'));
      await tester.pumpAndSettle();
      tester.semantics.decrease(find.semantics.byLabel('År'));
      await tester.pumpAndSettle();
      handle.dispose();
      await tapKey(tester, const Key('na-dialog-confirm'));
      expect(pickedIn(log), const LocalDate(year: 2019, month: 5, day: 4));
    });

    testWidgets('the picker looks right and is accessible', (tester) async {
      await pumpFramed(
        tester,
        NaDatePicker(
          initial: today,
          first: first,
          last: today,
          labels: wheelLabels,
          cancelLabel: const NaLabel('Annuller'),
          confirmLabel: const NaLabel('OK'),
          onDone: (choice) {},
        ),
      );
      await expectGolden(finder: goldenTarget, name: 'date_picker');
      await expectTapTargetsAccessible(tester);
    });
  });

  group('NaCarousel', () {
    Widget page(String text) => NaCard(child: Text(text));

    testWidgets('swipes between pages and moves the dots', (tester) async {
      await pumpFramed(
        tester,
        NaCarousel(
          pages: [page('Anna'), page('Bo')],
          pageLabels: const [NaLabel('Kort 1 af 2'), NaLabel('Kort 2 af 2')],
          backdrop: NaBackdrop.surface,
        ),
      );
      expect(find.byKey(const Key('na-page-dots')), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'carousel');
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Bo'), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('Kort 2 af 2')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('one page hides the dots', (tester) async {
      await pumpFramed(
        tester,
        NaCarousel(
          pages: [page('Anna')],
          pageLabels: const [NaLabel('Kort 1 af 1')],
          backdrop: NaBackdrop.primary,
        ),
      );
      expect(find.byKey(const Key('na-page-dots')), findsNothing);
    });
  });
}
