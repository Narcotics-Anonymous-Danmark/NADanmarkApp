import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/comments.dart';
import 'package:na_lints/src/scope/path_traits.dart';
import 'package:na_lints/src/scope/rule_scope.dart';

final class AvoidComments extends DartLintRule {
  const AvoidComments() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_comments',
    problemMessage: 'Comments are not allowed.',
    correctionMessage: 'Rename until the code explains itself.',
  );

  static const _allowedPrefixes = [
    '// ignore:',
    '// ignore_for_file:',
    '// expect_${'lint'}:',
  ];

  static const _licenseWords = ['copyright', 'license', 'licence'];

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
    context.registry.addCompilationUnit((final unit) {
      final header = headerCommentsOf(unit: unit)
          .where(
            (final comment) =>
                _licenseWords.any(comment.lexeme.toLowerCase().contains),
          )
          .toSet();
      commentsOf(unit: unit)
          .where((final comment) => !header.contains(comment))
          .where(
            (final comment) =>
                !_allowedPrefixes.any(comment.lexeme.trim().startsWith),
          )
          .forEach(
            (final comment) => reporter.atOffset(
              offset: comment.offset,
              length: comment.length,
              diagnosticCode: _code,
            ),
          );
    });
  }
}
