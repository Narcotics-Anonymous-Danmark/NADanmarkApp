import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/parameters.dart';
import 'package:na_lints/src/scope/override_marker.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class PreferNamedParameters extends DartLintRule {
  const PreferNamedParameters() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_named_parameters',
    problemMessage: 'Two or more positional parameters are not allowed.',
    correctionMessage: 'Make the parameters named, with required where needed.',
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
      exemptTraits: const {PathTrait.generated},
    );
    if (applicability == Applicability.exempt) {
      return;
    }
    context.registry
      ..addConstructorDeclaration((final node) {
        if (_positionalCountOf(node.parameters.parameters) >= 2) {
          reporter.atNode(node.parameters, _code);
        }
      })
      ..addFunctionDeclaration((final node) {
        if (node.name.lexeme == 'main' || node.isGetter || node.isSetter) {
          return;
        }
        if (_positionalCountOf(functionParametersOf(function: node)) >= 2) {
          reporter.atToken(node.name, _code);
        }
      })
      ..addMethodDeclaration((final node) {
        if (node.isOperator || node.isGetter || node.isSetter) {
          return;
        }
        if (overrideMarkerOf(node: node) == OverrideMarker.present) {
          return;
        }
        if (_positionalCountOf(methodParametersOf(method: node)) >= 2) {
          reporter.atToken(node.name, _code);
        }
      });
  }

  static int _positionalCountOf(final List<FormalParameter> parameters) =>
      parameters.where((final parameter) => parameter.isPositional).length;
}
