import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

sealed class StaticType {
  const StaticType();
}

final class KnownType extends StaticType {
  const KnownType({required this.type});

  final DartType type;
}

final class UnknownType extends StaticType {
  const UnknownType();
}

StaticType annotatedTypeOf({required final TypeAnnotation annotation}) =>
    _fromDartType(annotation.type);

StaticType methodReturnTypeOf({required final MethodDeclaration method}) =>
    switch (method.returnType) {
      final TypeAnnotation annotation => annotatedTypeOf(
        annotation: annotation,
      ),
      null => const UnknownType(),
    };

StaticType _fromDartType(final DartType? type) => switch (type) {
  final DartType known => KnownType(type: known),
  null => const UnknownType(),
};
