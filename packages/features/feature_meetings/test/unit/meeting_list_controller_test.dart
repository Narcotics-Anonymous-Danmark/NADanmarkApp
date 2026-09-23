@Tags(['unit'])
library;

import 'package:feature_meetings/feature_meetings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

const key = MeetingListKey('Aarhus');

({TestContainer harness, MeetingListController controller}) listUnderTest() {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  final subscription = harness.container.listen(
    meetingListProvider(key),
    (previous, next) {},
  );
  addTearDown(subscription.close);
  return (
    harness: harness,
    controller: harness.read(meetingListProvider(key).notifier),
  );
}

void main() {
  test('starts with all days, the whole day and nothing open', () {
    final subject = listUnderTest();
    expect(
      subject.harness.read(meetingListProvider(key)),
      MeetingListView.initial,
    );
  });

  test('selecting a day filters to that day', () {
    final subject = listUnderTest();
    subject.controller.selectDay(day: const OnlyDay(weekday: Weekday.friday));
    expect(
      subject.harness.read(meetingListProvider(key)).day,
      const OnlyDay(weekday: Weekday.friday),
    );
  });

  test('the hour range applies 350 ms after the last change', () {
    final subject = listUnderTest();
    const evening = HourRange(lower: 18, upper: 20);
    subject.controller
      ..dragHours(hours: const HourRange(lower: 17, upper: 23))
      ..dragHours(hours: evening);
    final view = subject.harness.read(meetingListProvider(key));
    expect(view.draftHours, evening);
    expect(view.hours, HourRange.wholeDay);
    subject.harness.time.advance(by: const Duration(milliseconds: 349));
    expect(
      subject.harness.read(meetingListProvider(key)).hours,
      HourRange.wholeDay,
    );
    subject.harness.time.advance(by: const Duration(milliseconds: 1));
    expect(subject.harness.read(meetingListProvider(key)).hours, evening);
  });

  test('one section is open at a time and toggles closed again', () {
    final subject = listUnderTest();
    MeetingListView view() => subject.harness.read(meetingListProvider(key));
    subject.controller.toggle(weekday: Weekday.monday);
    expect(
      view().expansionOf(weekday: Weekday.monday),
      SectionExpansion.expanded,
    );
    subject.controller.toggle(weekday: Weekday.tuesday);
    expect(
      view().expansionOf(weekday: Weekday.monday),
      SectionExpansion.collapsed,
    );
    expect(
      view().expansionOf(weekday: Weekday.tuesday),
      SectionExpansion.expanded,
    );
    subject.controller.toggle(weekday: Weekday.tuesday);
    expect(view().open, const NoSectionOpen());
  });

  test('opening a list asks for the format definitions', () async {
    final subject = listUnderTest();
    await Future<void>.delayed(Duration.zero);
    expect(subject.harness.meetingFormats.calls, 1);
  });

  test('today comes from the clock', () {
    final harness = TestContainer.buildAt(
      time: TestTime.copenhagen(startAt: anInstant(day: 9)),
    );
    addTearDown(harness.dispose);
    expect(harness.read(todayProvider), Weekday.wednesday);
  });

  test('list views and open sections compare by value', () {
    expect(
      MeetingListView.initial.withOpen(
        open: const SectionOpen(weekday: Weekday.monday),
      ),
      MeetingListView.initial.withOpen(
        open: const SectionOpen(weekday: Weekday.monday),
      ),
    );
    expect(
      {
        MeetingListView.initial.hashCode,
        const SectionOpen(weekday: Weekday.monday).hashCode,
        const NoSectionOpen().hashCode,
      },
      hasLength(3),
    );
  });
}
