// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacyStoreDumpDto _$LegacyStoreDumpDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LegacyStoreDumpDto',
      json,
      ($checkedConvert) {
        final val = LegacyStoreDumpDto(
          language: $checkedConvert(
            'language',
            (v) => const LenientText().fromJson(v),
          ),
          firstday: $checkedConvert(
            'firstday',
            (v) => const LenientText().fromJson(v),
          ),
          searchRange: $checkedConvert(
            'searchRange',
            (v) => const LenientText().fromJson(v),
          ),
          cleanTimeUnitSort: $checkedConvert(
            'cleanTimeUnitSort',
            (v) => const LenientText().fromJson(v),
          ),
          theme: $checkedConvert(
            'theme',
            (v) => const LenientText().fromJson(v),
          ),
          meetingFormatsV1: $checkedConvert(
            'meeting_formats_v1',
            (v) => _formatsCache(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'meetingFormatsV1': 'meeting_formats_v1'},
    );

Map<String, dynamic> _$LegacyStoreDumpDtoToJson(
  LegacyStoreDumpDto instance,
) => <String, dynamic>{
  'language': ?const LenientText().toJson(instance.language),
  'firstday': ?const LenientText().toJson(instance.firstday),
  'searchRange': ?const LenientText().toJson(instance.searchRange),
  'cleanTimeUnitSort': ?const LenientText().toJson(instance.cleanTimeUnitSort),
  'theme': ?const LenientText().toJson(instance.theme),
  'meeting_formats_v1': ?instance.meetingFormatsV1?.toJson(),
};

MigrationMarkerDto _$MigrationMarkerDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MigrationMarkerDto', json, ($checkedConvert) {
  final val = MigrationMarkerDto(
    version: $checkedConvert('version', (v) => const LenientText().fromJson(v)),
    completedAt: $checkedConvert(
      'completedAt',
      (v) => const LenientText().fromJson(v),
    ),
    imported: $checkedConvert(
      'imported',
      (v) => const LenientInt().fromJson(v),
    ),
    skipped: $checkedConvert('skipped', (v) => const LenientInt().fromJson(v)),
  );
  return val;
});

Map<String, dynamic> _$MigrationMarkerDtoToJson(MigrationMarkerDto instance) =>
    <String, dynamic>{
      'version': ?const LenientText().toJson(instance.version),
      'completedAt': ?const LenientText().toJson(instance.completedAt),
      'imported': ?const LenientInt().toJson(instance.imported),
      'skipped': ?const LenientInt().toJson(instance.skipped),
    };
