import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/process/command_line.dart';
import 'package:na_cli/src/process/executable.dart';
import 'package:na_cli/src/tools/shell.dart';

final class ReleaseKeychain {
  const ReleaseKeychain({required this.context, required this.password});

  final CliContext context;
  final String password;

  FilePath get path => context.files.homeDirectory.joinAll([
    'Library',
    'Keychains',
    'na-release.keychain-db',
  ]);

  Future<void> create({
    required final FilePath certificate,
    required final String certificatePassword,
  }) async {
    await _security(['create-keychain', '-p', password, path.value]);
    await _security(['set-keychain-settings', '-lut', '7200', path.value]);
    await _security(['unlock-keychain', '-p', password, path.value]);
    await _security([
      'import',
      certificate.value,
      '-k',
      path.value,
      '-P',
      certificatePassword,
      '-T',
      '/usr/bin/codesign',
      '-T',
      '/usr/bin/security',
    ]);
    await _security([
      'set-key-partition-list',
      '-S',
      'apple-tool:,apple:',
      '-s',
      '-k',
      password,
      path.value,
    ]);
    await _security([
      'list-keychains',
      '-d',
      'user',
      '-s',
      path.value,
      'login.keychain-db',
    ]);
  }

  Future<String> identities() => Shell(context: context).captureOrFail(
    command: _command(['find-identity', '-v', '-p', 'codesigning', path.value]),
  );

  Future<void> delete() async {
    await Shell(context: context).capture(
      command: _command(['delete-keychain', path.value]),
    );
    await Shell(context: context).capture(
      command: _command([
        'list-keychains',
        '-d',
        'user',
        '-s',
        'login.keychain-db',
      ]),
    );
  }

  Future<void> _security(final List<String> arguments) =>
      Shell(context: context).captureOrFail(command: _command(arguments));

  CommandLine _command(final List<String> arguments) => CommandLine.at(
    executable: const Executable('security'),
    arguments: arguments,
    workingDirectory: context.repoRoot,
  );
}
