import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class SettingsPort {
  Future<Settings> read();

  Future<Outcome<Settings, StorageFailure>> write({required Settings settings});
}

final Provider<SettingsPort> settingsPortProvider = unboundPort(
  portName: 'SettingsPort',
);
