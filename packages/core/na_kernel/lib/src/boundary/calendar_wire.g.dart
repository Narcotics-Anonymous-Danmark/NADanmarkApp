// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEventDto _$CalendarEventDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CalendarEventDto',
      json,
      ($checkedConvert) {
        final val = CalendarEventDto(
          eventName: $checkedConvert(
            'event_name',
            (v) => const LenientText().fromJson(v),
          ),
          eventStartDate: $checkedConvert(
            'event_start_date',
            (v) => const LenientText().fromJson(v),
          ),
          eventStartTime: $checkedConvert(
            'event_start_time',
            (v) => const LenientText().fromJson(v),
          ),
          locationTown: $checkedConvert(
            'location_town',
            (v) => const LenientText().fromJson(v),
          ),
          thumbnail: $checkedConvert(
            'thumbnail',
            (v) => const LenientText().fromJson(v),
          ),
          url: $checkedConvert('url', (v) => const LenientText().fromJson(v)),
        );
        return val;
      },
      fieldKeyMap: const {
        'eventName': 'event_name',
        'eventStartDate': 'event_start_date',
        'eventStartTime': 'event_start_time',
        'locationTown': 'location_town',
      },
    );

Map<String, dynamic> _$CalendarEventDtoToJson(CalendarEventDto instance) =>
    <String, dynamic>{
      'event_name': ?const LenientText().toJson(instance.eventName),
      'event_start_date': ?const LenientText().toJson(instance.eventStartDate),
      'event_start_time': ?const LenientText().toJson(instance.eventStartTime),
      'location_town': ?const LenientText().toJson(instance.locationTown),
      'thumbnail': ?const LenientText().toJson(instance.thumbnail),
      'url': ?const LenientText().toJson(instance.url),
    };
