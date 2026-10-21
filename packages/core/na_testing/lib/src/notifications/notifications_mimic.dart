import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/test_values.dart';

enum NotificationPermission { undetermined, granted, refused, unsupported }

enum NotificationPrompt { grant, refuse, ignore }

enum ScheduleBehaviour { accept, fail }

final class NotificationsMimic implements NotificationsPort {
  NotificationsMimic({
    required this.permission,
    required this.prompt,
    required this.behaviour,
  });

  NotificationPermission permission;
  NotificationPrompt prompt;
  ScheduleBehaviour behaviour;
  List<PlannedNotification> scheduled = const [];
  List<NotificationChannelName> channels = const [];
  CallCount promptCalls = const CallCount(0);
  CallCount replaceCalls = const CallCount(0);

  @override
  Future<NotificationAccess> ensureAccess() => switch (permission) {
    NotificationPermission.granted => Future.value(NotificationAccess.granted),
    NotificationPermission.refused => Future.value(NotificationAccess.refused),
    NotificationPermission.unsupported => Future.value(
      NotificationAccess.unsupported,
    ),
    NotificationPermission.undetermined => _prompted(),
  };

  @override
  Future<Outcome<ScheduledCount, UnavailableFailure>> replaceAll({
    required NotificationChannelName channel,
    required List<PlannedNotification> notifications,
  }) async {
    replaceCalls = replaceCalls.next;
    channels = List.unmodifiable([...channels, channel]);
    switch (behaviour) {
      case ScheduleBehaviour.accept:
        scheduled = List.unmodifiable(notifications);
        return Ok(value: ScheduledCount(notifications.length));
      case ScheduleBehaviour.fail:
        scheduled = const [];
        return const Err(
          error: UnavailableFailure(what: 'notifications: scripted failure'),
        );
    }
  }

  Future<NotificationAccess> _prompted() {
    promptCalls = promptCalls.next;
    return switch (prompt) {
      NotificationPrompt.grant => Future.value(
        _settle(permission: NotificationPermission.granted),
      ),
      NotificationPrompt.refuse => Future.value(
        _settle(permission: NotificationPermission.refused),
      ),
      NotificationPrompt.ignore => Completer<NotificationAccess>().future,
    };
  }

  NotificationAccess _settle({required NotificationPermission permission}) {
    this.permission = permission;
    return switch (permission) {
      NotificationPermission.granted => NotificationAccess.granted,
      NotificationPermission.refused ||
      NotificationPermission.undetermined => NotificationAccess.refused,
      NotificationPermission.unsupported => NotificationAccess.unsupported,
    };
  }
}
