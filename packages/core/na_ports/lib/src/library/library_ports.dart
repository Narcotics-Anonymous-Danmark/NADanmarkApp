import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class AudiobooksPort {
  Future<Outcome<Audiobook, Failure>> load({required AudiobookId book});
}

abstract interface class ReadingsPort {
  Future<Outcome<ReadingCollection, Failure>> load();
}

final Provider<AudiobooksPort> audiobooksPortProvider = unboundPort(
  portName: 'AudiobooksPort',
);

final Provider<ReadingsPort> readingsPortProvider = unboundPort(
  portName: 'ReadingsPort',
);
