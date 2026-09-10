import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/boundary/import_uris.dart';

final class AvoidMaterialCupertinoImport extends DartLintRule {
  const AvoidMaterialCupertinoImport() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_material_cupertino_import',
    problemMessage:
        'Importing package:flutter/material.dart or cupertino.dart is not '
        'allowed.',
    correctionMessage:
        'Import package:flutter/widgets.dart or '
        'package:na_design/na_design.dart instead.',
  );

  static const _forbidden = {
    'package:flutter/material.dart',
    'package:flutter/cupertino.dart',
  };

  @override
  void run(
    final CustomLintResolver resolver,
    final DiagnosticReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addImportDirective((final node) {
      if (_forbidden.contains(importUriOf(directive: node))) {
        reporter.atNode(node, _code);
      }
    });
  }
}
