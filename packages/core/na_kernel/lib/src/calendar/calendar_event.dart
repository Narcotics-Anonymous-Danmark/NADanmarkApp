import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/local_date.dart';
import 'package:na_kernel/src/time/local_time.dart';

extension type const EventName(String text) {}

extension type const EventTown(String text) {}

extension type const EventPageUrl(Uri uri) {}

extension type const ThumbnailUrl(Uri uri) {}

extension type const EventCategory(String slug) {
  static const EventCategory recovery = EventCategory('bedringsarrangement');
}

@immutable
sealed class EventStart {
  const EventStart();
}

final class StartsAt extends EventStart {
  const StartsAt({required this.time});

  final LocalTime time;

  @override
  int get hashCode => Object.hash(StartsAt, time);

  @override
  bool operator ==(Object other) => other is StartsAt && other.time == time;

  @override
  String toString() => 'StartsAt($time)';
}

final class NoStartTime extends EventStart {
  const NoStartTime();

  @override
  int get hashCode => (NoStartTime).hashCode;

  @override
  bool operator ==(Object other) => other is NoStartTime;

  @override
  String toString() => 'NoStartTime';
}

@immutable
sealed class EventThumbnail {
  const EventThumbnail();
}

final class ThumbnailAt extends EventThumbnail {
  const ThumbnailAt({required this.url});

  final ThumbnailUrl url;

  @override
  int get hashCode => Object.hash(ThumbnailAt, url);

  @override
  bool operator ==(Object other) => other is ThumbnailAt && other.url == url;

  @override
  String toString() => 'ThumbnailAt(${url.uri})';
}

final class NoThumbnail extends EventThumbnail {
  const NoThumbnail();

  @override
  int get hashCode => (NoThumbnail).hashCode;

  @override
  bool operator ==(Object other) => other is NoThumbnail;

  @override
  String toString() => 'NoThumbnail';
}

@immutable
final class CalendarEvent {
  const CalendarEvent({
    required this.name,
    required this.town,
    required this.date,
    required this.start,
    required this.thumbnail,
    required this.page,
  });

  final EventName name;
  final EventTown town;
  final LocalDate date;
  final EventStart start;
  final EventThumbnail thumbnail;
  final EventPageUrl page;

  @override
  int get hashCode => Object.hash(name, town, date, start, thumbnail, page);

  @override
  bool operator ==(Object other) =>
      other is CalendarEvent &&
      other.name == name &&
      other.town == town &&
      other.date == date &&
      other.start == start &&
      other.thumbnail == thumbnail &&
      other.page == page;

  @override
  String toString() => 'CalendarEvent(${name.text}, $date, ${page.uri})';
}
