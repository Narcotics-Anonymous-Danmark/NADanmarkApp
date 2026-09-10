import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/static_types.dart';
import 'package:na_lints/src/boundary/type_names.dart';
import 'package:na_lints/src/scope/override_marker.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidBuildHelperMethods extends DartLintRule {
  const AvoidBuildHelperMethods() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_build_helper_methods',
    problemMessage: 'Helper methods returning a Widget are not allowed.',
    correctionMessage:
        'Extract the piece into its own small const widget class.',
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
    context.registry.addMethodDeclaration((final node) {
      if (methodReturnTypeOf(method: node) case KnownType(
        :final type,
      ) when qualifiedTypeNamesOf(type: type).contains('flutter::Widget')) {
        _check(node: node, reporter: reporter);
      }
    });
  }

  void _check({
    required final MethodDeclaration node,
    required final DiagnosticReporter reporter,
  }) {
    final name = node.name.lexeme;
    if (name == 'build' &&
        overrideMarkerOf(node: node) == OverrideMarker.present) {
      return;
    }
    if (name.startsWith('_') || name.startsWith('build')) {
      reporter.atToken(node.name, _code);
    }
  }
}
