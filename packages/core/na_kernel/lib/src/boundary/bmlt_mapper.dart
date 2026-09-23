import 'package:na_kernel/src/boundary/bmlt_wire.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/meetings/format_codes.dart';
import 'package:na_kernel/src/meetings/meeting.dart';
import 'package:na_kernel/src/meetings/meeting_formats.dart';
import 'package:na_kernel/src/meetings/meeting_values.dart';
import 'package:na_kernel/src/meetings/municipality.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/hour_of_day.dart';
import 'package:na_kernel/src/time/local_time.dart';
import 'package:na_kernel/src/time/weekday.dart';

final class BmltMapper {
  const BmltMapper();

  static const WireJson _wire = WireJson();

  Outcome<List<Meeting>, DecodeFailure> meetings({required Object? json}) =>
      _wire
          .rows(
            json: json,
            fromJson: BmltMeetingDto.fromJson,
            context: 'meetings',
          )
          .map(
            transform: (dtos) => List<Meeting>.unmodifiable(
              dtos
                  .map((dto) => meeting(dto: dto))
                  .whereType<Ok<Meeting, DecodeFailure>>()
                  .map((ok) => ok.value),
            ),
          );

  Outcome<List<MunicipalityName>, DecodeFailure> municipalities({
    required Object? json,
  }) => _wire
      .rows(
        json: json,
        fromJson: BmltMunicipalityDto.fromJson,
        context: 'municipalities',
      )
      .map(
        transform: (dtos) => List<MunicipalityName>.unmodifiable(
          dtos.map(
            (dto) => MunicipalityName(_text(value: dto.locationMunicipality)),
          ),
        ),
      );

  Outcome<List<FormatRow>, DecodeFailure> formatRows({required Object? json}) =>
      _wire
          .rows(
            json: json,
            fromJson: BmltFormatDto.fromJson,
            context: 'formats',
          )
          .map(transform: (dtos) => formatRowsOf(dtos: dtos));

  List<FormatRow> formatRowsOf({required List<BmltFormatDto> dtos}) =>
      List.unmodifiable(
        dtos
            .map((dto) => formatRow(dto: dto))
            .whereType<Ok<FormatRow, DecodeFailure>>()
            .map((ok) => ok.value),
      );

  Outcome<FormatRow, DecodeFailure> formatRow({required BmltFormatDto dto}) =>
      switch (int.tryParse(_text(value: dto.id))) {
        final int id => Ok(
          value: FormatRow(
            id: FormatId(id),
            key: FormatKey(_text(value: dto.keyString)),
            name: FormatName(_text(value: dto.nameString)),
            description: FormatDescriptionText(
              _text(value: dto.descriptionString),
            ),
            typeEnum: FormatTypeCode(_text(value: dto.formatTypeEnum)),
            language: FormatLanguageCode(_text(value: dto.lang)),
          ),
        ),
        null => Err(error: DecodeFailure(detail: 'format.id: "${dto.id}"')),
      };

  BmltFormatDto formatDto({required FormatRow row}) => BmltFormatDto(
    id: '${row.id.value}',
    keyString: row.key.value,
    nameString: row.name.value,
    descriptionString: row.description.value,
    formatTypeEnum: row.typeEnum.value,
    lang: row.language.value,
  );

  Outcome<Meeting, DecodeFailure> meeting({required BmltMeetingDto dto}) {
    final id = int.tryParse(_text(value: dto.idBigint));
    final tinyint = int.tryParse(_text(value: dto.weekdayTinyint));
    if (id == null || tinyint == null) {
      return Err(
        error: DecodeFailure(
          detail:
              'meeting: id "${dto.idBigint}" weekday "${dto.weekdayTinyint}"',
        ),
      );
    }
    return Weekday.fromBmltTinyint(tinyint: tinyint).flatMap(
      transform: (weekday) =>
          _time(
            text: _text(value: dto.startTime),
            context: 'start_time',
          ).map(
            transform: (start) => _assemble(
              dto: dto,
              id: MeetingId(id),
              weekday: weekday,
              start: start,
            ),
          ),
    );
  }

  Meeting _assemble({
    required BmltMeetingDto dto,
    required MeetingId id,
    required Weekday weekday,
    required LocalTime start,
  }) => Meeting(
    id: id,
    name: MeetingName(_text(value: dto.meetingName)),
    weekday: weekday,
    start: start,
    duration: switch (_time(
      text: _text(value: dto.durationTime),
      context: 'duration_time',
    )) {
      Ok(:final value) => Duration(
        hours: value.hour.value,
        minutes: value.minute.value,
      ),
      Err() => Duration.zero,
    },
    formatCodes: MeetingFormatCodes(
      keys: List.unmodifiable(
        _list(text: _text(value: dto.formats)).map(FormatKey.new),
      ),
      sharedIds: List.unmodifiable(
        _list(
          text: _text(value: dto.formatSharedIdList),
        ).map((id) => FormatId(int.tryParse(id) ?? -1)),
      ),
    ),
    origin: _origin(dto: dto),
    virtualLink: _virtualLink(text: _text(value: dto.virtualMeetingLink)),
    dialIn: switch (_text(value: dto.phoneMeetingNumber)) {
      '' => const NoDialIn(),
      final String number => DialInNumber(number: PhoneNumber(number)),
    },
    location: _location(dto: dto),
    municipality: Municipality.normalise(
      raw: MunicipalityName(_text(value: dto.locationMunicipality)),
    ),
    locationLines: List.unmodifiable(
      [
            dto.locationText,
            dto.locationStreet,
            dto.locationCitySubsection,
            dto.locationNeighborhood,
            dto.locationMunicipality,
            dto.locationSubProvince,
            dto.locationProvince,
            dto.locationPostalCode1,
            dto.locationInfo,
          ]
          .map((value) => _text(value: value))
          .where((text) => text.isNotEmpty)
          .map(
            LocationLine.new,
          ),
    ),
    comment: switch (_text(value: dto.comments)) {
      '' => const NoComment(),
      final String text => Comment(text: CommentText(text)),
    },
    contactLines: List.unmodifiable(
      [
            dto.virtualMeetingAdditionalInfo,
            dto.contactPhone1,
            dto.contactEmail1,
          ]
          .map((value) => _text(value: value))
          .where((text) => text.isNotEmpty)
          .map(
            ContactLine.new,
          ),
    ),
    transitLines: List.unmodifiable(
      [
        TransitLine.fromWire(
          kind: TransitKind.train,
          text: _text(value: dto.trainLines),
        ),
        TransitLine.fromWire(
          kind: TransitKind.bus,
          text: _text(value: dto.busLines),
        ),
      ].where((line) => line.lines.value.isNotEmpty),
    ),
  );

  static String _text({required String? value}) => value?.trim() ?? '';

  static List<String> _list({required String text}) => List.unmodifiable(
    text.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty),
  );

  static Outcome<LocalTime, DecodeFailure> _time({
    required String text,
    required String context,
  }) {
    final parts = text.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return Err(error: DecodeFailure(detail: '$context: "$text"'));
    }
    return Ok(
      value: LocalTime(hour: HourOfDay(hour), minute: MinuteOfHour(minute)),
    );
  }

  static MeetingOrigin _origin({required BmltMeetingDto dto}) {
    if (!_text(value: dto.rootServerUri).contains('nadanmark.dk')) {
      return MeetingOrigin.otherRoot;
    }
    return _text(value: dto.rootServerId).isEmpty
        ? MeetingOrigin.denmark
        : MeetingOrigin.denmarkAggregated;
  }

  static VirtualLink _virtualLink({required String text}) =>
      switch (text.isEmpty ? null : Uri.tryParse(text)) {
        final Uri uri => VirtualLinkAt(uri: uri),
        null => const NoVirtualLink(),
      };

  static MeetingLocation _location({required BmltMeetingDto dto}) {
    final latitude = double.tryParse(_text(value: dto.latitude));
    final longitude = double.tryParse(_text(value: dto.longitude));
    if (latitude == null ||
        longitude == null ||
        (latitude == 0 && longitude == 0)) {
      return const Unmapped();
    }
    return Mapped(
      point: GeoPoint(
        latitude: Latitude(latitude),
        longitude: Longitude(longitude),
      ),
    );
  }
}
