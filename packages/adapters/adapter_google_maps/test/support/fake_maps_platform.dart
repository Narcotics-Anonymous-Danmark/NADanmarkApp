import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

final class RecordedMap {
  final List<MarkerUpdates> markerUpdates = [];
  final List<CameraUpdate> cameraUpdates = [];
  final List<MarkerId> shownInfo = [];
  final List<MarkerId> hiddenInfo = [];
}

final class FakeMapsPlatform extends MethodChannelGoogleMapsFlutter {
  final StreamController<MapEvent<Object?>> events =
      StreamController<MapEvent<Object?>>.broadcast();
  final Map<int, RecordedMap> maps = {};
  final Set<MarkerId> infoOpen = {};
  LatLngBounds region = LatLngBounds(
    southwest: const LatLng(55, 8),
    northeast: const LatLng(56, 9),
  );

  RecordedMap get last => maps.values.last;

  @override
  Future<void> init(int mapId) async => maps[mapId] = RecordedMap();

  @override
  Future<void> updateMapConfiguration(
    MapConfiguration configuration, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateMarkers(
    MarkerUpdates markerUpdates, {
    required int mapId,
  }) async => maps[mapId]?.markerUpdates.add(markerUpdates);

  @override
  Future<void> updatePolygons(
    PolygonUpdates polygonUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolylines(
    PolylineUpdates polylineUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateCircles(
    CircleUpdates circleUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateHeatmaps(
    HeatmapUpdates heatmapUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {}

  @override
  Future<void> updateClusterManagers(
    ClusterManagerUpdates clusterManagerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async => maps[mapId]?.cameraUpdates.add(cameraUpdate);

  @override
  Future<LatLngBounds> getVisibleRegion({required int mapId}) async => region;

  @override
  Future<void> showMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) async {
    infoOpen.add(markerId);
    maps[mapId]?.shownInfo.add(markerId);
  }

  @override
  Future<void> hideMarkerInfoWindow(
    MarkerId markerId, {
    required int mapId,
  }) async {
    infoOpen.remove(markerId);
    maps[mapId]?.hiddenInfo.add(markerId);
  }

  @override
  Future<bool> isMarkerInfoWindowShown(
    MarkerId markerId, {
    required int mapId,
  }) async => infoOpen.contains(markerId);

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) =>
      events.stream.where((e) => e is CameraMoveStartedEvent).cast();

  @override
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) =>
      events.stream.where((e) => e is CameraMoveEvent).cast();

  @override
  Stream<CameraIdleEvent> onCameraIdle({required int mapId}) =>
      events.stream.where((e) => e is CameraIdleEvent).cast();

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) =>
      events.stream.where((e) => e is MarkerTapEvent).cast();

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<PolygonTapEvent> onPolygonTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<CircleTapEvent> onCircleTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<MapTapEvent> onTap({required int mapId}) => const Stream.empty();

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<GroundOverlayTapEvent> onGroundOverlayTap({required int mapId}) =>
      const Stream.empty();

  @override
  Stream<PointOfInterestTapEvent> onPointOfInterestTap({required int mapId}) =>
      const Stream.empty();

  @override
  void dispose({required int mapId}) {}
}

void mockPlatformViews(TestDefaultBinaryMessenger messenger) =>
    messenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async => switch (call.method) {
        'create' => 0,
        String() => null,
      },
    );
