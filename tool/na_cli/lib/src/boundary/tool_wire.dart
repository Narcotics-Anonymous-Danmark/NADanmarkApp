import 'package:json_annotation/json_annotation.dart';
import 'package:na_cli/src/boundary/wire_json.dart';

part 'tool_wire.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText(), LenientFlag()],
)
final class FlutterDeviceDto {
  const FlutterDeviceDto({
    this.id,
    this.name,
    this.targetPlatform,
    this.emulator,
  });

  factory FlutterDeviceDto.fromJson(final WireObject json) =>
      _$FlutterDeviceDtoFromJson(json);

  final String? id;
  final String? name;
  final String? targetPlatform;
  final bool? emulator;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class FvmConfigDto {
  const FvmConfigDto({this.flutter});

  factory FvmConfigDto.fromJson(final WireObject json) =>
      _$FvmConfigDtoFromJson(json);

  final String? flutter;
}

@JsonSerializable(createFactory: false)
final class VersionInfoDto {
  const VersionInfoDto({
    required this.version,
    required this.build,
    required this.versionCode,
    required this.tag,
  });

  final String version;
  final int build;
  final int versionCode;
  final String tag;

  WireObject toJson() => _$VersionInfoDtoToJson(this);
}
