import 'package:meta/meta.dart';

extension type const MeetingId(int value) {}

extension type const MeetingName(String value) {}

extension type const Latitude(double value) {}

extension type const Longitude(double value) {}

extension type const PhoneNumber(String value) {}

extension type const CommentText(String value) {}

extension type const TransitLines(String value) {}

extension type const LocationLine(String text) {}

extension type const ContactLine(String text) {}

@immutable
final class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final Latitude latitude;
  final Longitude longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  String toString() => '${latitude.value},${longitude.value}';
}

@immutable
sealed class MeetingLocation {
  const MeetingLocation();
}

final class Mapped extends MeetingLocation {
  const Mapped({required this.point});

  final GeoPoint point;

  @override
  int get hashCode => Object.hash(Mapped, point);

  @override
  bool operator ==(Object other) => other is Mapped && other.point == point;

  @override
  String toString() => 'Mapped($point)';
}

final class Unmapped extends MeetingLocation {
  const Unmapped();

  @override
  int get hashCode => (Unmapped).hashCode;

  @override
  bool operator ==(Object other) => other is Unmapped;

  @override
  String toString() => 'Unmapped';
}

@immutable
sealed class VirtualLink {
  const VirtualLink();
}

final class NoVirtualLink extends VirtualLink {
  const NoVirtualLink();

  @override
  int get hashCode => (NoVirtualLink).hashCode;

  @override
  bool operator ==(Object other) => other is NoVirtualLink;

  @override
  String toString() => 'NoVirtualLink';
}

final class VirtualLinkAt extends VirtualLink {
  const VirtualLinkAt({required this.uri});

  final Uri uri;

  @override
  int get hashCode => Object.hash(VirtualLinkAt, uri);

  @override
  bool operator ==(Object other) => other is VirtualLinkAt && other.uri == uri;

  @override
  String toString() => 'VirtualLinkAt($uri)';
}

@immutable
sealed class DialIn {
  const DialIn();
}

final class NoDialIn extends DialIn {
  const NoDialIn();

  @override
  int get hashCode => (NoDialIn).hashCode;

  @override
  bool operator ==(Object other) => other is NoDialIn;

  @override
  String toString() => 'NoDialIn';
}

final class DialInNumber extends DialIn {
  const DialInNumber({required this.number});

  final PhoneNumber number;

  Uri get uri => Uri(scheme: 'tel', path: number.value);

  @override
  int get hashCode => Object.hash(DialInNumber, number);

  @override
  bool operator ==(Object other) =>
      other is DialInNumber && other.number == number;

  @override
  String toString() => 'DialInNumber(${number.value})';
}

@immutable
sealed class MeetingComment {
  const MeetingComment();
}

final class NoComment extends MeetingComment {
  const NoComment();

  @override
  int get hashCode => (NoComment).hashCode;

  @override
  bool operator ==(Object other) => other is NoComment;

  @override
  String toString() => 'NoComment';
}

final class Comment extends MeetingComment {
  const Comment({required this.text});

  final CommentText text;

  @override
  int get hashCode => Object.hash(Comment, text);

  @override
  bool operator ==(Object other) => other is Comment && other.text == text;

  @override
  String toString() => 'Comment(${text.value})';
}

enum TransitKind { train, bus }

@immutable
final class TransitLine {
  const TransitLine({required this.kind, required this.lines});

  factory TransitLine.fromWire({
    required TransitKind kind,
    required String text,
  }) => TransitLine(
    kind: kind,
    lines: TransitLines(text.replaceAll(_delimiter, ' ').trim()),
  );

  static final RegExp _delimiter = RegExp(
    '(Bus|Train) Lines#@-@#',
    caseSensitive: false,
  );

  final TransitKind kind;
  final TransitLines lines;

  @override
  int get hashCode => Object.hash(kind, lines);

  @override
  bool operator ==(Object other) =>
      other is TransitLine && other.kind == kind && other.lines == lines;

  @override
  String toString() => '${kind.name}: ${lines.value}';
}
