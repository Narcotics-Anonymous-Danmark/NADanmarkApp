import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

enum ScrutineeKind { enumType, sealedType, openType }

Set<String> qualifiedSuperTypeNamesOf({
  required final ClassDeclaration declaration,
}) {
  final element = declaration.declaredFragment?.element;
  if (element == null) {
    return const {};
  }
  return _qualifiedNamesOf(element.allSupertypes);
}

Set<String> qualifiedDirectSuperTypeNamesOf({
  required final ClassDeclaration declaration,
}) {
  final element = declaration.declaredFragment?.element;
  if (element == null) {
    return const {};
  }
  return _qualifiedNamesOf([
    ...?_supertypeOf(element),
    ...element.mixins,
    ...element.interfaces,
  ]);
}

List<InterfaceType>? _supertypeOf(final InterfaceElement element) =>
    switch (element.supertype) {
      final InterfaceType type => [type],
      null => null,
    };

Set<String> qualifiedTypeNamesOf({required final DartType type}) {
  if (type is! InterfaceType) {
    return const {};
  }
  return _qualifiedNamesOf([type, ...type.element.allSupertypes]);
}

ScrutineeKind scrutineeKindOf({required final Expression expression}) {
  final type = expression.staticType;
  if (type is! InterfaceType) {
    return ScrutineeKind.openType;
  }
  final element = type.element;
  if (element is EnumElement) {
    return ScrutineeKind.enumType;
  }
  if (element is ClassElement && element.isSealed) {
    return ScrutineeKind.sealedType;
  }
  return ScrutineeKind.openType;
}

Set<String> _qualifiedNamesOf(final Iterable<InterfaceType> types) =>
    Set.unmodifiable(
      types
          .map((final type) => _qualifiedNameOf(type.element))
          .whereType<String>(),
    );

String? _qualifiedNameOf(final InterfaceElement element) {
  final name = element.name;
  if (name == null) {
    return null;
  }
  final uri = element.library.uri;
  final origin = uri.scheme == 'package' ? uri.pathSegments.first : '$uri';
  return '$origin::$name';
}
