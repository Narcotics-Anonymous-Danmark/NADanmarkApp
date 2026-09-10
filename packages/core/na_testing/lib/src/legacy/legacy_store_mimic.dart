import 'package:na_ports/na_ports.dart';

final class LegacyStoreMimic implements LegacyStorePort {
  LegacyStoreMimic({required this.read});

  factory LegacyStoreMimic.absent() =>
      LegacyStoreMimic(read: const LegacyStoreAbsent());

  LegacyStoreRead read;
  int reads = 0;

  @override
  Future<LegacyStoreRead> readAll() async {
    reads += 1;
    return read;
  }
}
