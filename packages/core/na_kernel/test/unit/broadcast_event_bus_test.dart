@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('BroadcastEventBus', () {
    test('delivers only events of the requested type', () async {
      final bus = BroadcastEventBus();
      addTearDown(bus.dispose);
      final received = bus.on<LanguageChanged>().take(1).toList();
      bus
        ..publish(
          event: const LegacyMigrationCompleted(
            importedKeys: 3,
            skippedKeys: 0,
          ),
        )
        ..publish(event: const LanguageChanged(language: Language.english));
      expect(
        (await received).map((event) => event.language),
        [Language.english],
      );
    });
  });
}
