import 'package:na_cli/src/bootstrap/android_steps.dart';
import 'package:na_cli/src/bootstrap/common_steps.dart';
import 'package:na_cli/src/bootstrap/ios_steps.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/steps/step.dart';
import 'package:na_cli/src/tools/toolchain_settings.dart';

final class BootstrapPlan {
  const BootstrapPlan({required this.context});

  final CliContext context;

  List<Step> steps({required final List<ReleasePlatform> platforms}) {
    final settings = ToolchainSettings.load(context: context);
    if (platforms.contains(ReleasePlatform.ios) &&
        context.hostOs != HostOs.macos) {
      throw const CliFailure.usage(message: 'ios bootstrap needs macOS');
    }
    return List.unmodifiable([
      if (platforms.contains(ReleasePlatform.android))
        ...AndroidSteps(context: context, settings: settings).all(),
      if (platforms.contains(ReleasePlatform.ios))
        ...IosSteps(context: context, settings: settings).all(),
      ...CommonSteps(context: context, settings: settings).all(
        platforms: platforms,
      ),
    ]);
  }
}
