import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/host/host_os.dart';

enum ReleasePlatform {
  android,
  ios
  ;

  static List<ReleasePlatform> fromPositionals({
    required final List<String> positionals,
    required final HostOs hostOs,
  }) {
    if (positionals.isEmpty) {
      return switch (hostOs) {
        HostOs.linux => const [ReleasePlatform.android],
        HostOs.macos => const [ReleasePlatform.android, ReleasePlatform.ios],
      };
    }
    return List.unmodifiable(positionals.map(_single));
  }

  static ReleasePlatform _single(final String word) {
    final matches = ReleasePlatform.values.where((final p) => p.name == word);
    if (matches.isEmpty) {
      throw CliFailure.usage(message: 'unknown platform "$word"');
    }
    return matches.first;
  }
}
