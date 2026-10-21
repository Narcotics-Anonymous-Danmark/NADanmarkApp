@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/dates.dart';

PlannedNotification aPlannedNotification({
  NotificationId id = const NotificationId(1),
}) => PlannedNotification(
  id: id,
  at: anInstant(),
  title: const NotificationTitle('Cleanday - Anna'),
  body: const NotificationBody('Congratulations on 90 days'),
);

void main() {
  test('planned notifications compare by value', () {
    expect(aPlannedNotification(), aPlannedNotification());
    expect(aPlannedNotification().hashCode, aPlannedNotification().hashCode);
    expect(
      aPlannedNotification(),
      isNot(aPlannedNotification(id: const NotificationId(2))),
    );
    expect(aPlannedNotification().toString(), contains('Cleanday - Anna'));
  });

  test('a failed schedule is reported with its cause', () {
    const event = NotificationsFailed(
      failure: UnavailableFailure(what: 'plugin'),
    );
    expect(event.failure, const UnavailableFailure(what: 'plugin'));
  });
}
