import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/type_annotations.dart';
import 'package:na_lints/src/scope/override_marker.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidNullableTypes extends DartLintRule {
  const AvoidNullableTypes() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_nullable_types',
    problemMessage: 'Nullable types are not allowed outside the boundary.',
    correctionMessage:
        'Model absence as a named state in a sealed class instead of ?.',
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
    context.registry
      ..addNamedType((final node) => _check(node: node, reporter: reporter))
      ..addGenericFunctionType(
        (final node) => _check(node: node, reporter: reporter),
      )
      ..addRecordTypeAnnotation(
        (final node) => _check(node: node, reporter: reporter),
      );
  }

  void _check({
    required final TypeAnnotation node,
    required final DiagnosticReporter reporter,
  }) {
    if (nullabilityOf(annotation: node) == TypeNullability.nonNullable) {
      return;
    }
    final parent = node.parent;
    if (parent is IsExpression || parent is AsExpression) {
      return;
    }
    if (enclosingOverrideMarkerOf(node: node) == OverrideMarker.present) {
      return;
    }
    reporter.atNode(node, _code);
  }
}
