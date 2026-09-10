import 'dart:convert';

import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/cli_failure.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/ios/export_options.dart';
import 'package:na_cli/src/ios/ipa_inspector.dart';
import 'package:na_cli/src/ios/provisioning_profile.dart';
import 'package:na_cli/src/ios/release_keychain.dart';
import 'package:na_cli/src/ios/secrets_xcconfig.dart';
import 'package:na_cli/src/ios/signing_identities.dart';
import 'package:na_cli/src/plist/plist_reader.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/release/release_check.dart';
import 'package:na_cli/src/release/release_inputs.dart';
import 'package:na_cli/src/release/release_options.dart';
import 'package:na_cli/src/release/release_platform.dart';
import 'package:na_cli/src/tools/shell.dart';

final class IosRelease {
  const IosRelease({required this.context});

  final CliContext context;

  Future<void> build({required final ReleaseOptions options}) async {
    if (context.hostOs != HostOs.macos) {
      throw const CliFailure.general(message: 'release ios needs macOS');
    }
    await ReleaseCheck(context: context).assertReady(
      platforms: const [ReleasePlatform.ios],
      dirtyPolicy: options.dirtyPolicy,
    );
    final inputs = ReleaseInputs(context: context);
    final version = inputs.version();
    final defines = inputs.defines();
    final scratch = context.releaseScratchDir;
    final exportPlist = scratch.join('ExportOptions.plist');
    final buildCommand = CommandLine.at(
      executable: const Executable('flutter'),
      arguments: [
        'build',
        'ipa',
        '--release',
        '--dart-define-from-file=../env/release.json',
        '--build-name',
        '${version.version}',
        '--build-number',
        '${version.build.value}',
        '--export-options-plist',
        exportPlist.value,
      ],
      workingDirectory: context.appDir,
    );
    final destination = options.outputDir.join(
      inputs.artifactName(version: version, extension: 'ipa'),
    );
    switch (options.execution) {
      case BuildExecution.dryRun:
        context.console.out(line: 'dry-run: ${buildCommand.display}');
        context.console.out(line: 'dry-run: would write ${destination.value}');
        return;
      case BuildExecution.real:
        break;
    }
    final keychain = ReleaseKeychain(
      context: context,
      password: context.secrets.randomToken(bytes: 24),
    );
    final profilesDir = context.files.homeDirectory.joinAll([
      'Library',
      'MobileDevice',
      'Provisioning Profiles',
    ]);
    var installedProfile = scratch.join('unused.mobileprovision');
    try {
      context.files.ensureDirectory(path: scratch);
      final certificate = scratch.join('dist.p12');
      context.files.writeBytes(
        path: certificate,
        bytes: _decode(inputs.secret(key: 'IOS_DIST_CERT_BASE64')),
      );
      await keychain.create(
        certificate: certificate,
        certificatePassword: inputs.secret(key: 'IOS_DIST_CERT_PASSWORD'),
      );
      final identity = switch (const SigningIdentities().distributionIdentity(
        listing: await keychain.identities(),
      )) {
        IdentityFound(:final identity) => identity,
        IdentityMissing(:final reason) => throw CliFailure.general(
          message: reason,
        ),
      };
      final profile = await _profile(scratch: scratch, inputs: inputs);
      installedProfile = profilesDir.join(
        '${profile.uuid.value}.mobileprovision',
      );
      context.files.copyFile(
        from: scratch.join('profile.mobileprovision'),
        to: installedProfile,
      );
      context.files.writeText(
        path: exportPlist,
        text: ExportOptions(
          teamId: TeamId(inputs.secret(key: 'IOS_TEAM_ID')),
          bundleId: BundleId.iosApp,
          profileName: profile.name,
          signingCertificate: identity,
        ).render(),
      );
      context.files.writeText(
        path: context.appDir.joinAll(['ios', 'Flutter', 'Secrets.xcconfig']),
        text: const SecretsXcconfig().render(defines: defines.values),
      );
      await Shell(context: context).passThroughOrFail(command: buildCommand);
      final inspector = IpaInspector(context: context);
      final ipa = inspector.find();
      await inspector.verify(ipa: ipa, version: version, scratch: scratch);
      context.files.copyFile(from: ipa, to: destination);
      context.console.out(line: 'wrote ${destination.value}');
    } finally {
      await keychain.delete();
      context.files.deleteTree(path: installedProfile);
      context.files.deleteTree(path: scratch);
    }
  }

  Future<ProvisioningProfile> _profile({
    required final FilePath scratch,
    required final ReleaseInputs inputs,
  }) async {
    final encoded = scratch.join('profile.mobileprovision');
    context.files.writeBytes(
      path: encoded,
      bytes: _decode(inputs.secret(key: 'IOS_PROVISIONING_PROFILE_BASE64')),
    );
    final xml = await Shell(context: context).captureOrFail(
      command: CommandLine.at(
        executable: const Executable('security'),
        arguments: ['cms', '-D', '-i', encoded.value],
        workingDirectory: context.repoRoot,
      ),
    );
    final profile = ProvisioningProfile.fromPlist(
      plist: const PlistReader().read(xml: xml),
    );
    final problems = profile.problems(
      expectedTeam: TeamId(inputs.secret(key: 'IOS_TEAM_ID')),
      expectedBundle: BundleId.iosApp,
      now: context.clock.now(),
    );
    if (problems.isNotEmpty) {
      throw CliFailure.general(message: problems.join('\n'));
    }
    return profile;
  }

  List<int> _decode(final String base64Text) =>
      base64Decode(base64Text.replaceAll(RegExp(r'\s'), ''));
}
