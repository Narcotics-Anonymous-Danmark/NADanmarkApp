@Tags(['unit'])
library;

import 'package:feature_cleantime/feature_cleantime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

void main() {
  group('CleantimeProfilesStore', () {
    test('nothing stored means no profiles', () async {
      final harness = cleantimeHarness();
      expect(
        await harness.read(cleantimeProfilesStoreProvider).load(),
        isA<NoProfiles>(),
      );
    });

    test('an unreadable value means no profiles', () async {
      final harness = cleantimeHarness(
        storedValues: const {'cleantimeProfiles': '"oops"'},
      );
      expect(
        await harness.read(cleantimeProfilesStoreProvider).load(),
        isA<NoProfiles>(),
      );
    });

    test('profiles load with a clamped active index', () async {
      final harness = cleantimeHarness(
        storedValues: aStoredCleantimeProfiles(
          entries: [
            aCleantimeProfile(),
            aCleantimeProfile(name: bo),
          ],
          active: const ProfileIndex(7),
        ),
      );
      final stored = await harness.read(cleantimeProfilesStoreProvider).load();
      expect(stored, isA<ProfilesFound>());
      expect((stored as ProfilesFound).active, const ProfileIndex(1));
      expect(stored.entries, hasLength(2));
    });

    test('a missing or unreadable active index selects the first', () async {
      final harness = cleantimeHarness(
        storedValues: {
          ...aStoredCleantimeProfiles(),
          'activeCleantimeProfile': 'x',
        },
      );
      final stored = await harness.read(cleantimeProfilesStoreProvider).load();
      expect((stored as ProfilesFound).active, const ProfileIndex(0));
      final bare = cleantimeHarness(
        storedValues: {
          'cleantimeProfiles':
              aStoredCleantimeProfiles()['cleantimeProfiles'] ?? '',
        },
      );
      final loaded = await bare.read(cleantimeProfilesStoreProvider).load();
      expect((loaded as ProfilesFound).active, const ProfileIndex(0));
    });

    test('saving writes the list and the index', () async {
      final harness = cleantimeHarness();
      await harness
          .read(cleantimeProfilesStoreProvider)
          .save(
            profiles: aCleantimeProfiles(
              entries: [
                aCleantimeProfile(),
                aCleantimeProfile(name: bo),
              ],
              active: const ProfileIndex(1),
            ),
          );
      expect(harness.storage.snapshot['activeCleantimeProfile'], '1');
      expect(
        harness.storage.snapshot['cleantimeProfiles'],
        '[{"name":"Anna","cleanDate":"2020-05-03"},'
        '{"name":"Bo","cleanDate":"2020-05-03"}]',
      );
    });

    test('a failed list write skips the index', () async {
      final harness = cleantimeHarness();
      harness.storage.behaviour = WriteBehaviour.fail;
      final outcome = await harness
          .read(cleantimeProfilesStoreProvider)
          .save(profiles: aCleantimeProfiles());
      expect(outcome, isA<Err<StorageKey, StorageFailure>>());
      expect(
        harness.storage.snapshot.containsKey('activeCleantimeProfile'),
        isFalse,
      );
    });
  });
}
