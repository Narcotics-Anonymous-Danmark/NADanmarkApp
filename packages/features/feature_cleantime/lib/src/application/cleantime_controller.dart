import 'dart:async';

import 'package:collection/collection.dart';
import 'package:feature_cleantime/src/application/anniversary_schedule.dart';
import 'package:feature_cleantime/src/application/cleantime_profiles_store.dart';
import 'package:feature_cleantime/src/application/cleantime_texts.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<CleantimeController, LoadResult<CleantimeView>>
cleantimeControllerProvider = NotifierProvider.autoDispose(
  CleantimeController.new,
);

@immutable
sealed class CleanTimeAmount {
  const CleanTimeAmount();
}

final class YearsAmount extends CleanTimeAmount {
  const YearsAmount({required this.years});

  final YearCount years;

  @override
  int get hashCode => Object.hash(YearsAmount, years);

  @override
  bool operator ==(Object other) =>
      other is YearsAmount && other.years == years;
}

final class MonthsAmount extends CleanTimeAmount {
  const MonthsAmount({required this.months});

  final MonthCount months;

  @override
  int get hashCode => Object.hash(MonthsAmount, months);

  @override
  bool operator ==(Object other) =>
      other is MonthsAmount && other.months == months;
}

final class DaysAmount extends CleanTimeAmount {
  const DaysAmount({required this.days});

  final DayCount days;

  @override
  int get hashCode => Object.hash(DaysAmount, days);

  @override
  bool operator ==(Object other) => other is DaysAmount && other.days == days;
}

@immutable
final class CleantimeView {
  const CleantimeView({
    required this.profiles,
    required this.today,
    required this.order,
  });

  final CleantimeProfiles profiles;
  final LocalDate today;
  final CleanTimeUnitOrder order;

  CleantimeProfile get active => profiles.activeProfile;

  CleanTime get cleanTime =>
      CleanTime.between(cleanDate: active.cleanDate, today: today);

  AnniversaryToday get anniversaryToday =>
      AnniversaryToday.of(cleanDate: active.cleanDate, today: today);

  List<List<CleanTimeAmount>> get groups {
    final time = cleanTime;
    final inOrder = <List<CleanTimeAmount>>[
      [
        YearsAmount(years: time.yearsMonthsDays.years),
        MonthsAmount(months: time.yearsMonthsDays.months),
        DaysAmount(days: time.yearsMonthsDays.days),
      ],
      [
        MonthsAmount(months: time.monthsDays.months),
        DaysAmount(days: time.monthsDays.days),
      ],
      [DaysAmount(days: time.days)],
    ];
    return List.unmodifiable(
      inOrder.map(
        (group) => List<CleanTimeAmount>.unmodifiable(switch (order) {
          CleanTimeUnitOrder.yearsMonthsDays => group,
          CleanTimeUnitOrder.daysMonthsYears => group.reversed,
        }),
      ),
    );
  }

  CleantimeView withProfiles({required CleantimeProfiles profiles}) =>
      CleantimeView(profiles: profiles, today: today, order: order);

  @override
  int get hashCode => Object.hash(profiles, today, order);

  @override
  bool operator ==(Object other) =>
      other is CleantimeView &&
      other.profiles == profiles &&
      other.today == today &&
      other.order == order;
}

final class CleantimeController extends Notifier<LoadResult<CleantimeView>> {
  CleantimeProfile _fallback = const CleantimeProfile(
    name: ProfileName(''),
    cleanDate: LocalDate(year: 1970, month: 1, day: 1),
  );

  @override
  LoadResult<CleantimeView> build() {
    unawaited(Future.microtask(_load));
    return const Loading();
  }

  Future<void> add({required ProfileName name}) => _apply(
    change: (profiles) => profiles.add(
      profile: CleantimeProfile(
        name: name.trimmed,
        cleanDate: ref.read(clockProvider).today(),
      ),
    ),
  );

  Future<void> rename({required ProfileName name}) =>
      _apply(change: (profiles) => profiles.rename(name: name.trimmed));

  Future<void> changeDate({required LocalDate cleanDate}) =>
      _apply(change: (profiles) => profiles.changeDate(cleanDate: cleanDate));

  Future<void> select({required ProfileIndex index}) =>
      _apply(change: (profiles) => profiles.select(index: index));

  Future<void> deleteActive() => _apply(
    change: (profiles) => profiles.deleteActive(fallback: _fallback),
  );

  Future<void> _load() async {
    if (!ref.mounted) {
      return;
    }
    final settingsPort = ref.read(settingsPortProvider);
    final store = ref.read(cleantimeProfilesStoreProvider);
    final today = ref.read(clockProvider).today();
    final settings = await settingsPort.read();
    final stored = await store.load();
    if (!ref.mounted) {
      return;
    }
    _fallback = CleantimeProfile(
      name: CleantimeTexts.of(
        language: settings.language,
      ).defaultProfileName(index: const ProfileIndex(0)),
      cleanDate: today,
    );
    final profiles = switch (stored) {
      ProfilesFound(:final entries, :final active) => CleantimeProfiles.restore(
        entries: entries,
        active: active,
        fallback: _fallback,
      ),
      NoProfiles() => CleantimeProfiles.single(profile: _fallback),
    };
    state = Loaded(
      value: CleantimeView(
        profiles: profiles,
        today: today,
        order: settings.cleanTimeUnitOrder,
      ),
    );
    switch (stored) {
      case NoProfiles():
        await _save(profiles: profiles);
      case ProfilesFound():
        break;
    }
  }

  Future<void> _apply({
    required CleantimeProfiles Function(CleantimeProfiles profiles) change,
  }) async {
    switch (state) {
      case Loaded(:final value):
        final next = change(value.profiles);
        state = Loaded(value: value.withProfiles(profiles: next));
        await _save(profiles: next);
      case Loading() || Failed():
        break;
    }
  }

  Future<void> _save({required CleantimeProfiles profiles}) async {
    final schedule = ref.read(anniversaryScheduleProvider);
    await ref.read(cleantimeProfilesStoreProvider).save(profiles: profiles);
    unawaited(schedule.refresh());
  }
}

@immutable
sealed class HomeCleantime {
  const HomeCleantime();
}

final class NoHomeProfiles extends HomeCleantime {
  const NoHomeProfiles();
}

final class HomeProfiles extends HomeCleantime {
  const HomeProfiles({required this.entries, required this.today});

  final List<CleantimeProfile> entries;
  final LocalDate today;

  @override
  int get hashCode => Object.hash(Object.hashAll(entries), today);

  @override
  bool operator ==(Object other) =>
      other is HomeProfiles &&
      other.today == today &&
      const ListEquality<CleantimeProfile>().equals(other.entries, entries);
}

final NotifierProvider<CleantimeHomeController, LoadResult<HomeCleantime>>
cleantimeHomeProvider = NotifierProvider.autoDispose(
  CleantimeHomeController.new,
);

final class CleantimeHomeController
    extends Notifier<LoadResult<HomeCleantime>> {
  @override
  LoadResult<HomeCleantime> build() {
    unawaited(Future.microtask(_load));
    return const Loading();
  }

  Future<void> _load() async {
    if (!ref.mounted) {
      return;
    }
    final today = ref.read(clockProvider).today();
    final stored = await ref.read(cleantimeProfilesStoreProvider).load();
    if (!ref.mounted) {
      return;
    }
    state = Loaded(
      value: switch (stored) {
        ProfilesFound(:final entries) => HomeProfiles(
          entries: entries,
          today: today,
        ),
        NoProfiles() => const NoHomeProfiles(),
      },
    );
  }
}
