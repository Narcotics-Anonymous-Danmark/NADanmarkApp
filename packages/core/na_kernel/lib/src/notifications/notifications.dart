import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/instant.dart';

extension type const NotificationId(int value) {}

extension type const NotificationTitle(String text) {}

extension type const NotificationBody(String text) {}

extension type const NotificationChannelName(String text) {}

extension type const ScheduledCount(int value) {}

enum NotificationAccess { granted, refused, unsupported }

@immutable
final class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final NotificationId id;
  final Instant at;
  final NotificationTitle title;
  final NotificationBody body;

  @override
  int get hashCode => Object.hash(id, at, title, body);

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  String toString() =>
      'PlannedNotification(${id.value}, ${at.utc.toIso8601String()}, '
      '${title.text}, ${body.text})';
}
