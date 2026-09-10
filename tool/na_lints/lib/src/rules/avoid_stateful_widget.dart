import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/type_names.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidStatefulWidget extends DartLintRule {
  const AvoidStatefulWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_stateful_widget',
    problemMessage:
        'Extending StatefulWidget or State directly is only allowed inside '
        'na_design flutter_bridge.',
    correctionMessage:
        'Keep the widget stateless and move the state into a Riverpod '
        'Notifier.',
  );

  static const _stateful = {'flutter::StatefulWidget', 'flutter::State'};

  @override
  void run(
    final CustomLintResolver resolver,
    final DiagnosticReporter reporter,
    final CustomLintContext context,
  ) {
    final applicability = applicabilityOf(
      path: resolver.path,
      scope: RuleScope.libOnly,
      exemptTraits: const {PathTrait.designFlutterBridge},
    );
    if (applicability == Applicability.exempt) {
      return;
    }
    context.registry.addClassDeclaration((final node) {
      final supertypes = qualifiedDirectSuperTypeNamesOf(declaration: node);
      if (supertypes.intersection(_stateful).isNotEmpty) {
        reporter.atToken(node.name, _code);
      }
    });
  }
}
