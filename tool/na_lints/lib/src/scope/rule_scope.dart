import 'package:na_lints/src/scope/path_traits.dart';

enum RuleScope { everywhere, libOnly }

enum Applicability { applies, exempt }

Applicability applicabilityOf({
  required final String path,
  required final RuleScope scope,
  required final Set<PathTrait> exemptTraits,
}) {
  final traits = pathTraitsOf(path: path);
  if (traits.intersection(exemptTraits).isNotEmpty) {
    return Applicability.exempt;
  }
  return switch (scope) {
    RuleScope.everywhere => Applicability.applies,
    RuleScope.libOnly =>
      traits.contains(PathTrait.lib)
          ? Applicability.applies
          : Applicability.exempt,
  };
}
