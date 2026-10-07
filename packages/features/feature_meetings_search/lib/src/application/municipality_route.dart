import 'package:na_kernel/na_kernel.dart';

extension type const MunicipalitySegment(String value) {
  MunicipalitySegment.of({required Municipality municipality})
    : this(switch (municipality) {
        NamedMunicipality(:final name) => name.value,
        OnlineMunicipality() => onlineValue,
      });

  static const String onlineValue = 'Online';

  Municipality get municipality => value == onlineValue
      ? const OnlineMunicipality()
      : NamedMunicipality(name: MunicipalityName(value));
}
