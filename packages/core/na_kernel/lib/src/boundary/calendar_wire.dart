import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/calendar/calendar_event.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/local_date.dart';
import 'package:na_kernel/src/time/local_time.dart';

part 'calendar_wire.g.dart';

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  fieldRename: FieldRename.snake,
  converters: [LenientText()],
)
final class CalendarEventDto {
  const CalendarEventDto({
    this.eventName,
    this.eventStartDate,
    this.eventStartTime,
    this.locationTown,
    this.thumbnail,
    this.url,
  });

  factory CalendarEventDto.fromJson(WireObject json) =>
      _$CalendarEventDtoFromJson(json);

  final String? eventName;
  final String? eventStartDate;
  final String? eventStartTime;
  final String? locationTown;
  final String? thumbnail;
  final String? url;

  WireObject toJson() => _$CalendarEventDtoToJson(this);
}

final class CalendarMapper {
  const CalendarMapper();

  static const WireJson _wire = WireJson();

  Outcome<List<CalendarEvent>, DecodeFailure> events({
    required Object? json,
  }) => _wire
      .rows(
        json: json,
        fromJson: CalendarEventDto.fromJson,
        context: 'calendar',
      )
      .map(
        transform: (dtos) => List<CalendarEvent>.unmodifiable(
          dtos
              .map((dto) => event(dto: dto))
              .whereType<Ok<CalendarEvent, DecodeFailure>>()
              .map((ok) => ok.value),
        ),
      );

  Outcome<CalendarEvent, DecodeFailure> event({
    required CalendarEventDto dto,
  }) {
    final dateText = (dto.eventStartDate ?? '').trim();
    final pageText = (dto.url ?? '').trim();
    return switch ((
      LocalDate.parseIso(text: dateText),
      _webUrl(text: pageText),
    )) {
      (Ok(value: final date), Ok(value: final page)) => Ok(
        value: CalendarEvent(
          name: EventName((dto.eventName ?? '').trim()),
          town: EventTown((dto.locationTown ?? '').trim()),
          date: date,
          start: _start(text: (dto.eventStartTime ?? '').trim()),
          thumbnail: _thumbnail(text: (dto.thumbnail ?? '').trim()),
          page: EventPageUrl(page),
        ),
      ),
      (Err(:final error), Outcome<Uri, DecodeFailure>()) ||
      (Ok(), Err(:final error)) => Err(
        error: DecodeFailure(detail: 'calendar event: ${error.detail}'),
      ),
    };
  }

  static EventStart _start({required String text}) => text.isEmpty
      ? const NoStartTime()
      : switch (LocalTime.parseClock(text: text)) {
          Ok(:final value) => StartsAt(time: value),
          Err() => const NoStartTime(),
        };

  static EventThumbnail _thumbnail({required String text}) =>
      switch (_webUrl(text: text)) {
        Ok(:final value) => ThumbnailAt(url: ThumbnailUrl(value)),
        Err() => const NoThumbnail(),
      };

  static Outcome<Uri, DecodeFailure> _webUrl({required String text}) =>
      switch (Uri.tryParse(text)) {
        final Uri uri
            when text.isNotEmpty &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty =>
          Ok(value: uri),
        Object() || null => Err(
          error: DecodeFailure(detail: '"$text" is not a web URL'),
        ),
      };
}
