import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

const ProfileName bo = ProfileName('Bo');
const LocalDate september10 = LocalDate(year: 2026, month: 9, day: 10);

TestContainer cleantimeHarness({
  Map<String, String> storedValues = const {},
  NotificationPermission permission = NotificationPermission.granted,
  NotificationPrompt prompt = NotificationPrompt.grant,
  ScheduleBehaviour behaviour = ScheduleBehaviour.accept,
  LocalDate today = september10,
  HourOfDay utcHour = const HourOfDay(12),
}) {
  final harness = TestContainer.buildAt(
    time: TestTime.copenhagen(
      startAt: Instant(
        DateTime.utc(today.year, today.month, today.day, utcHour.value),
      ),
    ),
    storedValues: storedValues,
  );
  addTearDown(harness.dispose);
  harness.notifications
    ..permission = permission
    ..prompt = prompt
    ..behaviour = behaviour;
  return harness;
}

Future<void> flush() async {
  for (var turn = 0; turn < 10; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

Instant tenOClock(LocalDate date) =>
    Instant(DateTime.utc(date.year, date.month, date.day, 8));
