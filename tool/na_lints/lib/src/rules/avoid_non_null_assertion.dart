import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

final class AvoidNonNullAssertion extends DartLintRule {
  const AvoidNonNullAssertion() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_non_null_assertion',
    problemMessage: 'The null assertion operator (!) is not allowed.',
    correctionMessage:
        'Model absence as a sealed class and match on it exhaustively.',
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final DiagnosticReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addPostfixExpression((final node) {
      if (node.operator.type == TokenType.BANG) {
        reporter.atToken(node.operator, _code);
      }
    });
  }
}
