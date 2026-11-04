// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_codec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResumePointDto _$ResumePointDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResumePointDto', json, ($checkedConvert) {
      final val = ResumePointDto(
        trackId: $checkedConvert(
          'trackId',
          (v) => const LenientText().fromJson(v),
        ),
        trackIndex: $checkedConvert(
          'trackIndex',
          (v) => const LenientWholeNumber().fromJson(v),
        ),
        position: $checkedConvert(
          'position',
          (v) => const LenientWholeNumber().fromJson(v),
        ),
        duration: $checkedConvert(
          'duration',
          (v) => const LenientWholeNumber().fromJson(v),
        ),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ResumePointDtoToJson(ResumePointDto instance) =>
    <String, dynamic>{
      'trackId': ?const LenientText().toJson(instance.trackId),
      'trackIndex': ?const LenientWholeNumber().toJson(instance.trackIndex),
      'position': ?const LenientWholeNumber().toJson(instance.position),
      'duration': ?const LenientWholeNumber().toJson(instance.duration),
      'updatedAt': ?const LenientText().toJson(instance.updatedAt),
    };
