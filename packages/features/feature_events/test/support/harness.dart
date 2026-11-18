import 'package:feature_events/feature_events.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

TestContainer eventsHarness() {
  final harness = TestContainer.build();
  addTearDown(harness.dispose);
  return harness;
}

Future<void> flush() async {
  for (var turn = 0; turn < 20; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<EventsState> loadedEvents(TestContainer harness) async {
  harness.read(eventsProvider);
  await flush();
  return harness.read(eventsProvider);
}

List<CalendarEvent> eventsIn(EventsState state) => switch (state) {
  Loaded(:final value) => value,
  Loading() || Failed() => throw StateError('$state'),
};

const Failure offline = NetworkFailure(detail: 'offline');

Future<void> pumpEvents({
  required WidgetTester tester,
  required TestContainer harness,
  required Widget child,
  Language language = Language.danish,
}) async {
  await pumpFeature(
    tester: tester,
    harness: harness,
    language: language,
    child: goldenFrame(
      child: ColoredBox(color: const Color(0xFFF4F5F8), child: child),
    ),
  );
  final context = tester.element(find.byWidget(child));
  await tester.runAsync(() => precacheImage(eventPlaceholder, context));
  await tester.pumpAndSettle();
}
