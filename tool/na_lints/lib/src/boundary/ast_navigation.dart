import 'package:analyzer/dart/ast/ast.dart';

Iterable<AstNode> ancestorsOf({required final AstNode node}) sync* {
  var current = node.parent;
  while (current != null) {
    yield current;
    current = current.parent;
  }
}
