import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidWildcardSwitch extends DartLintRule {
  const AvoidWildcardSwitch() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_wildcard_switch',
    problemMessage: 'Patterns must not use _ or default.',
    correctionMessage:
        'Name the matched type instead, e.g. Err(), NoAnniversary() or '
        'Object() for an open type.',
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
    context.registry
      ..addSwitchDefault((final node) => reporter.atNode(node, _code))
      ..addWildcardPattern((final node) => reporter.atNode(node, _code));
  }
}
