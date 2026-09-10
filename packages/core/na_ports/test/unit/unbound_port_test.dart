@Tags(['unit'])
library;

import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

void main() {
  group('unbound ports', () {
    test('fail loudly with the port name when read without an override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(clockProvider),
        throwsA(
          isA<ProviderException>().having(
            (wrapped) => wrapped.exception,
            'exception',
            isA<UnboundPortError>().having(
              (error) => error.portName,
              'portName',
              'Clock',
            ),
          ),
        ),
      );
    });
  });
}
