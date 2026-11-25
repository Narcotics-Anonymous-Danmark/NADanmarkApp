import 'package:adapter_google_maps/src/google_map_handle.dart';
import 'package:adapter_google_maps/src/map_conversions.dart';
import 'package:adapter_google_maps/src/marker_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class GoogleMapSurface extends StatelessWidget {
  const GoogleMapSurface({
    required this.icons,
    required this.initial,
    required this.myLocation,
    required this.markers,
    required this.events,
    super.key,
  });

  final MarkerIcons icons;
  final MapCamera initial;
  final MyLocationLayer myLocation;
  final List<MapMarker> markers;
  final MapEvents events;

  @override
  Widget build(BuildContext context) => FutureBuilder<Set<Marker>>(
    future: icons.markersFor(markers: markers, events: events),
    builder: (context, snapshot) => GoogleMap(
      key: const Key('google-map'),
      initialCameraPosition: cameraPositionOf(camera: initial),
      gestureRecognizers: const {
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
      myLocationEnabled: switch (myLocation) {
        MyLocationLayer.shown => true,
        MyLocationLayer.hidden => false,
      },
      myLocationButtonEnabled: switch (myLocation) {
        MyLocationLayer.shown => true,
        MyLocationLayer.hidden => false,
      },
      markers: snapshot.data ?? const <Marker>{},
      onMapCreated: (controller) =>
          events.created(handle: GoogleMapHandle(controller: controller)),
      onCameraMove: (position) =>
          events.cameraMoved(camera: mapCameraOf(position: position)),
      onCameraIdle: events.cameraIdle,
    ),
  );
}
