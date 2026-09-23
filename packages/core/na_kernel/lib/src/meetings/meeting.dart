import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/meetings/format_codes.dart';
import 'package:na_kernel/src/meetings/meeting_values.dart';
import 'package:na_kernel/src/meetings/municipality.dart';
import 'package:na_kernel/src/time/local_time.dart';
import 'package:na_kernel/src/time/weekday.dart';

enum TemporaryClosure { temporarilyClosed, open }

@immutable
sealed class MeetingVenue {
  const MeetingVenue();
}

final class InPerson extends MeetingVenue {
  const InPerson();

  @override
  int get hashCode => (InPerson).hashCode;

  @override
  bool operator ==(Object other) => other is InPerson;
}

final class Virtual extends MeetingVenue {
  const Virtual({required this.link});

  final Uri link;

  @override
  int get hashCode => Object.hash(Virtual, link);

  @override
  bool operator ==(Object other) => other is Virtual && other.link == link;
}

final class Hybrid extends MeetingVenue {
  const Hybrid({required this.link});

  final Uri link;

  @override
  int get hashCode => Object.hash(Hybrid, link);

  @override
  bool operator ==(Object other) => other is Hybrid && other.link == link;
}

@immutable
sealed class MeetingAction {
  const MeetingAction({required this.uri});

  final Uri uri;
}

final class OpenDirections extends MeetingAction {
  const OpenDirections({required super.uri});

  @override
  int get hashCode => Object.hash(OpenDirections, uri);

  @override
  bool operator ==(Object other) => other is OpenDirections && other.uri == uri;

  @override
  String toString() => 'OpenDirections($uri)';
}

final class JoinVirtualMeeting extends MeetingAction {
  const JoinVirtualMeeting({required super.uri});

  @override
  int get hashCode => Object.hash(JoinVirtualMeeting, uri);

  @override
  bool operator ==(Object other) =>
      other is JoinVirtualMeeting && other.uri == uri;

  @override
  String toString() => 'JoinVirtualMeeting($uri)';
}

final class CallDialIn extends MeetingAction {
  const CallDialIn({required super.uri});

  @override
  int get hashCode => Object.hash(CallDialIn, uri);

  @override
  bool operator ==(Object other) => other is CallDialIn && other.uri == uri;

  @override
  String toString() => 'CallDialIn($uri)';
}

@immutable
final class MeetingTimes {
  const MeetingTimes({required this.start, required this.end});

  final LocalTime start;
  final LocalTime end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  bool operator ==(Object other) =>
      other is MeetingTimes && other.start == start && other.end == end;

  @override
  String toString() => '$start - $end';
}

@immutable
final class Meeting {
  const Meeting({
    required this.id,
    required this.name,
    required this.weekday,
    required this.start,
    required this.duration,
    required this.formatCodes,
    required this.origin,
    required this.virtualLink,
    required this.dialIn,
    required this.location,
    required this.municipality,
    required this.locationLines,
    required this.comment,
    required this.contactLines,
    required this.transitLines,
  });

  final MeetingId id;
  final MeetingName name;
  final Weekday weekday;
  final LocalTime start;
  final Duration duration;
  final MeetingFormatCodes formatCodes;
  final MeetingOrigin origin;
  final VirtualLink virtualLink;
  final DialIn dialIn;
  final MeetingLocation location;
  final Municipality municipality;
  final List<LocationLine> locationLines;
  final MeetingComment comment;
  final List<ContactLine> contactLines;
  final List<TransitLine> transitLines;

  MeetingTimes get times => MeetingTimes(
    start: start,
    end: start.plus(duration: duration),
  );

  MeetingVenue get venue => switch (virtualLink) {
    NoVirtualLink() => const InPerson(),
    VirtualLinkAt(:final uri) => switch (formatCodes.presenceOf(
      key: FormatKey.hybrid,
    )) {
      KeyPresence.present => Hybrid(link: uri),
      KeyPresence.absent => Virtual(link: uri),
    },
  };

  TemporaryClosure get closure => switch ((
    formatCodes.presenceOf(key: FormatKey.temporarilyClosed),
    virtualLink,
  )) {
    (KeyPresence.present, NoVirtualLink()) =>
      TemporaryClosure.temporarilyClosed,
    (KeyPresence.present, VirtualLinkAt()) ||
    (KeyPresence.absent, NoVirtualLink()) ||
    (KeyPresence.absent, VirtualLinkAt()) => TemporaryClosure.open,
  };

  List<MeetingAction> get actions => List.unmodifiable([
    ..._directions,
    ..._virtualActions,
  ]);

  Iterable<MeetingAction> get _directions => switch ((venue, location)) {
    (InPerson() || Hybrid(), Mapped(:final point)) => [
      OpenDirections(
        uri: Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$point',
        ),
      ),
    ],
    (Virtual(), Mapped()) ||
    (InPerson() || Virtual() || Hybrid(), Unmapped()) => const [],
  };

  Iterable<MeetingAction> get _virtualActions => switch ((venue, dialIn)) {
    (InPerson(), NoDialIn() || DialInNumber()) => const [],
    (Virtual(:final link) || Hybrid(:final link), NoDialIn()) => [
      JoinVirtualMeeting(uri: link),
    ],
    (Virtual(:final link) || Hybrid(:final link), final DialInNumber number) =>
      [JoinVirtualMeeting(uri: link), CallDialIn(uri: number.uri)],
  };

  @override
  int get hashCode => Object.hash(
    id,
    name,
    weekday,
    start,
    duration,
    formatCodes,
    origin,
    virtualLink,
    dialIn,
    location,
    municipality,
    Object.hashAll(locationLines),
    comment,
    Object.hashAll(contactLines),
    Object.hashAll(transitLines),
  );

  @override
  bool operator ==(Object other) =>
      other is Meeting &&
      other.id == id &&
      other.name == name &&
      other.weekday == weekday &&
      other.start == start &&
      other.duration == duration &&
      other.formatCodes == formatCodes &&
      other.origin == origin &&
      other.virtualLink == virtualLink &&
      other.dialIn == dialIn &&
      other.location == location &&
      other.municipality == municipality &&
      const ListEquality<LocationLine>().equals(
        other.locationLines,
        locationLines,
      ) &&
      other.comment == comment &&
      const ListEquality<ContactLine>().equals(
        other.contactLines,
        contactLines,
      ) &&
      const ListEquality<TransitLine>().equals(
        other.transitLines,
        transitLines,
      );

  @override
  String toString() =>
      'Meeting(${id.value}, ${name.value}, ${weekday.name} $times)';
}
