@Tags(['widget'])
library;

import 'package:feature_meetings/feature_meetings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

List<Meeting> weekOfMeetings() => [
  aMeeting(id: 1, weekday: Weekday.sunday, startTime: '11:00:00'),
  aMeeting(id: 2, weekday: Weekday.monday, startTime: '19:00:00'),
  aMeeting(id: 3, weekday: Weekday.monday, startTime: '17:30:00'),
  aMeeting(id: 4, weekday: Weekday.friday, startTime: '20:00:00'),
];

Future<TestContainer> pumpList(
  WidgetTester tester, {
  List<Meeting>? meetings,
  FirstDayOfWeek firstDay = FirstDayOfWeek.monday,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.resetPhysicalSize);
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  await pumpFeature(
    tester: tester,
    harness: harness,
    child: SingleChildScrollView(
      child: goldenFrame(
        child: ColoredBox(
          color: NaColors.light.background,
          child: MeetingList(
            listKey: const MeetingListKey('Varde'),
            meetings: meetings ?? weekOfMeetings(),
            firstDay: firstDay,
          ),
        ),
      ),
    ),
  );
  return harness;
}

Finder section(String weekday) => find.byKey(Key('meeting-section-$weekday'));

Finder card(int id) => find.byKey(Key('meeting-card-$id'));

void main() {
  setUpAll(loadNaFonts);

  testWidgets('sections follow the first day and start collapsed', (
    tester,
  ) async {
    await pumpList(tester);
    final order = [
      'monday',
      'friday',
      'sunday',
    ].map((day) => tester.getTopLeft(section(day)).dy).toList();
    expect(order, List.of(order)..sort());
    expect(find.text('Mandag (2)'), findsOneWidget);
    expect(card(2), findsNothing);
    await expectGolden(finder: goldenTarget, name: 'list_collapsed');
    await expectAccessible(tester);
  });

  testWidgets('Sunday first puts Sunday on top', (tester) async {
    await pumpList(tester, firstDay: FirstDayOfWeek.sunday);
    expect(
      tester.getTopLeft(section('sunday')).dy,
      lessThan(tester.getTopLeft(section('monday')).dy),
    );
  });

  testWidgets('one section opens at a time, sorted by start time', (
    tester,
  ) async {
    await pumpList(tester);
    await tester.tap(section('monday'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(card(3)).dy,
      lessThan(tester.getTopLeft(card(2)).dy),
    );
    await expectGolden(finder: goldenTarget, name: 'list_expanded');
    await expectAccessible(tester);
    await tester.ensureVisible(section('friday'));
    await tester.tap(section('friday'));
    await tester.pumpAndSettle();
    expect(card(4), findsOneWidget);
    expect(card(2), findsNothing);
  });

  testWidgets('the day filter keeps one day', (tester) async {
    await pumpList(tester);
    await tester.tap(find.byKey(const Key('meeting-day-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fredag').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NaListRow>(find.byKey(const Key('meeting-day-filter')))
          .value,
      'Fredag',
    );
    expect(section('monday'), findsNothing);
    expect(find.text('Fredag (1)'), findsOneWidget);
    await expectGolden(finder: goldenTarget, name: 'list_filtered');
  });

  testWidgets('cancelling the day selector keeps the filter', (tester) async {
    await pumpList(tester);
    await tester.tap(find.byKey(const Key('meeting-day-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuller'));
    await tester.pumpAndSettle();
    expect(section('monday'), findsOneWidget);
  });

  testWidgets('the hour range filters after the debounce', (tester) async {
    final harness = await pumpList(tester);
    final handle = tester.ensureSemantics();
    for (final _ in List.filled(18, 0)) {
      tester.semantics.increase(find.semantics.byLabel('Tidligste starttid'));
      await tester.pump();
    }
    expect(find.text('Søndag (1)'), findsOneWidget);
    harness.time.advance(by: const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(section('sunday'), findsNothing);
    expect(find.text('Mandag (1)'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no matching meetings shows nothing found', (tester) async {
    await pumpList(tester, meetings: const []);
    expect(find.text('Intet fundet'), findsOneWidget);
    await expectGolden(finder: goldenTarget, name: 'list_empty');
    await expectAccessible(tester);
  });

  testWidgets("today's section uses the highlight colour", (tester) async {
    final harness = TestContainer.buildAt(
      time: TestTime.copenhagen(startAt: anInstant(day: 7)),
    );
    addTearDown(harness.dispose);
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: MeetingList(
        listKey: const MeetingListKey('Varde'),
        meetings: weekOfMeetings(),
        firstDay: FirstDayOfWeek.monday,
      ),
    );
    expect(
      tester.widget<NaSectionHeader>(section('monday')).tone,
      NaSectionTone.highlighted,
    );
    expect(
      tester.widget<NaSectionHeader>(section('friday')).tone,
      NaSectionTone.normal,
    );
  });
}
