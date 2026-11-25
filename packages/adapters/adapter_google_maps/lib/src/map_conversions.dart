import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:na_kernel/na_kernel.dart';

LatLng latLngOf({required GeoPoint point}) =>
    LatLng(point.latitude.value, point.longitude.value);

GeoPoint geoPointOf({required LatLng latLng}) => GeoPoint(
  latitude: Latitude(latLng.latitude),
  longitude: Longitude(latLng.longitude),
);

CameraPosition cameraPositionOf({required MapCamera camera}) => CameraPosition(
  target: latLngOf(point: camera.target),
  zoom: camera.zoom.value,
);

MapCamera mapCameraOf({required CameraPosition position}) => MapCamera(
  target: geoPointOf(latLng: position.target),
  zoom: MapZoom(position.zoom),
);

MapBounds mapBoundsOf({required LatLngBounds bounds}) => MapBounds(
  southWest: geoPointOf(latLng: bounds.southwest),
  northEast: geoPointOf(latLng: bounds.northeast),
);

LatLngBounds latLngBoundsOf({required MapBounds bounds}) => LatLngBounds(
  southwest: latLngOf(point: bounds.southWest),
  northeast: latLngOf(point: bounds.northEast),
);
