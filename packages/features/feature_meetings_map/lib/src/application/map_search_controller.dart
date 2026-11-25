import 'dart:async';

import 'package:collection/collection.dart';
import 'package:feature_meetings/feature_meetings.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<MapSearchController, MapSearchState> mapSearchProvider =
    NotifierProvider.autoDispose(MapSearchController.new);

@immutable
sealed class MapStage {
  const MapStage();
}

final class PlacingCamera extends MapStage {
  const PlacingCamera();

  @override
  int get hashCode => (PlacingCamera).hashCode;

  @override
  bool operator ==(Object other) => other is PlacingCamera;
}

final class MapDrawn extends MapStage {
  const MapDrawn({required this.initial, required this.myLocation});

  final MapCamera initial;
  final MyLocationLayer myLocation;

  @override
  int get hashCode => Object.hash(initial, myLocation);

  @override
  bool operator ==(Object other) =>
      other is MapDrawn &&
      other.initial == initial &&
      other.myLocation == myLocation;

  @override
  String toString() => 'MapDrawn($initial, ${myLocation.name})';
}

enum MapSearchStatus { notSearched, searching, searched, failed }

final class DetailsTicket {
  DetailsTicket();
}

@immutable
sealed class DetailsRequest {
  const DetailsRequest();
}

final class NoDetails extends DetailsRequest {
  const NoDetails();

  @override
  int get hashCode => (NoDetails).hashCode;

  @override
  bool operator ==(Object other) => other is NoDetails;
}

final class DetailsFor extends DetailsRequest {
  const DetailsFor({required this.meetings, required this.ticket});

  final MeetingIds meetings;
  final DetailsTicket ticket;

  @override
  int get hashCode => Object.hash(meetings, ticket);

  @override
  bool operator ==(Object other) =>
      other is DetailsFor &&
      other.meetings == meetings &&
      identical(other.ticket, ticket);
}

@immutable
final class MapSearchState {
  MapSearchState({
    required this.stage,
    required List<MapMarker> markers,
    required this.status,
    required this.details,
  }) : markers = List.unmodifiable(markers);

  final MapStage stage;
  final List<MapMarker> markers;
  final MapSearchStatus status;
  final DetailsRequest details;

  MapSearchState drawn({required MapDrawn stage}) => MapSearchState(
    stage: stage,
    markers: markers,
    status: status,
    details: details,
  );

  MapSearchState showing({
    required List<MapMarker> markers,
    required MapSearchStatus status,
  }) => MapSearchState(
    stage: stage,
    markers: markers,
    status: status,
    details: details,
  );

  MapSearchState detailing({required DetailsRequest details}) => MapSearchState(
    stage: stage,
    markers: markers,
    status: status,
    details: details,
  );

  @override
  int get hashCode =>
      Object.hash(stage, Object.hashAll(markers), status, details);

  @override
  bool operator ==(Object other) =>
      other is MapSearchState &&
      other.stage == stage &&
      other.status == status &&
      other.details == details &&
      const ListEquality<MapMarker>().equals(other.markers, markers);
}

sealed class _HandleSlot {
  const _HandleSlot();
}

final class _NoHandle extends _HandleSlot {
  const _NoHandle();
}

final class _Bound extends _HandleSlot {
  const _Bound({required this.handle});

  final MapHandle handle;
}

sealed class _View {
  const _View();
}

final class _Undrawn extends _View {
  const _Undrawn();
}

final class _Viewing extends _View {
  const _Viewing({required this.camera});

  final MapCamera camera;
}

sealed class _SearchHistory {
  const _SearchHistory();
}

final class _NeverSearched extends _SearchHistory {
  const _NeverSearched();
}

final class _SearchedOnce extends _SearchHistory {
  const _SearchedOnce({required this.area});

  final SearchedArea area;
}

sealed class _PlaceSlot {
  const _PlaceSlot();
}

final class _NoPlace extends _PlaceSlot {
  const _NoPlace();
}

final class _PlaceShown extends _PlaceSlot {
  const _PlaceShown({required this.marker});

  final PlaceMarker marker;
}

sealed class _InfoSlot {
  const _InfoSlot();
}

final class _NoPendingInfo extends _InfoSlot {
  const _NoPendingInfo();
}

final class _InfoAfterMove extends _InfoSlot {
  const _InfoAfterMove({required this.marker});

  final MarkerKey marker;
}

sealed class _LocateSlot {
  const _LocateSlot();

  void finish();
}

final class _NotLocating extends _LocateSlot {
  const _NotLocating();

  @override
  void finish() {}
}

final class _Locating extends _LocateSlot {
  const _Locating({required this.span, required this.timeout});

  final BusySpan span;
  final Cancellation timeout;

  @override
  void finish() {
    timeout.cancel();
    span.end();
  }
}

final class _SearchRun {
  _SearchRun();
}

final class MapSearchController extends Notifier<MapSearchState>
    implements MapEvents {
  static const Duration locateTimeout = Duration(seconds: 10);

  _HandleSlot _handle = const _NoHandle();
  _View _view = const _Undrawn();
  _SearchHistory _history = const _NeverSearched();
  _PlaceSlot _place = const _NoPlace();
  _InfoSlot _pendingInfo = const _NoPendingInfo();
  _LocateSlot _locating = const _NotLocating();
  _SearchRun _run = _SearchRun();
  List<MeetingPin> _pins = const [];
  final Set<BusySpan> _searchSpans = {};

  static const MarkerClusterer _clusterer = MarkerClusterer();

  @override
  MapSearchState build() {
    ref.onDispose(_release);
    unawaited(Future.microtask(_placeCamera));
    return MapSearchState(
      stage: const PlacingCamera(),
      markers: const [],
      status: MapSearchStatus.notSearched,
      details: const NoDetails(),
    );
  }

  @override
  void created({required MapHandle handle}) => _handle = _Bound(handle: handle);

  @override
  void cameraMoved({required MapCamera camera}) =>
      _view = _Viewing(camera: camera);

  @override
  void cameraIdle() {
    switch ((_pendingInfo, _handle)) {
      case (_InfoAfterMove(:final marker), _Bound(:final handle)):
        _pendingInfo = const _NoPendingInfo();
        unawaited(handle.showInfo(marker: marker));
      case (_NoPendingInfo(), _HandleSlot()) || (_InfoSlot(), _NoHandle()):
        break;
    }
    switch ((_view, _handle, _history)) {
      case (_Viewing(:final camera), _Bound(:final handle), _NeverSearched()):
        unawaited(_search(camera: camera, handle: handle));
      case (
        _Viewing(:final camera),
        _Bound(:final handle),
        _SearchedOnce(:final area),
      ):
        switch (area.needFor(camera: camera)) {
          case SearchNeed.due:
            unawaited(_search(camera: camera, handle: handle));
          case SearchNeed.notDue:
            state = state.showing(
              markers: _markersAt(zoom: camera.zoom),
              status: state.status,
            );
        }
      case (_Undrawn(), _HandleSlot(), _SearchHistory()) ||
          (_View(), _NoHandle(), _SearchHistory()):
        break;
    }
  }

  @override
  void markerTapped({required MarkerKey marker}) {
    final tapped = state.markers.firstWhereOrNull((m) => m.key == marker);
    switch ((tapped, _handle)) {
      case (PinMarker(:final pin), _HandleSlot()):
        state = state.detailing(
          details: DetailsFor(
            meetings: MeetingIds(ids: pin.ids),
            ticket: DetailsTicket(),
          ),
        );
      case (final ClusterMarker cluster, _Bound(:final handle)):
        unawaited(handle.fit(bounds: cluster.bounds));
      case (PlaceMarker(:final key), _Bound(:final handle)):
        unawaited(handle.toggleInfo(marker: key));
      case (ClusterMarker() || PlaceMarker(), _NoHandle()) ||
          (null, _HandleSlot()):
        break;
    }
  }

  Future<void> retry() async {
    switch ((_view, _handle)) {
      case (_Viewing(:final camera), _Bound(:final handle)):
        await _search(camera: camera, handle: handle);
      case (_Undrawn(), _HandleSlot()) || (_View(), _NoHandle()):
        break;
    }
  }

  Future<void> showPlace({
    required PlaceDescription description,
    required GeoPoint point,
  }) async {
    final marker = PlaceMarker(description: description, point: point);
    _place = _PlaceShown(marker: marker);
    state = state.showing(
      markers: _markersAt(zoom: _zoom),
      status: state.status,
    );
    switch (_handle) {
      case _Bound(:final handle):
        _pendingInfo = _InfoAfterMove(marker: marker.key);
        await handle.moveTo(
          camera: MapCamera(target: point, zoom: MapZoom.place),
        );
      case _NoHandle():
        break;
    }
  }

  BusyTracker get _tracker => BusyTracker(bus: ref.read(eventBusProvider));

  MapZoom get _zoom => switch (_view) {
    _Viewing(:final camera) => camera.zoom,
    _Undrawn() => MapZoom.initial,
  };

  Future<void> _placeCamera() async {
    final geolocation = ref.read(geolocationPortProvider);
    final access = await geolocation.access();
    if (!ref.mounted) {
      return;
    }
    switch (access) {
      case LocationAccess.granted:
        _locating = _Locating(
          span: _tracker.begin(activity: BusyActivity.locating),
          timeout: ref
              .read(schedulerProvider)
              .after(
                delay: locateTimeout,
                action: () => _draw(
                  point: GeoPoint.searchFallback,
                  myLocation: MyLocationLayer.shown,
                ),
              ),
        );
        final fix = await geolocation.currentPosition();
        if (!ref.mounted) {
          return;
        }
        _draw(
          point: switch (fix) {
            Located(:final point) => point,
            ServicesOff() ||
            AccessRefused() ||
            NoFix() => GeoPoint.searchFallback,
          },
          myLocation: MyLocationLayer.shown,
        );
      case LocationAccess.askable || LocationAccess.refused:
        _draw(
          point: GeoPoint.searchFallback,
          myLocation: MyLocationLayer.hidden,
        );
    }
  }

  void _draw({required GeoPoint point, required MyLocationLayer myLocation}) {
    switch (state.stage) {
      case MapDrawn():
        return;
      case PlacingCamera():
        _locating.finish();
        _locating = const _NotLocating();
        final camera = MapCamera(target: point, zoom: MapZoom.initial);
        _view = _Viewing(camera: camera);
        state = state.drawn(
          stage: MapDrawn(initial: camera, myLocation: myLocation),
        );
    }
  }

  Future<void> _search({
    required MapCamera camera,
    required MapHandle handle,
  }) async {
    final run = _SearchRun();
    _run = run;
    _pins = const [];
    state = state.showing(
      markers: _markersAt(zoom: camera.zoom),
      status: MapSearchStatus.searching,
    );
    final span = _tracker.begin(activity: BusyActivity.findingMeetings);
    _searchSpans.add(span);
    try {
      final bounds = await handle.visibleBounds();
      if (_freshness(run: run) == _Freshness.stale) {
        return;
      }
      final radius = MapRadius.auto(
        target: camera.target,
        farLeft: bounds.farLeft,
      );
      _history = _SearchedOnce(
        area: SearchedArea(
          centre: camera.target,
          zoom: camera.zoom,
          radius: radius,
        ),
      );
      final outcome = await ref
          .read(meetingSearchPortProvider)
          .meetingSpots(centre: camera.target, radius: radius);
      if (_freshness(run: run) == _Freshness.stale) {
        return;
      }
      switch (outcome) {
        case Ok(:final value):
          _pins = pinsWithin(spots: value, bounds: bounds);
          state = state.showing(
            markers: _markersAt(zoom: _zoom),
            status: MapSearchStatus.searched,
          );
        case Err():
          state = state.showing(
            markers: state.markers,
            status: MapSearchStatus.failed,
          );
      }
    } finally {
      span.end();
      _searchSpans.remove(span);
    }
  }

  _Freshness _freshness({required _SearchRun run}) =>
      ref.mounted && identical(run, _run)
      ? _Freshness.current
      : _Freshness.stale;

  List<MapMarker> _markersAt({required MapZoom zoom}) => List.unmodifiable([
    ..._clusterer.cluster(pins: _pins, zoom: zoom),
    ...switch (_place) {
      _PlaceShown(:final marker) => [marker],
      _NoPlace() => const <MapMarker>[],
    },
  ]);

  void _release() {
    _locating.finish();
    for (final span in List.of(_searchSpans)) {
      span.end();
    }
    _searchSpans.clear();
  }
}

enum _Freshness { current, stale }
