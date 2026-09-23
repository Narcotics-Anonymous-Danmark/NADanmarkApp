import 'dart:io';

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';

const WireJson wire = WireJson();
const BmltMapper mapper = BmltMapper();

Meeting aMeeting({
  int id = 1,
  String name = 'Bare for i dag',
  Weekday weekday = Weekday.monday,
  int hour = 19,
  int minute = 0,
  Duration duration = const Duration(hours: 1),
  List<String> formats = const [],
  List<int> sharedIds = const [],
  MeetingOrigin origin = MeetingOrigin.denmark,
  VirtualLink virtualLink = const NoVirtualLink(),
  DialIn dialIn = const NoDialIn(),
  MeetingLocation location = const Mapped(
    point: GeoPoint(
      latitude: Latitude(55.476224),
      longitude: Longitude(8.4606976),
    ),
  ),
  Municipality municipality = const NamedMunicipality(
    name: MunicipalityName('Aarhus'),
  ),
  List<String> locationLines = const ['Kulturhuset', 'Gaden 1'],
  MeetingComment comment = const NoComment(),
  List<String> contactLines = const [],
  List<TransitLine> transitLines = const [],
}) => Meeting(
  id: MeetingId(id),
  name: MeetingName(name),
  weekday: weekday,
  start: LocalTime(hour: HourOfDay(hour), minute: MinuteOfHour(minute)),
  duration: duration,
  formatCodes: MeetingFormatCodes(
    keys: List.unmodifiable(formats.map(FormatKey.new)),
    sharedIds: List.unmodifiable(sharedIds.map(FormatId.new)),
  ),
  origin: origin,
  virtualLink: virtualLink,
  dialIn: dialIn,
  location: location,
  municipality: municipality,
  locationLines: List.unmodifiable(locationLines.map(LocationLine.new)),
  comment: comment,
  contactLines: List.unmodifiable(contactLines.map(ContactLine.new)),
  transitLines: transitLines,
);

VirtualLink aVirtualLink({String url = 'https://zoom.example/j/1'}) =>
    VirtualLinkAt(uri: Uri.parse(url));

FormatRow aFormatRow({
  int id = 17,
  String key = 'ÅM',
  String name = 'Åben Møde',
  String description = 'Alle er velkomne',
  String typeEnum = 'FC3',
  String language = 'da',
}) => FormatRow(
  id: FormatId(id),
  key: FormatKey(key),
  name: FormatName(name),
  description: FormatDescriptionText(description),
  typeEnum: FormatTypeCode(typeEnum),
  language: FormatLanguageCode(language),
);

String bmltFixtureText({required String name}) {
  final segments = Directory.current.absolute.uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  final file =
      List.generate(
        segments.length + 1,
        (depth) => File(
          '/${segments.take(segments.length - depth).join('/')}'
          '/packages/core/na_testing/fixtures/wire/bmlt/$name',
        ),
      ).firstWhere(
        (candidate) => candidate.existsSync(),
        orElse: () => throw StateError('fixture $name not found'),
      );
  return file.readAsStringSync();
}

T fixture<T>({
  required String name,
  required Outcome<T, DecodeFailure> Function(Object? json) decode,
}) => switch (wire
    .parse(
      text: bmltFixtureText(name: name),
      context: name,
    )
    .flatMap(transform: decode)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('$name: $error'),
};

List<Meeting> recordedMeetings() => fixture(
  name: 'denmark_meetings.json',
  decode: (json) => mapper.meetings(json: json),
);

List<MunicipalityName> recordedMunicipalities() => fixture(
  name: 'denmark_municipalities.json',
  decode: (json) => mapper.municipalities(json: json),
);

List<FormatRow> recordedFormatRows() => [
  ...fixture(
    name: 'formats_da.json',
    decode: (json) => mapper.formatRows(json: json),
  ),
  ...fixture(
    name: 'formats_en.json',
    decode: (json) => mapper.formatRows(json: json),
  ),
];
