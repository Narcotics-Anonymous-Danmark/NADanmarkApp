import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/type_annotations.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidDefaultParameterValues extends DartLintRule {
  const AvoidDefaultParameterValues() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_default_parameter_values',
    problemMessage: 'Default parameter values are not allowed in production.',
    correctionMessage:
        'Make the parameter required so every call site states its choice; '
        'defaults belong in test builders and na_testing.',
  );

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
        PathTrait.flutterBridge,
        PathTrait.testing,
        PathTrait.generated,
      },
    );
    if (applicability == Applicability.exempt) {
      return;
    }
    context.registry.addDefaultFormalParameter((final node) {
      if (defaultValuePresenceOf(parameter: node) ==
          DefaultValuePresence.present) {
        reporter.atNode(node, _code);
      }
    });
  }
}
