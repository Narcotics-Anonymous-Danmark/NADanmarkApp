import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

List<CommentToken> commentsOf({required final CompilationUnit unit}) {
  final comments = <CommentToken>[];
  Token? token = unit.beginToken;
  while (token != null) {
    comments.addAll(_chainFrom(token.precedingComments));
    if (token.type == TokenType.EOF) {
      break;
    }
    token = token.next;
  }
  return List.unmodifiable(comments);
}

List<CommentToken> headerCommentsOf({required final CompilationUnit unit}) =>
    List.unmodifiable(_chainFrom(unit.beginToken.precedingComments));

Iterable<CommentToken> _chainFrom(final CommentToken? first) sync* {
  var comment = first;
  while (comment != null) {
    yield comment;
    final next = comment.next;
    comment = next is CommentToken ? next : null;
  }
}
