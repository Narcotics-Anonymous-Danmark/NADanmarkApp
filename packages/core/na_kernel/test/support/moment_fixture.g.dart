// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment_fixture.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MomentFixtureDto _$MomentFixtureDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MomentFixtureDto', json, ($checkedConvert) {
      final val = MomentFixtureDto(
        rows: $checkedConvert(
          'rows',
          (v) => (v as List<dynamic>?)
              ?.map((e) => MomentRowDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

MomentRowDto _$MomentRowDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MomentRowDto', json, ($checkedConvert) {
      final val = MomentRowDto(
        clean: $checkedConvert('clean', (v) => v as String?),
        today: $checkedConvert('today', (v) => v as String?),
        ymd: $checkedConvert(
          'ymd',
          (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
        ),
        md: $checkedConvert(
          'md',
          (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
        ),
        days: $checkedConvert('days', (v) => (v as num?)?.toInt()),
        tag: $checkedConvert('tag', (v) => v as String?),
        upcoming: $checkedConvert(
          'upcoming',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });
