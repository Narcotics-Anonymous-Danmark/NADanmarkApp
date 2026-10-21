import 'package:adapter_notifications/src/local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> notificationsOverrides({
  required FlutterLocalNotificationsPlatform platform,
}) => [
  notificationsPortProvider.overrideWithValue(
    LocalNotifications(platform: platform),
  ),
];
