import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:timezone/timezone.dart' as tz;

extension type const AndroidIconName(String resource) {}

extension type const NotificationChannelId(String value) {}

enum PermissionPrompt { notShown, shown }

sealed class NotificationTarget {
  const NotificationTarget();

  factory NotificationTarget.of({
    required FlutterLocalNotificationsPlatform platform,
  }) => switch (platform) {
    final AndroidFlutterLocalNotificationsPlugin android => AndroidTarget(
      plugin: android,
    ),
    final IOSFlutterLocalNotificationsPlugin ios => DarwinTarget(plugin: ios),
    FlutterLocalNotificationsPlatform() => const UnsupportedTarget(),
  };
}

final class AndroidTarget extends NotificationTarget {
  const AndroidTarget({required this.plugin});

  final AndroidFlutterLocalNotificationsPlugin plugin;
}

final class DarwinTarget extends NotificationTarget {
  const DarwinTarget({required this.plugin});

  final IOSFlutterLocalNotificationsPlugin plugin;
}

final class UnsupportedTarget extends NotificationTarget {
  const UnsupportedTarget();
}

final class LocalNotifications implements NotificationsPort {
  LocalNotifications({required FlutterLocalNotificationsPlatform platform})
    : _target = NotificationTarget.of(platform: platform);

  static const AndroidIconName androidIcon = AndroidIconName('ic_notification');
  static const NotificationChannelId channelId = NotificationChannelId(
    'cleanday',
  );

  final NotificationTarget _target;
  PermissionPrompt _prompt = PermissionPrompt.notShown;

  late final Future<void> _initialised = switch (_target) {
    AndroidTarget(:final plugin) => plugin.initialize(
      settings: AndroidInitializationSettings(androidIcon.resource),
    ),
    DarwinTarget(:final plugin) => plugin.initialize(
      settings: const DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    ),
    UnsupportedTarget() => Future<void>.value(),
  };

  @override
  Future<NotificationAccess> ensureAccess() async {
    try {
      await _initialised;
      return switch (_target) {
        AndroidTarget(:final plugin) => await _androidAccess(plugin: plugin),
        DarwinTarget(:final plugin) => await _darwinAccess(plugin: plugin),
        UnsupportedTarget() => NotificationAccess.unsupported,
      };
    } on PlatformException {
      return NotificationAccess.refused;
    }
  }

  @override
  Future<Outcome<ScheduledCount, UnavailableFailure>> replaceAll({
    required NotificationChannelName channel,
    required List<PlannedNotification> notifications,
  }) async {
    switch (_target) {
      case UnsupportedTarget():
        return const Ok(value: ScheduledCount(0));
      case AndroidTarget() || DarwinTarget():
        break;
    }
    try {
      await _initialised;
      await _cancelAll();
      await Future.wait(
        notifications.map(
          (notification) =>
              _schedule(channel: channel, notification: notification),
        ),
      );
      return Ok(value: ScheduledCount(notifications.length));
    } on PlatformException catch (error) {
      return Err(error: UnavailableFailure(what: 'notifications: $error'));
    }
  }

  Future<NotificationAccess> _androidAccess({
    required AndroidFlutterLocalNotificationsPlugin plugin,
  }) async => switch (await plugin.areNotificationsEnabled()) {
    true => NotificationAccess.granted,
    false || null => switch (_markPrompt()) {
      PermissionPrompt.shown => NotificationAccess.refused,
      PermissionPrompt.notShown => switch (await plugin
          .requestNotificationsPermission()) {
        true => NotificationAccess.granted,
        false || null => NotificationAccess.refused,
      },
    },
  };

  Future<NotificationAccess> _darwinAccess({
    required IOSFlutterLocalNotificationsPlugin plugin,
  }) async => switch (await plugin.checkPermissions()) {
    NotificationsEnabledOptions(isEnabled: true) => NotificationAccess.granted,
    NotificationsEnabledOptions() || null => switch (_markPrompt()) {
      PermissionPrompt.shown => NotificationAccess.refused,
      PermissionPrompt.notShown => switch (await plugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      )) {
        true => NotificationAccess.granted,
        false || null => NotificationAccess.refused,
      },
    },
  };

  PermissionPrompt _markPrompt() {
    final before = _prompt;
    _prompt = PermissionPrompt.shown;
    return before;
  }

  Future<void> _cancelAll() => switch (_target) {
    AndroidTarget(:final plugin) => plugin.cancelAll(),
    DarwinTarget(:final plugin) => plugin.cancelAll(),
    UnsupportedTarget() => Future<void>.value(),
  };

  Future<void> _schedule({
    required NotificationChannelName channel,
    required PlannedNotification notification,
  }) => switch (_target) {
    AndroidTarget(:final plugin) => plugin.zonedSchedule(
      id: notification.id.value,
      title: notification.title.text,
      body: notification.body.text,
      scheduledDate: tz.TZDateTime.from(notification.at.utc, tz.UTC),
      notificationDetails: AndroidNotificationDetails(
        channelId.value,
        channel.text,
        icon: androidIcon.resource,
      ),
      scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    ),
    DarwinTarget(:final plugin) => plugin.zonedSchedule(
      id: notification.id.value,
      title: notification.title.text,
      body: notification.body.text,
      scheduledDate: tz.TZDateTime.from(notification.at.utc, tz.UTC),
      notificationDetails: const DarwinNotificationDetails(),
    ),
    UnsupportedTarget() => Future<void>.value(),
  };
}
