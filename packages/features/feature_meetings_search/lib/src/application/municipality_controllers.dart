import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<MunicipalitiesController, LoadResult<List<Municipality>>>
municipalitiesProvider = NotifierProvider.autoDispose(
  MunicipalitiesController.new,
);

final NotifierProviderFamily<
  MunicipalityMeetingsController,
  LoadResult<List<Meeting>>,
  Municipality
>
municipalityMeetingsProvider = NotifierProvider.autoDispose.family(
  MunicipalityMeetingsController.new,
);

final class MunicipalitiesController
    extends Notifier<LoadResult<List<Municipality>>> {
  @override
  LoadResult<List<Municipality>> build() {
    unawaited(Future.microtask(_load));
    return const Loading();
  }

  Future<void> retry() {
    state = const Loading();
    return _load();
  }

  Future<void> _load() async {
    final outcome = await BusyTracker(bus: ref.read(eventBusProvider)).track(
      activity: BusyActivity.findingMeetings,
      work: () => ref.read(meetingSearchPortProvider).denmarkMunicipalities(),
    );
    if (!ref.mounted) {
      return;
    }
    state = LoadResult.fromOutcome(
      outcome: outcome.map(
        transform: (names) => Municipality.directory(names: names),
      ),
    );
  }
}

final class MunicipalityMeetingsController
    extends Notifier<LoadResult<List<Meeting>>> {
  MunicipalityMeetingsController(this.municipality);

  final Municipality municipality;

  @override
  LoadResult<List<Meeting>> build() {
    unawaited(Future.microtask(_load));
    return const Loading();
  }

  Future<void> retry() {
    state = const Loading();
    return _load();
  }

  Future<void> _load() async {
    final outcome = await BusyTracker(bus: ref.read(eventBusProvider)).track(
      activity: BusyActivity.findingMeetings,
      work: () => ref.read(meetingSearchPortProvider).denmarkMeetings(),
    );
    if (!ref.mounted) {
      return;
    }
    state = LoadResult.fromOutcome(
      outcome: outcome.map(
        transform: (meetings) => List<Meeting>.unmodifiable(
          meetings.where((meeting) => meeting.municipality == municipality),
        ),
      ),
    );
  }
}
