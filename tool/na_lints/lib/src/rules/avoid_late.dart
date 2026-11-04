import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidLate extends DartLintRule {
  const AvoidLate() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_late',
    problemMessage: 'The late modifier is not allowed.',
    correctionMessage:
        'Initialise the value where it is declared, pass it in through the '
        'constructor, or model the not-yet-known phase as a sealed state.',
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final DiagnosticReporter reporter,
    final CustomLintContext context,
  ) {
    final applicability = applicabilityOf(
      path: resolver.path,
      scope: RuleScope.everywhere,
      exemptTraits: const {PathTrait.generated},
    );
    if (applicability == Applicability.exempt) {
      return;
    }
    context.registry.addVariableDeclarationList((final node) {
      final keyword = node.lateKeyword;
      if (keyword != null) {
        reporter.atToken(keyword, _code);
      }
    });
  }
}
