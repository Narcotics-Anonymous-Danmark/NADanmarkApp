import 'dart:ui' as ui;

import 'package:adapter_google_maps/src/map_conversions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

extension type const MarkerAsset(String path) {
  MarkerAsset.cluster({required ClusterBucket bucket})
    : this('$_folder/${bucket.name}.png');

  static const String _folder = 'packages/adapter_google_maps/assets/markers';

  static const MarkerAsset blue = MarkerAsset('$_folder/marker_blue.png');
  static const MarkerAsset red = MarkerAsset('$_folder/marker_red.png');
}

@immutable
final class ClusterIconKey {
  const ClusterIconKey({required this.bucket, required this.meetings});

  final ClusterBucket bucket;
  final MeetingCount meetings;

  @override
  int get hashCode => Object.hash(bucket, meetings);

  @override
  bool operator ==(Object other) =>
      other is ClusterIconKey &&
      other.bucket == bucket &&
      other.meetings == meetings;
}

final class MarkerIcons {
  MarkerIcons({required this.bundle});

  static const double pinWidth = 28;
  static const double pinHeight = 34;
  static const double clusterPixelRatio = 1.6;
  static const double labelSize = 15;
  static const Offset pinAnchor = Offset(0.5, 1);
  static const Offset clusterAnchor = Offset(0.5, 0.5);

  final AssetBundle bundle;
  final Expando<Future<Set<Marker>>> _markerSets = Expando();
  final Map<ClusterIconKey, Future<BitmapDescriptor>> _clusterIcons = {};

  Future<Set<Marker>> markersFor({
    required List<MapMarker> markers,
    required MapEvents events,
  }) => _markerSets[markers] ??= _build(markers: markers, events: events);

  Future<Set<Marker>> _build({
    required List<MapMarker> markers,
    required MapEvents events,
  }) async => Set.unmodifiable(
    await Future.wait(
      markers.map((marker) => _marker(marker: marker, events: events)),
    ),
  );

  Future<Marker> _marker({
    required MapMarker marker,
    required MapEvents events,
  }) async => Marker(
    markerId: MarkerId(marker.key.value),
    position: latLngOf(point: marker.point),
    consumeTapEvents: true,
    onTap: () => events.markerTapped(marker: marker.key),
    anchor: switch (marker) {
      ClusterMarker() => clusterAnchor,
      PinMarker() || PlaceMarker() => pinAnchor,
    },
    infoWindow: switch (marker) {
      PlaceMarker(:final description) => InfoWindow(title: description.value),
      PinMarker() || ClusterMarker() => InfoWindow.noText,
    },
    icon: switch (marker) {
      PinMarker(pin: SinglePin()) => _pin(asset: MarkerAsset.blue),
      PinMarker(pin: SharedPin()) => _pin(asset: MarkerAsset.red),
      ClusterMarker(:final bucket, :final meetings) => await clusterIcon(
        key: ClusterIconKey(bucket: bucket, meetings: meetings),
      ),
      PlaceMarker() => BitmapDescriptor.defaultMarker,
    },
  );

  BitmapDescriptor _pin({required MarkerAsset asset}) =>
      AssetMapBitmap(asset.path, width: pinWidth, height: pinHeight);

  Future<BitmapDescriptor> clusterIcon({required ClusterIconKey key}) =>
      _clusterIcons[key] ??= _paintCluster(key: key);

  Future<BitmapDescriptor> _paintCluster({required ClusterIconKey key}) async =>
      BytesMapBitmap(
        await paintClusterPng(key: key),
        imagePixelRatio: clusterPixelRatio,
      );

  Future<Uint8List> paintClusterPng({required ClusterIconKey key}) async {
    final data = await bundle.load(
      MarkerAsset.cluster(bucket: key.bucket).path,
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawImage(image, Offset.zero, Paint());
    final paragraph =
        (ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.center,
                  fontSize: labelSize * clusterPixelRatio,
                  fontWeight: FontWeight.bold,
                ),
              )
              ..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)))
              ..addText('${key.meetings.value}'))
            .build()
          ..layout(ui.ParagraphConstraints(width: width));
    canvas.drawParagraph(
      paragraph,
      Offset(0, (height - paragraph.height) / 2),
    );
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(image.width, image.height);
    final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    rendered.dispose();
    picture.dispose();
    return png?.buffer.asUint8List() ?? Uint8List(0);
  }
}
