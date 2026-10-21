// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleantime_profiles_codec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CleantimeProfileDto _$CleantimeProfileDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CleantimeProfileDto', json, ($checkedConvert) {
      final val = CleantimeProfileDto(
        name: $checkedConvert('name', (v) => const LenientText().fromJson(v)),
        cleanDate: $checkedConvert(
          'cleanDate',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CleantimeProfileDtoToJson(
  CleantimeProfileDto instance,
) => <String, dynamic>{
  'name': ?const LenientText().toJson(instance.name),
  'cleanDate': ?const LenientText().toJson(instance.cleanDate),
};
