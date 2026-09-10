import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/static_types.dart';
import 'package:na_lints/src/scope/override_marker.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidBoolType extends DartLintRule {
  const AvoidBoolType() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_bool_type',
    problemMessage: 'Declaring a bool is not allowed outside the boundary.',
    correctionMessage:
        'Give the two states a named enum; keep booleans to inline '
        'predicates in where, any, every and contains.',
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
      exemptTraits: const {PathTrait.boundary, PathTrait.generated},
    );
    if (applicability == Applicability.exempt) {
      return;
    }
    context.registry.addNamedType((final node) {
      if (annotatedTypeOf(annotation: node) case KnownType(
        :final type,
      ) when type.isDartCoreBool) {
        _check(node: node, reporter: reporter);
      }
    });
  }

  void _check({
    required final NamedType node,
    required final DiagnosticReporter reporter,
  }) {
    final parent = node.parent;
    if (parent is IsExpression || parent is AsExpression) {
      return;
    }
    if (parent is TypeLiteral) {
      return;
    }
    if (enclosingOverrideMarkerOf(node: node) == OverrideMarker.present) {
      return;
    }
    reporter.atNode(node, _code);
  }
}
