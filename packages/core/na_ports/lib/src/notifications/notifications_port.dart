import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class NotificationsPort {
  Future<NotificationAccess> ensureAccess();

  Future<Outcome<ScheduledCount, UnavailableFailure>> replaceAll({
    required NotificationChannelName channel,
    required List<PlannedNotification> notifications,
  });
}

final Provider<NotificationsPort> notificationsPortProvider = unboundPort(
  portName: 'NotificationsPort',
);
