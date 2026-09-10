import 'package:analyzer/dart/ast/ast.dart';

String importUriOf({required final ImportDirective directive}) =>
    directive.uri.stringValue ?? '';
