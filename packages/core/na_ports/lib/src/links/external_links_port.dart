import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

enum LinkOpening { opened, refused }

abstract interface class ExternalLinksPort {
  Future<LinkOpening> open({required Uri uri});
}

final Provider<ExternalLinksPort> externalLinksPortProvider = unboundPort(
  portName: 'ExternalLinksPort',
);
