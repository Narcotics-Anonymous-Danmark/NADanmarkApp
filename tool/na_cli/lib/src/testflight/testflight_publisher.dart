import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/ios/provisioning_profile.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/process/process_outcome.dart';
import 'package:na_cli/src/publish/notes_source.dart';
import 'package:na_cli/src/release/version.dart';
import 'package:na_cli/src/testflight/app_store_connect_client.dart';
import 'package:na_cli/src/testflight/build_processing.dart';
import 'package:na_cli/src/tools/shell.dart';

sealed class WaitPolicy {
  const WaitPolicy();
}

final class WaitForProcessing extends WaitPolicy {
  const WaitForProcessing({required this.limit});

  final Duration limit;
}

final class NoWait extends WaitPolicy {
  const NoWait();
}

final class TestflightPublisher {
  const TestflightPublisher({required this.context, required this.client});

  final CliContext context;
  final AppStoreConnectClient client;

  static const Duration pollInterval = Duration(seconds: 30);

  Future<void> upload({required final FilePath ipa}) async {
    final shell = Shell(context: context);
    final altool = await shell.passThrough(
      command: _xcrun([
        'altool',
        '--upload-app',
        '-f',
        ipa.value,
        '-t',
        'ios',
        '--apiKey',
        client.credentials.keyId,
        '--apiIssuer',
        client.credentials.issuerId,
      ]),
    );
    switch (altool) {
      case ProcessSucceeded():
        return;
      case ProcessFailed() || ProcessUnavailable():
        context.console.err(line: 'altool failed, trying iTMSTransporter');
        await shell.passThroughOrFail(
          command: _xcrun([
            'iTMSTransporter',
            '-m',
            'upload',
            '-assetFile',
            ipa.value,
            '-apiKey',
            client.credentials.keyId,
            '-apiIssuer',
            client.credentials.issuerId,
            '-v',
            'informational',
          ]),
        );
    }
  }

  Future<void> awaitProcessing({
    required final AppVersion version,
    required final WaitPolicy policy,
    required final NotesText notes,
  }) async {
    switch (policy) {
      case NoWait():
        return;
      case WaitForProcessing(:final limit):
        final app = await client.appId(
          bundleId: BundleId.iosApp,
          now: context.clock.now(),
        );
        final buildId = await _poll(app: app, version: version, limit: limit);
        switch (notes) {
          case NotesAbsent():
            return;
          case NotesProvided(:final text):
            await client.setWhatsNew(
              buildId: buildId,
              whatsNew: text,
              now: context.clock.now(),
            );
        }
    }
  }

  Future<String> _poll({
    required final AppStoreAppId app,
    required final AppVersion version,
    required final Duration limit,
  }) async {
    final started = context.clock.now();
    while (true) {
      final now = context.clock.now();
      if (now.difference(started) > limit) {
        throw CliFailure.general(
          message:
              'build ${version.build.value} was not processed within '
              '${limit.inMinutes} minutes',
        );
      }
      final state = await client.buildState(
        app: app,
        version: version,
        now: now,
      );
      switch (state) {
        case BuildValid(:final buildId):
          context.console.out(line: 'testflight: build $buildId is VALID');
          return buildId;
        case BuildRejected(:final state):
          throw CliFailure.general(message: 'testflight: build is $state');
        case BuildNotYetVisible():
          context.console.out(line: 'testflight: build not visible yet');
        case BuildStillProcessing(:final state):
          context.console.out(line: 'testflight: build is $state');
      }
      await context.sleeper.sleep(duration: pollInterval);
    }
  }

  CommandLine _xcrun(final List<String> arguments) => CommandLine.at(
    executable: const Executable('xcrun'),
    arguments: arguments,
    workingDirectory: context.repoRoot,
  );
}
