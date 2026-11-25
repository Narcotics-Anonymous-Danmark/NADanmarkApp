import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

typedef MimicSurface =
    Widget Function({
      required MapCamera initial,
      required MyLocationLayer myLocation,
      required List<MapMarker> markers,
      required MapEvents events,
    });

sealed class ViewportScript {
  const ViewportScript();
}

final class ViewportFromZoom extends ViewportScript {
  const ViewportFromZoom();
}

final class ViewportFixed extends ViewportScript {
  const ViewportFixed({required this.bounds});

  final MapBounds bounds;
}

sealed class SurfaceEvents {
  const SurfaceEvents();
}

final class NoSurfaceEvents extends SurfaceEvents {
  const NoSurfaceEvents();
}

final class AttachedEvents extends SurfaceEvents {
  const AttachedEvents({required this.events});

  final MapEvents events;
}

enum InfoWindowState { shown, hidden }

final class MapSurfaceMimic implements MapHandle {
  MapSurfaceMimic({required this.camera});

  static const double viewportPixels = 400;
  static const double tilePixels = 256;

  MapCamera camera;
  ViewportScript viewport = const ViewportFromZoom();
  SurfaceEvents _events = const NoSurfaceEvents();
  final Set<MapEvents> _created = {};
  final List<MapCamera> moves = [];
  final List<MapBounds> fits = [];
  final List<MarkerKey> infoToggles = [];
  final Map<MarkerKey, InfoWindowState> infoWindows = {};
  List<MapMarker> markers = const [];
  MyLocationLayer myLocation = MyLocationLayer.hidden;
  final List<MapCamera> builtAt = [];

  MimicSurface get surface =>
      ({
        required initial,
        required myLocation,
        required markers,
        required events,
      }) => MapSurfaceMimicView(
        mimic: this,
        initial: initial,
        myLocation: myLocation,
        markers: markers,
        events: events,
      );

  void attach({
    required MapCamera initial,
    required MyLocationLayer myLocation,
    required List<MapMarker> markers,
    required MapEvents events,
  }) {
    this.markers = markers;
    this.myLocation = myLocation;
    _events = AttachedEvents(events: events);
    if (_created.add(events)) {
      camera = initial;
      builtAt.add(initial);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        events
          ..created(handle: this)
          ..cameraMoved(camera: initial)
          ..cameraIdle();
      });
    }
  }

  void connect({required MapEvents events}) =>
      _events = AttachedEvents(events: events);

  void moveCamera({required MapCamera to}) {
    camera = to;
    switch (_events) {
      case AttachedEvents(:final events):
        events
          ..cameraMoved(camera: to)
          ..cameraIdle();
      case NoSurfaceEvents():
        break;
    }
  }

  void tap({required MarkerKey marker}) {
    switch (_events) {
      case AttachedEvents(:final events):
        events.markerTapped(marker: marker);
      case NoSurfaceEvents():
        break;
    }
  }

  MapBounds get currentBounds => switch (viewport) {
    ViewportFixed(:final bounds) => bounds,
    ViewportFromZoom() => _derivedBounds(),
  };

  MapBounds _derivedBounds() {
    final lngSpan =
        viewportPixels / tilePixels * 360 / math.pow(2, camera.zoom.value);
    final latSpan =
        lngSpan * math.cos(camera.target.latitude.value * math.pi / 180);
    final lat = camera.target.latitude.value;
    final lng = camera.target.longitude.value;
    return MapBounds(
      southWest: GeoPoint(
        latitude: Latitude(lat - latSpan / 2),
        longitude: Longitude(lng - lngSpan / 2),
      ),
      northEast: GeoPoint(
        latitude: Latitude(lat + latSpan / 2),
        longitude: Longitude(lng + lngSpan / 2),
      ),
    );
  }

  @override
  Future<MapBounds> visibleBounds() async => currentBounds;

  @override
  Future<void> moveTo({required MapCamera camera}) async {
    moves.add(camera);
    scheduleMicrotask(() => moveCamera(to: camera));
  }

  @override
  Future<void> fit({required MapBounds bounds}) async {
    fits.add(bounds);
    final zoom = MapZoom(math.min(21, camera.zoom.value + 2));
    scheduleMicrotask(
      () => moveCamera(
        to: MapCamera(
          target: GeoPoint(
            latitude: Latitude(
              (bounds.southWest.latitude.value +
                      bounds.northEast.latitude.value) /
                  2,
            ),
            longitude: Longitude(
              (bounds.southWest.longitude.value +
                      bounds.northEast.longitude.value) /
                  2,
            ),
          ),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Future<void> showInfo({required MarkerKey marker}) async =>
      infoWindows[marker] = InfoWindowState.shown;

  @override
  Future<void> toggleInfo({required MarkerKey marker}) async {
    infoToggles.add(marker);
    infoWindows[marker] = switch (infoWindows[marker] ??
        InfoWindowState.hidden) {
      InfoWindowState.shown => InfoWindowState.hidden,
      InfoWindowState.hidden => InfoWindowState.shown,
    };
  }
}

final class MapSurfaceMimicView extends StatelessWidget {
  const MapSurfaceMimicView({
    required this.mimic,
    required this.initial,
    required this.myLocation,
    required this.markers,
    required this.events,
    super.key,
  });

  final MapSurfaceMimic mimic;
  final MapCamera initial;
  final MyLocationLayer myLocation;
  final List<MapMarker> markers;
  final MapEvents events;

  @override
  Widget build(BuildContext context) {
    mimic.attach(
      initial: initial,
      myLocation: myLocation,
      markers: markers,
      events: events,
    );
    return ColoredBox(
      key: const Key('map-surface-mimic'),
      color: const Color(0xFFFFFFFF),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final marker in markers)
              GestureDetector(
                key: Key('map-marker-${marker.key.value}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => events.markerTapped(marker: marker.key),
                child: SizedBox(
                  height: 32,
                  child: Text(
                    markerLabel(marker: marker),
                    style: NaTheme.of(context).typography.body.copyWith(
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String markerLabel({required MapMarker marker}) => switch (marker) {
  PinMarker(pin: SinglePin(:final id)) => 'blue ${id.value}',
  PinMarker(pin: SharedPin(:final ids)) =>
    'red ${ids.map((id) => id.value).join(',')}',
  ClusterMarker(:final bucket, :final meetings) =>
    'cluster ${bucket.name} ${meetings.value}',
  PlaceMarker(:final description) => 'place ${description.value}',
};
