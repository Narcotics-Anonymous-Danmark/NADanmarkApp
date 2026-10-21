@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';
import 'package:test/test.dart';

const NotificationChannelName channel = NotificationChannelName('Cleanday');

PlannedNotification aPlannedNotification() => PlannedNotification(
  id: const NotificationId(1),
  at: anInstant(),
  title: const NotificationTitle('Cleanday - Anna'),
  body: const NotificationBody('Congratulations on 90 days'),
);

NotificationsMimic mimicWith({
  NotificationPermission permission = NotificationPermission.undetermined,
  NotificationPrompt prompt = NotificationPrompt.grant,
  ScheduleBehaviour behaviour = ScheduleBehaviour.accept,
}) => NotificationsMimic(
  permission: permission,
  prompt: prompt,
  behaviour: behaviour,
);

void main() {
  group('NotificationsMimic', () {
    test('an undetermined permission prompts once and remembers', () async {
      final mimic = mimicWith();
      expect(await mimic.ensureAccess(), NotificationAccess.granted);
      expect(await mimic.ensureAccess(), NotificationAccess.granted);
      expect(mimic.promptCalls, const CallCount(1));
    });

    test('a refused prompt stays refused', () async {
      final mimic = mimicWith(prompt: NotificationPrompt.refuse);
      expect(await mimic.ensureAccess(), NotificationAccess.refused);
      expect(mimic.permission, NotificationPermission.refused);
    });

    test('settled permissions answer without prompting', () async {
      expect(
        await mimicWith(
          permission: NotificationPermission.granted,
        ).ensureAccess(),
        NotificationAccess.granted,
      );
      expect(
        await mimicWith(
          permission: NotificationPermission.refused,
        ).ensureAccess(),
        NotificationAccess.refused,
      );
      expect(
        await mimicWith(
          permission: NotificationPermission.unsupported,
        ).ensureAccess(),
        NotificationAccess.unsupported,
      );
    });

    test('an ignored prompt never answers', () async {
      final mimic = mimicWith(prompt: NotificationPrompt.ignore);
      final answer = mimic.ensureAccess().then((access) => access);
      await Future<void>.delayed(Duration.zero);
      expect(mimic.promptCalls, const CallCount(1));
      expect(answer, isA<Future<NotificationAccess>>());
    });

    test('replacing keeps only the latest plan', () async {
      final mimic = mimicWith();
      await mimic.replaceAll(
        channel: channel,
        notifications: [aPlannedNotification()],
      );
      final outcome = await mimic.replaceAll(
        channel: channel,
        notifications: const [],
      );
      expect(
        outcome,
        const Ok<ScheduledCount, UnavailableFailure>(value: ScheduledCount(0)),
      );
      expect(mimic.scheduled, isEmpty);
      expect(mimic.replaceCalls, const CallCount(2));
      expect(mimic.channels, [channel, channel]);
    });

    test('a scripted failure schedules nothing', () async {
      final mimic = mimicWith(behaviour: ScheduleBehaviour.fail);
      expect(
        await mimic.replaceAll(
          channel: channel,
          notifications: [aPlannedNotification()],
        ),
        isA<Err<ScheduledCount, UnavailableFailure>>(),
      );
      expect(mimic.scheduled, isEmpty);
    });

    test('the test container binds the mimic', () async {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      expect(
        harness.notifications.permission,
        NotificationPermission.undetermined,
      );
    });

    test('planned notifications compare by value', () {
      expect(aPlannedNotification(), aPlannedNotification());
      expect(aPlannedNotification().hashCode, aPlannedNotification().hashCode);
      expect(aPlannedNotification().toString(), contains('90 days'));
    });
  });

  group('cleantime builders', () {
    test('stored profiles decode back to the same profiles', () {
      final stored = aStoredCleantimeProfiles(
        entries: [
          aCleantimeProfile(),
          aCleantimeProfile(name: const ProfileName('Bo')),
        ],
        active: const ProfileIndex(1),
      );
      expect(
        const CleantimeProfilesCodec().decodeProfiles(
          text: stored[SettingKeys.cleantimeProfiles.name] ?? '',
        ),
        isA<Ok<List<CleantimeProfile>, DecodeFailure>>(),
      );
      expect(stored[SettingKeys.activeCleantimeProfile.name], '1');
    });

    test('defaults hold one profile', () {
      expect(aCleantimeProfiles().entries, [aCleantimeProfile()]);
      expect(
        aLegacyCleantimeDump().cleanDateProfiles,
        [aLegacyCleanDateProfile()],
      );
    });
  });
}
