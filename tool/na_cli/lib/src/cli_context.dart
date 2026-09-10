import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/ports/clock.dart';
import 'package:na_cli/src/ports/console.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/ports/file_system.dart';
import 'package:na_cli/src/ports/http_transport.dart';
import 'package:na_cli/src/ports/process_runner.dart';
import 'package:na_cli/src/ports/secret_generator.dart';
import 'package:na_cli/src/ports/sleeper.dart';

final class CliContext {
  const CliContext({
    required this.repoRoot,
    required this.hostOs,
    required this.processes,
    required this.files,
    required this.environment,
    required this.console,
    required this.clock,
    required this.sleeper,
    required this.secrets,
    required this.http,
  });

  final FilePath repoRoot;
  final HostOs hostOs;
  final ProcessRunner processes;
  final FileSystem files;
  final Environment environment;
  final Console console;
  final Clock clock;
  final Sleeper sleeper;
  final SecretGenerator secrets;
  final HttpTransport http;

  FilePath get appDir => repoRoot.join('app');

  FilePath get coverageDir => repoRoot.join('coverage');

  FilePath get envDir => repoRoot.join('env');

  FilePath get releaseScratchDir => repoRoot.join('.na-release');
}
