@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/map.dart';
import '../support/pump_app.dart';

const GeoPoint aarhus = GeoPoint(
  latitude: Latitude(56.15),
  longitude: Longitude(10.2),
);

String cardKeyOf(Widget widget) => switch (widget.key) {
  ValueKey<String>(:final value) => value,
  Key() || null => '',
};

String loaderText(WidgetTester tester) =>
    tester.widget<NaIndeterminateBar>(loadingBarFinder()).statusText;

void main() {
  group('Requirement: Initial camera', () {
    testWidgets('Position arrives in time', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        delivery: const FixAfter(
          delay: Duration(seconds: 3),
          fix: Located(point: aarhus),
        ),
        settleWith: AppSettle.frames,
      );
      expect(loaderText(tester), 'Locating…');
      subject.app.time.advance(by: const Duration(seconds: 3));
      await settle(tester);
      expect(subject.map.builtAt, const [
        MapCamera(target: aarhus, zoom: MapZoom.initial),
      ]);
      expect(subject.map.myLocation, MyLocationLayer.shown);
    });

    testWidgets('Position times out', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        delivery: const FixNever(),
        settleWith: AppSettle.frames,
      );
      subject.app.time.advance(by: const Duration(seconds: 9));
      await pumpFrames(tester);
      expect(subject.map.builtAt, isEmpty);
      subject.app.time.advance(by: const Duration(seconds: 1));
      await settle(tester);
      expect(subject.map.builtAt, const [fallbackCamera]);
    });

    testWidgets('No permission draws immediately', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        access: LocationAccess.askable,
      );
      expect(subject.map.builtAt, const [fallbackCamera]);
      expect(subject.map.myLocation, MyLocationLayer.hidden);
      expect(subject.app.geolocation.requestCalls, const CallCount(0));
    });
  });

  group('Requirement: Initial search', () {
    testWidgets('First search runs on map ready', (tester) async {
      final subject = await pumpMap(tester: tester);
      final request = spotRequests(subject).single;
      expect(request.queryParameters['lat_val'], '55.476224');
      expect(request.queryParameters['long_val'], '8.4606976');
    });
  });

  group('Requirement: Auto radius', () {
    testWidgets('Radius follows the visible region', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        viewport: ViewportFixed(bounds: farLeftAt(km: 20)),
      );
      expect(
        spotRequests(subject).single.queryParameters['geo_width_km'],
        '22',
      );
    });

    testWidgets('Pins query carries the exact parameters', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        viewport: ViewportFixed(bounds: farLeftAt(km: 20)),
      );
      expect(
        spotRequests(subject).single.toString(),
        '$tomatoBase?switcher=GetSearchResults'
        '&data_field_key=longitude,latitude,id_bigint&geo_width_km=22'
        '&long_val=8.4606976&lat_val=55.476224'
        '&sort_keys=longitude,latitude&callingApp=bmlt_search_3_ionic',
      );
    });
  });

  group('Requirement: Re-search on camera move', () {
    testWidgets('Small pan keeps pins', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(1)]),
        viewport: ViewportFixed(bounds: farLeftAt(km: 20)),
      );
      await moveMap(
        tester,
        subject,
        MapCamera(
          target: north(GeoPoint.searchFallback, km: 1),
          zoom: MapZoom.initial,
        ),
      );
      expect(spotRequests(subject), hasLength(1));
      expect(marker('pin-1'), findsOneWidget);
    });

    testWidgets('Large pan re-searches', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(1)]),
        viewport: ViewportFixed(bounds: farLeftAt(km: 20)),
      );
      final held = subject.bmlt.hold(endpoint: BmltEndpoint.spots);
      await moveMapWhileSearching(
        tester,
        subject,
        MapCamera(
          target: north(GeoPoint.searchFallback, km: 3),
          zoom: MapZoom.initial,
        ),
      );
      expect(spotRequests(subject), hasLength(2));
      expect(
        spotRequests(subject).last.queryParameters['lat_val'],
        '${north(GeoPoint.searchFallback, km: 3).latitude.value}',
      );
      expect(marker('pin-1'), findsNothing);
      expect(loaderText(tester), 'Finding meetings…');
      held.release();
      await settle(tester);
      expect(marker('pin-1'), findsOneWidget);
    });

    testWidgets('Zooming out re-searches', (tester) async {
      final subject = await pumpMap(tester: tester);
      final far = north(GeoPoint.searchFallback, km: 200);
      await moveMap(
        tester,
        subject,
        MapCamera(target: far, zoom: const MapZoom(10)),
      );
      expect(spotRequests(subject), hasLength(2));
      await moveMap(
        tester,
        subject,
        MapCamera(target: far, zoom: const MapZoom(9)),
      );
      expect(spotRequests(subject), hasLength(3));
    });
  });

  group('Requirement: Pins for visible meetings', () {
    testWidgets('Co-located meetings become one red pin', (tester) async {
      await pumpMap(
        tester: tester,
        viewport: const ViewportFixed(bounds: denmark),
        spots: spotRows([
          spot(1, 55.6761, 12.5683),
          spot(2, 55.6762, 12.5683),
          spot(3, 55.6761, 12.5684),
        ]),
      );
      expect(markerText('red 1,2,3'), findsOneWidget);
    });

    testWidgets('Distinct meetings get blue pins', (tester) async {
      await pumpMap(
        tester: tester,
        viewport: const ViewportFixed(bounds: denmark),
        spots: spotRows([spot(1, 55.6761, 12.5683), spot(2, 55.6806, 12.5683)]),
      );
      expect(markerText('blue 1'), findsOneWidget);
      expect(markerText('blue 2'), findsOneWidget);
    });

    testWidgets('Meetings outside the view are skipped', (tester) async {
      await pumpMap(
        tester: tester,
        viewport: const ViewportFixed(bounds: denmark),
        spots: spotRows([spot(1, 55.6761, 12.5683), spot(2, 59.9, 10.75)]),
      );
      expect(marker('pin-1'), findsOneWidget);
      expect(marker('pin-2'), findsNothing);
    });

    testWidgets('Rows without coordinates are skipped', (tester) async {
      await pumpMap(
        tester: tester,
        viewport: const ViewportFixed(bounds: denmark),
        spots: spotRows([
          aBmltSpotDto(id: 1, latitude: ''),
          aBmltSpotDto(id: 2, latitude: 'x'),
          spot(3, 55.6761, 12.5683),
        ]),
      );
      expect(marker('pin-1'), findsNothing);
      expect(marker('pin-2'), findsNothing);
      expect(marker('pin-3'), findsOneWidget);
    });
  });

  group('Requirement: Clustering', () {
    testWidgets('Three close pins cluster', (tester) async {
      await pumpMap(
        tester: tester,
        spots: spotRows([
          spotNear(1, northKm: 0.2),
          spotNear(2, northKm: 0.4),
          spotNear(3, northKm: 0.6),
        ]),
      );
      expect(markerText('cluster m1 3'), findsOneWidget);
      expect(marker('pin-1'), findsNothing);
    });

    testWidgets('Two close pins stay pins', (tester) async {
      await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(1, northKm: 0.2), spotNear(2, northKm: 0.4)]),
      );
      expect(marker('pin-1'), findsOneWidget);
      expect(marker('pin-2'), findsOneWidget);
    });

    testWidgets('Cluster label counts meetings', (tester) async {
      await pumpMap(
        tester: tester,
        spots: spotRows([
          spotNear(1, northKm: 0.2),
          spotNear(2, northKm: 0.4),
          spotNear(7, northKm: 0.6),
          spotNear(8, northKm: 0.6),
          spotNear(9, northKm: 0.6),
        ]),
      );
      expect(markerText('cluster m1 5'), findsOneWidget);
    });

    testWidgets('Tapping a cluster zooms into it', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([
          spotNear(1, northKm: 0.2),
          spotNear(2, northKm: 0.4),
          spotNear(3, northKm: 0.6),
        ]),
      );
      await tester.tap(marker('cluster-1'));
      await settle(tester);
      expect(subject.map.fits, [
        MapBounds(
          southWest: north(GeoPoint.searchFallback, km: 0.2),
          northEast: north(GeoPoint.searchFallback, km: 0.6),
        ),
      ]);
      expect(detailsModal, findsNothing);
    });

    testWidgets('No clusters from zoom 15', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([
          spotNear(1, northKm: 0.2),
          spotNear(2, northKm: 0.4),
          spotNear(3, northKm: 0.6),
        ]),
      );
      await moveMap(
        tester,
        subject,
        const MapCamera(
          target: GeoPoint.searchFallback,
          zoom: MapZoom.clusteringLimit,
        ),
      );
      expect(spotRequests(subject), hasLength(1));
      expect(marker('pin-1'), findsOneWidget);
      expect(marker('pin-2'), findsOneWidget);
      expect(marker('pin-3'), findsOneWidget);
    });
  });

  group('Requirement: Tap pin opens details', () {
    testWidgets('Blue pin opens one meeting', (tester) async {
      await pumpMap(tester: tester, spots: spotRows([spotNear(115)]));
      await tester.tap(marker('pin-115'));
      await settle(tester);
      expect(detailsModal, findsOneWidget);
      expect(find.byKey(const Key('meeting-card-115')), findsOneWidget);
    });

    testWidgets('Red pin opens all co-located meetings', (tester) async {
      await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(115), spotNear(351)]),
      );
      await tester.tap(marker('pin-115'));
      await settle(tester);
      expect(find.byKey(const Key('meeting-card-115')), findsOneWidget);
      expect(find.byKey(const Key('meeting-card-351')), findsOneWidget);
    });
  });

  group('Requirement: Places search', () {
    testWidgets('Predictions appear while typing', (tester) async {
      final subject = await pumpMap(tester: tester);
      await typePlace(tester, subject, 'Aarh');
      await pauseTyping(tester, subject);
      expect(
        find.descendant(
          of: suggestion(0),
          matching: find.text('Aarhus, Denmark'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: suggestion(1),
          matching: find.text('Aarhus C, Aarhus, Denmark'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Autocomplete waits for typing to pause', (tester) async {
      final subject = await pumpMap(tester: tester);
      await typePlace(tester, subject, 'A');
      await typePlace(tester, subject, 'Aa');
      await typePlace(tester, subject, 'Aar');
      await pauseTyping(tester, subject);
      final requests = subject.places.requestsTo(
        endpoint: PlacesEndpoint.autocomplete,
      );
      expect(requests, hasLength(1));
      expect(requests.single.queryParameters['input'], 'Aar');
      expect(requests.single.queryParameters['language'], 'en');
    });

    testWidgets('Selecting a place moves the camera', (tester) async {
      final subject = await pumpMap(tester: tester);
      await typePlace(tester, subject, 'Aarh');
      await pauseTyping(tester, subject);
      await tester.tap(suggestion(0));
      await settle(tester);
      expect(markerText('place Aarhus, Denmark'), findsOneWidget);
      expect(subject.map.moves, [
        MapCamera(target: aarhusPlace.point, zoom: MapZoom.place),
      ]);
      expect(suggestion(0), findsNothing);
      expect(
        subject.map.infoWindows[MarkerKey.place],
        InfoWindowState.shown,
      );
      expect(spotRequests(subject), hasLength(2));
    });

    testWidgets('Clearing the field clears the predictions', (tester) async {
      final subject = await pumpMap(tester: tester);
      await typePlace(tester, subject, 'Aarh');
      await pauseTyping(tester, subject);
      expect(suggestion(0), findsOneWidget);
      await tester.tap(find.byKey(const Key('na-search-clear')));
      await tester.pump();
      expect(suggestion(0), findsNothing);
    });

    testWidgets('Tapping the place marker toggles its info window', (
      tester,
    ) async {
      final subject = await pumpMap(tester: tester);
      await typePlace(tester, subject, 'Aarh');
      await pauseTyping(tester, subject);
      await tester.tap(suggestion(0));
      await settle(tester);
      await tester.tap(marker('place'));
      await settle(tester);
      expect(subject.map.infoToggles, const [MarkerKey.place]);
      expect(
        subject.map.infoWindows[MarkerKey.place],
        InfoWindowState.hidden,
      );
      expect(detailsModal, findsNothing);
    });
  });

  group('Requirement: API key configuration', () {
    testWidgets('Missing key degrades gracefully', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        maps: MapAvailabilityChoice.unavailable,
      );
      expect(pageText('Map unavailable'), findsOneWidget);
      expect(subject.app.geolocation.calls, const CallCount(0));
      expect(subject.bmlt.requests, isEmpty);
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-settings')));
      await settle(tester);
      expect(pageText('Settings'), findsWidgets);
    });
  });

  group('Requirement: Map search failure', () {
    testWidgets('Failure shows an error over the map', (tester) async {
      await pumpMap(tester: tester, spots: const BmltUnreachable());
      expect(pageText('The meetings could not be loaded'), findsOneWidget);
      expect(find.byKey(const Key('map-search-retry')), findsOneWidget);
      expect(loadingBarFinder(), findsNothing);
    });

    testWidgets('Try again searches the current camera', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: const BmltUnreachable(),
      );
      subject.bmlt.serve(
        endpoint: BmltEndpoint.spots,
        reply: spotRows([spotNear(1)]),
      );
      await tester.tap(find.byKey(const Key('map-search-retry')));
      await settle(tester);
      expect(marker('pin-1'), findsOneWidget);
      expect(pageText('The meetings could not be loaded'), findsNothing);
      expect(
        spotRequests(subject).map((uri) => uri.queryParameters['lat_val']),
        ['55.476224', '55.476224'],
      );
    });
  });

  group('Requirement: Newest map search wins', () {
    testWidgets('Older pins result is discarded', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(1)]),
        settleWith: AppSettle.frames,
      );
      final held = subject.bmlt.hold(endpoint: BmltEndpoint.spots);
      await settle(tester);
      expect(spotRequests(subject), hasLength(1));
      subject.bmlt.serve(
        endpoint: BmltEndpoint.spots,
        reply: spotRows([spotNear(2, northKm: 40)]),
      );
      await moveMap(
        tester,
        subject,
        MapCamera(
          target: north(GeoPoint.searchFallback, km: 40),
          zoom: MapZoom.initial,
        ),
      );
      expect(marker('pin-2'), findsOneWidget);
      held.release();
      await settle(tester);
      expect(marker('pin-2'), findsOneWidget);
      expect(marker('pin-1'), findsNothing);
    });
  });

  group('Requirement: Leaving the map', () {
    testWidgets('Leaving during a search hides the loader', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        settleWith: AppSettle.frames,
      );
      final held = subject.bmlt.hold(endpoint: BmltEndpoint.spots);
      await moveMapWhileSearching(
        tester,
        subject,
        MapCamera(
          target: north(GeoPoint.searchFallback, km: 300),
          zoom: MapZoom.initial,
        ),
      );
      expect(loadingBarFinder(), findsOneWidget);
      await tester.tap(find.byKey(const Key('menu-button')));
      await pumpFrames(tester);
      await tester.tap(find.byKey(const Key('menu-settings')));
      await pumpFrames(tester);
      await settle(tester);
      expect(loadingBarFinder(), findsNothing);
      held.release();
      await settle(tester);
      expect(loadingBarFinder(), findsNothing);
    });
  });

  group('Requirement: Meeting details modal', () {
    testWidgets('Modal shows all co-located meetings', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(115), spotNear(351)]),
      );
      subject.bmlt.serve(
        endpoint: BmltEndpoint.byId,
        reply: BmltRows.meetings(
          meetings: [aBmltMeetingDto(id: 351), aBmltMeetingDto(id: 115)],
        ),
      );
      await tester.tap(marker('pin-115'));
      await settle(tester);
      final cards = find.descendant(
        of: detailsModal,
        matching: find.byWidgetPredicate(
          (widget) => cardKeyOf(widget).startsWith('meeting-card-'),
        ),
      );
      expect(tester.widgetList(cards).map(cardKeyOf), [
        'meeting-card-351',
        'meeting-card-115',
      ]);
    });

    testWidgets('By-id query carries every id', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(123), spotNear(456)]),
      );
      await tester.tap(marker('pin-123'));
      await settle(tester);
      expect(
        subject.bmlt.requestsTo(endpoint: BmltEndpoint.byId).single.toString(),
        '$tomatoBase?switcher=GetSearchResults'
        '&meeting_ids%5B%5D=123&meeting_ids%5B%5D=456',
      );
    });

    testWidgets('Close dismisses the modal', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(115)]),
      );
      await tester.tap(marker('pin-115'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('meeting-details-close')));
      await settle(tester);
      expect(detailsModal, findsNothing);
      expect(marker('pin-115'), findsOneWidget);
      expect(subject.map.builtAt, hasLength(1));
      expect(spotRequests(subject), hasLength(1));
    });

    testWidgets('Failed details can be retried', (tester) async {
      final subject = await pumpMap(
        tester: tester,
        spots: spotRows([spotNear(115)]),
      );
      subject.bmlt.serve(
        endpoint: BmltEndpoint.byId,
        reply: const BmltUnreachable(),
      );
      await tester.tap(marker('pin-115'));
      await settle(tester);
      expect(
        find.descendant(
          of: detailsModal,
          matching: find.text('The meetings could not be loaded'),
        ),
        findsOneWidget,
      );
      subject.bmlt.serve(
        endpoint: BmltEndpoint.byId,
        reply: BmltRows.meetings(meetings: [aBmltMeetingDto()]),
      );
      await tester.tap(find.byKey(const Key('meeting-details-retry')));
      await settle(tester);
      expect(find.byKey(const Key('meeting-card-115')), findsOneWidget);
    });
  });
}
