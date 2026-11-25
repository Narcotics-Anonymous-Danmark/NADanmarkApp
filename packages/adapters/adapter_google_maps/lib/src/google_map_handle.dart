import 'package:adapter_google_maps/src/map_conversions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class GoogleMapHandle implements MapHandle {
  const GoogleMapHandle({required this.controller});

  static const double fitPadding = 48;

  final GoogleMapController controller;

  @override
  Future<MapBounds> visibleBounds() async =>
      mapBoundsOf(bounds: await controller.getVisibleRegion());

  @override
  Future<void> moveTo({required MapCamera camera}) => controller.animateCamera(
    CameraUpdate.newCameraPosition(cameraPositionOf(camera: camera)),
  );

  @override
  Future<void> fit({required MapBounds bounds}) => controller.animateCamera(
    CameraUpdate.newLatLngBounds(latLngBoundsOf(bounds: bounds), fitPadding),
  );

  @override
  Future<void> showInfo({required MarkerKey marker}) =>
      controller.showMarkerInfoWindow(MarkerId(marker.value));

  @override
  Future<void> toggleInfo({required MarkerKey marker}) async {
    final id = MarkerId(marker.value);
    switch (await controller.isMarkerInfoWindowShown(id)) {
      case true:
        await controller.hideMarkerInfoWindow(id);
      case false:
        await controller.showMarkerInfoWindow(id);
    }
  }
}
