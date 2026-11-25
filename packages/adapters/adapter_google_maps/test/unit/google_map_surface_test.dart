@Tags(['unit'])
library;

import 'dart:ui' as ui;

import 'package:adapter_google_maps/adapter_google_maps.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import '../support/fake_maps_platform.dart';

final class RecordingEvents implements MapEvents {
  final List<MapHandle> handles = [];
  final List<MapCamera> moves = [];
  final List<MarkerKey> taps = [];
  CallCount idles = const CallCount(0);

  @override
  void created({required MapHandle handle}) => handles.add(handle);

  @override
  void cameraMoved({required MapCamera camera}) => moves.add(camera);

  @override
  void cameraIdle() => idles = idles.next;

  @override
  void markerTapped({required MarkerKey marker}) => taps.add(marker);
}

const MapCamera esbjerg = MapCamera(
  target: GeoPoint.searchFallback,
  zoom: MapZoom.initial,
);

const GeoPoint aarhus = GeoPoint(
  latitude: Latitude(56.15),
  longitude: Longitude(10.2),
);

List<MapMarker> sampleMarkers() => [
  const PinMarker(
    pin: SinglePin(id: MeetingId(1), point: aarhus),
  ),
  PinMarker(
    pin: SharedPin(ids: const [MeetingId(2), MeetingId(3)], point: aarhus),
  ),
  ClusterMarker(
    pins: List.generate(
      3,
      (index) => SinglePin(id: MeetingId(10 + index), point: aarhus),
    ),
  ),
  const PlaceMarker(
    description: PlaceDescription('Aarhus, Denmark'),
    point: aarhus,
  ),
];

Future<({FakeMapsPlatform platform, RecordingEvents events})> pumpSurface(
  WidgetTester tester, {
  List<MapMarker> markers = const [],
  MyLocationLayer myLocation = MyLocationLayer.shown,
}) async {
  final platform = FakeMapsPlatform();
  GoogleMapsFlutterPlatform.instance = platform;
  mockPlatformViews(tester.binding.defaultBinaryMessenger);
  final events = RecordingEvents();
  final icons = MarkerIcons(bundle: RepoAssetBundle.locate());
  await tester.runAsync(
    () => icons.markersFor(markers: markers, events: events),
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GoogleMapSurface(
        icons: icons,
        initial: esbjerg,
        myLocation: myLocation,
        markers: markers,
        events: events,
      ),
    ),
  );
  await tester.runAsync(
    () => icons.markersFor(markers: markers, events: events),
  );
  await tester.pumpAndSettle();
  return (platform: platform, events: events);
}

Set<Marker> currentMarkers(FakeMapsPlatform platform) => {
  ...platform.last.markerUpdates.expand((update) => update.markersToAdd),
};

Marker markerWith(FakeMapsPlatform platform, String key) =>
    currentMarkers(platform).firstWhere((m) => m.markerId.value == key);

void main() {
  group('GoogleMapSurface', () {
    testWidgets('starts at the initial camera and reports the handle', (
      tester,
    ) async {
      final subject = await pumpSurface(tester);
      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.initialCameraPosition, cameraPositionOf(camera: esbjerg));
      expect(map.myLocationEnabled, isTrue);
      expect(map.myLocationButtonEnabled, isTrue);
      expect(map.compassEnabled, isTrue);
      expect(map.zoomControlsEnabled, isTrue);
      expect(
        map.gestureRecognizers.single.constructor(),
        isA<EagerGestureRecognizer>(),
      );
      expect(subject.events.handles.single, isA<GoogleMapHandle>());
    });

    testWidgets('hides the location layer without permission', (tester) async {
      await pumpSurface(tester, myLocation: MyLocationLayer.hidden);
      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.myLocationEnabled, isFalse);
      expect(map.myLocationButtonEnabled, isFalse);
    });

    testWidgets('forwards camera moves and idles', (tester) async {
      final subject = await pumpSurface(tester);
      final mapId = subject.platform.maps.keys.single;
      subject.platform.events
        ..add(
          CameraMoveEvent(
            mapId,
            const CameraPosition(target: LatLng(56.15, 10.2), zoom: 11),
          ),
        )
        ..add(CameraIdleEvent(mapId));
      await tester.pump();
      expect(subject.events.moves, [
        const MapCamera(target: aarhus, zoom: MapZoom(11)),
      ]);
      expect(subject.events.idles, const CallCount(1));
    });

    testWidgets('draws every marker and reports taps by key', (tester) async {
      final subject = await pumpSurface(tester, markers: sampleMarkers());
      expect(
        currentMarkers(subject.platform).map((m) => m.markerId.value).toSet(),
        {'pin-1', 'pin-2', 'cluster-10', 'place'},
      );
      expect(
        currentMarkers(subject.platform).every((m) => m.consumeTapEvents),
        isTrue,
      );
      expect(
        markerWith(subject.platform, 'place').infoWindow.title,
        'Aarhus, Denmark',
      );
      expect(
        markerWith(subject.platform, 'cluster-10').anchor,
        MarkerIcons.clusterAnchor,
      );
      expect(
        (markerWith(subject.platform, 'pin-1').icon as AssetMapBitmap)
            .assetName,
        MarkerAsset.blue.path,
      );
      expect(
        (markerWith(subject.platform, 'pin-2').icon as AssetMapBitmap)
            .assetName,
        MarkerAsset.red.path,
      );
      markerWith(subject.platform, 'pin-2').onTap?.call();
      expect(subject.events.taps, const [MarkerKey('pin-2')]);
    });
  });

  group('GoogleMapHandle', () {
    testWidgets('reads the visible region as bounds', (tester) async {
      final subject = await pumpSurface(tester);
      final handle = subject.events.handles.single;
      expect(
        await handle.visibleBounds(),
        const MapBounds(
          southWest: GeoPoint(latitude: Latitude(55), longitude: Longitude(8)),
          northEast: GeoPoint(latitude: Latitude(56), longitude: Longitude(9)),
        ),
      );
    });

    testWidgets('moves and fits the camera', (tester) async {
      final subject = await pumpSurface(tester);
      final handle = subject.events.handles.single;
      await handle.moveTo(
        camera: const MapCamera(target: aarhus, zoom: MapZoom.place),
      );
      await handle.fit(
        bounds: const MapBounds(southWest: aarhus, northEast: aarhus),
      );
      expect(
        subject.platform.last.cameraUpdates.map((u) => u.toJson()).toList(),
        [
          CameraUpdate.newCameraPosition(
            const CameraPosition(target: LatLng(56.15, 10.2), zoom: 10),
          ).toJson(),
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: const LatLng(56.15, 10.2),
              northeast: const LatLng(56.15, 10.2),
            ),
            GoogleMapHandle.fitPadding,
          ).toJson(),
        ],
      );
    });

    testWidgets('shows and toggles info windows', (tester) async {
      final subject = await pumpSurface(tester);
      final handle = subject.events.handles.single;
      await handle.showInfo(marker: MarkerKey.place);
      await handle.toggleInfo(marker: MarkerKey.place);
      await handle.toggleInfo(marker: MarkerKey.place);
      expect(subject.platform.last.shownInfo, const [
        MarkerId('place'),
        MarkerId('place'),
      ]);
      expect(subject.platform.last.hiddenInfo, const [MarkerId('place')]);
    });
  });

  group('MarkerIcons', () {
    testWidgets('the same marker list is converted once', (tester) async {
      final icons = MarkerIcons(bundle: RepoAssetBundle.locate());
      final markers = sampleMarkers();
      final events = RecordingEvents();
      final same = await tester.runAsync(() async {
        final first = icons.markersFor(markers: markers, events: events);
        final second = icons.markersFor(markers: markers, events: events);
        await first;
        return identical(first, second);
      });
      expect(same, isTrue);
    });

    testWidgets('cluster icons keep the bucket image size', (tester) async {
      final icons = MarkerIcons(bundle: RepoAssetBundle.locate());
      final png = await tester.runAsync(
        () => icons.paintClusterPng(
          key: const ClusterIconKey(
            bucket: ClusterBucket.m3,
            meetings: MeetingCount(64),
          ),
        ),
      );
      final size = await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(png ?? Uint8List(0));
        final frame = await codec.getNextFrame();
        return Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
      expect(size, const Size(66, 65));
    });
  });
}
