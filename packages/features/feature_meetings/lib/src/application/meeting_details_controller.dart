import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

@immutable
final class MeetingIds {
  MeetingIds({required List<MeetingId> ids}) : ids = List.unmodifiable(ids);

  final List<MeetingId> ids;

  @override
  int get hashCode => Object.hashAll(ids);

  @override
  bool operator ==(Object other) =>
      other is MeetingIds &&
      const ListEquality<MeetingId>().equals(other.ids, ids);

  @override
  String toString() => 'MeetingIds(${ids.map((id) => id.value).join(',')})';
}

final NotifierProviderFamily<
  MeetingDetailsController,
  LoadResult<List<Meeting>>,
  MeetingIds
>
meetingDetailsProvider = NotifierProvider.autoDispose.family(
  MeetingDetailsController.new,
);

final class MeetingDetailsController
    extends Notifier<LoadResult<List<Meeting>>> {
  MeetingDetailsController(this.meetings);

  final MeetingIds meetings;

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
    final span = BusyTracker(
      bus: ref.read(eventBusProvider),
    ).begin(activity: BusyActivity.findingMeetings);
    ref.onDispose(span.end);
    final outcome = await ref
        .read(meetingSearchPortProvider)
        .meetingsById(ids: meetings.ids);
    span.end();
    if (!ref.mounted) {
      return;
    }
    state = LoadResult.fromOutcome(outcome: outcome);
  }
}
