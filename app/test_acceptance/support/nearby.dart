import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import 'meetings.dart';
import 'pump_app.dart';

const tomato = 'https://tomato.test/main_server/client_interface/json/';
const RoutePath nearbyPath = RoutePath('/location-search');
const nearbySlider = Key('nearby-radius-slider');
const locateButton = Key('nearby-locate');
const locationNotSetNote = Key('nearby-location-not-set');

final GeoPoint aarhus = aGeoPoint(
  latitude: const Latitude(56.15),
  longitude: const Longitude(10.2),
);

Uri nearbyUri({required GeoPoint at, required Km radius}) => Uri.parse(
  '$tomato?switcher=GetSearchResults&geo_width_km=${radius.value}'
  '&long_val=${at.longitude.value}&lat_val=${at.latitude.value}'
  '&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic',
);

List<Uri> nearbyRequests(BmltServerMimic bmlt) =>
    bmlt.requestsTo(endpoint: BmltEndpoint.nearby);

BmltRows nearbyRows(List<BmltMeetingDto> meetings) =>
    BmltRows.meetings(meetings: meetings);

BmltRows mondayMeeting() => nearbyRows([aBmltMeetingDto(id: 1, weekday: 2)]);

BmltRows fridayMeetings() => nearbyRows([
  aBmltMeetingDto(id: 2, weekday: 6),
  aBmltMeetingDto(id: 3, weekday: 6),
]);

BmltServerMimic nearbyServing({BmltReply reply = const BmltNoResults()}) =>
    BmltServerMimic()..serve(endpoint: BmltEndpoint.nearby, reply: reply);

Future<AppHarness> pumpNearby({
  required WidgetTester tester,
  required BmltServerMimic bmlt,
  Map<String, String> storedValues = inEnglish,
  LocationAccess access = LocationAccess.granted,
  PromptAnswer answer = PromptAnswer.grant,
  FixDelivery delivery = const FixAtOnce(fix: NoFix()),
  RoutePath location = nearbyPath,
  AppSettle settleWith = AppSettle.idle,
}) {
  final container = realJftContainer(storedValues: storedValues, bmlt: bmlt);
  container.geolocation
    ..currentAccess = access
    ..promptAnswer = answer
    ..delivery = delivery;
  return pumpApp(
    tester: tester,
    container: container,
    initialLocation: location.value,
    settleWith: settleWith,
  );
}

FixDelivery locatedAt(GeoPoint point) => FixAtOnce(fix: Located(point: point));

Future<void> advance({
  required WidgetTester tester,
  required AppHarness app,
  required Duration by,
}) async {
  app.time.advance(by: by);
  await pumpFrames(tester);
}

Future<void> moveNearbySlider({
  required WidgetTester tester,
  required Km to,
}) async {
  final rect = tester.getRect(find.byKey(nearbySlider));
  final fraction =
      (to.value - Km.searchRadiusMinimum.value) /
      (Km.searchRadiusMaximum.value - Km.searchRadiusMinimum.value);
  final x = (rect.left + 12 + fraction * (rect.width - 24)).clamp(
    rect.left + 1,
    rect.right - 1,
  );
  await tester.tapAt(Offset(x, rect.center.dy));
  await pumpFrames(tester);
}

Km sliderValue(WidgetTester tester) =>
    Km(tester.widget<NaSlider>(find.byKey(nearbySlider)).value);

Finder loadingBar() => find.byKey(const Key('global-loading-bar'));

String loadingText(WidgetTester tester) =>
    tester.widget<NaIndeterminateBar>(loadingBar()).statusText;
