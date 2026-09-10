import 'package:na_cli/src/boundary/field_text.dart';
import 'package:na_cli/src/boundary/json_object.dart';

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

  factory FlutterDevice.fromJson({required final JsonObject object}) =>
      FlutterDevice(
        id: DeviceId(object.text(key: 'id').orElse(fallback: '')),
        name: object.text(key: 'name').orElse(fallback: ''),
        platform: DevicePlatform.fromTargetPlatform(
          object.text(key: 'targetPlatform').orElse(fallback: ''),
        ),
        origin: switch (object.truth(key: 'emulator')) {
          FieldTruth.yes => DeviceOrigin.emulator,
          FieldTruth.no => DeviceOrigin.physical,
          FieldTruth.absent => DeviceOrigin.physical,
        },
      );

  final DeviceId id;
  final String name;
  final DevicePlatform platform;
  final DeviceOrigin origin;

  static List<FlutterDevice> parseList({required final String json}) =>
      switch (JsonObject.parse(text: json)) {
        JsonListParsed(:final objects) => List.unmodifiable(
          objects.map((final object) => FlutterDevice.fromJson(object: object)),
        ),
        JsonObjectParsed() => const [],
        JsonMalformed() => const [],
      };
}
