import 'package:analyzer/dart/ast/ast.dart';

List<FormalParameter> functionParametersOf({
  required final FunctionDeclaration function,
}) => function.functionExpression.parameters?.parameters ?? const [];

List<FormalParameter> methodParametersOf({
  required final MethodDeclaration method,
}) => method.parameters?.parameters ?? const [];
