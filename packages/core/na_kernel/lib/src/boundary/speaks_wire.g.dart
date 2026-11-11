// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speaks_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeakGroupDto _$SpeakGroupDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SpeakGroupDto', json, ($checkedConvert) {
      final val = SpeakGroupDto(
        title: $checkedConvert('title', (v) => const LenientText().fromJson(v)),
        speaks: $checkedConvert(
          'speaks',
          (v) => (v as List<dynamic>?)
              ?.map((e) => SpeakEntryDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SpeakGroupDtoToJson(SpeakGroupDto instance) =>
    <String, dynamic>{
      'title': ?const LenientText().toJson(instance.title),
      'speaks': ?instance.speaks?.map((e) => e.toJson()).toList(),
    };

SpeakEntryDto _$SpeakEntryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SpeakEntryDto', json, ($checkedConvert) {
      final val = SpeakEntryDto(
        name: $checkedConvert('name', (v) => const LenientText().fromJson(v)),
        location: $checkedConvert(
          'location',
          (v) => const LenientText().fromJson(v),
        ),
        year: $checkedConvert('year', (v) => const LenientText().fromJson(v)),
        audioUrl: $checkedConvert(
          'audioUrl',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SpeakEntryDtoToJson(SpeakEntryDto instance) =>
    <String, dynamic>{
      'name': ?const LenientText().toJson(instance.name),
      'location': ?const LenientText().toJson(instance.location),
      'year': ?const LenientText().toJson(instance.year),
      'audioUrl': ?const LenientText().toJson(instance.audioUrl),
    };
