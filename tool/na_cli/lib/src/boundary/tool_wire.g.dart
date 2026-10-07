// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlutterDeviceDto _$FlutterDeviceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FlutterDeviceDto', json, ($checkedConvert) {
      final val = FlutterDeviceDto(
        id: $checkedConvert('id', (v) => const LenientText().fromJson(v)),
        name: $checkedConvert('name', (v) => const LenientText().fromJson(v)),
        targetPlatform: $checkedConvert(
          'targetPlatform',
          (v) => const LenientText().fromJson(v),
        ),
        emulator: $checkedConvert(
          'emulator',
          (v) => const LenientFlag().fromJson(v),
        ),
      );
      return val;
    });

FvmConfigDto _$FvmConfigDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FvmConfigDto', json, ($checkedConvert) {
      final val = FvmConfigDto(
        flutter: $checkedConvert(
          'flutter',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$VersionInfoDtoToJson(VersionInfoDto instance) =>
    <String, dynamic>{
      'version': instance.version,
      'build': instance.build,
      'versionCode': instance.versionCode,
      'tag': instance.tag,
    };
