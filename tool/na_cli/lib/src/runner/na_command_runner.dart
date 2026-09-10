import 'package:args/command_runner.dart';
import 'package:na_cli/src/cli_context.dart';
import 'package:na_cli/src/commands/analyze_command.dart';
import 'package:na_cli/src/commands/bootstrap_command.dart';
import 'package:na_cli/src/commands/check_command.dart';
import 'package:na_cli/src/commands/coverage_command.dart';
import 'package:na_cli/src/commands/doctor_command.dart';
import 'package:na_cli/src/commands/emulator_command.dart';
import 'package:na_cli/src/commands/format_command.dart';
import 'package:na_cli/src/commands/gen_command.dart';
import 'package:na_cli/src/commands/publish_command.dart';
import 'package:na_cli/src/commands/release_command.dart';
import 'package:na_cli/src/commands/run_command.dart';
import 'package:na_cli/src/commands/test_command.dart';

final class NaCommandRunner extends CommandRunner<int> {
  NaCommandRunner({required final CliContext context})
    : super('na', 'Developer CLI for the NA Danmark Flutter workspace.') {
    addCommand(BootstrapCommand(context: context));
    addCommand(DoctorCommand(context: context));
    addCommand(RunCommand(context: context));
    addCommand(EmulatorCommand(context: context));
    addCommand(TestCommand(context: context));
    addCommand(CoverageCommand(context: context));
    addCommand(CheckCommand(context: context));
    addCommand(FormatCommand(context: context));
    addCommand(AnalyzeCommand(context: context));
    addCommand(GenCommand(context: context));
    addCommand(ReleaseCommand(context: context));
    addCommand(PublishCommand(context: context));
  }
}
