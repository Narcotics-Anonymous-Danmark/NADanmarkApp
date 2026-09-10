import 'package:na_cli/src/devices/flutter_device.dart';

sealed class DevicePreference {
  const DevicePreference();
}

final class PreferPhysical extends DevicePreference {
  const PreferPhysical();
}

final class PreferEmulator extends DevicePreference {
  const PreferEmulator();
}

final class ExactTarget extends DevicePreference {
  const ExactTarget({required this.id});

  final DeviceId id;
}

final class AnyDevice extends DevicePreference {
  const AnyDevice();
}

sealed class DeviceChoice {
  const DeviceChoice();
}

final class UseDevice extends DeviceChoice {
  const UseDevice({required this.device});

  final FlutterDevice device;
}

final class BootEmulator extends DeviceChoice {
  const BootEmulator({required this.platform});

  final DevicePlatform platform;
}

final class NoDeviceMatches extends DeviceChoice {
  const NoDeviceMatches({required this.reason});

  final String reason;
}

final class DeviceSelector {
  const DeviceSelector();

  DeviceChoice select({
    required final List<FlutterDevice> devices,
    required final DevicePlatform platform,
    required final DevicePreference preference,
  }) {
    final onPlatform = devices.where((final d) => d.platform == platform);
    final physical = onPlatform.where(
      (final d) => d.origin == DeviceOrigin.physical,
    );
    final emulators = onPlatform.where(
      (final d) => d.origin == DeviceOrigin.emulator,
    );
    return switch (preference) {
      ExactTarget(:final id) => _exact(devices: devices, id: id),
      PreferPhysical() =>
        physical.isEmpty
            ? const NoDeviceMatches(reason: 'no physical device connected')
            : UseDevice(device: physical.first),
      PreferEmulator() =>
        emulators.isEmpty
            ? BootEmulator(platform: platform)
            : UseDevice(device: emulators.first),
      AnyDevice() =>
        physical.isNotEmpty
            ? UseDevice(device: physical.first)
            : emulators.isNotEmpty
            ? UseDevice(device: emulators.first)
            : BootEmulator(platform: platform),
    };
  }

  DeviceChoice _exact({
    required final List<FlutterDevice> devices,
    required final DeviceId id,
  }) {
    final match = devices.where((final d) => d.id == id);
    return match.isEmpty
        ? NoDeviceMatches(reason: 'no device with id ${id.value}')
        : UseDevice(device: match.first);
  }
}
