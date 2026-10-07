@Tags(['unit'])
library;

import 'package:na_cli/src/boundary/app_store_wire.dart';
import 'package:na_cli/src/boundary/tool_wire.dart';
import 'package:na_cli/src/boundary/wire_json.dart';
import 'package:test/test.dart';

void main() {
  const wire = WireJson();

  group('object', () {
    test('decodes an object through its DTO', () {
      final read = wire.object(
        text: '{"flutter":"3.41.3"}',
        fromJson: FvmConfigDto.fromJson,
      );
      expect((read as WireDecoded<FvmConfigDto>).value.flutter, '3.41.3');
    });

    test('rejects malformed text, lists and values of the wrong shape', () {
      for (final text in ['{', '[]', '{"data":"x"}']) {
        expect(
          wire.object(text: text, fromJson: AscListDto.fromJson),
          isA<WireRejected<AscListDto>>(),
          reason: text,
        );
      }
    });
  });

  group('objects', () {
    test('keeps the rows that decode and skips the rest', () {
      final read = wire.objects(
        text:
            '[{"id":"a","emulator":true},3,'
            '{"id":7,"emulator":"yes"}]',
        fromJson: FlutterDeviceDto.fromJson,
      );
      final devices = (read as WireDecoded<List<FlutterDeviceDto>>).value;
      expect(devices.map((final device) => device.id), ['a', '7']);
      expect(devices.map((final device) => device.emulator), [true, null]);
    });

    test('rejects anything but a list', () {
      expect(
        wire.objects(text: '{}', fromJson: FlutterDeviceDto.fromJson),
        isA<WireRejected<List<FlutterDeviceDto>>>(),
      );
      expect(
        wire.objects(text: 'nope', fromJson: FlutterDeviceDto.fromJson),
        isA<WireRejected<List<FlutterDeviceDto>>>(),
      );
    });
  });

  group('textEntries', () {
    test('keeps only text values', () {
      final read = wire.textEntries(text: '{"a":"1","b":2,"c":null}');
      expect((read as WireDecoded<Map<String, String>>).value, {'a': '1'});
    });

    test('rejects lists and malformed text', () {
      expect(wire.textEntries(text: '[]'), isA<WireRejected<Object?>>());
      expect(wire.textEntries(text: '{'), isA<WireRejected<Object?>>());
    });
  });

  test('converters accept only what they can read', () {
    const text = LenientText();
    expect(text.fromJson('a'), 'a');
    expect(text.fromJson(2.5), '2.5');
    expect(text.fromJson(true), isNull);
    expect(text.toJson('a'), 'a');
    const flag = LenientFlag();
    expect(flag.fromJson(false), isFalse);
    expect(flag.fromJson('true'), isNull);
    expect(flag.toJson(true), isTrue);
  });

  test('encode writes compact JSON', () {
    expect(
      wire.encode(
        json: const VersionInfoDto(
          version: '2.0.0',
          build: 1,
          versionCode: 1120000001,
          tag: 'v2.0.0',
        ).toJson(),
      ),
      '{"version":"2.0.0","build":1,"versionCode":1120000001,"tag":"v2.0.0"}',
    );
  });
}
