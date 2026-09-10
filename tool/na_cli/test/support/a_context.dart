import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/host/host_os.dart';
import 'package:na_cli/src/ports/http_transport.dart';
import 'package:na_cli/src/ports/process_runner.dart';
import 'package:na_cli/src/ports/sleeper.dart';

import 'file_system_mimic.dart';
import 'process_runner_mimic.dart';
import 'simple_mimics.dart';

const String testRoot = '/repo';

CliContext aContext({
  final ProcessRunner? processes,
  final FileSystemMimic? files,
  final ConsoleMimic? console,
  final Map<String, String> environment = const {},
  final HostOs hostOs = HostOs.linux,
  final DateTime? now,
  final FixedClock? clock,
  final Sleeper? sleeper,
  final HttpTransport? http,
}) => CliContext(
  repoRoot: const FilePath(testRoot),
  hostOs: hostOs,
  processes: processes ?? ProcessRunnerMimic(),
  files: files ?? FileSystemMimic(),
  environment: EnvironmentMimic(values: environment),
  console: console ?? ConsoleMimic(),
  clock: clock ?? FixedClock(current: now ?? DateTime.utc(2026, 9, 10, 12)),
  sleeper: sleeper ?? SleeperMimic(),
  secrets: const SecretGeneratorMimic(),
  http: http ?? HttpTransportMimic(),
);
