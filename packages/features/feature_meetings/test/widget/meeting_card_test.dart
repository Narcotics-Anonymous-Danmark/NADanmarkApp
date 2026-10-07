@Tags(['widget'])
library;

import 'package:feature_meetings/feature_meetings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

Future<TestContainer> pumpCard(WidgetTester tester, Meeting meeting) async {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  await harness.read(meetingFormatsProvider.notifier).ensureLoaded();
  await pumpFeature(
    tester: tester,
    harness: harness,
    child: goldenFrame(child: MeetingCard(meeting: meeting)),
  );
  return harness;
}

Finder byKey(String key) => find.byKey(Key(key));

void main() {
  setUpAll(loadNaFonts);

  testWidgets('an in-person meeting shows its details and directions', (
    tester,
  ) async {
    final harness = await pumpCard(
      tester,
      aMeeting(
        id: 1,
        weekday: Weekday.monday,
        startTime: '19:00:00',
        duration: '01:30:00',
        formats: 'ÅM,HV',
        sharedIds: '17,33',
        busLines: 'Bus Lines#@-@#2A',
      ),
    );
    expect(find.text('Mandag 19:00 - 20:30'), findsOneWidget);
    expect(find.text('Traditionerne tro'), findsOneWidget);
    expect(find.text('Åben Møde'), findsOneWidget);
    expect(find.text('Handicap venlig'), findsOneWidget);
    expect(find.text('Dyr er ikke tilladt i lokalerne'), findsOneWidget);
    expect(find.text('Bus: 2A'), findsOneWidget);
    expect(byKey('meeting-closed-1'), findsNothing);
    expect(byKey('meeting-virtual-1'), findsNothing);
    await expectGolden(finder: goldenTarget, name: 'card_in_person');
    await expectAccessible(tester);
    await tester.tap(byKey('meeting-directions-1'));
    expect(harness.links.opened.single.host, 'www.google.com');
  });

  testWidgets('a hybrid meeting offers directions and the virtual link', (
    tester,
  ) async {
    final harness = await pumpCard(
      tester,
      aMeeting(
        id: 2,
        formats: 'HY',
        sharedIds: '',
        virtualLink: 'https://zoom.example/j/2',
      ),
    );
    expect(byKey('meeting-directions-2'), findsOneWidget);
    await tester.tap(byKey('meeting-virtual-2'));
    expect(harness.links.opened, [Uri.parse('https://zoom.example/j/2')]);
    await expectGolden(finder: goldenTarget, name: 'card_hybrid');
    await expectAccessible(tester);
  });

  testWidgets('a virtual meeting with a phone number offers the dial-in', (
    tester,
  ) async {
    final harness = await pumpCard(
      tester,
      aMeeting(
        id: 3,
        formats: 'VM',
        sharedIds: '57',
        municipality: '',
        virtualLink: 'https://zoom.example/j/3',
        phoneMeeting: '+45 11 22 33 44',
      ),
    );
    expect(byKey('meeting-directions-3'), findsNothing);
    await tester.tap(byKey('meeting-dial-in-3'));
    expect(harness.links.opened, [Uri(scheme: 'tel', path: '+45 11 22 33 44')]);
    await expectGolden(finder: goldenTarget, name: 'card_virtual_phone');
    await expectAccessible(tester);
  });

  testWidgets('a temporarily closed meeting shows the red chip', (
    tester,
  ) async {
    await pumpCard(tester, aMeeting(id: 4, formats: 'TC', sharedIds: ''));
    expect(
      find.descendant(
        of: byKey('meeting-closed-4'),
        matching: find.text('Midlertidigt lukket'),
      ),
      findsOneWidget,
    );
    await expectGolden(finder: goldenTarget, name: 'card_closed');
    await expectAccessible(tester);
  });

  testWidgets('no chips are shown while the formats are loading', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: MeetingCard(meeting: aMeeting(id: 5)),
    );
    expect(byKey('meeting-formats-5'), findsNothing);
  });

  testWidgets('tapping the chips opens the formats popover', (tester) async {
    await pumpCard(
      tester,
      aMeeting(id: 6, formats: 'ÅM,ST', sharedIds: '17,55'),
    );
    await tester.tap(byKey('meeting-formats-6'));
    await tester.pumpAndSettle();
    expect(byKey('formats-popover'), findsOneWidget);
    expect(
      find.descendant(
        of: byKey('format-row-ST'),
        matching: find.text('Stempelmøde'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: byKey('format-row-ÅM'), matching: find.text('ÅM')),
      findsOneWidget,
    );
    await expectTapTargetsAccessible(tester);
    await tester.tap(byKey('formats-popover-close'));
    await tester.pumpAndSettle();
    expect(byKey('formats-popover'), findsNothing);
  });

  testWidgets('the popover body lists key, name and description', (
    tester,
  ) async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    final formats =
        FormatIndex.build(
          rows: recordedFormatRows(),
          display: FormatLanguageCode.danish,
        ).formatsOf(
          codes: const MeetingFormatCodes(
            keys: [FormatKey('ST'), FormatKey('ÅM'), FormatKey('XYZ')],
            sharedIds: [],
          ),
          origin: MeetingOrigin.denmark,
        );
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(
        child: SizedBox(
          height: 420,
          child: NaPopover(
            closeKey: const Key('close'),
            title: 'Mødeformater',
            closeLabel: 'Luk',
            onClose: () {},
            child: FormatsPopoverBody(
              meetingName: 'Traditionerne tro',
              formats: formats,
            ),
          ),
        ),
      ),
    );
    expect(
      find.descendant(of: byKey('format-row-XYZ'), matching: find.text('XYZ')),
      findsNWidgets(2),
    );
    await expectGolden(finder: goldenTarget, name: 'formats_popover');
    await expectAccessible(tester);
  });
}
