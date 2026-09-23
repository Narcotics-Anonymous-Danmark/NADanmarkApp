@Tags(['unit'])
library;

import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

void main() {
  test('every feature port throws with its name until bound', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final expectations = <ProviderListenable<Object>, String>{
      settingsPortProvider: 'SettingsPort',
      legacyStorePortProvider: 'LegacyStorePort',
      jftPortProvider: 'JftPort',
      externalLinksPortProvider: 'ExternalLinksPort',
      appInfoProvider: 'AppInfo',
      meetingSearchPortProvider: 'MeetingSearchPort',
      meetingFormatsPortProvider: 'MeetingFormatsPort',
    };
    for (final entry in expectations.entries) {
      expect(
        () => container.read(entry.key),
        throwsA(
          isA<ProviderException>().having(
            (wrapped) => wrapped.exception.toString(),
            'message',
            contains('${entry.value} is not bound'),
          ),
        ),
      );
    }
  });

  test('legacy store reads compare by value', () {
    expect(
      const LegacyStoreFound(entries: {'a': 1}),
      const LegacyStoreFound(entries: {'a': 1}),
    );
    expect(
      const LegacyStoreFound(entries: {'a': 1}),
      isNot(const LegacyStoreFound(entries: {'a': 2})),
    );
    expect(const LegacyStoreAbsent(), const LegacyStoreAbsent());
    expect(
      const LegacyStoreUnreadable(detail: 'x'),
      const LegacyStoreUnreadable(detail: 'x'),
    );
    expect(const LegacyStoreFound(entries: {'a': 1}).toString(), contains('a'));
    expect(const LegacyStoreUnreadable(detail: 'x').toString(), contains('x'));
    expect(const LegacyStoreAbsent().toString(), 'LegacyStoreAbsent');
    expect(
      const LegacyStoreFound(entries: {'a': 1}).hashCode,
      const LegacyStoreFound(entries: {'b': 2}).hashCode,
    );
    expect(
      const LegacyStoreAbsent().hashCode,
      const LegacyStoreAbsent().hashCode,
    );
    expect(
      const LegacyStoreUnreadable(detail: 'x').hashCode,
      const LegacyStoreUnreadable(detail: 'x').hashCode,
    );
  });
}
