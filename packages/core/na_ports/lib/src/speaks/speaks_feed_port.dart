import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class SpeaksFeedPort {
  Future<Outcome<List<FeedGroup>, Failure>> feed({
    required SpeakLanguage language,
  });
}

final Provider<SpeaksFeedPort> speaksFeedPortProvider = unboundPort(
  portName: 'SpeaksFeedPort',
);
