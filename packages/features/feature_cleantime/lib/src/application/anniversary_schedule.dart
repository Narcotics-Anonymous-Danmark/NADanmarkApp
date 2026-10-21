import 'dart:async';

import 'package:collection/collection.dart';
import 'package:feature_cleantime/src/application/cleantime_profiles_store.dart';
import 'package:feature_cleantime/src/application/cleantime_texts.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final Provider<AnniversarySchedule> anniversaryScheduleProvider = Provider(
  (ref) => AnniversarySchedule(
    store: ref.read(cleantimeProfilesStoreProvider),
    settings: ref.read(settingsPortProvider),
    clock: ref.read(clockProvider),
    notifications: ref.read(notificationsPortProvider),
    events: ref.read(eventBusProvider),
  ),
);

final Provider<ScheduleRefresh> anniversaryRefreshOnShowProvider =
    Provider.autoDispose((ref) {
      unawaited(ref.read(anniversaryScheduleProvider).refresh());
      return ScheduleRefresh.requested;
    });

final Provider<ScheduleRefresh> anniversaryLanguageListenerProvider = Provider((
  ref,
) {
  final schedule = ref.read(anniversaryScheduleProvider);
  final subscription = ref
      .read(eventBusProvider)
      .on<LanguageChanged>()
      .listen((_) => unawaited(schedule.refresh()));
  ref.onDispose(subscription.cancel);
  return ScheduleRefresh.listening;
});

enum ScheduleRefresh { requested, listening }

enum _Phase { idle, running, runAgain }

@immutable
final class _Candidate {
  const _Candidate({
    required this.position,
    required this.profile,
    required this.anniversary,
    required this.at,
  });

  final ProfileIndex position;
  final CleantimeProfile profile;
  final Anniversary anniversary;
  final Instant at;
}

final class AnniversarySchedule {
  AnniversarySchedule({
    required this.store,
    required this.settings,
    required this.clock,
    required this.notifications,
    required this.events,
  });

  static const LocalTime notifyAt = LocalTime(
    hour: HourOfDay(10),
    minute: MinuteOfHour(0),
  );
  static const Duration minimumLead = Duration(minutes: 1);
  static const ScheduledCount maximum = ScheduledCount(64);

  final CleantimeProfilesStore store;
  final SettingsPort settings;
  final Clock clock;
  final NotificationsPort notifications;
  final EventBus events;

  _Phase _phase = _Phase.idle;
  Future<void> _current = Future.value();

  Future<void> refresh() {
    switch (_phase) {
      case _Phase.idle:
        _phase = _Phase.running;
        _current = _runUntilSettled();
      case _Phase.running || _Phase.runAgain:
        _phase = _Phase.runAgain;
    }
    return _current;
  }

  Future<void> _runUntilSettled() async {
    await _runOnce();
    switch (_phase) {
      case _Phase.runAgain:
        _phase = _Phase.running;
        await _runUntilSettled();
      case _Phase.running || _Phase.idle:
        _phase = _Phase.idle;
    }
  }

  Future<void> _runOnce() async {
    final texts = CleantimeTexts.of(language: (await settings.read()).language);
    final plan = _plan(
      profiles: switch (await store.load()) {
        ProfilesFound(:final entries) => entries,
        NoProfiles() => const <CleantimeProfile>[],
      },
      texts: texts,
    );
    final allowed = plan.isEmpty
        ? NotificationAccess.granted
        : await notifications.ensureAccess();
    final outcome = await notifications.replaceAll(
      channel: texts.channel,
      notifications: switch (allowed) {
        NotificationAccess.granted => plan,
        NotificationAccess.refused ||
        NotificationAccess.unsupported => const <PlannedNotification>[],
      },
    );
    switch (outcome) {
      case Ok():
        break;
      case Err(:final error):
        events.publish(event: NotificationsFailed(failure: error));
    }
  }

  List<PlannedNotification> _plan({
    required List<CleantimeProfile> profiles,
    required CleantimeTexts texts,
  }) {
    final today = clock.today();
    final earliest = clock.now().plus(duration: minimumLead);
    final candidates = profiles.indexed
        .expand(
          (entry) =>
              UpcomingAnniversary.within(
                cleanDate: entry.$2.cleanDate,
                today: today,
              ).map(
                (upcoming) => _Candidate(
                  position: ProfileIndex(entry.$1),
                  profile: entry.$2,
                  anniversary: upcoming.anniversary,
                  at: clock.instantOf(date: upcoming.date, time: notifyAt),
                ),
              ),
        )
        .where(
          (candidate) =>
              candidate.at.compareTo(other: earliest) != Comparison.before,
        )
        .sorted(
          (left, right) => switch (left.at.compareTo(other: right.at)) {
            Comparison.before => -1,
            Comparison.after => 1,
            Comparison.same => left.position.position.compareTo(
              right.position.position,
            ),
          },
        )
        .take(maximum.value);
    return List.unmodifiable(
      candidates.indexed.map(
        (entry) => PlannedNotification(
          id: NotificationId(entry.$1 + 1),
          at: entry.$2.at,
          title: texts.notificationTitle(name: entry.$2.profile.name),
          body: texts.notificationBody(anniversary: entry.$2.anniversary),
        ),
      ),
    );
  }
}
