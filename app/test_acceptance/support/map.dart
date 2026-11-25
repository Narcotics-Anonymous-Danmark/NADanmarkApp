import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import 'meetings.dart';
import 'pump_app.dart';

typedef MapApp = ({
  AppHarness app,
  MapSurfaceMimic map,
  BmltServerMimic bmlt,
  PlacesServerMimic places,
});

const RoutePath mapPath = RoutePath('/map-search');
const String tomatoBase =
    'https://tomato.test/main_server/client_interface/json/';
const double degreesPerKm = 0.008993203354928916;

const MapBounds denmark = MapBounds(
  southWest: GeoPoint(latitude: Latitude(54), longitude: Longitude(8)),
  northEast: GeoPoint(latitude: Latitude(58), longitude: Longitude(13)),
);

GeoPoint north(GeoPoint from, {required double km}) => GeoPoint(
  latitude: Latitude(from.latitude.value + km * degreesPerKm),
  longitude: from.longitude,
);

MapBounds farLeftAt({required double km}) => MapBounds(
  southWest: north(GeoPoint.searchFallback, km: -km),
  northEast: north(GeoPoint.searchFallback, km: km),
);

BmltRows spotRows(List<BmltSpotDto> spots) => BmltRows.spots(spots: spots);

BmltSpotDto spot(int id, double latitude, double longitude) => aBmltSpotDto(
  id: id,
  latitude: '$latitude',
  longitude: '$longitude',
);

BmltSpotDto spotNear(int id, {double northKm = 0}) => aBmltSpotAt(
  id: id,
  point: north(GeoPoint.searchFallback, km: northKm),
);

Future<MapApp> pumpMap({
  required WidgetTester tester,
  BmltReply spots = const BmltNoResults(),
  LocationAccess access = LocationAccess.granted,
  FixDelivery delivery = const FixAtOnce(fix: NoFix()),
  ViewportScript viewport = const ViewportFromZoom(),
  MapAvailabilityChoice maps = MapAvailabilityChoice.available,
  Map<String, String> storedValues = inEnglish,
  AppSettle settleWith = AppSettle.idle,
}) async {
  final map = MapSurfaceMimic(camera: fallbackCamera)..viewport = viewport;
  final bmlt = BmltServerMimic()
    ..serve(endpoint: BmltEndpoint.spots, reply: spots);
  final places = PlacesServerMimic();
  final container = realJftContainer(
    storedValues: storedValues,
    bmlt: bmlt,
    map: map,
    places: places,
    maps: maps,
  );
  container.geolocation
    ..currentAccess = access
    ..delivery = delivery;
  final app = await pumpApp(
    tester: tester,
    container: container,
    initialLocation: mapPath.value,
    settleWith: settleWith,
  );
  addTearDown(app.dispose);
  return (app: app, map: map, bmlt: bmlt, places: places);
}

List<Uri> spotRequests(MapApp subject) =>
    subject.bmlt.requestsTo(endpoint: BmltEndpoint.spots);

Finder marker(String key) => find.byKey(Key('map-marker-$key'));

Finder markerText(String label) => find.text(label);

Future<void> moveMap(
  WidgetTester tester,
  MapApp subject,
  MapCamera camera,
) async {
  subject.map.moveCamera(to: camera);
  await settle(tester);
}

Future<void> moveMapWhileSearching(
  WidgetTester tester,
  MapApp subject,
  MapCamera camera,
) async {
  subject.map.moveCamera(to: camera);
  await pumpFrames(tester);
}

Future<void> typePlace(
  WidgetTester tester,
  MapApp subject,
  String text,
) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}

Future<void> pauseTyping(WidgetTester tester, MapApp subject) async {
  subject.app.time.advance(by: const Duration(milliseconds: 300));
  await settle(tester);
}

Finder suggestion(int index) => find.byKey(Key('place-suggestion-$index'));

Finder get detailsModal => find.byKey(const Key('meeting-details'));

Finder loadingBarFinder() => find.byKey(const Key('global-loading-bar'));
