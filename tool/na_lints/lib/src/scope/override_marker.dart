import 'package:analyzer/dart/ast/ast.dart';
import 'package:na_lints/src/boundary/ast_navigation.dart';

enum OverrideMarker { present, absent }

OverrideMarker overrideMarkerOf({required final AnnotatedNode node}) =>
    node.metadata.any((final annotation) => annotation.name.name == 'override')
    ? OverrideMarker.present
    : OverrideMarker.absent;

OverrideMarker enclosingOverrideMarkerOf({required final AstNode node}) =>
    ancestorsOf(node: node).whereType<ClassMember>().any(
      (final member) =>
          overrideMarkerOf(node: member) == OverrideMarker.present,
    )
    ? OverrideMarker.present
    : OverrideMarker.absent;
