import 'package:analyzer/dart/ast/ast.dart';

String constructorLabelOf({required final ConstructorName name}) =>
    [name.type.name.lexeme, name.name?.name].whereType<String>().join('.');
