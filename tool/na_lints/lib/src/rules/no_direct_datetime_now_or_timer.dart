import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/constructor_labels.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class NoDirectDateTimeNowOrTimer extends DartLintRule {
  const NoDirectDateTimeNowOrTimer() : super(code: _code);

  static const _code = LintCode(
    name: 'no_direct_datetime_now_or_timer',
    problemMessage: 'Time must come from the Clock, Ticker or Scheduler port.',
    correctionMessage:
        'Inject the port and call clock.now(), ticker.every() or '
        'scheduler.after() instead.',
  );

  static const _forbidden = {
    'DateTime.now',
    'DateTime.timestamp',
    'Timer',
    'Timer.periodic',
    'Future.delayed',
    'Stopwatch',
  };

  @override
  void run(
    final CustomLintResolver resolver,
    final DiagnosticReporter reporter,
    final CustomLintContext context,
  ) {
    final applicability = applicabilityOf(
      path: resolver.path,
      scope: RuleScope.libOnly,
      exemptTraits: const {
        PathTrait.clockAdapter,
        PathTrait.testing,
        PathTrait.boundaryFolder,
        PathTrait.flutterBridge,
      },
    );
    if (applicability == Applicability.exempt) {
      return;
    }
    context.registry.addInstanceCreationExpression((final node) {
      if (_forbidden.contains(constructorLabelOf(name: node.constructorName))) {
        reporter.atNode(node, _code);
      }
    });
  }
}
