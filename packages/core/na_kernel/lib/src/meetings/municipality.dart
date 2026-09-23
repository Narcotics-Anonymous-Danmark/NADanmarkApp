import 'package:meta/meta.dart';

extension type const MunicipalityName(String value) {}

@immutable
sealed class Municipality {
  const Municipality();

  static const Set<String> onlineAliases = {
    '',
    'Online møde',
    'Viborg online',
    'Viborg.',
  };

  static Municipality normalise({required MunicipalityName raw}) =>
      onlineAliases.contains(raw.value.trim())
      ? const OnlineMunicipality()
      : NamedMunicipality(name: MunicipalityName(raw.value.trim()));

  static List<Municipality> directory({
    required List<MunicipalityName> names,
  }) {
    final unique = names.map((name) => normalise(raw: name)).toSet();
    return List.unmodifiable([
      ...unique.whereType<NamedMunicipality>(),
      ...unique.whereType<OnlineMunicipality>(),
    ]);
  }
}

final class NamedMunicipality extends Municipality {
  const NamedMunicipality({required this.name});

  final MunicipalityName name;

  @override
  int get hashCode => Object.hash(NamedMunicipality, name);

  @override
  bool operator ==(Object other) =>
      other is NamedMunicipality && other.name == name;

  @override
  String toString() => name.value;
}

final class OnlineMunicipality extends Municipality {
  const OnlineMunicipality();

  @override
  int get hashCode => (OnlineMunicipality).hashCode;

  @override
  bool operator ==(Object other) => other is OnlineMunicipality;

  @override
  String toString() => 'Online';
}
