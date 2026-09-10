import 'dart:io';

import 'package:na_cli/src/host/host_os.dart';

final class HostOsDetector {
  const HostOsDetector();

  HostOs detect() {
    if (Platform.isMacOS) {
      return HostOs.macos;
    }
    if (Platform.isLinux) {
      return HostOs.linux;
    }
    throw UnsupportedError(
      'na supports Linux and macOS only, found ${Platform.operatingSystem}',
    );
  }
}
