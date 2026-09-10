import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/type_names.dart';

final class AvoidWildcardSwitch extends DartLintRule {
  const AvoidWildcardSwitch() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_wildcard_switch',
    problemMessage:
        'Switches over enums and sealed types must not use _ or default.',
    correctionMessage:
        'List every case explicitly so the compiler checks exhaustiveness.',
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final DiagnosticReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry
      ..addSwitchStatement((final node) {
        if (scrutineeKindOf(expression: node.expression) ==
            ScrutineeKind.openType) {
          return;
        }
        for (final member in node.members) {
          _checkMember(member: member, reporter: reporter);
        }
      })
      ..addSwitchExpression((final node) {
        if (scrutineeKindOf(expression: node.expression) ==
            ScrutineeKind.openType) {
          return;
        }
        for (final each in node.cases) {
          if (each.guardedPattern.pattern is WildcardPattern) {
            reporter.atNode(each, _code);
          }
        }
      });
  }

  void _checkMember({
    required final SwitchMember member,
    required final DiagnosticReporter reporter,
  }) {
    switch (member) {
      case SwitchDefault():
        reporter.atNode(member, _code);
      case SwitchPatternCase(:final guardedPattern)
          when guardedPattern.pattern is WildcardPattern:
        reporter.atNode(member, _code);
      case SwitchPatternCase():
      case SwitchCase():
        return;
    }
  }
}
