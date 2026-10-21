@Tags(['unit'])
library;

import 'package:adapter_notifications/adapter_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

const NotificationChannelName channel = NotificationChannelName('Cleanday');

enum PlatformAnswer { yes, no, unknown, throws }

enum PluginCall {
  initialize,
  areNotificationsEnabled,
  requestNotificationsPermission,
  checkPermissions,
  cancelAll,
}

enum DarwinPermission { alert, badge, sound }

bool? answerOf(PlatformAnswer answer) => switch (answer) {
  PlatformAnswer.yes => true,
  PlatformAnswer.no => false,
  PlatformAnswer.unknown => null,
  PlatformAnswer.throws => throw PlatformException(code: 'scripted'),
};

final class ScheduledCall {
  const ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
  });

  final NotificationId id;
  final NotificationTitle title;
  final NotificationBody body;
  final tz.TZDateTime at;
}

final class AndroidPluginMimic extends AndroidFlutterLocalNotificationsPlugin {
  AndroidPluginMimic({
    this.enabled = PlatformAnswer.no,
    this.request = PlatformAnswer.yes,
    this.scheduling = PlatformAnswer.yes,
  });

  final PlatformAnswer enabled;
  final PlatformAnswer request;
  final PlatformAnswer scheduling;
  final List<PluginCall> calls = [];
  final List<ScheduledCall> scheduled = [];
  final List<AndroidScheduleMode> modes = [];
  final List<AndroidNotificationDetails?> details = [];
  final List<AndroidInitializationSettings> initialisedWith = [];

  @override
  Future<bool> initialize({
    required AndroidInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    calls.add(PluginCall.initialize);
    initialisedWith.add(settings);
    return true;
  }

  @override
  Future<bool?> areNotificationsEnabled() async {
    calls.add(PluginCall.areNotificationsEnabled);
    return answerOf(enabled);
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    calls.add(PluginCall.requestNotificationsPermission);
    return answerOf(request);
  }

  @override
  Future<void> cancelAll() async => calls.add(PluginCall.cancelAll);

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    AndroidNotificationDetails? notificationDetails,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exact,
  }) async {
    answerOf(scheduling);
    modes.add(scheduleMode);
    details.add(notificationDetails);
    scheduled.add(
      ScheduledCall(
        id: NotificationId(id),
        title: NotificationTitle(title ?? ''),
        body: NotificationBody(body ?? ''),
        at: scheduledDate,
      ),
    );
  }
}

final class IosPluginMimic extends IOSFlutterLocalNotificationsPlugin {
  IosPluginMimic({
    this.enabled = PlatformAnswer.no,
    this.request = PlatformAnswer.yes,
  });

  final PlatformAnswer enabled;
  final PlatformAnswer request;
  final List<PluginCall> calls = [];
  final List<ScheduledCall> scheduled = [];
  final List<DarwinInitializationSettings> initialisedWith = [];
  Set<DarwinPermission> requested = const {};

  @override
  Future<bool?> initialize({
    required DarwinInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    calls.add(PluginCall.initialize);
    initialisedWith.add(settings);
    return true;
  }

  @override
  Future<NotificationsEnabledOptions?> checkPermissions() async {
    calls.add(PluginCall.checkPermissions);
    return switch (answerOf(enabled)) {
      final bool isEnabled => NotificationsEnabledOptions(
        isEnabled: isEnabled,
        isAlertEnabled: isEnabled,
        isBadgeEnabled: isEnabled,
        isSoundEnabled: isEnabled,
        isProvisionalEnabled: false,
        isCriticalEnabled: false,
        isProvidesAppNotificationSettingsEnabled: false,
      ),
      null => null,
    };
  }

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requested = {
      if (alert) DarwinPermission.alert,
      if (badge) DarwinPermission.badge,
      if (sound) DarwinPermission.sound,
    };
    return answerOf(request);
  }

  @override
  Future<void> cancelAll() async => calls.add(PluginCall.cancelAll);

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    DarwinNotificationDetails? notificationDetails,
  }) async {
    scheduled.add(
      ScheduledCall(
        id: NotificationId(id),
        title: NotificationTitle(title ?? ''),
        body: NotificationBody(body ?? ''),
        at: scheduledDate,
      ),
    );
  }
}

final class OtherPlatform extends FlutterLocalNotificationsPlatform {}

PlannedNotification planned({required NotificationId id}) =>
    PlannedNotification(
      id: id,
      at: Instant(DateTime.utc(2026, 10, 10, 8)),
      title: const NotificationTitle('Cleanday - Anna'),
      body: const NotificationBody('Congratulations on 60 days'),
    );

void main() {
  group('Android', () {
    test('enabled notifications are granted without asking', () async {
      final android = AndroidPluginMimic(enabled: PlatformAnswer.yes);
      final adapter = LocalNotifications(platform: android);
      expect(await adapter.ensureAccess(), NotificationAccess.granted);
      expect(android.calls, [
        PluginCall.initialize,
        PluginCall.areNotificationsEnabled,
      ]);
      expect(
        android.initialisedWith.single.defaultIcon,
        LocalNotifications.androidIcon.resource,
      );
    });

    test('disabled notifications are requested once per run', () async {
      final android = AndroidPluginMimic(request: PlatformAnswer.no);
      final adapter = LocalNotifications(platform: android);
      expect(await adapter.ensureAccess(), NotificationAccess.refused);
      expect(await adapter.ensureAccess(), NotificationAccess.refused);
      expect(
        android.calls.where(
          (call) => call == PluginCall.requestNotificationsPermission,
        ),
        hasLength(1),
      );
      expect(
        android.calls.where((call) => call == PluginCall.initialize),
        hasLength(1),
      );
    });

    test('a granted request is granted', () async {
      expect(
        await LocalNotifications(platform: AndroidPluginMimic()).ensureAccess(),
        NotificationAccess.granted,
      );
    });

    test('an unknown request answer is refused', () async {
      expect(
        await LocalNotifications(
          platform: AndroidPluginMimic(
            enabled: PlatformAnswer.unknown,
            request: PlatformAnswer.unknown,
          ),
        ).ensureAccess(),
        NotificationAccess.refused,
      );
    });

    test('a platform error while asking is refused', () async {
      expect(
        await LocalNotifications(
          platform: AndroidPluginMimic(enabled: PlatformAnswer.throws),
        ).ensureAccess(),
        NotificationAccess.refused,
      );
    });

    test('replacing cancels first and schedules the exact instants', () async {
      final android = AndroidPluginMimic();
      final outcome = await LocalNotifications(platform: android).replaceAll(
        channel: channel,
        notifications: [
          planned(id: const NotificationId(1)),
          planned(id: const NotificationId(2)),
        ],
      );
      expect(
        outcome,
        const Ok<ScheduledCount, UnavailableFailure>(value: ScheduledCount(2)),
      );
      expect(android.calls, [PluginCall.initialize, PluginCall.cancelAll]);
      final first = android.scheduled.first;
      expect(first.id, const NotificationId(1));
      expect(first.title, const NotificationTitle('Cleanday - Anna'));
      expect(first.body, const NotificationBody('Congratulations on 60 days'));
      expect(first.at.toUtc(), DateTime.utc(2026, 10, 10, 8));
      expect(first.at.location, tz.UTC);
      final details = android.details.first;
      expect(details?.channelId, LocalNotifications.channelId.value);
      expect(details?.channelName, channel.text);
      expect(details?.icon, LocalNotifications.androidIcon.resource);
      expect(android.modes.toSet(), {
        AndroidScheduleMode.inexactAllowWhileIdle,
      });
    });

    test('an empty plan only cancels', () async {
      final android = AndroidPluginMimic();
      expect(
        await LocalNotifications(
          platform: android,
        ).replaceAll(channel: channel, notifications: const []),
        const Ok<ScheduledCount, UnavailableFailure>(value: ScheduledCount(0)),
      );
      expect(android.calls, [PluginCall.initialize, PluginCall.cancelAll]);
      expect(android.scheduled, isEmpty);
    });

    test('a platform failure while scheduling is unavailable', () async {
      expect(
        await LocalNotifications(
          platform: AndroidPluginMimic(scheduling: PlatformAnswer.throws),
        ).replaceAll(
          channel: channel,
          notifications: [planned(id: const NotificationId(1))],
        ),
        isA<Err<ScheduledCount, UnavailableFailure>>(),
      );
    });
  });

  group('iOS', () {
    test('initialises without prompting', () async {
      final ios = IosPluginMimic(enabled: PlatformAnswer.yes);
      expect(
        await LocalNotifications(platform: ios).ensureAccess(),
        NotificationAccess.granted,
      );
      expect(ios.calls, [PluginCall.initialize, PluginCall.checkPermissions]);
      final settings = ios.initialisedWith.single;
      expect(
        [
          settings.requestAlertPermission,
          settings.requestSoundPermission,
          settings.requestBadgePermission,
        ],
        everyElement(isFalse),
      );
      expect(ios.requested, isEmpty);
    });

    test('asks for alert, badge and sound once', () async {
      final ios = IosPluginMimic(enabled: PlatformAnswer.unknown);
      final adapter = LocalNotifications(platform: ios);
      expect(await adapter.ensureAccess(), NotificationAccess.granted);
      expect(ios.requested, DarwinPermission.values.toSet());
    });

    test('a refused prompt is refused and not repeated', () async {
      final ios = IosPluginMimic(request: PlatformAnswer.no);
      final adapter = LocalNotifications(platform: ios);
      expect(await adapter.ensureAccess(), NotificationAccess.refused);
      expect(await adapter.ensureAccess(), NotificationAccess.refused);
    });

    test('schedules with the same instants', () async {
      final ios = IosPluginMimic();
      await LocalNotifications(platform: ios).replaceAll(
        channel: channel,
        notifications: [planned(id: const NotificationId(3))],
      );
      expect(ios.calls.last, PluginCall.cancelAll);
      expect(ios.scheduled.single.id, const NotificationId(3));
      expect(ios.scheduled.single.at.toUtc(), DateTime.utc(2026, 10, 10, 8));
    });
  });

  group('other platforms', () {
    test('are unsupported and schedule nothing', () async {
      final adapter = LocalNotifications(platform: OtherPlatform());
      expect(await adapter.ensureAccess(), NotificationAccess.unsupported);
      expect(
        await adapter.replaceAll(
          channel: channel,
          notifications: [planned(id: const NotificationId(1))],
        ),
        const Ok<ScheduledCount, UnavailableFailure>(value: ScheduledCount(0)),
      );
    });
  });

  test('notificationsOverrides binds the port', () {
    final container = ProviderContainer(
      overrides: notificationsOverrides(platform: AndroidPluginMimic()),
    );
    addTearDown(container.dispose);
    expect(
      container.read(notificationsPortProvider),
      isA<LocalNotifications>(),
    );
  });
}
