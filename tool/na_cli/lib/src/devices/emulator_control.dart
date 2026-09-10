import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/devices/device_selector.dart';
import 'package:na_cli/src/devices/flutter_device.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/tools/shell.dart';
import 'package:na_cli/src/tools/toolchain_settings.dart';

final class EmulatorControl {
  const EmulatorControl({required this.context});

  final CliContext context;

  static const Duration bootTimeout = Duration(seconds: 180);
  static const Duration pollInterval = Duration(seconds: 3);

  Future<List<FlutterDevice>> devices() async {
    final json = await Shell(context: context).captureOrFail(
      command: _flutter(const ['devices', '--machine']),
    );
    return FlutterDevice.parseList(json: json);
  }

  Future<FlutterDevice> ensure({
    required final DevicePlatform platform,
    required final DevicePreference preference,
  }) async {
    final choice = const DeviceSelector().select(
      devices: await devices(),
      platform: platform,
      preference: preference,
    );
    return switch (choice) {
      UseDevice(:final device) => device,
      NoDeviceMatches(:final reason) => throw CliFailure.general(
        message: reason,
      ),
      BootEmulator() => _boot(platform),
    };
  }

  Future<FlutterDevice> _boot(final DevicePlatform platform) async {
    final settings = ToolchainSettings.load(context: context);
    switch (platform) {
      case DevicePlatform.android:
        await Shell(context: context).captureOrFail(
          command: _flutter(['emulators', '--launch', settings.avdName]),
        );
        await _waitForAndroidBoot(settings);
      case DevicePlatform.ios:
        if (context.hostOs != HostOs.macos) {
          throw const CliFailure.general(message: 'iOS simulators need macOS');
        }
        await Shell(context: context).captureOrFail(
          command: CommandLine.at(
            executable: const Executable('xcrun'),
            arguments: ['simctl', 'boot', settings.iosSimulatorName],
            workingDirectory: context.repoRoot,
          ),
        );
      case DevicePlatform.other:
        throw const CliFailure.general(message: 'cannot boot this platform');
    }
    return _awaitVisible(platform);
  }

  Future<void> _waitForAndroidBoot(final ToolchainSettings settings) async {
    final started = context.clock.now();
    while (context.clock.now().difference(started) < bootTimeout) {
      final outcome = await context.processes.capture(
        command: CommandLine.at(
          executable: Executable(settings.adb.value),
          arguments: const ['shell', 'getprop', 'sys.boot_completed'],
          workingDirectory: context.repoRoot,
        ),
      );
      if (outcome is ProcessSucceeded && outcome.stdout.trim() == '1') {
        return;
      }
      await context.sleeper.sleep(duration: pollInterval);
    }
    throw const CliFailure.general(
      message: 'emulator did not finish booting within 180 s',
    );
  }

  Future<FlutterDevice> _awaitVisible(final DevicePlatform platform) async {
    final started = context.clock.now();
    while (context.clock.now().difference(started) < bootTimeout) {
      final running = (await devices()).where(
        (final d) =>
            d.platform == platform && d.origin == DeviceOrigin.emulator,
      );
      if (running.isNotEmpty) {
        return running.first;
      }
      await context.sleeper.sleep(duration: pollInterval);
    }
    throw const CliFailure.general(
      message: 'booted emulator never appeared in flutter devices',
    );
  }

  Future<void> stop() async {
    final settings = ToolchainSettings.load(context: context);
    await Shell(context: context).capture(
      command: CommandLine.at(
        executable: Executable(settings.adb.value),
        arguments: const ['emu', 'kill'],
        workingDirectory: context.repoRoot,
      ),
    );
    if (context.hostOs == HostOs.macos) {
      await Shell(context: context).capture(
        command: CommandLine.at(
          executable: const Executable('xcrun'),
          arguments: ['simctl', 'shutdown', settings.iosSimulatorName],
          workingDirectory: context.repoRoot,
        ),
      );
    }
  }

  CommandLine _flutter(final List<String> arguments) => CommandLine.at(
    executable: const Executable('flutter'),
    arguments: arguments,
    workingDirectory: context.repoRoot,
  );
}
