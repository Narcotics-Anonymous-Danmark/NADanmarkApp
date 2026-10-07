import 'package:na_cli/src/boundary/tool_wire.dart';
import 'package:na_cli/src/boundary/wire_json.dart';

extension type const DeviceId(String value) {}

enum DevicePlatform {
  android,
  ios,
  other
  ;

  static DevicePlatform fromTargetPlatform(final String value) {
    if (value.startsWith('android')) {
      return DevicePlatform.android;
    }
    if (value.startsWith('ios')) {
      return DevicePlatform.ios;
    }
    return DevicePlatform.other;
  }
}

enum DeviceOrigin { physical, emulator }

final class FlutterDevice {
  const FlutterDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.origin,
  });

  factory FlutterDevice.fromDto({required final FlutterDeviceDto dto}) =>
      FlutterDevice(
        id: DeviceId(dto.id ?? ''),
        name: dto.name ?? '',
        platform: DevicePlatform.fromTargetPlatform(dto.targetPlatform ?? ''),
        origin: switch (dto.emulator) {
          true => DeviceOrigin.emulator,
          false || null => DeviceOrigin.physical,
        },
      );

  final DeviceId id;
  final String name;
  final DevicePlatform platform;
  final DeviceOrigin origin;

  static List<FlutterDevice> parseList({required final String json}) =>
      switch (const WireJson().objects(
        text: json,
        fromJson: FlutterDeviceDto.fromJson,
      )) {
        WireDecoded(:final value) => List.unmodifiable(
          value.map((final dto) => FlutterDevice.fromDto(dto: dto)),
        ),
        WireRejected() => const [],
      };
}
