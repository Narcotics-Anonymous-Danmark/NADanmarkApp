import 'package:na_cli/src/ports/console.dart';
import 'package:na_cli/src/steps/step.dart';

enum StepMode { apply, dryRun, force }

final class StepReport {
  const StepReport({required this.name, required this.state});

  final String name;
  final StepState state;
}

final class StepRunner {
  const StepRunner({required this.console, required this.mode});

  final Console console;
  final StepMode mode;

  Future<List<StepReport>> runAll({required final List<Step> steps}) async {
    final reports = <StepReport>[];
    for (final step in steps) {
      reports.add(await _runOne(step));
    }
    return List.unmodifiable(reports);
  }

  Future<List<StepReport>> checkAll({required final List<Step> steps}) async {
    final reports = <StepReport>[];
    for (final step in steps) {
      final state = await step.check();
      console.out(line: '[${_label(state)}] ${step.name}');
      reports.add(StepReport(name: step.name, state: state));
    }
    return List.unmodifiable(reports);
  }

  Future<StepReport> _runOne(final Step step) async {
    final state = switch (mode) {
      StepMode.force => StepState.needed,
      StepMode.apply || StepMode.dryRun => await step.check(),
    };
    switch (state) {
      case StepState.satisfied:
        console.out(line: '[skip] ${step.name}');
      case StepState.needed:
        console.out(line: '[run]  ${step.name}');
        switch (mode) {
          case StepMode.dryRun:
            break;
          case StepMode.apply || StepMode.force:
            await step.run();
        }
    }
    return StepReport(name: step.name, state: state);
  }

  String _label(final StepState state) => switch (state) {
    StepState.satisfied => ' ok ',
    StepState.needed => 'MISS',
  };
}
