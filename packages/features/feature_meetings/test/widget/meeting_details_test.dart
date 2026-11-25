@Tags(['widget'])
library;

import 'package:feature_meetings/feature_meetings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

final MeetingIds twoMeetings = MeetingIds(
  ids: const [MeetingId(1), MeetingId(2)],
);

TestContainer detailsHarness() {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  harness.meetingSearch.meetings = Ok(
    value: [
      aMeeting(id: 1, weekday: Weekday.monday),
      aMeeting(id: 2, weekday: Weekday.friday),
      aMeeting(id: 3, weekday: Weekday.friday),
    ],
  );
  return harness;
}

Future<void> openDetails(WidgetTester tester, TestContainer harness) async {
  await pumpFeature(
    tester: tester,
    harness: harness,
    child: Builder(
      builder: (context) => GestureDetector(
        key: const Key('open'),
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            showMeetingDetails(context: context, meetings: twoMeetings),
        child: const SizedBox.expand(),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

Finder get details => find.byKey(const Key('meeting-details'));

void main() {
  setUpAll(loadNaFonts);

  testWidgets('shows one card per meeting in the returned order', (
    tester,
  ) async {
    final harness = detailsHarness();
    await openDetails(tester, harness);
    expect(harness.meetingSearch.byIdQueries, [twoMeetings.ids]);
    expect(
      tester
          .widgetList<MeetingCard>(find.byType(MeetingCard))
          .map((card) => card.meeting.id),
      const [MeetingId(1), MeetingId(2)],
    );
    expect(find.text('Mødedetaljer'), findsOneWidget);
    await expectAccessible(tester);
    await expectGolden(finder: details, name: 'meeting_details_loaded');
  });

  testWidgets('shows a spinner and the loading bar while fetching', (
    tester,
  ) async {
    final harness = detailsHarness();
    final gate = harness.meetingSearch.holdById();
    await pumpFeature(
      tester: tester,
      harness: harness,
      child: Builder(
        builder: (context) => GestureDetector(
          key: const Key('open'),
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              showMeetingDetails(context: context, meetings: twoMeetings),
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MeetingCard), findsNothing);
    expect(
      harness.events.recordedOf<BusyStarted>().map((e) => e.activity),
      [BusyActivity.findingMeetings],
    );
    expect(
      find.descendant(of: details, matching: find.byType(NaSpinner)),
      findsOneWidget,
    );
    gate.open();
    await tester.pumpAndSettle();
    expect(find.byType(MeetingCard), findsNWidgets(2));
    expect(
      harness.events.recordedOf<BusyEnded>().map((e) => e.activity),
      [BusyActivity.findingMeetings],
    );
  });

  testWidgets('a failure can be retried', (tester) async {
    final harness = detailsHarness();
    harness.meetingSearch.queueById(
      result: const Err(error: NetworkFailure(detail: 'offline')),
    );
    await openDetails(tester, harness);
    expect(find.text('Møderne kunne ikke hentes'), findsOneWidget);
    await expectAccessible(tester);
    await expectGolden(finder: details, name: 'meeting_details_error');
    await tester.tap(find.byKey(const Key('meeting-details-retry')));
    await tester.pumpAndSettle();
    expect(find.byType(MeetingCard), findsNWidgets(2));
  });

  testWidgets('close dismisses the modal', (tester) async {
    await openDetails(tester, detailsHarness());
    await tester.tap(find.byKey(const Key('meeting-details-close')));
    await tester.pumpAndSettle();
    expect(details, findsNothing);
  });

  test('ids compare by value', () {
    expect(twoMeetings, MeetingIds(ids: const [MeetingId(1), MeetingId(2)]));
    expect(
      twoMeetings.hashCode,
      MeetingIds(ids: const [MeetingId(1), MeetingId(2)]).hashCode,
    );
    expect(twoMeetings, isNot(MeetingIds(ids: const [MeetingId(2)])));
    expect(twoMeetings.toString(), 'MeetingIds(1,2)');
  });
}
