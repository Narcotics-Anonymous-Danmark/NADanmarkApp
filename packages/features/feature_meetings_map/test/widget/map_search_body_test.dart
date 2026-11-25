@Tags(['widget'])
library;

import 'package:feature_meetings_map/feature_meetings_map.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/misc.dart';

const GeoPoint nearFallback = GeoPoint(
  latitude: Latitude(55.48),
  longitude: Longitude(8.47),
);

({TestContainer harness, MapSurfaceMimic map}) mapPage({
  MapAvailability Function(MapSurfaceMimic map)? availability,
  FixDelivery delivery = const FixAtOnce(fix: NoFix()),
  List<MeetingSpot> spots = const [],
}) {
  final map = MapSurfaceMimic(
    camera: const MapCamera(
      target: GeoPoint.searchFallback,
      zoom: MapZoom.initial,
    ),
  );
  final harness = TestContainer.build(
    extra: <Override>[
      mapAvailabilityProvider.overrideWithValue(
        availability?.call(map) ?? MapsAvailable(surface: map.surface),
      ),
    ],
  );
  addTearDown(harness.dispose);
  harness.geolocation.delivery = delivery;
  harness.meetingSearch.spots = Ok(value: spots);
  return (harness: harness, map: map);
}

Future<void> pumpMapPage(WidgetTester tester, TestContainer harness) =>
    pumpFeature(
      tester: tester,
      harness: harness,
      child: goldenFrame(
        child: SizedBox(
          height: 560,
          child: ColoredBox(
            color: NaColors.light.background,
            child: const MapSearchBody(),
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadNaFonts);

  testWidgets('shows "Map unavailable" without a key', (tester) async {
    final page = mapPage(availability: (map) => const MapsUnavailable());
    await pumpMapPage(tester, page.harness);
    expect(find.text('Kortet er ikke tilgængeligt'), findsOneWidget);
    expect(page.harness.geolocation.calls, const CallCount(0));
    await expectAccessible(tester);
    await expectGolden(finder: goldenTarget, name: 'map_unavailable');
  });

  testWidgets('keeps the map area empty while placing the camera', (
    tester,
  ) async {
    final page = mapPage(delivery: const FixNever());
    await pumpMapPage(tester, page.harness);
    expect(find.byKey(const Key('map-placing')), findsOneWidget);
    expect(find.byKey(const Key('map-surface-mimic')), findsNothing);
    await expectGolden(finder: goldenTarget, name: 'map_placing');
    page.harness.time.advance(by: const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('draws the surface with the pins of the first search', (
    tester,
  ) async {
    final page = mapPage(
      spots: [
        const MeetingSpot(id: MeetingId(1), point: nearFallback),
        const MeetingSpot(id: MeetingId(2), point: nearFallback),
      ],
    );
    await pumpMapPage(tester, page.harness);
    expect(find.byKey(const Key('map-marker-pin-1')), findsOneWidget);
    expect(find.text('red 1,2'), findsOneWidget);
    expect(page.map.myLocation, MyLocationLayer.shown);
    await expectAccessible(tester);
  });

  testWidgets('lists suggestions under the field and picks one', (
    tester,
  ) async {
    final page = mapPage();
    await pumpMapPage(tester, page.harness);
    await tester.enterText(find.byType(EditableText), 'Aar');
    page.harness.time.advance(by: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('place-suggestion-0')), findsOneWidget);
    expect(find.text('Aarhus C, Aarhus, Denmark'), findsOneWidget);
    await expectAccessible(tester);
    await expectGolden(finder: goldenTarget, name: 'map_suggestions');
    await tester.tap(find.byKey(const Key('place-suggestion-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('place-suggestions')), findsNothing);
    expect(find.text('place Aarhus, Denmark'), findsOneWidget);
    expect(page.map.moves, [
      MapCamera(target: aarhusPlace.point, zoom: MapZoom.place),
    ]);
  });

  testWidgets('shows the failure over the map and retries', (tester) async {
    final page = mapPage(
      spots: [const MeetingSpot(id: MeetingId(1), point: nearFallback)],
    );
    page.harness.meetingSearch.queueSpots(
      result: const Err(error: NetworkFailure(detail: 'offline')),
    );
    await pumpMapPage(tester, page.harness);
    expect(find.byKey(const Key('map-search-failed')), findsOneWidget);
    await expectAccessible(tester);
    await expectGolden(finder: goldenTarget, name: 'map_failed');
    await tester.tap(find.byKey(const Key('map-search-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-search-failed')), findsNothing);
    expect(find.byKey(const Key('map-marker-pin-1')), findsOneWidget);
  });

  testWidgets('a pin tap opens the meeting details', (tester) async {
    final page = mapPage(
      spots: [const MeetingSpot(id: MeetingId(115), point: nearFallback)],
    );
    await pumpMapPage(tester, page.harness);
    await tester.tap(find.byKey(const Key('map-marker-pin-115')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meeting-details')), findsOneWidget);
    expect(find.byKey(const Key('meeting-card-115')), findsOneWidget);
    await tester.tap(find.byKey(const Key('meeting-details-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meeting-details')), findsNothing);
  });
}
