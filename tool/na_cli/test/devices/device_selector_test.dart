@Tags(['unit'])
library;

import 'package:na_cli/src/devices/device_selector.dart';
import 'package:na_cli/src/devices/flutter_device.dart';
import 'package:test/test.dart';

import '../support/builders.dart';

void main() {
  const selector = DeviceSelector();

  List<FlutterDevice> devices(final List<Map<String, Object>> raw) =>
      FlutterDevice.parseList(json: aDevicesJson(devices: raw));

  test('parses flutter devices --machine output', () {
    final parsed = devices([
      aDevice(),
      aDevice(id: 'R58M', targetPlatform: 'android-arm64', emulator: false),
      aDevice(id: 'ios-sim', targetPlatform: 'ios', emulator: true),
      aDevice(id: 'linux', targetPlatform: 'linux-x64', emulator: false),
    ]);
    expect(parsed.map((final d) => d.platform), [
      DevicePlatform.android,
      DevicePlatform.android,
      DevicePlatform.ios,
      DevicePlatform.other,
    ]);
    expect(parsed[1].origin, DeviceOrigin.physical);
  });

  test('prefers a physical device when any is present', () {
    final choice = selector.select(
      devices: devices([aDevice(), aDevice(id: 'phone', emulator: false)]),
      platform: DevicePlatform.android,
      preference: const AnyDevice(),
    );
    expect((choice as UseDevice).device.id.value, 'phone');
  });

  test('falls back to a running emulator, then to booting one', () {
    expect(
      (selector.select(
                devices: devices([aDevice()]),
                platform: DevicePlatform.android,
                preference: const AnyDevice(),
              )
              as UseDevice)
          .device
          .id
          .value,
      'emulator-5554',
    );
    expect(
      selector.select(
        devices: devices([]),
        platform: DevicePlatform.android,
        preference: const AnyDevice(),
      ),
      isA<BootEmulator>(),
    );
  });

  test('--device requires a physical device', () {
    expect(
      selector.select(
        devices: devices([aDevice()]),
        platform: DevicePlatform.android,
        preference: const PreferPhysical(),
      ),
      isA<NoDeviceMatches>(),
    );
  });

  test('--emulator ignores physical devices', () {
    expect(
      selector.select(
        devices: devices([aDevice(id: 'phone', emulator: false)]),
        platform: DevicePlatform.android,
        preference: const PreferEmulator(),
      ),
      isA<BootEmulator>(),
    );
  });

  test('--target picks the exact id across platforms', () {
    final choice = selector.select(
      devices: devices([aDevice(id: 'ios-sim', targetPlatform: 'ios')]),
      platform: DevicePlatform.android,
      preference: const ExactTarget(id: DeviceId('ios-sim')),
    );
    expect(choice, isA<UseDevice>());
    expect(
      selector.select(
        devices: devices([]),
        platform: DevicePlatform.android,
        preference: const ExactTarget(id: DeviceId('nope')),
      ),
      isA<NoDeviceMatches>(),
    );
  });

  test('malformed json yields no devices', () {
    expect(FlutterDevice.parseList(json: 'not json'), isEmpty);
  });
}
