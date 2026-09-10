import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

enum TypeNullability { nullable, nonNullable }

enum DefaultValuePresence { present, absent }

TypeNullability nullabilityOf({required final TypeAnnotation annotation}) =>
    switch (annotation.question) {
      Token() => TypeNullability.nullable,
      null => TypeNullability.nonNullable,
    };

DefaultValuePresence defaultValuePresenceOf({
  required final DefaultFormalParameter parameter,
}) => switch (parameter.defaultValue) {
  Expression() => DefaultValuePresence.present,
  null => DefaultValuePresence.absent,
};
