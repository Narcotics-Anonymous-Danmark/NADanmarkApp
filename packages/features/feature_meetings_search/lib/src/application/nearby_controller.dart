import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<NearbyMeetingsController, NearbyState>
nearbyMeetingsProvider = NotifierProvider.autoDispose(
  NearbyMeetingsController.new,
);

@immutable
sealed class NearbyResults {
  const NearbyResults();
}

final class AwaitingFirstResult extends NearbyResults {
  const AwaitingFirstResult();

  @override
  int get hashCode => (AwaitingFirstResult).hashCode;

  @override
  bool operator ==(Object other) => other is AwaitingFirstResult;
}

final class Shown extends NearbyResults {
  const Shown({required this.meetings, required this.origin});

  final List<Meeting> meetings;
  final SearchOrigin origin;

  @override
  int get hashCode => Object.hash(Object.hashAll(meetings), origin);

  @override
  bool operator ==(Object other) =>
      other is Shown &&
      other.origin == origin &&
      const ListEquality<Meeting>().equals(other.meetings, meetings);
}

final class SearchFailed extends NearbyResults {
  const SearchFailed();

  @override
  int get hashCode => (SearchFailed).hashCode;

  @override
  bool operator ==(Object other) => other is SearchFailed;
}

@immutable
final class NearbyState {
  const NearbyState({required this.radius, required this.results});

  final Km radius;
  final NearbyResults results;

  NearbyState withRadius({required Km radius}) =>
      NearbyState(radius: radius, results: results);

  NearbyState withResults({required NearbyResults results}) =>
      NearbyState(radius: radius, results: results);

  @override
  int get hashCode => Object.hash(radius, results);

  @override
  bool operator ==(Object other) =>
      other is NearbyState &&
      other.radius == radius &&
      other.results == results;
}

final class NearbyMeetingsController extends Notifier<NearbyState> {
  static const Duration grantedTimeout = Duration(seconds: 10);
  static const Duration promptTimeout = Duration(seconds: 45);
  static const Duration sliderDebounce = Duration(milliseconds: 500);

  late Debouncer _debouncer;
  SearchOrigin _best = const DefaultPosition();
  LocateSlot _locating = const NoLocate();
  SearchTicket _searchTicket = const SearchTicket(0);
  final Set<BusySpan> _searchSpans = {};

  @override
  NearbyState build() {
    _debouncer = ref.read(schedulerProvider).debounce(window: sliderDebounce);
    ref.onDispose(_release);
    unawaited(Future.microtask(_start));
    return const NearbyState(
      radius: Km.searchRadiusFallback,
      results: AwaitingFirstResult(),
    );
  }

  Future<void> locate() async {
    _locating.finish();
    final run = LocateRun(
      span: _tracker.begin(activity: BusyActivity.locating),
    );
    _locating = run;
    final geolocation = ref.read(geolocationPortProvider);
    final access = await geolocation.access();
    if (_freshnessOf(run: run) == RunFreshness.stale) {
      return;
    }
    run.startTimeout(
      cancellation: ref
          .read(schedulerProvider)
          .after(
            delay: switch (access) {
              LocationAccess.granted => grantedTimeout,
              LocationAccess.askable || LocationAccess.refused => promptTimeout,
            },
            action: () => _timedOut(run: run),
          ),
    );
    final granted = switch (access) {
      LocationAccess.granted => LocationAccess.granted,
      LocationAccess.askable ||
      LocationAccess.refused => await geolocation.requestAccess(),
    };
    if (_freshnessOf(run: run) == RunFreshness.stale) {
      return;
    }
    switch (granted) {
      case LocationAccess.granted:
        await _awaitFix(run: run, geolocation: geolocation);
      case LocationAccess.askable || LocationAccess.refused:
        _settle(run: run);
    }
  }

  void changeRadius({required Km radius}) {
    state = state.withRadius(radius: radius);
    _debouncer(action: () => unawaited(_search()));
  }

  Future<void> retry() {
    state = state.withResults(results: const AwaitingFirstResult());
    return _search();
  }

  BusyTracker get _tracker => BusyTracker(bus: ref.read(eventBusProvider));

  Future<void> _start() async {
    final settings = await ref.read(settingsPortProvider).read();
    if (!ref.mounted) {
      return;
    }
    state = state.withRadius(radius: settings.searchRadius);
    await locate();
  }

  Future<void> _awaitFix({
    required LocateRun run,
    required GeolocationPort geolocation,
  }) async {
    final fix = await geolocation.currentPosition();
    if (_freshnessOf(run: run) == RunFreshness.stale) {
      return;
    }
    switch (fix) {
      case Located(:final point):
        _best = DevicePosition(point: point);
        switch (run.phase) {
          case LocatePhase.waiting:
            _settle(run: run);
          case LocatePhase.timedOut:
            unawaited(_search());
          case LocatePhase.finished:
            break;
        }
      case ServicesOff() || AccessRefused() || NoFix():
        switch (run.phase) {
          case LocatePhase.waiting:
            _settle(run: run);
          case LocatePhase.timedOut || LocatePhase.finished:
            break;
        }
    }
  }

  void _settle({required LocateRun run}) {
    run.finish();
    unawaited(_search());
  }

  void _timedOut({required LocateRun run}) {
    run.timeOut();
    unawaited(_search());
  }

  RunFreshness _freshnessOf({required LocateRun run}) =>
      ref.mounted && identical(run, _locating)
      ? RunFreshness.current
      : RunFreshness.stale;

  Future<void> _search() async {
    _searchTicket = _searchTicket.next;
    final ticket = _searchTicket;
    final origin = _best;
    final span = _tracker.begin(activity: BusyActivity.findingMeetings);
    _searchSpans.add(span);
    try {
      final outcome = await ref
          .read(meetingSearchPortProvider)
          .nearbyMeetings(centre: origin.point, radius: state.radius);
      if (!ref.mounted || ticket != _searchTicket) {
        return;
      }
      state = state.withResults(
        results: switch (outcome) {
          Ok(:final value) => Shown(meetings: value, origin: origin),
          Err() => const SearchFailed(),
        },
      );
    } finally {
      span.end();
      _searchSpans.remove(span);
    }
  }

  void _release() {
    _debouncer.dispose();
    _locating.finish();
    for (final span in List.of(_searchSpans)) {
      span.end();
    }
    _searchSpans.clear();
  }
}

extension type const SearchTicket(int value) {
  SearchTicket get next => SearchTicket(value + 1);
}

enum LocatePhase { waiting, timedOut, finished }

enum RunFreshness { current, stale }

sealed class LocateSlot {
  const LocateSlot();

  void finish();
}

final class NoLocate extends LocateSlot {
  const NoLocate();

  @override
  void finish() {}
}

final class LocateRun extends LocateSlot {
  LocateRun({required this.span});

  final BusySpan span;
  final List<Cancellation> _timeouts = [];
  LocatePhase _phase = LocatePhase.waiting;

  LocatePhase get phase => _phase;

  void startTimeout({required Cancellation cancellation}) =>
      _timeouts.add(cancellation);

  void timeOut() {
    _phase = LocatePhase.timedOut;
    span.end();
  }

  @override
  void finish() {
    _phase = LocatePhase.finished;
    for (final timeout in _timeouts) {
      timeout.cancel();
    }
    span.end();
  }
}
